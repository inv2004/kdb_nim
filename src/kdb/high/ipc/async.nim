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
  await client.sendASyncAsync(t.inner)

  var buf = await client.recv(8)  # TODO: copy-paste
  var len = 0
  littleEndian32(len.addr, buf[4].addr)
  buf.add(newString(len - 8))
  let size = await client.recvInto(buf[8].addr, len - 8)  # TODO: add logic to add into buffer
  var kBytes = newKVec[byte](len)
  copyMem(kBytes.k.byteArr.addr, buf[0].addr, len)
  
  let k = d9(kBytes.k)
  assert not isNil(k)

  result = k.toK().toKTable(U, check)

proc processMessage[T,U](client: AsyncSocket, callback: proc (request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  var buf = await client.recv(8)
  var len = 0
  littleEndian32(len.addr, buf[4].addr)
  buf.add(newString(len - 8))
  let size = await client.recvInto(buf[8].addr, len - 8)  # TODO: add logic to add into buffer
  var kBytes = newKVec[byte](len)
  copyMem(kBytes.k.byteArr.addr, buf[0].addr, len)
  
  let k = d9(kBytes.k)
  assert not isNil(k)

  let reply = callback(k.toK().toKTable(T))
  case buf[1].byte
  of 0: await client.sendASyncAsync(reply.inner)      # initial request was async
  of 1: await client.sendSyncReplyAsync(reply.inner)  # initial request was sync
  else: raise newException(KError, "unsupported msg type")

proc processClient[T,U](client: AsyncSocket,
    process: proc (client: AsyncSocket, callback: proc (request: KTable[T]): KTable[U] {.closure,gcsafe.}): Future[system.void],
    callback: proc (request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  await handshake(client)
  while true:
    await processMessage(client, callback)

proc asyncServe*[T,U](port: uint32, callback: proc (request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port))
  server.listen()
  while true:
      let client = await server.accept()
      echo "connected"
      await processClient[T,U](client, processMessage, callback)

