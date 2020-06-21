#import bindings  waiting module mutual imports
#export bindings

import sequtils

proc initMemory*() = 
  echo "Init KDB Memory"
  discard khp("", -1)

proc kind*(x: K): KKind {.inline.} =
  x.k.kind

proc len*(x: K0): int64 =
  if isNil(x):
    return 0
  case x.kind
  of kList: x.kLen
  of kVecBool: x.boolLen
  of kVecGUID: x.guidLen
  of kVecByte: x.byteLen
  of kVecShort: x.shortLen
  of kVecInt: x.intLen
  of kVecLong: x.longLen
  of kVecReal: x.realLen
  of kVecFloat: x.floatLen
  of kVecSym: x.stringLen
  of kVecTimestamp: x.tsLen
  of kVecMonth: x.monthLen
  of kVecDate: x.dateLen
  of kVecDateTime: x.dtLen
  of kVecTime: x.timeLen
  of kVecMinute: x.minuteLen
  of kVecTimespan: x.tpLen
  of kVecSecond: x.secondLen
  of kDict: x.keys.len
  of kTable: x.dict.values.kArr[0].len
  else: raise newException(KError, "Not List: " & $x.kind)

proc len*(x: K): int =
  len(x.k).int

proc add*(x: var K0, v: K)

proc add*(x: var K0, v: bool) =
  if x.kind == KKind.kVecBool:
    ja(x.addr, v.unsafeAddr)
  else:
    add(x, v.toK())

proc add*(x: var K, v: bool) =
  add(x.k, v)

proc add*(x: var K0, v: GUID) =
  if x.kind == KKind.kVecGUID:
    ja(x.addr, v.unsafeAddr)
  else:
    add(x, v.toK())

proc add*(x: var K, v: GUID) =
  add(x.k, v)

proc add*(x: var K0, v: int32) =
  if x.kind == KKind.kVecInt:
    ja(x.addr, v.unsafeAddr)
  else:
    add(x, v.toK())

proc add*(x: var K, v: int32) =
  add(x.k, v)

proc add*(x: var K0, v: int64) =
  case x.kind
  of KKind.kVecLong:
    ja(x.addr, v.unsafeAddr)
  of KKind.kVecTimestamp:
    ja(x.addr, v.unsafeAddr)
  else:
    add(x, v.toK())

proc add*(x: var K, v: int64) =
  add(x.k, v)

proc add*(x: var K, v: int) =
  add(x.k, v.int64)

proc add*(x: var K0, v: float64) =
  ja(x.addr, v.unsafeAddr)

proc add*(x: var K, v: float) =
  add(x.k, v)

proc add*(x: var K0, v: cstring) =
  if x.kind == KKind.kVecSym:
    js(x.addr, ss(v))
  else:
    add(x, v.toK())

proc add*(x: var K, v: string) =
  add(x.k, v.cstring)

proc add*(x: var K0, v: Time) =
  case x.kind
  of KKind.kVecTimestamp:
    let n = v.toNanos()
    ja(x.addr, n.unsafeAddr)
  else:
    let n = v.toNanos()
    add(x, n.toK())

proc add*(x: var K0, v: DateTime) =
  case x.kind
  of KKind.kVecDateTime:
    let n = v.toMillis()
    ja(x.addr, n.unsafeAddr)
  else:
    let n = v.toMillis()
    add(x, n.toK())

proc add*(x: var K, v: DateTime) =
  add(x.k, v)

proc checkAdd(x: var K0, v: K): bool =
  case x.kind
  of kList: result = true
  of kVecLong: result = v.k.kind == KKind.kLong
  of kVecSym: result = v.k.kind == KKind.kSym
  else: raise newException(KError, "checkAdd[K] is not supported for " & $x.kind)

proc add*(x: var K0, v: K) =
  case x.kind
  of kList: jk(x.addr, r1(v.k))
  of kVecLong: add(x, v.k.jj)
  of kVecFloat: add(x, v.k.ff)
  of kVecSym:
    case v.k.kind
    of kSym: add(x, v.k.ss)
    # of kVecChar: add(x, cast[cstring](v.k.charArr)) # TODO: not sure
    else: raise newException(KError, "add[KVecSym] cannot add " & $v.k.kind)
  of kVecDateTime:
    assert v.k.kind == KKind.kDateTime
    add(x, v.k.dt)
  of kVecTimestamp:
    assert v.k.kind == KKind.kTimestamp
    add(x, v.k.ts)
  of kVecGUID: add(x, v.k.gg)
  else: raise newException(KError, "add[K] is not supported for " & $x.kind)

proc add*(x: var K, v: K) =
  add(x.k, v)

proc newKVec*[T](): K =
  let k0 = ktn(typeToKKind[T]().toVecKKind().int, 0)
  result = K(k: k0)

proc newKVecTyped*(k: KKind): K =
  let t = if 236 < k.int and k.int < 255: 256 - k.int else: k.int
  let k0 = ktn(t, 0)
  result = K(k: k0)

proc newKList*(): K =
  result = K(k: knk(0))

proc newKDict*[KT, VT](): K =
  # let header = ktn(typeToKVecKind[KT]().int, 0)
  # let data = ktn(typeToKVecKind[VT]().int, 0)
  let header = newKVec[KT]()
  let data = newKVec[VT]()
  result = K(k: xD(r1(header.k), r1(data.k)))  # TODO: not sure about refC == 1 or 0

proc newKDict*(keys, values: K): K =
  result = K(k: xD(r1(keys.k), r1(values.k)))

