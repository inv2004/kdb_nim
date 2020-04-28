import bindings
export bindings

import uuids

proc initMemory*() = 
  echo "Init KDB Memory"
  discard khp("", -1)

converter toK*(x: cstring): K =
  K(k: kpn(x, x.len.clonglong))

converter toK*(x: string): K =
  K(k: kpn(x.cstring, x.len.cint))

converter toK*(x: int16): K=
  K(k: kh(x))

converter toK*(x: int32): K=
  K(k: ki(x))

converter toK*(x: int): K =
  K(k: kj(x.clonglong))

converter toK*(x: int64): K =
  K(k: kj(x.clonglong))

converter toK*(x: float32): K =
  K(k: ke(x.cfloat))

converter toK*(x: float64): K =
  K(k: kf(x.cdouble))

converter toK*(x: char): K =
  K(k: kc(x))

proc toSym*(x: cstring): K =
  K(k: ks(x))

proc toSym*(x: string): K =
  K(k: ks(x.cstring))

proc `s`*(x: string): K =
  K(k: ks(x.cstring))

converter toKMonth*(x: cint): K =
  K(k: km(x))

proc toKMinute*(x: cint): K =
  K(k: kmi(x))

proc toKSecond*(x: cint): K =
  K(k: kse(x))

proc toKDate*(x: cint): K =
  K(k: kd(x))

proc toKDateTime*(x: cdouble): K =
  K(k: kz(x))

proc toKTimestamp*(x: clonglong): K =
  K(k: ktj(KKind.kTimestamp.byte, x))

proc toKTimespan*(x: clonglong): K =
  K(k: ktj(KKind.kTimespan.byte, x))

proc toKTime*(x: cint): K =
  K(k: kt(x))


converter toK*(x: byte): K =
  K(k: kg(x.cint))

converter toK*(x: bool): K =
  K(k: kb(x))

converter toK*(x: GUID): K =
  K(k: ku(x))

proc toGUID*(x: string): K =
  let uuid = parseUUID(x)
  let guid = cast[GUID](uuid)
  K(k: ku(guid))

converter toK*(x: array[16, byte]): K =
  let guid = GUID(g: x)
  toK(guid)

converter toK*(x: K0): K =
  K(k: x)

template `%`*(x: untyped): K =
  toK(x)

proc kind*(x: K): KKind {.inline.} =
  x.k.kind

proc len*(x: K0): clonglong =
  case x.kind
  of kList: x.kLen
  of kVecBool: x.boolLen
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
  else: raise newException(KError, "Not List: " & $x.kind)

iterator pairs*(x: K0): (int, K0) =  # it is copy of items, better to merge somehow
  case x.kind
  of kList:
    var i = 0
    while i < x.kLen:
      yield (i, x.kArr[i])
      inc(i)
  of kVecInt:
    var i = 0
    while i < x.intLen:
      yield (i, x.intArr[i].toK().k)
      inc(i)
  of kVecSym:
    var i = 0
    while i < x.stringLen:
      yield (i, x.stringArr[i].toSym().k)
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.kind)

iterator items*(x: K0): K0 =
  case x.kind
  of kList:
    var i = 0
    while i < x.kLen:
      yield x.kArr[i]
      inc(i)
  of kVecInt:
    var i = 0
    while i < x.intLen:
      yield x.intArr[i].toK().k
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
  of kVecInt:
    var i = 0
    while i < x.k.intLen:
      yield x.k.intArr[i].toK()
      inc(i)
  of kVecSym:
    var i = 0
    while i < x.k.stringLen:
      yield x.k.stringArr[i].toSym()
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.k.kind)

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

proc typeToKType*[T](): int =
  when T is int: 6
  elif T is int64: 7
  elif T is string: 11 # TOD: not sure
  elif T is void: 0
  else: raise newException(KError, "cannot convert type")

proc newKDict*[KT, VT](): K =
  let header = ktn(typeToKType[KT](), 0)
  let data = ktn(typeToKType[VT](), 0)
  result = K(k: xD(header, data))
  # r1(header)
  # r1(data)

proc add*(x: var K0, v: cstring) =
  case x.kind
  of kList:
    let v = v.toK()
    jk(x.addr, r1(v.k))
  of kVecSym: js(x.addr, ss(v))
  else: raise newException(KError, "add[cstring] is not supported for " & $x.kind)

