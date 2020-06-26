import kdb/low

type
  KVec*[T] = object
    inner*: K

proc newKVec*[T](): KVec[T] =
  let kVec = low.newKVec[T]()
  KVec[T](inner: kVec)

# proc newKVecTyped(k: KKind, size: int): KVec

proc add*[T](v: var KVec[T], x: T) =
  v.inner.add(%x)  # TODO: not ok for not list

proc `$`*(v: KVec): string =
  $v.inner

proc len*(v: KVec): int =
  v.inner.len()

proc `[]`*[U](v: KVec[seq[seq[U]]], idx: int): KVec[seq[U]] =
  KVec[seq[U]](inner: v.inner.get[:K](idx))

proc `[]`*[U](v: KVec[seq[U]], idx: int): KVec[U] =
  KVec[U](inner: v.inner.get[:K](idx))

proc `[]`*[T](v: KVec[T], idx: int): T =
  v.inner.get[:T](idx)

iterator items*[T](v: KVec[T]): T =
  for x in v.inner.items(T):
    yield x

iterator mitems*[T](v: var KVec[T]): var T =
  for i in 0..<v.inner.len:
    yield v.inner.k.getM[:T](i)

iterator pairs*[T](v: KVec[T]): (int, T) =
  for i, x in v.inner.pairs(T):
    yield (i, x)

