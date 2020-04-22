import k_fmt

proc checkStructOffset*() =
  checkCStructOffset()
  checkNimStructOffset()

proc main2() =
  var t = newKTable()
  t.addColumn("aaa", 6)
  t.addColumn("bbb", 0)
  t.addRow(3, "30")
  t.addRow(4, "40")
  t.addRow(5, "50")
  echo t

  echo t

  var d = newKDict(6, 0)
  d[1] = "one"
  d[2] = "two"
  echo d

proc main() =
  let h = connect("11.11.111.111", 9999)
  let r = h.exec("f")
  echo r

when isMainModule:
  main2()
