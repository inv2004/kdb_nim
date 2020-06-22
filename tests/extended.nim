
import kdb/high
import kdb/low

type
  T1 = object of RootObj
    k: int64
    v: string

  T2 = object
    k, v: int

  T11 = object of T1
    vv: float

  T111 = object of T11
    vvv: string
  
  T3 = object
    v: string

defineTable(T1)

defineTable(T2)

defineTable(T11)

defineTable(T111)

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
  var v = t.v
  check toSeq(t.k) == @[101.int64, 102]

test "table_transforms_with_default":
  var t = newTTable(T1)
  t.add(T1(k: 1, v: "one"))
  check t.inner.cols() == @["k", "v"]
  check compiles(t.vv) == false

  var tt = t.transform(T11)
  tt.add(T11(k: 2, v: "two", vv: 2.2))
  check tt.inner.cols() == @["k", "v", "vv"]
  check tt.vv[0] == 0.0  # default value
  check tt.vv[1] == 2.2

  try:
    echo t
    check false
  except:
    check true

  var ttt = tt.transform(T3)
  check ttt.inner.cols() == @["v"]

test "table_transforms_with_vec":
  var t = newTTable(T1)
  t.add(T1(k: 1, v: "one"))
  t.add(T1(k: 2, v: "two"))
  check t.inner.cols() == @["k", "v"]
  check compiles(t.vv) == false

  let tt = t.transform(T11, @[1.1, 2.2])
  check tt.inner.cols() == @["k", "v", "vv"]
  check tt.vv[0] == 1.1
  check tt.vv[1] == 2.2


