import k_fmt

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
  let r = h.exec("f", 10)
  echo r

proc main() =
  while true:
    var t = newKTable()
    t.addColumn[:int]("aaa")
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
    var dd = newKDict[int, int]()
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

proc rc(x: K0): string =
  result.add $x.kind
  result.add ": "
  result.add $cast[ptr UncheckedArray[cint]](x)[1]

when isMainModule:
  main1()
