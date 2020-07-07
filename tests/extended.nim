import kdb

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

  T4 = object of T1
    s: Sym

  # T4 = object
  #   k: int64
  #   v: seq[int64]

defineTable(T1)

defineTable(T2)

defineTable(T11)

defineTable(T111)

defineTable(T4)

test "vec":
  var t = kdb.newKVec[int64]()
  t.add(10)
  t.add(20)
  check toSeq(t) == @[10.int64, 20]

test "vec_of_vec":
  var v = kdb.newKVec[seq[int64]]()
  v.add(@[10.int64, 20])
  v.add(@[30.int64, 40, 50])
  check v.len() == 2
  check v[0].len() == 2
  check v[1].len() == 3
  var v1 = v[1]
  check compiles(v1.add(60.6)) == false
  v1.add(60)
  check v[1].len() == 4

test "vec_of_vec_of_vec":
  var v = kdb.newKVec[seq[seq[int64]]]()
  v.add(@[@[10.int64], @[20.int64, 30]])
  v.add(@[@[40.int64, 50], @[60.int64]])

test "dict":
  var d = kdb.newKDict[int, float]()
  d[1] = 1.1
  d[2] = 2.2
  d[1] = 3.3
  echo d
  var dd = kdb.newKDict[int, string]()
  dd[1] = "onn"
  dd[2] = "two"
  dd[1] = "one"
  echo dd

test "dict_of_vec":
  var d = kdb.newKDict[int, seq[float]]()
  d[1] = @[1.1, 11.1]
  d[2] = @[2.2, 22.2]

test "table":
  var t = newKTable(T1)
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
  var t = newKTable(T1)
  t.add(T1(k: 1, v: "one"))
  check t.cols() == @["k", "v"]
  check compiles(t.vv) == false

  var tt = t.transform(T11)
  tt.add(T11(k: 2, v: "two", vv: 2.2))
  check tt.cols() == @["k", "v", "vv"]
  check tt.vv[0] == 0.0  # default value
  check tt.vv[1] == 2.2

  try:
    echo t
    check false
  except:
    check true

  var ttt = tt.transform(T3)
  check ttt.cols() == @["v"]

test "table_transforms_with_vec":
  var t = newKTable(T1)
  t.add(T1(k: 1, v: "one"))
  t.add(T1(k: 2, v: "two"))
  check t.cols() == @["k", "v"]
  check compiles(t.vv) == false

  let tt = t.transform(T11, @[1.1, 2.2])
  check tt.cols() == @["k", "v", "vv"]
  check tt.vv[0] == 1.1
  check tt.vv[1] == 2.2

# test "table_of_vec":
#   var t = newKTable(T4)

test "sym":
  var t = newKTable(T1)
  t.add(T1(k: 1, v: "one"))
  t.add(T1(k: 2, v: "two"))
  let tt = t.transform(T4, [s"one", s"two"])
  check tt.s[0] == s"one"
  check tt.s[1] == s"two"

test "sym_string":
  var t = newKTable(T1)
  t.add(T1(k: 1, v: "one"))
  t.add(T1(k: 2, v: "two"))
  var tt = t.transform(T4, ["one", "two"])
  check tt.s[0] == "one"
  check tt.s[1] == "two"
  tt.add(T4(k: 3, v: "three", s: "three"))
  check tt.s[2] == s"three"