proc addColumn*[T](t: var K, name: string, col: K) =
  if isNil(t.k):
    var header = newKVec[KSym]()
    header.k.add(name.cstring)
    var data = newKList()
    data.add(col)
    let dict = newKDict(header, data)
    t.k = xT(r1(dict.k))
  else:
    assert typeToKKind[T]().toVecKKind().int == col.k.kind.int
    if t.len != col.len:
      raise newException(KError, "column.len is not equal to table.len")
    t.k.dict.keys.add(name.cstring)
    t.k.dict.values.add(%col.k)

proc addColumn*[T](t: var K, name: string) =
  if isNil(t.k):
    var header = newKVec[KSym]()
    header.k.add(name.cstring)
    let colData = newKVec[T]()
    var data = newKList()
    data.add(colData)
    let dict = newKDict(header, data)
    t.k = xT(r1(dict.k))
  else:
    t.k.dict.keys.add(name.cstring)
    var c1 = newKVec[T]()
    t.k.dict.values.add(%c1.k)

# proc eval*(s: string, args: varargs[K]): K =
#   let h = 0.SocketHandle

#   let k0 = case args.len
#               of 0: k(h, s.cstring, nil)
#               of 1: k(h, s.cstring, args[0].k, nil)
#               of 2: k(h, s.cstring, args[0].k, args[1].k, nil)
#               of 3: k(h, s.cstring, args[0].k, args[1].k, args[2].k, nil)
#               else: raise newException(KError, "Cannot exec with more than 3 arguments")

#   if k0.kind == KKind.kError:
#     echo $k0.msg
#     raise newException(KError, $k0.msg)

#   K(k: k0)

proc dictLookup(d: K0, k: K): K {.gcsafe.}

include iters

proc deleteColumn*(t: var K, name: string) =  ## TODO: optimize lookup with additional table
  assert not isNil(t.k)
  let d = t.k.dict
  let keyK = name.toSym()
  var i = 0
  var found = false
  for x in toK(d.keys):
    if x == keyK:
      found = true
      break
    inc(i)
  if found:
    d.keys.stringLen.dec()
    d.values.kLen.dec()
    let newLen = d.keys.len() - i
    r0(d.values.kArr[i])
    moveMem(d.keys.stringArr[i].addr, d.keys.stringArr[i+1].addr, newLen * sizeof(cstring))
    moveMem(d.values.kArr[i].addr, d.values.kArr[i+1].addr, newLen * sizeof(K0))

  else:
    raise newException(KeyError, "key not found: " & name)

proc addColumnWithKind*(t: var K, name: string, k: KKind, col: K) =
  if isNil(t.k):
    var header = newKVecTyped(k)
    header.k.add(name.cstring)
    var data = newKList()
    data.add(col)
    let dict = newKDict(header, data)
    t.k = xT(r1(dict.k))
  else:
    assert k.int == col.k.kind.int
    if t.len != col.len:
      raise newException(KError, "column.len is not equal to table.len")
    t.k.dict.keys.add(name.cstring)
    t.k.dict.values.add(%col.k)

# proc addRow*(t: var K, vals: openArray[K]) =
#   assert t.k != nil
#   assert t.k.dict.values.len == vals.len
#   for i in 0..<t.k.dict.values.len:
#     t.k.dict.values.kArr[i].add(vals[i])

proc addRow*(t: var K, vals: varargs[K]) =
  assert not isNil(t.k)
  assert t.k.dict.values.len == vals.len
  for i in 0..<t.k.dict.values.len:
    t.k.dict.values.kArr[i].add(vals[i])

proc newKTable*(cols: openArray[(string, KKind)]): K =
  if cols.len > 0:
    let header = toSymVec(cols.mapIt(it[0]))
    let data = %cols.mapIt(newKVecTyped(it[1]))
    let dict = newKDict(header, data)
    K(k: xT(r1(dict.k)))
  else:
    K(k: nil)

proc newKTable*(): K =
  K(k: nil) # empty table is nil
#  xT(fromDict)

proc `[]`*(x: K, c: string): K =
  assert x.kind == KKind.kTable
  dictLookup(x.k.dict, c.toSym())

proc `[]=`*(x: var K0, k: K, v: K) =
  case x.kind
  of kDict:
    if x.values.checkAdd(v):
      x.keys.add(k)
      x.values.add(v)
    else:
      raise newException(KError, "checkAdd failed for " & $x.values.kind)
  else: raise newException(KError, "[K;K;K]`[]=` is not supported for " & $x.kind)

proc `[]=`*(x: var K, k: K, v: K) =
  `[]=`(x.k, k, v)

proc `[]=`*(x: var K0, i: int64, v: K) =
  case x.kind
  of kVecFloat: x.floatArr[i] = v.k.ff
  else: `[]=`(x, i.toK(), v)

proc `[]=`*(x: var K, i: int64, v: K) =
  `[]=`(x.k, i, v)

# proc `[]=`*(x: var K, i: SomeInteger, v: K) =
#   case x.k.kind
#   of kDict:
#     x.k.keys.add(i)
#     x.k.values.add(v.k)
#   of kVecSym:
#     assert v.k.kind == kSym     # /-------\
#     x.k.stringArr[i] = v.k.ss   # TODO: fix
#   else: raise newException(KError, "[K;int;K]`[]=` is not supported for " & $x.k.kind)

proc columns*(x: K): seq[string] =
  assert x.kind == KKind.kTable
  # result: seq[string]
  var cResult: seq[cstring]
  cResult.add toOpenArray(x.k.dict.keys.stringArr.addr, 0, x.k.dict.keys.stringLen.int - 1)
  cResult.mapIt($it)

proc dictLookup(d: K0, k: K): K {.gcsafe.} =  ## TODO: optimize lookup with additional table
  var i = 0
  for x in toK(d.keys):
    if x == k:
      return d.values[i]
    inc(i)
  raise newException(KeyError, "key not found: " & $k)
