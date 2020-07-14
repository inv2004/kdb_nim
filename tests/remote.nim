# test "testRemote":
#   let h = connect("test-kdb", 9999)
#   check h > 0
#   let result = h.exec0("test")
#   echo result

import tables
import sequtils
import os
import asyncdispatch

test "test_ipc_sync":
  proc server() {.gcsafe.} =
    let client = listen(9999)
    let d = low.read(client)
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

test "test_ipc_sendasync":
  proc server() {.gcsafe.} =
    let client = listen(9998)
    var t = low.read(client)
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

test "test_ipc_async":
  proc server() {.gcsafe.} =
    proc f(x: K): K =
      result = x
      for x in result.mitems[:int64]:
        x *= 2

    waitFor asyncServe(9997, f)

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let h = connect("localhost", 9997)
  check true
  h.sendASync(%[10, 20, 30])
  let response = h.read()
  check response == %[20, 40, 60]

  # worker1.joinThread()
