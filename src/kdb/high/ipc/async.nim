import kdb/low
export low.asyncServe
export low.asyncConnect
import kdb/high/table

import asyncnet, asyncdispatch
import endians

var defaultCheck = false

proc setCheck*(check: bool) =
  defaultCheck = check

proc callTable*[T,U](client: AsyncSocket, x: string, t: KTable[T], check = defaultCheck): Future[KTable[U]] {.async.} =
  await client.callASync(x, t.inner)
  let k = await client.read()
  result = k.toKTable(U, check)

proc processMessage[T,U](client: AsyncSocket, callback: proc (c: string, request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  let x = await client.readMessage()

  let k = x[1]
  assert isCall(k)

  let reply = callback(k[0].getStr(), k[1].toK().toKTable(T))
  case x[0]
  of Async: await client.sendASyncAsync(reply.inner)      # initial request was async
  of Sync: await client.sendSyncReplyAsync(reply.inner)   # initial request was sync
  else: raise newException(KError, "unsupported msg type: " & $x[0])

proc processClient[T,U](client: AsyncSocket,
    process: proc (client: AsyncSocket, callback: proc (x: string, request: KTable[T]): KTable[U] {.closure,gcsafe.}): Future[system.void],
    callback: proc (x: string, request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  await handshake(client)
  while true:
    await processMessage(client, callback)

proc asyncServe*[T,U](port: uint32, callback: proc (x: string, request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port))
  server.listen()
  while true:
    let client = await server.accept()
    echo "connected"
    await processClient[T,U](client, processMessage, callback)

