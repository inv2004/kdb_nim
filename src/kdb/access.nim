import converters
export converters

proc getFloat64*(x: K): float64 =
  assert x.k.kind == KKind.kFloat
  x.k.ff

proc getInt64*(x: K): int64 =
  assert x.k.kind == KKind.kLong
  x.k.jj

template math(op: untyped, t: KKind, f: untyped) =
  proc op*(a, b: K): K =
    toK(op(f(a), f(b)))

template mathType(t: KKind, f: untyped) =
    math(`+`, t, f)
    # math(`-`, t, f)
    # math(`*`, t, f)
    # math(`div`, t, f)
    # math(`mod`, t, f)

mathType(KKind.kLong, getInt64)
# mathType(KKind.kFloat, getFloat64)

# proc `+`*(a: K, b: K): K =
  # assert a.kind == KKind.kLong
  # assert b.kind == KKind.kLong
  # toK(a.k.jj + b.k.jj)
