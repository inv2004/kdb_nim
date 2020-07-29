import kdb
import asyncdispatch

type
  ReqT = object
    x: int64
  ResT = object
    x: float64

defineTable(ReqT)
defineTable(ResT)

serve(9000):
  proc f1(x: KTable[ReqT]): KTable[ResT] {.gcsafe.} =
    result = newKTable(ResT)
    for x in x.x:
      result.add(ResT(x: 11 * x.float + x.float / 10.0))

  proc f2(x: KTable[ResT]): KTable[ReqT] {.gcsafe.} =
    result = newKTable(ReqT)
    for x in x.x:
      result.add(ReqT(x: 11 * x.int64))

proc send1() {.async.} =
  let h = waitFor asyncConnect("localhost", 9000)
  var t = newKTable(ReqT)
  t.add(ReqT(x: 1))
  t.add(ReqT(x: 2))
  t.add(ReqT(x: 3))
  let response = waitFor h.callTable[:ReqT, ResT]("f1", t, check = true)
  echo response

proc send2() {.async.} =
  let h = waitFor asyncConnect("localhost", 9000)
  var t = newKTable(ResT)
  t.add(ResT(x: 1))
  t.add(ResT(x: 2))
  t.add(ResT(x: 3))
  let response = waitFor h.callTable[:ResT, ReqT]("f2", t, check = true)
  echo response

waitFor send1()
waitFor send2()

runForever()