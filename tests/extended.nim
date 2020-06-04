type T1 =
  object
    k: int
    v: string

test "table":
  var t = newTTable(T1)
  t.add(T1(k: 10, v: "10"))
  echo repr t.inner.k.dict.values.kArr[1].kArr[0]
  # echo "T1: ", t.inner["k"]
  # echo "T2: ", t.inner["v"]
  check 1 == 1
