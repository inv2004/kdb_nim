# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

import tables

test "testRemoteRead":
  let h = connect("test-kdb", 9999)
  let r = h.read()
  if r.kind != KKind.kList or r.len < 2:
    h.sendSyncReply("not_call".toError())
  else:
    const map = {1: "one", 2: "two", 3:"three"}.toTable

    var t = r[1]
    case t.kind
    of kTable:
      var c1 = newSeq[int]()
      var c2 = newSeq[string]()
      for i in 0..<t.len:
        c1.add i
        let a: int64 = t["a"][i].k.jj
        c2.add map[a.int]
      t.addColumn[:int]("z", %c1)
      t.addColumn[:string]("zz", %c2)
      t.addColumn[:KSym]("zzz", c2.toSymVec())
      h.sendSyncReply(t)
    else:
      h.sendSyncReply("not_table".toError())
