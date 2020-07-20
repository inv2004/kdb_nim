import kdb/low
export low.asyncServe
export low.asyncConnect
import kdb/high/table

import asyncnet, asyncdispatch
import endians

var defaultCheck = false

proc setCheck*(check: bool) =
  defaultCheck = check

proc handshake(client: AsyncSocket) {.async} =
  let buf = await client.recv(3)
  let version = if buf.len() > 1: min(3.byte, buf[^2].byte) else: 0.byte
  var bufSend = "_"
  bufSend[0] = version.char
  await client.send(bufSend)

proc sendSyncReplyAsync*(client: AsyncSocket, v: K) {.async.} =
  case v.kind
  of kError:  # kError does not work via b9
    let strLen = v.k.msg.len()
    let len = 8 + 2 + strLen
    var data = newString(len)
    data[0] = 1.char  # little endian
    data[1] = 2.char  # response type
    littleEndian64(data[4].addr, len.unsafeAddr)
    data[8] = 128.char
    copyMem(data[9].addr, v.k.msg, strLen)
    data[len-1] = 0.char
    await client.send(data)
  else:
    let data = b9(3, v.k)
    data.byteArr[1] = 2  # response type
    await client.send(data.byteArr.addr, data.byteLen.int)
    r0(data)

proc sendAsyncAsync*(client: AsyncSocket, v: K) {.async.} =
  let data = b9(3, v.k)
  data.byteArr[1] = 0  # async type
  await client.send(data.byteArr.addr, data.byteLen.int)
  r0(data)

proc processMessage(client: AsyncSocket, callback: proc (request: K): K {.closure,gcsafe.}) {.async.} =
  var buf = await client.recv(8)
  var len = 0
  littleEndian32(len.addr, buf[4].addr)
  buf.add(newString(len - 8))
  let size = await client.recvInto(buf[8].addr, len - 8)  # TODO: add logic to add into buffer
  var kBytes = newKVec[byte](len)
  copyMem(kBytes.k.byteArr.addr, buf[0].addr, len)
  
  let k = d9(kBytes.k)
  assert not isNil(k)

  let reply = callback(k.toK())
  case buf[1].byte
  of 0: await client.sendASyncAsync(reply)      # initial request was async
  of 1: await client.sendSyncReplyAsync(reply)  # initial request was sync
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
      await processClient(client, processMessage, callback)

