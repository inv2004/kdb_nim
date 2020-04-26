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

  var d = newKDict(6, 0)
  d[1] = "one"
  d[2] = "two"
  echo d

proc main() =
  let h = connect("11.11.111.111", 9999)
  let r = h.exec("f")
  echo r

proc main() =
  discard khp("", -1)
  while true:
    var t = newKTable()
    t.addColumn("aaa", 6)
    t.addColumn("bbb", 0)
    t.addRow(3, "30")
    t.addRow(4, "40")
    t.addRow(5, "50")
    # echo t
    var i = toK(1122)
    var d = newKDict(6, 0)
    d[1] = "one"
    d[2] = "two"
    echo d
    var dd = newKDict(6, 6)
    dd[1] = 11
    dd[2] = 22
    var l = newKList()
    l.add("aa".cstring)
    var v1 = newKVec(6)
    v1.add(10)
    v1.add(20)
    var v2 = newKVecSym()
    v2.add("100")
    v2.add("200")
    var vv = newKList()
    vv.add(v1)
    vv.add(v2)
    for x in vv:
      for y in x:
        echo y

proc rc(x: K0): string =
  result.add $x.kind
  result.add ": "
  result.add $cast[ptr UncheckedArray[cint]](x)[1]

when isMainModule:
  main()