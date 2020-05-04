#import bindings  waiting module mutual imports
#export bindings

proc initMemory*() = 
  echo "Init KDB Memory"
  discard khp("", -1)

proc kind*(x: K): KKind {.inline.} =
  x.k.kind

proc len*(x: K0): int64 =
  if x == nil:
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

iterator items*(x: K0): K0 =
  case x.kind
  of kList:
    var i = 0
    while i < x.kLen:
      yield x.kArr[i]
      inc(i)
  of kVecBool:
    var i = 0
    while i < x.boolLen:
      yield x.intArr[i].toK().k
      inc(i)
  of kVecInt:
    var i = 0
    while i < x.intLen:
      yield x.intArr[i].toK().k
      inc(i)
  of kVecLong:
    var i = 0
    while i < x.longLen:
      yield x.longArr[i].toK().k
      inc(i)
  of kVecSym:
    var i = 0
    while i < x.stringLen:
      yield x.stringArr[i].toSym().k
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.kind)

iterator items*(x: K): K =
  case x.k.kind
  of kList:
    var i = 0
    while i < x.k.kLen:
      let v = r1(x.k.kArr[i])
      yield v
      inc(i)
  of kVecBool:
    var i = 0
    while i < x.k.boolLen:
      yield x.k.boolArr[i].toK()
      inc(i)
  of kVecInt:
    var i = 0
    while i < x.k.intLen:
      yield x.k.intArr[i].toK()
      inc(i)
  of kVecLong:
    var i = 0
    while i < x.k.longLen:
      yield x.k.longArr[i].toK()
      inc(i)
  of kVecSym:
    var i = 0
    while i < x.k.stringLen:
      yield x.k.stringArr[i].toSym()
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.k.kind)

proc `[]`*(x: K0, i: int64): K

iterator pairs*(x: K): (K, K) =
  case x.k.kind
  of KKind.kDict:
    var i = 0
    for k in x.k.keys:
      yield (k.toK(), x.k.values[i])
      inc(i)
  else:
    var i = 0
    for v in x:
      yield (i.toK(), v)
      inc(i)

# iterator mitems*(x: K0): var K0 =
  # case x.kind
  # of kList:
    # var i = 0
    # while i < x.kLen:
      # yield x.kArr[i]
      # inc(i)
  # of kVecInt:
  #   var i = 0
  #   while i < x.intLen:
  #     yield x.intArr[i]
  #     inc(i)
  # of kVecSym:
    # var i = 0
    # while i < x.stringLen:
      # yield x.stringArr[i]
      # inc(i)
  # else: raise newException(KError, "mitems is not supported for " & $x.kind)

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

proc add*(x: var K0, v: DateTime) =
  case x.kind
  of KKind.kVecDateTime:
    let n = v.toMillis()
    ja(x.addr, n.unsafeAddr)
  of KKind.kVecTimestamp:
    let n = v.toNanos()
    ja(x.addr, n.unsafeAddr)
  else:
    let n = v.toNanos()
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
  of kVecTimestamp: add(x, v.k.ts)
  of kVecGUID: add(x, v.k.gg)
  else: raise newException(KError, "add[K] is not supported for " & $x.kind)

proc add*(x: var K, v: K) =
  add(x.k, v)

proc newKVec*[T](): K =
  let k0 = ktn(typeToKType[T](), 0)
  result = K(k: k0)

proc newKList*(): K =
  result = K(k: knk(0))

proc newKDict*[KT, VT](): K =
  # let header = ktn(typeToKType[KT](), 0)
  # let data = ktn(typeToKType[VT](), 0)
  let header = newKVec[KT]()
  let data = newKVec[VT]()
  result = K(k: xD(r1(header.k), r1(data.k)))  # TODO: not sure about refC == 1 or 0

proc newKDict*(keys, values: K): K =
  result = K(k: xD(r1(keys.k), r1(values.k)))

proc addColumn*[T](t: var K, name: string) =
  if t.k == nil:
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
    t.k.dict.values.add(r1(c1.k))

proc addRow*(t: var K, vals: varargs[K]) =
  assert t.k.dict.values.len == vals.len
  for i in 0..<t.k.dict.values.len:
    t.k.dict.values.kArr[i].add(vals[i])

# proc newKTable*(fromDict = newKDict(10, 0)): K =
proc newKTable*(): K =
  K(k: nil) # empty table is nil
