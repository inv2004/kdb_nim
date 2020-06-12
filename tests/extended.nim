
import kdb/high
import kdb/low

type T1 =
  object
    k: int64
    v: string

type T2 =
  object
    k, v: int

defineTable(T1)

test "vec":
  var t = high.newKVec[int64]()
  t.add(10)
  t.add(20)
  check toSeq(t) == @[10.int64, 20]

test "table":
  var t = newTTable(T1)
  t.add(T1(k: 1, v: "one"))
  t.add(T1(k: 2, v: "two"))
  # discard r1(t.inner.k.dict.values.kArr)
  check t.len == 2
  check compiles(t.add(T1(k: 11, v: "oneone"))) == true
  check compiles(t.add(T2(k: 10, v: 20))) == false
  check toSeq(t.k.pairs()) == @[(0, 1.int64), (1, 2.int64)]
  check t.k.mapIt(it + 10) == @[11.int64, 12]
  check compiles(t.k.mapIt(it + "abc")) == false
  var k = t.k
  for x in k.mitems():
    x += 100
  echo t
  # echo t.v
  # echo "T1: ", t.inner["k"]
  # echo "T2: ", t.inner["v"]
