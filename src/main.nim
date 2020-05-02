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
  # checkStructOffset()
  main3()
