import kdb/low

type
  TVec*[T] = object
    inner*: K

proc newKVec*[T](): TVec[T] =
  let kVec = low.newKVec[T]()
  TVec[T](inner: kVec)

# proc newKVecTyped(k: KKind, size: int): TVec

proc add*[T](v: var TVec[T], x: T) =
  v.inner.add(x)

proc `[]`*[T](v: TVec[T], idx: int): T =
  v.inner.get[:T](idx)

iterator items*[T](v: TVec[T]): T =
  for x in v.inner.items(T):
    yield x

iterator mitems*[T](v: var TVec[T]): var T =
  for i in 0..<v.inner.len:
    yield v.inner.k.getM[:T](i)

iterator pairs*[T](v: TVec[T]): (int, T) =
  for i, x in v.inner.pairs(T):
    yield (i, x)

