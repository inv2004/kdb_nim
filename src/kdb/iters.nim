
proc get*[T](x: K0, i: int): T =
  when T is K: x.kArr[i]
  elif T is int64: x.longArr[i]
  elif T is float64: x.floatArr[i]
  elif T is cstring: x.stringArr[i]
  elif T is string: $x.stringArr[i]
  else: raise newException(KError, "`[]` is not supported for " & $x.kind)

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
  of kVecBool:
    var i = 0
    while i < x.k.boolLen:
      yield x.k.boolArr[i].toK()
      inc(i)
  of kVecInt:
    var i = 0
    while i < x.k.len:
      yield x.k.get[:int64](i).toK()
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
  of kTable:
    var i = 0
    while i < x.k.dict.keys.len:
      yield x.k.dict.keys.stringArr[i].toSym()
      inc(i)
  else: raise newException(KError, "items is not supported for " & $x.k.kind)

iterator items*[T](x: K, _: typedesc[T]): T =
  for i in 0..<x.len:
    yield x.k.get[:T](i)

iterator mitems*[T](x: var K): var T =
  when T is int64:
    assert x.k.kind == KKind.kVecLong
    var i = 0
    while i < x.k.longLen:
      yield x.k.longArr[i]
      inc(i)
  elif T is float64:
    assert x.k.kind == KKind.kVecFloat
    var i = 0
    while i < x.k.floatLen:
      yield x.k.floatArr[i]
      inc(i)
  elif T is cstring:
    assert x.k.kind == KKind.kVecSym
    var i = 0
    while i < x.k.stringLen:
      yield x.k.stringArr[i]
      inc(i)
  else: raise newException(KError, "mitems is not supported for " & $x.k.kind)

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

