# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

test "testRemoteRead":
  let h = connect("test-kdb", 9999)
  let r = h.read()
  if r.kind != KKind.kList or r.len < 2:
    h.sendSyncReply("not_call".toError())
  else:
    var t = r[1]
    case t.kind
    of kTable:
      var c1 = newSeq[int]()
      var c2 = newSeq[string]()
      for i in 0..<t.len:
        c1.add i
        c2.add $i
      t.addColumn[:int]("z", %c1)
      t.addColumn[:string]("zz", %c2)
      h.sendSyncReply(t)
    else:
      h.sendSyncReply("not_table".toError())
