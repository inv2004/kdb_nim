import k_bindings
export k_bindings

converter toK*(x: int): K=
  result = K(k: ki(x.cint))

converter toK*(x: int64): K =
  result = K(k: ki(x.cint))

converter toK*(x: float64): K =
  K(k: kf(x.cdouble))

converter toK*(x: string): K =
  result = K(k: ks(x.cstring))
  r1(result.k)

converter toK*(x: cstring): K =
  result = K(k: ks(x))
  # r1(result.k)

converter toKDate*(x: cint): K =
  K(k: kd(x))

converter toKDateTime*(x: cdouble): K =
  K(k: kz(x))

converter toKTimestamp*(x: clonglong): K =
  K(k: ktj(KKind.kTimestamp.byte, x))

converter toKTimespan*(x: clonglong): K =
  K(k: ktj(KKind.kTimespan.byte, x))

converter toKTime*(x: cint): K =
  K(k: kt(x))

converter toK*(x: bool): K =
  K(k: kb(x))

converter toK*(x: K0): K =
  result = K(k: x)
  r1(result.k)

proc `%`*(x: int): K =
  toK(x)

proc len*(x: K0): clonglong =
  case x.kind
  of kList: x.kLen
  of kVecInt: x.intLen
  of kVecLong: x.longLen
  of kVecSym: x.stringLen
  of kVecDate: x.dateLen
  else: raise newException(KError, "Not List: " & $x.kind)

iterator items*(x: K0): K =
  case x.kind
  of kList:
    var i = 0
    while i < x.kLen:
      yield x.kArr[i]
      inc(i)
  of kVecInt:
    var i = 0
    while i < x.intLen:
      yield x.intArr[i].toK()
      inc(i)
  of kVecSym:
    var i = 0
    while i < x.stringLen:
      yield x.stringArr[i].toK()
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.kind)

iterator mitems*(x: K0): var K0 =
  case x.kind
  of kList:
    var i = 0
    while i < x.kLen:
      yield x.kArr[i]
      inc(i)
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
  else: raise newException(KError, "mitems is not supported for " & $x.kind)

proc newKDict*(kt, vt: int): K =
  let header = ktn(kt, 0)
  let data = ktn(vt, 0)
  result = K(k: xD(header, data))
  # r1(header)
  # r1(data)
  # r1(result.k)

proc add*(x: var K0, v: cstring) =
  js(x.addr, ss(v))

proc add*(x: var K, v: cstring) =
  add(x.k, v)

proc add*(x: var K, v: string) =
  add(x.k, v.cstring)

proc add*(x: var K0, v: cint) =
  ja(x.addr, v.unsafeAddr)

proc add*(x: var K0, v: int) =
  add(x, v.cint)

proc add*(x: var K0, v: K0) =
  case x.kind
  of kList: jk(x.addr, v)
  of kVecInt: add(x, v.ii.cint)
  else: raise newException(KError, "add is not supported for " & $x.kind)

proc add*(x: var K, v: K) =
  add(x.k, v.k)

proc newKVec*(x: int): K =
  result = K(k: ktn(x.cint, 0))
  # r1(result.k) // 0 after first add

proc newKVecSym*(): K =
  newKVec(11)

proc newKList*(): K =
  result = K(k: knk(0))
  # r1(result.k) // 0 after first add

proc addColumn*(t: var K, name: cstring, x: int) =
  if t.k == nil:
    var header = newKVecSym()
    header.add(name)
    var data = newKList()
    var c1 = newKVec(x)
    data.add(c1)
    t.k = xT(xD(header.k, data.k))
    r1(header.k)
    r1(c1.k)
    r1(data.k)
    # r1(t.k.dict)
    # r1(t.k)
  else:
    t.k.dict.keys.add(name)
    var c1 = newKVec(x)
    t.k.dict.values.add(c1.k)
    r1(c1.k)

proc addRow*(t: var K, vals: varargs[K]) =
  assert t.k.dict.values.len == vals.len
  for i in 0..<t.k.dict.values.len:
    t.k.dict.values.kArr[i].add(vals[i].k)

proc newKTable*(fromDict = newKDict(10, 0)): K =
#  xT(fromDict)
  K(k: nil) # empty table is nil

proc `[]`*(x: K0, i: int64): K =
  case x.kind
  of kVecBool: x.boolArr[i].toK()
  of kVecInt: x.intArr[i].toK()
  of kVecLong: x.longArr[i].toK()
  of kVecFloat: x.floatArr[i].toK()
  of kVecSym: x.stringArr[i].toK()
  of kVecTimestamp: x.tsArr[i].toKTimestamp()
  of kVecDate: x.dateArr[i].toKDate()
  of kVecDateTime: x.dtArr[i].toKDateTime()
  of kVecTimespan: x.tpArr[i].toKTimespan()
  of kVecTime: x.ttArr[i].toKTime()
  of kList: x.kArr[i]
  else: raise newException(KError, "`[]` is not supported for " & $x.kind)

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

