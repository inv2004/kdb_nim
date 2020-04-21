import k_fmt

proc checkStructOffset*() =
  checkCStructOffset()
  checkNimStructOffset()

proc main() =
  var t = newKTable()
  t.addColumn("aaa", 6)
  t.addColumn("bbb", 0)
  t.addRow(3, "30")
  t.addRow(4, "40")
  t.addRow(5, "50")
  echo t
  
  var d = newKDict(6, 0)
  d[1] = "one"
  d[2] = "two"
  echo d

when isMainModule:
  main()
