import kdb

proc checkStructOffset*() =
  checkCStructOffset()
  checkNimStructOffset()

proc main2() =
  var t = newKTable()
  t.addColumn[:int]("aaa")
  t.addColumn[:void]("bbb")
  t.addRow(3, "30")
  t.addRow(4, "40")
  t.addRow(5, "50")
  echo t

  var d = newKDict[int, void]()
  d[1] = "one"
  d[2] = "two"
  echo d

proc main1() =
  let h = connect("test-kdb", 9999)
  var r = h.exec0("f")
  echo r
  r = h.exec("f")
  echo r
  r = h.exec("f1", 1)
  echo r
  h.execAsync0("{`a set 13}")

proc main() =
  while true:
    var t = newKTable()
    t.addColumn[:int64]("aaa")
    t.addColumn[:void]("bbb")
    t.addRow(3, "30")
    t.addRow(4, "40")
    t.addRow(5, "50")
    echo t
    var i = toK(1122)
    var d = newKDict[int, void]()
    d[1] = "one"
    d[2] = "two"
    echo d
    var dd = newKDict[int, int64]()
    dd[1] = 11
    dd[2] = 22
    echo dd
    var l = newKList()
    l.add("aa".cstring)
    echo l
    var v1 = newKVec[int]()
    v1.add(10)
    v1.add(20)
    var v2 = newKVecSym()
    v2.add("100")
    v2.add("200")
    var v3 = newKVec[void]()
    v3.add("100")
    v3.add("200")
    echo v3
    var vv = newKList()
    vv.add(v1)
    vv.add(v2)
    for x in vv:
      for y in x:
        echo y
    echo vv

proc main3() =
  while true:
    var l = newKList()
    var v = newKVec[int]()
    v.add(10)
    l.add(v)
    v.add(20)
    v.add(30)
    v.add(40)
    v.add(50)
    echo l
    break

proc rc(x: K0): string =
  result.add $x.kind
  result.add ": "
  result.add $cast[ptr UncheckedArray[cint]](x)[1]

when isMainModule:
  main()
