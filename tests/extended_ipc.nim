
import os

type
  ReqT = object
    x: int64

defineTable(ReqT)

test "test_ipc_high":
  proc server() {.gcsafe.} =
    let client = listen(9999)
    var (call, data) = client.read(ReqT)
    check call == "test"
    var c = data.x
    for x in c.mitems():
      x *= 10
    client.reply(data)

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let h = connect("localhost", 9999)
  check true
  var t = newTTable(ReqT)
  t.add(ReqT(x: 1))
  t.add(ReqT(x: 2))
  t.add(ReqT(x: 3))
  let response = h.callTable[:ReqT]("test", t.inner)
  check toSeq(response.x) == @[10.int64, 20, 30]

  worker1.joinThread()

