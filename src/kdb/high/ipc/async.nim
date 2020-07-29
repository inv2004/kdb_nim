import kdb/low
export low.asyncServe
export low.asyncConnect
import kdb/high/table

import asyncnet, asyncdispatch
import endians

import macros

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
    await process(client, callback)

proc asyncServe*[T,U](port: uint32, callback: proc (x: string, request: KTable[T]): KTable[U] {.closure,gcsafe.}) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port))
  server.listen()
  while true:
    let client = await server.accept()
    echo "connected"
    asyncCheck processClient[T,U](client, processMessage, callback)

proc processMessage1(client: AsyncSocket, process: proc (n: string, k: K): K {.gcsafe,closure.} ) {.async, gcsafe.} =
  let x = await client.readMessage()

  let k = x[1]
  assert isCall(k)

  let fnName = k[0].getStr()

  let reply = process(fnName, k[1].toK())

  case x[0]
  of Async: await client.sendASyncAsync(reply)      # initial request was async
  of Sync: await client.sendSyncReplyAsync(reply)   # initial request was sync
  else: raise newException(KError, "unsupported msg type: " & $x[0])

proc processClient1(client: AsyncSocket, process: proc (n: string, k: K): K {.gcsafe,closure.}) {.async, gcsafe.} =
  await handshake(client)
  while true:
    await processMessage1(client, process)

proc asyncServe1*(port: uint32, process: proc (n: string, k: K): K {.gcsafe,closure.}) {.async, gcsafe.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port))
  server.listen()
  echo "serve ", port
  while true:
    let client = await server.accept()
    asyncCheck processClient1(client, process)

proc getDefs(t: NimNode): seq[(string, NimNode)] =
  if t.kind == nnkStmtList:
    for x in t:
      assert x.kind == nnkProcDef
      let name = x[0].strVal
      assert x[3].len == 2  # only one input param to function
      assert x[3][1].kind == nnkIdentDefs
      assert x[3][1][1].kind == nnkBracketExpr
      assert x[3][1][1][0].kind == nnkSym
      assert x[3][1][1][0].strVal == "KTable"  # param is KTable
      let ttype = x[3][1][1][1]
      result.add (name, ttype)
  elif t.kind == nnkProcDef:
    let name = t[0].strVal
    assert t[3].len == 2  # only one input param to function
    assert t[3][1].kind == nnkIdentDefs
    assert t[3][1][1].kind == nnkBracketExpr
    assert t[3][1][1][0].kind == nnkSym
    assert t[3][1][1][0].strVal == "KTable"  # param is KTable
    let ttype = t[3][1][1][1]
    result.add (name, ttype)

proc newCaseStmt(x: NimNode): NimNode =
  result = newNimNode(nnkCaseStmt)
  result.add x

proc newOfBranch(x: NimNode, b: NimNode): NimNode =
  result = newNimNode(nnkOfBranch)
  result.add x
  result.add b

proc newElse(body: NimNode): NimNode =
  result = newNimNode(nnkElse)
  result.add body

proc newRaiseStmt(body: NimNode): NimNode =
  result = newNimNode(nnkRaiseStmt)
  result.add body

proc newInfix(x, y, z: NimNode): NimNode =
  result = newNimNode(nnkInfix)
  result.add x
  result.add y
  result.add y

proc newPragma(x: varargs[NimNode]): NimNode =
  result = newNimNode(nnkPragma)
  result.add x

macro serve*(port: typed, body: typed): untyped =
  result = newStmtList()

  if body.kind == nnkStmtList:
    for x in body:
      result.add x
  elif body.kind == nnkProcDef:
    result.add body

  let defs = getDefs(body)

  let kType = bindSym("K")
  let kError = bindSym("KError")

  var params = newSeq[NimNode]()
  params.add kType
  params.add newIdentDefs(ident "n", ident "string")
  params.add newIdentDefs(ident "k", kType)

  var ccase = newCaseStmt(ident "n")

  for (n, t) in defs:
    ccase.add newOfBranch(newStrLitNode(n), newStmtList(newDotExpr(newCall(ident n, newCall(newDotExpr(ident"k", ident"toKTable"), t)), ident"inner")))
  ccase.add newElse(newStmtList(newRaiseStmt(newCall(ident"newException", ident"ValueError", newInfix(ident"&", newStrLitNode"function call not found", ident "n")))))

  result.add newProc(ident("process1"), params, newStmtList(ccase), pragmas = newPragma(ident"gcsafe"))

  result.add quote do:
    asyncCheck asyncServe1(`port`, process1)

#  echo result.treeRepr

# dumpTree:
# proc process1(n: string, k: K): K {.gcsafe,closure.} =
#   case n
#   of "f1": f1(k.toTable(ReqT)).inner
#   of "f2": f2(k.toTable(ResT)).inner
#   else: raise newException(KError, "aaa" & n)

# asyncServe1(9999, process2)