proc add*(x: var K, v: cstring) =
  add(x.k, v)

proc add*(x: var K, v: string) =
  add(x.k, v.cstring)

proc add*(x: var K0, v: cint) =
  ja(x.addr, v.unsafeAddr)

proc add*(x: var K0, v: int) =
  add(x, v.cint)

proc add*(x: var K, v: int) =
  add(x.k, v)

proc add*(x: var K0, v: K0) =
  case x.kind
  of kList: jk(x.addr, r1(v))
  of kVecInt: add(x, v.ii.cint)
  else: raise newException(KError, "add is not supported for " & $x.kind)

proc add*(x: var K, v: K) =
  add(x.k, v.k)

proc newKVec*[T](): K =
  let k0 = ktn(typeToKType[T](), 0)
  result = K(k: k0)

proc newKVecSym*(): K =
  newKVec[string]()

proc newKList*(): K =
  result = K(k: knk(0))

proc addColumn*[T](t: var K, name: string) =
  if t.k == nil:
    var header = newKVecSym()
    header.add(name)
    var data = newKList()
    var c1 = newKVec[T]()
    data.add(c1)
    let d0 = xD(r1(header.k), r1(data.k))
    t.k = xT(d0)
  else:
    t.k.dict.keys.add(name)
    var c1 = newKVec[T]()
    t.k.dict.values.add(c1.k)

proc addRow*(t: var K, vals: varargs[K]) =
  assert t.k.dict.values.len == vals.len
  for i in 0..<t.k.dict.values.len:
    t.k.dict.values.kArr[i].add(vals[i].k)

# proc newKTable*(fromDict = newKDict(10, 0)): K =
proc newKTable*(): K =
  K(k: nil) # empty table is nil
#  xT(fromDict)

proc `[]`*(x: K, i: int64): K =
  discard r1(x.k)
  case x.k.kind
  of kVecBool: x.k.boolArr[i].toK()
  of kVecGUID: x.k.guidArr[i].toK()
  of kVecByte: x.k.byteArr[i].toK()
  of kVecShort: x.k.shortArr[i].toK()
  of kVecInt: x.k.intArr[i].toK()
  of kVecLong: x.k.longArr[i].toK()
  of kVecReal: x.k.realArr[i].toK()
  of kVecFloat: x.k.floatArr[i].toK()
  of kVecSym: x.k.stringArr[i].toSym()
  of kVecTimestamp: x.k.tsArr[i].toKTimestamp()
  of kVecMonth: x.k.monthArr[i].toKMonth()
  of kVecDate: x.k.dateArr[i].toKDate()
  of kVecDateTime: x.k.dtArr[i].toKDateTime()
  of kVecTimespan: x.k.tpArr[i].toKTimespan()
  of kVecMinute: x.k.minuteArr[i].toKMinute()
  of kVecSecond: x.k.secondArr[i].toKSecond()
  of kVecTime: x.k.timeArr[i].toKTime()
  of kList: r1(x.k.kArr[i])
  else: raise newException(KError, "`[]` is not supported for " & $x.k.kind)

proc `[]=`*(x: var K, k: K, v: K) =
  var x = x.k
  case x.kind
  of kDict:
    x.keys.add(k.k)
    x.values.add(v.k)
  else: raise newException(KError, "[K;K;K]`[]=` is not supported for " & $x.kind)

proc `[]=`*(x: var K, i: int, v: K) =
  case x.k.kind
  of kDict:
    x.k.keys.add(i)
    x.k.values.add(v.k)
  of kVecSym:
    assert v.k.kind == kSym     # /-------\
    x.k.stringArr[i] = v.k.ss   # TODO: fix
  else: raise newException(KError, "[K;int;K]`[]=` is not supported for " & $x.k.kind)

proc connect*(hostname: string, port: int): FileHandle =
  result = khp(hostname, port)
  if result <= 0:
    raise newException(KError, "Connection error")

proc exec*(h: FileHandle, s: string, args: varargs[K]): K =
  case args.len
  of 0: result = K(k: k(h, s.cstring, nil))
  of 1: result = K(k: k(h, s.cstring, args[0].k, nil))
  of 2: result = K(k: k(h, s.cstring, args[0].k, args[1].k, nil))
  of 3: result = K(k: k(h, s.cstring, args[0].k, args[1].k, args[2].k, nil))
  else: raise newException(KError, "Cannot exec with more than 3 arguments")

