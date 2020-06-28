import kdb/low
import sequtils

export Sym
# type
#   Sym* = string

proc newSym*(x: string): Sym =
  Sym(inner: x.toSym())

proc `s`*(x: string): Sym =
  newSym(x)

proc `$`*(x: Sym): string =
  $x.inner

proc `==`*(a, b: Sym): bool =
  a.inner == b.inner

converter toSymNotLow*(x: string): Sym =
  newSym(x)
