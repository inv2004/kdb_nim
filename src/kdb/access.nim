import converters
export converters

proc getByte*(x: K): byte =
  assert x.k.kind == KKind.kByte
  x.k.by

proc getInt16*(x: K): int16 =
  assert x.k.kind == KKind.kInt
  x.k.sh

proc getInt32*(x: K): int64 =
  assert x.k.kind == KKind.kInt
  x.k.ii

proc getInt64*(x: K): int64 =
  assert x.k.kind == KKind.kLong
  x.k.jj

proc getInt*(x: K): int =
  assert x.k.kind == KKind.kLong
  x.k.jj.int

proc getFloat32*(x: K): float32 =
  assert x.k.kind == KKind.kReal
  x.k.rr

proc getFloat64*(x: K): float64 =
  assert x.k.kind == KKind.kFloat
  x.k.ff

proc getFloat*(x: K): float =
  assert x.k.kind == KKind.kFloat
  x.k.ff

template math1(op: untyped) =
  proc op*(a: K): K =
    case a.k.kind
    of kByte: op(a.k.by)  # TODO: WHY ?
    of kShort: toK(op(a.k.sh))
    of kInt: toK(op(a.k.ii))
    of kLong: toK(op(a.k.jj))
    of kReal: op(a.k.rr)  # TODO: WHY ?
    of kFloat: toK(op(a.k.jj))
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

template math2(op: untyped) =
  proc op*(a, b: K): K =
    case a.k.kind
    of kByte: toK(op(a.k.by, b.k.by))
    of kShort: toK(op(a.k.sh, b.k.sh))
    of kInt: toK(op(a.k.ii, b.k.ii))
    of kLong: toK(op(a.k.jj, b.k.jj))
    of kReal: op(a.k.rr, b.k.rr)  # TODO: WHY ?
    of kFloat: toK(op(a.k.jj, b.k.jj))
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

template mathCmp(op: untyped) =
  proc op*(a, b: K): bool =
    case a.k.kind
    of kByte: op(a.k.by, b.k.by)
    of kShort: op(a.k.sh, b.k.sh)
    of kInt: op(a.k.ii, b.k.ii)
    of kLong: op(a.k.jj, b.k.jj)
    of kReal: op(a.k.rr, b.k.rr)
    of kFloat: op(a.k.jj, b.k.jj)
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

math1(`-`)
math2(`+`)
math2(`-`)
math2(`*`)
math2(`div`)
math2(`mod`)
mathCmp(`<`)
mathCmp(`<=`)

proc `==`*(a: K, b: K): bool =
  if a.k.kind != b.k.kind:
    return false
  case a.k.kind
  of kBool: a.k.bb == b.k.bb
  of kGUID: a.k.gg.g == b.k.gg.g
  of kByte: a.k.by == b.k.by
  of kShort: a.k.sh == b.k.sh
  of kInt: a.k.ii == b.k.ii
  of kLong: a.k.jj == b.k.jj
  of kReal: a.k.rr == b.k.rr
  of kFloat: a.k.ff == b.k.ff
  of kChar: a.k.ch == b.k.ch
  of kSym: a.k.ss == b.k.ss
  of kTimestamp: a.k.ts == b.k.ts
  of kDateTime: a.k.dt == b.k.dt
  of kVecChar: cast[cstring](a.k.charArr) == cast[cstring](b.k.charArr)  # TODO not sure
  of kVecFloat:
    var vA: seq[float]
    vA.add toOpenArray(a.k.floatArr.addr, 0, a.k.floatLen.int - 1)
    var vB: seq[float]
    vB.add toOpenArray(b.k.floatArr.addr, 0, b.k.floatLen.int - 1)
    vA == vB
  else: raise newException(KError, "`==` is not supported for " & $a.k.kind)

