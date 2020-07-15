
import os

type
  ReqT = object
    x: int64
  ReqTErr1 = object
    x: float
  ReqTErr2 = object
    y: float

defineTable(ReqT)
defineTable(ReqTErr1)
defineTable(ReqTErr2)

test "test_ipc":
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
  var t = newKTable(ReqT)
  t.add(ReqT(x: 1))
  t.add(ReqT(x: 2))
  t.add(ReqT(x: 3))
  let response = h.callTable[:ReqT]("test", t.inner, check = true)
  check toSeq(response.x) == @[10.int64, 20, 30]

  worker1.joinThread()

test "test_ipc_high_check":
  proc server() {.gcsafe.} =
    let client = listen(9998)
    try:
      var (call, data) = client.read(ReqTErr1)
      check false
    except:
      check true
  
    var t = newKTable(ReqTErr1)
    client.reply(t)

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let h = connect("localhost", 9998)
  check true
  var t = newKTable(ReqT)
  try:
    let response = h.callTable[:ReqTErr2]("test", t.inner, check = true)
    check false
  except:
    check true

  worker1.joinThread()

# test "test_ipc_high_async":
#   proc server() {.gcsafe.} =
#     proc f(x: K): K =
#       result = x
#       for x in result.mitems[:int64]:
#         x *= 2

#     waitFor asyncServe(9997, f)

#   var worker1: Thread[void]
#   createThread(worker1, server)

#   sleep(20)

#   let h = connect("localhost", 9997)
#   check true
#   h.sendASync(%[10, 20, 30])
#   let response = h.read()
#   check response == %[20, 40, 60]

#   # worker1.joinThread()
