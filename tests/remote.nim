# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

test "testRemoteRead":
  let h = connect("test-kdb", 9999)
  let r = h.read()
  echo r
  let s = 1.toK()
  check s.kind == KKind.kLong
  h.send(1.toK())
  echo "ok"
