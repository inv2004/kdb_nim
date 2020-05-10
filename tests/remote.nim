# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

test "testRemoteRead":
  let h = connect("test-kdb", 9999)
  let r = h.read()
  let rr = 10 + r[1].k.jj
  h.sendSyncReply(rr)
  echo "ok"
