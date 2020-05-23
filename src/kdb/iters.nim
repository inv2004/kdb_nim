
proc get*[T](x: K, i: int): T =
  when T is K:
    case x.kind
    of kList: K(k: x.k.kArr[i])
    of kVecInt: x.k.intArr[i].toK()
    of kVecLong: x.k.longArr[i].toK()
    of kVecSym: x.k.stringArr[i].toSym()
    else: raise newException(KError, "get[K] is not supported for " & $x.kind)
  elif T is int64: x.k.longArr[i]
  elif T is float64: x.k.floatArr[i]
  elif T is cstring: x.k.stringArr[i]
  elif T is string: $x.k.stringArr[i]
  else: raise newException(KError, "get is not supported for " & $x.kind)

proc getM*[T](x: K0, i: int): var T =
  when T is K: x.kArr[i]
  elif T is int64: x.longArr[i]
  elif T is float64: x.floatArr[i]
  elif T is cstring: x.stringArr[i]
  elif T is string: $x.stringArr[i]
  else: raise newException(KError, "getM is not supported for " & $x.kind)

# TODO: remove after format leaking check
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
      yield x.boolArr[i].toK().k
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
  of kTable:
    var i = 0
    while i < x.dict.len:
      yield x.stringArr[i].toSym().k
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.kind)

iterator items*(x: K): K =
  case x.k.kind
  of kList:
    var i = 0
    while i < x.k.kLen:
      let v = r1(x.k.kArr[i])  #TODO: not sure
      yield v
      inc(i)
  of kTable:
    var i = 0
    while i < x.k.dict.keys.len:
      yield x.k.dict.keys.stringArr[i].toSym()
      inc(i)
  else:
    for i in 0..<x.len:
      yield x.get[:K](i)

iterator items*[T](x: K, _: typedesc[T]): T =
  for i in 0..<x.len:
    yield x.k.get[:T](i)

iterator mitems*[T](x: var K): var T =
  for i in 0..<x.len:
    yield x.k.getM[:T](i)

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

iterator pairs*[T](x: K, _: typedesc[T]): (int, T) =
  var i = 0
  for v in x.items(T):
    yield (i, v)
    inc(i)
