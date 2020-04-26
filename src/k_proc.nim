import k_bindings
export k_bindings

proc toSym*(x: cstring): K =
  K(k: ks(x))

converter toK*(x: int): K=
  K(k: ki(x.cint))

converter toK*(x: int64): K =
  K(k: ki(x.cint))

converter toK*(x: float64): K =
  K(k: kf(x.cdouble))

converter toK*(x: string): K =
  K(k: kpn(x.cstring, x.len.cint))

converter toK*(x: cstring): K =
  K(k: kpn(x, x.len.clonglong))

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
  K(k: x)

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

proc newKDict*(kt, vt: int): K =
  let header = ktn(kt, 0)
  let data = ktn(vt, 0)
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

proc newKVec*(x: int): K =
  let k0 = ktn(x.cint, 0)
  result = K(k: k0)

proc newKVecSym*(): K =
  newKVec(11)

proc newKList*(): K =
  result = K(k: knk(0))

proc addColumn*(t: var K, name: cstring, x: int) =
  if t.k == nil:
    var header = newKVecSym()
    header.add(name)
    var data = newKList()
    var c1 = newKVec(x)
    data.add(c1)
    let d0 = xD(r1(header.k), r1(data.k))
    t.k = xT(d0)
  else:
    t.k.dict.keys.add(name)
    var c1 = newKVec(x)
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
  of kVecInt: x.k.intArr[i].toK()
  of kVecLong: x.k.longArr[i].toK()
  of kVecFloat: x.k.floatArr[i].toK()
  of kVecSym: x.k.stringArr[i].toSym()
  of kVecTimestamp: x.k.tsArr[i].toKTimestamp()
  of kVecDate: x.k.dateArr[i].toKDate()
  of kVecDateTime: x.k.dtArr[i].toKDateTime()
  of kVecTimespan: x.k.tpArr[i].toKTimespan()
  of kVecTime: x.k.ttArr[i].toKTime()
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

