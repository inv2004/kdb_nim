
proc `[]`*(x: K0, i: int64): K =
  if x.kind != KKind.kDict:
    if i >= x.len:
      raise newException(KError, "index " & $i & " not in 0 .. " & $(x.len - 1))
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
  of kList: x.kArr[i].toK()
  else: raise newException(KError, "getFromK0 is not supported for " & $x.kind)

proc get*[T](x: K0, i: int): T =
  when T is K: x[i]
  elif T is int64: x.longArr[i]
  elif T is int: x.longArr[i].int
  elif T is float64: x.floatArr[i]
  elif T is cstring: x.stringArr[i]
  elif T is string: $x.stringArr[i]
  elif T is Sym: Sym(inner: toSym($x.stringArr[i]))  # TODO: not sure
  else: raise newException(KError, "getK0[" & $T & "] is not supported for " & $x.kind)

proc getDict*[T, U](x: K, k: T): U =
  for i in 0..<x.k.keys.len():
    if x.k.keys.get[:T](i.int) == k:
      return x.k.values.get[:U](i.int)
  raise newException(KError, "key not found " & $k)

proc get*[T](x: K, i: int): T =
  x.k.get[:T](i)

proc `[]`*(x: K, i: int64): K =
  result = x.get[:K](i.int)
  # discard r1(result.k)  # TODO: not sure

proc getM*[T](x: K0, i: int): var T =
  when T is K0: x.kArr[i]
  elif T is int64: x.longArr[i]
  elif T is float64: x.floatArr[i]
  elif T is cstring: x.stringArr[i]
  elif T is string: x.stringArr[i]
  else: raise newException(KError, "getM is not supported for " & $T)

iterator items*(x: K): K =
  case x.k.kind
  of kDict:
    for i in 0..<x.k.len:
      yield x.k.keys[i]
  of kTable:
    for i in 0..<x.k.dict.keys.len:
      yield x.k.dict.keys.stringArr[i].toSym()
  else:
    for i in 0..<x.len:
      yield x.get[:K](i)

iterator items*[T](x: K, _: typedesc[T]): T =
  for i in 0..<x.len:
    yield x.get[:T](i)

iterator mitems*[T](x: var K): var T =
  for i in 0..<x.len:
    yield x.k.getM[:T](i)

iterator pairs*(x: K): (K, K) =
  case x.k.kind
  of KKind.kDict:
    var i = 0
    for k in toK(x.k.keys):
      yield (k, x.k.values[i])
      inc(i)
  of KKind.kTable:
    var i = 0
    for k in toK(x.k.dict.keys):
      yield (k, x.k.dict.values[i])
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
