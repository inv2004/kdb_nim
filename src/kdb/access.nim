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
    of kFloat: toK(op(a.k.ff))
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

template math2(op: untyped) =
  proc op*(a, b: K): K =
    assert a.k.kind == b.k.kind
    case a.k.kind
    of kByte: toK(op(a.k.by, b.k.by))
    of kShort: toK(op(a.k.sh, b.k.sh))
    of kInt: toK(op(a.k.ii, b.k.ii))
    of kLong: toK(op(a.k.jj, b.k.jj))
    of kReal: toK(op(a.k.rr, b.k.rr))  # TODO: WHY ?
    of kFloat: toK(op(a.k.ff, b.k.ff))
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

template math2Int(op: untyped) =
  proc op*(a, b: K): K =
    assert a.k.kind == b.k.kind
    case a.k.kind
    of kByte: toK(op(a.k.by, b.k.by))
    of kShort: toK(op(a.k.sh, b.k.sh))
    of kInt: toK(op(a.k.ii, b.k.ii))
    of kLong: toK(op(a.k.jj, b.k.jj))
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

template math2var(op: untyped) =
  proc op*(a: var K, b: K) =
    assert a.k.kind == b.k.kind
    case a.k.kind
    of kByte: op(a.k.by, b.k.by)
    of kShort: op(a.k.sh, b.k.sh)
    of kInt: op(a.k.ii, b.k.ii)
    of kLong: op(a.k.jj, b.k.jj)
    of kReal: op(a.k.rr, b.k.rr)
    of kFloat: op(a.k.ff, b.k.ff)
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

template mathCmp(op: untyped) =
  proc op*(a, b: K): bool =
    assert a.k.kind == b.k.kind
    case a.k.kind
    of kByte: op(a.k.by, b.k.by)
    of kShort: op(a.k.sh, b.k.sh)
    of kInt: op(a.k.ii, b.k.ii)
    of kLong: op(a.k.jj, b.k.jj)
    of kReal: op(a.k.rr, b.k.rr)
    of kFloat: op(a.k.ff, b.k.ff)
    else: raise newException(KError, "OP is not supported for " & $a.k.kind)

math1(`-`)
math2(`+`)
math2(`-`)
math2(`*`)
math2Int(`div`)
math2Int(`mod`)
mathCmp(`<`)
mathCmp(`<=`)
math2var(`+=`)
math2var(`-=`)
math2var(`*=`)

proc `==`*(a: K0, b: K0): bool =
  if isNil(a) and isNil(b):
      return true
  if isNil(a) or isNil(b):  # xor
      return false
  if a.kind != b.kind:
    return false
  case a.kind
  of kBool: a.bb == b.bb
  of kGUID: a.gg.g == b.gg.g
  of kByte: a.by == b.by
  of kShort: a.sh == b.sh
  of kInt: a.ii == b.ii
  of kLong: a.jj == b.jj
  of kReal: a.rr == b.rr
  of kFloat: a.ff == b.ff
  of kChar: a.ch == b.ch
  of kSym: a.ss == b.ss
  of kTimestamp: a.ts == b.ts
  of kDateTime: a.dt == b.dt
  of kVecChar: cast[cstring](a.charArr) == cast[cstring](b.charArr)  # TODO not sure
  of kVecLong:
    var vA: seq[int64]
    vA.add toOpenArray(a.longArr.addr, 0, a.longLen.int - 1)
    var vB: seq[int64]
    vB.add toOpenArray(b.longArr.addr, 0, b.longLen.int - 1)
    vA == vB
  of kVecFloat:
    var vA: seq[float]
    vA.add toOpenArray(a.floatArr.addr, 0, a.floatLen.int - 1)
    var vB: seq[float]
    vB.add toOpenArray(b.floatArr.addr, 0, b.floatLen.int - 1)
    vA == vB
  of kVecSym:  # TODO: maybe slow: check
    var vA: seq[cstring]
    vA.add toOpenArray(a.stringArr.addr, 0, a.stringLen.int - 1)
    var vB: seq[cstring]
    vB.add toOpenArray(b.stringArr.addr, 0, b.stringLen.int - 1)
    vA == vB
  of kList:  # TODO: probably too slow: remake
    var vA: seq[K0]
    vA.add toOpenArray(a.kArr.addr, 0, a.kLen.int - 1)
    var vB: seq[K0]
    vB.add toOpenArray(b.kArr.addr, 0, b.kLen.int - 1)
    vA == vB
  else: raise newException(KError, "`==` is not supported for " & $a.kind)

proc `==`*(a, b: K): bool =
  a.k == b.k