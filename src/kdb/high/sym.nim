import kdb/low

export Sym

proc newSym*(x: string): Sym =
  Sym(inner: toSym(x))

proc `s`*(x: string): Sym =
  newSym(x)

proc default*(Sym: typedesc): Sym =
  newSym("")

proc `$`*(x: Sym): string =
  $x.inner

proc `==`*(a, b: Sym): bool =
  a.inner == b.inner
