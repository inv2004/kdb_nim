import k_bindings
export k_bindings

converter toK*(x: int): K =
  ki(x.cint)

converter toK*(x: int64): K =
  ki(x.cint)

converter toK*(x: float64): K =
  kf(x.cdouble)

converter toK*(x: string): K =
  ks(x.cstring)

converter toK*(x: cstring): K =
  ks(x)

proc len*(x: K): clonglong =
  case x.kind
  of kList: x.kLen
  of kVecInt: x.intLen
  of kVecSym: x.stringLen
  else: raise newException(KError, "Not List")

iterator items*(x: K): K =
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

iterator mitems*(x: K): var K =
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
  xD(header, data)

proc add*(x: var K, v: cstring) =
  js(x.addr, ss(v))

proc add*(x: var K, v: cint) =
  ja(x.addr, v.unsafeAddr)

proc add*(x: var K, v: K) =
  case x.kind
  of kList: jk(x.addr, v)
  of kVecInt: add(x, v.ii.cint)
  else: raise newException(KError, "add is not supported for " & $x.kind)

proc newKVec*(x: int): K =
  ktn(x.cint, 0)

proc newKVecSym*(): K =
  newKVec(11)

proc newKList*(): K =
  knk(0)

proc addColumn*(t: var K, name: cstring, x: int) =
  if t == nil:
    var header = newKVecSym()
    header.add(name)
    var data = newKList()
    var c1 = ktn(x, 0)
    data.add(c1)
    t = xT(xD(header, data))
  else:
    t.dict.keys.add(name)
    var c1 = newKVec(x)
    t.dict.values.add(c1)

proc `%`(x: int): K =
  ki(x.cint)

proc addRow*(t: var K, vals: varargs[K]) =
  assert t.dict.values.len == vals.len
  for i in 0..<t.dict.values.len:
    t.dict.values.kArr[i].add(vals[i])

proc newKTable*(fromDict = newKDict(10, 0)): K =
#  xT(fromDict)
  nil # empty table is nil

proc `[]`*(x: K, i: int64): K =
  case x.kind
  of kVecInt: x.intArr[i].toK()
  of kVecLong: x.longArr[i].toK()
  of kVecFloat: x.floatArr[i].toK()
  of kVecSym: x.stringArr[i].toK()
  of kList: x.kArr[i]
  else: raise newException(KError, "`[]` is not supported for " & $x.kind)

proc `[]=`*(x: var K, k: K, v: K) =
  case x.kind
  of kDict:
    x.keys.add(k)
    x.values.add(v)
  else: raise newException(KError, "[K;K;K]`[]=` is not supported for " & $x.kind)

proc `[]=`*(x: var K, i: int, v: K) =
  case x.kind
  of kDict:
    x.keys.add(%i)
    x.values.add(v)
  of kVecSym:
    assert v.kind == kSym  # /-------\
    x.stringArr[i] = v.ss     # TODO: fix
  else: raise newException(KError, "[K;int;K]`[]=` is not supported for " & $x.kind)

proc connect*(hostname: string, port: int): FileHandle =
  result = khp(hostname, port)
  if result <= 0:
    raise newException(KError, "Connection error")

proc exec*(h: FileHandle, s: string, args: varargs[K]): K =
  case args.len
  of 0: result = k(h, s.cstring, nil)
  of 1: result = k(h, s.cstring, args[0], nil)
  of 2: result = k(h, s.cstring, args[0], args[1], nil)
  of 3: result = k(h, s.cstring, args[0], args[1], args[2], nil)
  else: raise newException(KError, "Cannot exec with more than 3 arguments")

