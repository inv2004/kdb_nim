# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

import tables
import sequtils
import os

test "test_ipc_sync":
  proc server() {.gcsafe.} =
    let client = waitOnPort(9999)
    let d = kdb.read(client)
    check isCall(d)
    check d[0] == %"test"
    var t = d[1]
    for x in t.mitems[:int64]:
      x *= 2
    client.sendSyncReply(t)

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let h = connect("localhost", 9999)
  check true
  let response = exec(h, "test", %[10, 20, 30])
  check response == %[20, 40, 60]

  worker1.joinThread()

test "test_ipc_async":
  proc server() {.gcsafe.} =
    let client = waitOnPort(9998)
    var t = kdb.read(client)
    for x in t.mitems[:int64]:
      x *= 2
    client.sendASync(t)

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let h = connect("localhost", 9998)
  check true
  h.sendASync(%[10, 20, 30])
  let response = h.read()
  check response == %[20, 40, 60]

  worker1.joinThread()


# test "testRemoteRead":
#   let h = connect("test-kdb", 9999)
#   let r = h.read()
#   if not r.isCall():
#     h.sendSyncReply("not_call".toError())
#   else:
#     const map = {1: "one", 2: "two", 3:"three"}.toTable

#     var t = r[1]
#     case t.kind
#     of kTable:
#       var c1 = (0..<t.len).toSeq()
#       let c2 = t["a"].mapIt(map.getOrDefault(it.k.jj.int))
#       t.addColumn[:int]("z", %c1)
#       t.addColumn[:string]("zz", %c2)
#       t.addColumn[:KSym]("zzz", c2.toSymVec())
#       h.sendSyncReply(t)
#     else:
#       h.sendSyncReply("not_table".toError())
