
import os
import asyncdispatch

type
  ReqT = object
    x: int64
  ResT = object
    x: float64
  ReqTErr1 = object
    x: float
  ReqTErr2 = object
    y: float

defineTable(ReqT)
defineTable(ResT)
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
  let response = h.callTable[:ReqT]("test", t, check = true)
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
    let response = h.callTable[:ReqTErr2]("test", t, check = true)
    check false
  except:
    check true

  worker1.joinThread()

test "test_ipc_async_server":
  serve(9997):
    proc test1(x: KTable[ReqT]): KTable[ResT] {.gcsafe.} =
      result = newKTable(ResT)
      for x in x.x:
        result.add(ResT(x: 11 * x.float + x.float / 10.0))
    proc test2(x: KTable[ResT]): KTable[ReqT] {.gcsafe.} =
      result = newKTable(ReqT)
      for x in x.x:
        result.add(ReqT(x: 10 * x.int))

  let h = waitFor asyncConnect("localhost", 9997)
  check true

  var t = newKTable(ReqT)
  t.add(ReqT(x: 1))
  t.add(ReqT(x: 2))
  t.add(ReqT(x: 3))
  let response = waitFor h.asyncCallTable[:ReqT, ResT]("test1", t, check = true)
  check toSeq(response.x) == @[11.1.float, 22.2, 33.3]

  var t2 = newKTable(ResT)
  t2.add(ResT(x: 1.1))
  t2.add(ResT(x: 2.2))
  t2.add(ResT(x: 3.3))
  let response2 = waitFor h.asyncCallTable[:ResT, ReqT]("test2", t2, check = true)
  check toSeq(response2.x) == @[10.int64, 20, 30]

test "test_ipc_async_client":
  proc server() {.gcsafe.} =
    let client = listen(9996)

    var t = newKTable(ReqT)
    t.add(ReqT(x: 1))
    t.add(ReqT(x: 2))
    t.add(ReqT(x: 3))

    let resp = client.callTable[:ResT]("test1", t.inner)
    check toSeq(resp.x) == @[1.0, 2.0, 3.0]

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let client = waitFor asyncConnect("localhost", 9996)
  check true

  serveOne(client):
    proc test1(x: KTable[ReqT]): KTable[ResT] {.gcsafe.} =
      check toSeq(x.x) == @[1.int64, 2, 3]
      result = newKTable(ResT)
      for x in x.x:
        result.add(ResT(x: x.float))

test "test_ipc_async_error":
  proc server() {.gcsafe.} =
    let client = listen(9995)

    var t = newKTable(ReqT)
    t.add(ReqT(x: 1))
    t.add(ReqT(x: 2))
    t.add(ReqT(x: 3))

    try:
      let resp = client.callTable[:ResT]("test2", t.inner)
      check false
    except KErrorRemote:
      check "test2" == getCurrentExceptionMsg()

  var worker1: Thread[void]
  createThread(worker1, server)

  sleep(20)

  let client = waitFor asyncConnect("localhost", 9995)
  check true

  serveOne(client):
    proc test1(x: KTable[ReqT]): KTable[ResT] {.gcsafe.} =
      check toSeq(x.x) == @[1.int64, 2, 3]
      result = newKTable(ResT)
      for x in x.x:
        result.add(ResT(x: x.float))