#  xT(fromDict)

proc dictLookup(d: K0, k: K): K

proc `[]`*(x: K0, i: int64): K =
  if x.kind != KKind.kDict:
    if i >= x.len:
      raise newException(KError, "index 10 not in 0 .. " & $(x.len - 1))
  case x.kind
  of kVecBool: x.boolArr[i].toK()
  of kVecGUID: x.guidArr[i].toK()
  of kVecByte: x.byteArr[i].toK()
  of kVecShort: x.shortArr[i].toK()
  of kVecInt: x.intArr[i].toK()
  of kVecLong: x.longArr[i].toK()
  of kVecReal: x.realArr[i].toK()
  of kVecFloat: x.floatArr[i].toK()
  of kVecSym: x.stringArr[i].toSym()
  of kVecTimestamp: x.tsArr[i].toKTimestamp()
  of kVecMonth: x.monthArr[i].toKMonth()
  of kVecDate: x.dateArr[i].toKDate()
  of kVecDateTime: x.dtArr[i].toKDateTime()
  of kVecTimespan: x.tpArr[i].toKTimespan()
  of kVecMinute: x.minuteArr[i].toKMinute()
  of kVecSecond: x.secondArr[i].toKSecond()
  of kVecTime: x.timeArr[i].toKTime()
  of kDict: dictLookup(x, i.toK())
  of kList: r1(x.kArr[i])
  else: raise newException(KError, "`[]` is not supported for " & $x.kind)

proc `[]`*(x: K, i: int64): K =
  result = x.k[i]
  # discard r1(result.k)  # TODO: not sure

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

proc `==`*(a: K, b: K): bool =
  if a.k.kind != b.k.kind:
    return false
  case a.k.kind
  of kBool: a.k.bb == b.k.bb
  of kGUID: a.k.gg.g == b.k.gg.g
  of kByte: a.k.by == b.k.by
  of kShort: a.k.sh == b.k.sh
  of kInt: a.k.ii == b.k.ii
  of kLong: a.k.jj == b.k.jj
  of kReal: a.k.rr == b.k.rr
  of kFloat: a.k.ff == b.k.ff
  of kChar: a.k.ch == b.k.ch
  of kSym: a.k.ss == b.k.ss
  of kTimestamp: a.k.ts == b.k.ts
  of kDateTime: a.k.dt == b.k.dt
  of kVecChar: cast[cstring](a.k.charArr) == cast[cstring](b.k.charArr)  # TODO not sure
  of kVecFloat:
    var vA: seq[float]
    vA.add toOpenArray(a.k.floatArr.addr, 0, a.k.floatLen.int)
    var vB: seq[float]
    vB.add toOpenArray(b.k.floatArr.addr, 0, b.k.floatLen.int)
    vA == vB
  else: raise newException(KError, "`==` is not supported for " & $a.k.kind)

proc dictLookup(d: K0, k: K): K =
  var i = 0
  for x in d.keys:
    if x == k:
      return d.values[i]
    inc(i)
  raise newException(KeyError, "key not found: " & $k)

proc connect*(hostname: string, port: int): FileHandle =
  result = khp(hostname, port)
  if result <= 0:
    raise newException(KError, "Connection error")

proc execIntenal(h: FileHandle, s: string, args: varargs[K]): K0 =
  case args.len
  of 0: result = k(h, s.cstring, nil)
  of 1: result = k(h, s.cstring, args[0].k, nil)
  of 2: result = k(h, s.cstring, args[0].k, args[1].k, nil)
  of 3: result = k(h, s.cstring, args[0].k, args[1].k, args[2].k, nil)
  else: raise newException(KError, "Cannot exec with more than 3 arguments")

  if result.kind == KKind.kError:
    raise newException(KErrorRemote, $result.msg)

proc exec*(h: FileHandle, s: string, args: varargs[K]): K =
  let k0 = execIntenal(h, s, args)

  if k0.kind == KKind.kError:
    raise newException(KErrorRemote, $result.k.msg)
  else:
    K(k: k0)

proc exec0*(h: FileHandle, s: string): K =
  exec(h, s, nil.toK())

proc execAsync*(h: FileHandle, s: string, args: varargs[K]) =
  discard execIntenal(-h, s, args)

proc execAsync0*(h: FileHandle, s: string, args: varargs[K]) =
  execAsync(h, s, nil.toK())
