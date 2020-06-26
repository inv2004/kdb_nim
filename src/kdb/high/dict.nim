import kdb/low

type
  KDict*[T, U] = object
    inner*: K

proc newKDict*[T, U](): KDict[T, U] =
  let kDict = low.newKDict[T, U]()
  KDict[T, U](inner: kDict)

proc `$`*(v: KDict): string =
  $v.inner

proc `[]=`*[T, U](x: var KDict[T, U], k: T, v: U) =
  x.inner[k] = %v

proc `[]`*[T, U](x: KDict[T, U], k: T): U =
  x.inner.getDict[:T, U](k)

