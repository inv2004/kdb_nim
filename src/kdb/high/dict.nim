import kdb/low

type
  TDict*[T, U] = object
    inner*: K

proc newKDict*[T, U](): TDict[T, U] =
  let kDict = low.newKDict[T, U]()
  TDict[T, U](inner: kDict)

proc `$`*(v: TDict): string =
  $v.inner

proc `[]=`*[T, U](x: var TDict[T, U], k: T, v: U) =
  x.inner[k] = %v

proc `[]`*[T, U](x: TDict[T, U], k: T): U =
  x.inner.getDict[:T, U](k)

