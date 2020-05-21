# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

import tables
import sequtils
import os

test "testRemote":
  proc server() {.gcsafe.} =
    let s = waitOnPort(9999)
    let d = kdb.read(s)
    check d.kind == KKind.kLong

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(000)

  let h = connect("localhost", 9999)
  check true
  sendAsync(h, %100)

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
