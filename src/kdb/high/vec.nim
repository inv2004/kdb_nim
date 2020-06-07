import kdb

type
  TVec*[T] = object
    inner*: K

proc newTVec*[T](): TVec[T] =
  let kVec = newKVec[T]()
  TVec[T](inner: kVec)

proc add*[T](v: var TVec[T], x: T) =
  v.inner.add(x)

iterator items*[T](v: TVec[T]): T =
  for x in v.inner.items(T):
    yield x
