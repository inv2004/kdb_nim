test "simple_atoms":
  check (%true).kind == KKind.kBool
  check (%10.byte).kind == KKind.kByte
  check (%10.int16).kind == KKind.kShort
  check (%10.int32).kind == KKind.kInt
  check (%10.int).kind == KKind.kLong
  check (%10.int64).kind == KKind.kLong
  check (%10.float32).kind == KKind.kReal
  check (%10.float).kind == KKind.kFloat
  check (%10.float64).kind == KKind.kFloat
  check (%'a').kind == KKind.kChar
  check toSym("aaa").kind == KKind.kSym
  check s"aaa".kind == KKind.kSym

test "guid":
  let guid1 = %[10.byte,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]
  check guid1.kind == KKind.kGUID
  let guidStr = "0a000000-0000-0000-0000-000000000001"
  let guid2 = toGUID(guidStr)
  check guid2.kind == KKind.kGUID
  check guid1.k.gg == guid2.k.gg
  check $guid1 == guidStr

test "vectors":
  var v = newKVec[int]()
  check v.kind == KKind.kVecLong
  try:
    v.add(false)
    check false
  except:
    check true
  v.add(10)
  v.add(20)
  check v[0] == 10
  check v[1] == 20
  check v.len == 2

test "simple_lists":
  var l = newKList()
  l.add(false)
  l.add(10)
  check l.len == 2
  check l[0] == false
  check l[1] == 10

test "list_of_vecs":
  var v1 = newKVec[bool]()
  v1.add(false)
  v1.add(true)
  var v2 = newKVec[int]()
  v2.add(10)
  var l2 = newKList()
  l2.add(100)
  var l = newKList()
  l.add(v1)
  l.add(v2)
  l.add(l2)
  check $l == "([false, true]; [10]; (100))"

test "dicts_simple":
  var d = newKDict[int, string]()
  d[1] = "one"
  d[10] = "ten"
  check d[10] == "ten"
  try:
    discard d[11]
    check false
  except:
    check true
  check d.len == 2
  check $d == """{1: "one"; 10: "ten"}"""

  var dd = newKDict[int, Ksym]()
  try:
    dd[1] = "one"
    check false
  except:
    check true
  dd[2] = s"two"
  dd[10] = s"ten"
  check $dd == "{2: two; 10: ten}"

  var ddd = newKDict[int, nil]()
  ddd[1] = 111
  ddd[10] = "ten"
  check $ddd == """{1: 111; 10: "ten"}"""

test "dict_of_dict":
  var d = newKDict[nil, string]()
  var d1 = newKDict[int, KSym]()
  d1[1] = s"one"
  d1[2] = s"two"
  var d2 = newKDict[int, string]()
  d2[11] = "eleven"
  d[d1] = "11"
  d[d2] = "22"
  check $d == """{{1: one; 2: two}: "11"; {11: "eleven"}: "22"}"""

test "tables_simple":
  var t = newKTable()
  check t.len == 0
  t.addColumn[:int]("aaa")
  t.addColumn[:string]("bbb")
  check t.len == 0
  t.addRow(3, "30")
  t.addRow(4, "40")
  t.addRow(5, "50")
  check t.len == 3
  check t.flatTable() == """|aaa: [3, 4, 5], bbb: ("30"; "40"; "50")|"""

  var tt = newKTable()
  tt.addColumn[:GUID]("id")
  tt.addColumn[:KSym]("nick")
  tt.addColumn[:string]("name")
  tt.addRow("0a000000-0000-0000-0000-000000000001".toGUID(), s"nick1", "name1")
  tt.addRow("0a000000-0000-0000-0000-000000000002".toGUID(), s"nick2", "name2")
  tt.addRow("0a000000-0000-0000-0000-000000000003".toGUID(), s"nick3", "name3")
  tt.addRow("0a000000-0000-0000-0000-000000000004".toGUID(), s"nick4", "name4")
  let tStr = tt.flatTable()
  check tStr.startsWith "|id: [0a000000-0000-0000-0000-000000000001, 0a000000-"
  check tStr.contains "nick: [nick1, nick2, nick3, nick4]"
  check tStr.contains """name: ("name1"; "name2"; "name3"; "name4")|"""

test "iterators":
  var t = newKVec[KSym]()
  t.add(s"aa")
  t.add(s"bb")
  t.add(s"cc")
  var str = ""
  for x in t:
    str.add $x
  check str == "aabbcc"

  str = ""
  for i, x in t:
    str.add $i & ":" & $x
  check str == "0:aa1:bb2:cc"

  var l = newKList()
  l.add(10)
  l.add(20)
  l.add(30)
  str = ""
  for x in l:
    str.add $x
  check str == "102030"

  var d = newKDict[int, KSym]()
  d[1] = s"one"
  d[2] = s"two"
  str = ""
  for k, v in d:
    str.add $k & ":" & $v
  check str == "1:one2:two"

