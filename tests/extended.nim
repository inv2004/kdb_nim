type T1 =
  object
    k: int64
    v: string

type T2 =
  object
    k, v: int

# proc `k`*(t: TTable[T1]): seq[int] =
  # t.inner.k.dict.values[0].k.longArr

# mkTable(T1)

proc k*(t: TTable[T1]): TVec[int64] =
  TVec[int64](inner: t.inner.k.dict.values[0])

test "vec":
  var t = newTVec[int]()
  t.add(10)
  t.add(20)
  echo t

test "table":
  var t = newTTable(T1)
  t.add(T1(k: 1, v: "one"))
  t.add(T1(k: 2, v: "two"))
  # discard r1(t.inner.k.dict.values.kArr)
  check t.len == 2
  check compiles(t.add(T1(k: 11, v: "oneone"))) == true
  check compiles(t.add(T2(k: 10, v: 20))) == false
  for x in t.k:
    echo x
  echo t.k.mapIt(it + 10)
  # echo t.v
  # echo "T1: ", t.inner["k"]
  # echo "T2: ", t.inner["v"]