test "times":
  var v = newKVec[KTimestamp]()
  let ts = getTime()
  v.add(ts)
  v.add(ts)
  check v.len == 2
  check v[0].kind == KKind.kTimestamp
  check v[0] == ts
  check v[1] == ts

  var vv = newKVec[KDateTime]()
  let dt = now().utc()
  vv.add(dt)
  vv.add(dt)
  check vv[0].kind == KKind.kDateTime
  check vv[0] == dt
  check vv[1] == dt

test "amend":
  var v = newKVec[float]()
  v.add(10.1)
  v.add(11.2)
  v.add(12.3)
  v[0] = 110.1
  v[2] = 112.3
  check $v == "[110.1, 11.2, 112.3]"

test "seq":
  let v = %[10.1, 11.2, 12.3]
  check $v == "[10.1, 11.2, 12.3]"
  var vv = %[10.1, 111.2, 12.3]
  check v != vv
  vv[1] = 11.2.toK()
  check v == vv

test "list_seq":
  var l = newKList()
  let dt = now().utc()
  l.add %[1]  # TODO: cannot implicit convert
  l.add %[4, 5]
  l.add %[7, 8, 9]
  l.add %[10.0, 11.0, 12.0, 13.0]
  l.add %[dt, dt]
  check $l == "([1]; [4, 5]; [7, 8, 9]; [10.0, 11.0, 12.0, 13.0]; [" & $ %dt & ", " & $ %dt & "])"

test "tables_from":
  var tNil = newKTable()
  tNil.addColumn[:int64]("aaa", %[1,2,3])
  check tNil.len == 3

  var t = newKTable({"aaa": KKind.kLong, "bbb": KKind.kList})
  t.addRow(1,
    %[
      %[1,2,3],
      %[4,5,6]
    ]
  )

  try:
    t.addColumn[:int64]("ccc", %[%2, %[1,2,3]])
    check false
  except:
    check true

  try:
    t.addColumn[:int64]("ccc", %[1,2,3])
    check false
  except:
    check true

test "tables_idx":
  var t = newKTable()
  t.addColumn[:int64]("aaa", %[1,2,3])
  t.addColumn[:string]("bbb", %["aaa", "bbb", "ccc"])
  t.addColumn[:KSym]("ccc", ["aaa", "bbb", "ccc"].toSymVec())
  check t.len == 3

  try:
    discard t["zzz"]
    check false
  except:
    check true

  check t["aaa"][0] == 1
  check t["bbb"][2] == "ccc"
  check t["ccc"][1] == s"bbb"

import tables
import sequtils

test "table_cols":
  const map = {1: "one", 2: "two", 3:"three"}.toTable

  var t = newKTable()
  t.addColumn[:int64]("a", %[1, 2, 3, 4])

  var c1 = (0..<t.len).toSeq()
  let c2 = t["a"].mapIt(map.getOrDefault(it.k.jj.int))
  t.addColumn[:int]("z", %c1)
  t.addColumn[:string]("zz", %c2)
  t.addColumn[:KSym]("zzz", c2.toSymVec())

  check t.toSeq() == @[s"a", s"z", s"zz", s"zzz"]
  check t.columns() == @["a", "z", "zz", "zzz"]

test "basic_math":
  let a = %10
  let b = a + 2
  check b < 14
  check b <= 14
  check b > 10
  check b >= 10
  check b == 12
  let c = b*2
  check c == 24
  check -c == -24
  var f = %2.5
  check (f*(%2.0)) == 5.0
  f += 10.0
  check f == 12.5
  f *= 2.0
  check f == 25.0

test "mitems":
  var a = %[10, 20, 30]
  for x in a.mitems[:int64]:
    x *= 2
  check a == %[20, 40, 60]

  var b = %[10.1, 20.2, 30.3]
  for x in b.mitems[:float64]:
    x *= 2
  check b == %[20.2, 40.4, 60.6]

  var c = ["aa", "bb", "cc"].toSymVec()
  for x in c.mitems[:cstring]:
    x = ($x & $x).cstring
  check c == ["aaaa", "bbbb", "cccc"].toSymVec()

  var d = %["aa", "bb", "cc"]
  for x in c.mitems[:cstring]:
    x = ($x & $x).cstring
  check d == %["aa", "bb", "cc"]


