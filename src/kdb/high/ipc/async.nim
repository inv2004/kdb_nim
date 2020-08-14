import kdb/low
export low.asyncConnect
export low.KErrorRemote
import kdb/high/table

import shared

import asyncnet, asyncdispatch
import endians

import macros

var defaultCheck = false

proc setCheck*(check: bool) =
  defaultCheck = check

proc asyncCallTable*[T,U](client: AsyncSocket, x: string, t: KTable[T], check = defaultCheck): Future[KTable[U]] {.async.} =
  let k = await client.asyncCall(x, t.inner)
  result = k.toKTable(U, check)

proc processMessage1(client: AsyncSocket, process: proc (n: string, k: K): K {.gcsafe,closure.}) {.async.} =
  let (msgType, k) = await client.readMessage()

  assert isCall(k)

  let fnName = k[0].getStr()

  let reply = process(fnName, k[1].toK())

  case msgType
  of Async: await client.sendASyncAsync(reply)      # initial request was async
  of Sync: await client.sendSyncReplyAsync(reply)   # initial request was sync
  else: raise newException(KError, "unsupported msg type: " & $msgType)

proc processClient(client: AsyncSocket, handshake: bool, process: proc (n: string, k: K): K {.gcsafe,closure.}, oneshot: bool) {.async, gcsafe.} =
  if handshake:
    await handshake(client)
  while true:
    await processMessage1(client, process)
    if oneshot:
      break

proc asyncServe*(client: AsyncSocket, process: proc (n: string, k: K): K {.gcsafe,closure.}, oneshot: bool) {.async, gcsafe.} =
  # asyncCheck processClient(client, false, process)
  await processClient(client, false, process, oneshot)

proc asyncServe*(port: uint32, process: proc (n: string, k: K): K {.gcsafe,closure.}, oneshot: bool) {.async, gcsafe.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port))
  server.listen()
  echo "serve ", port
  while true:
    let client = await server.accept()
    asyncCheck processClient(client, true, process, oneshot)

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

macro serve*(port: uint32 | AsyncSocket, body: typed): untyped =
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

  result.add newProc(ident("process123"), params, newStmtList(ccase), pragmas = newPragma(ident"gcsafe"))

  result.add quote do:
    asyncCheck asyncServe(`port`, process123, false)

macro serveOne*(port: uint32 | AsyncSocket, body: typed): untyped =
  result = newStmtList()

  if body.kind == nnkStmtList:
    for x in body:
      result.add x
  elif body.kind == nnkProcDef:
    result.add body

  let defs = getDefs(body)

  let kType = bindSym("K")
  let kError = bindSym("KError")
  let toKError = bindSym("toKError")

  var params = newSeq[NimNode]()
  params.add kType
  params.add newIdentDefs(ident "n", ident "string")
  params.add newIdentDefs(ident "k", kType)

  var ccase = newCaseStmt(ident "n")

  for (n, t) in defs:
    ccase.add newOfBranch(newStrLitNode(n), newStmtList(newDotExpr(newCall(ident n, newCall(newDotExpr(ident"k", ident"toKTable"), t)), ident"inner")))
  ccase.add newElse(newStmtList(newCall(toKError, ident"n")))

  result.add newProc(ident("process123"), params, newStmtList(ccase), pragmas = newPragma(ident"gcsafe"))

  result.add quote do:
    waitFor asyncServe(`port`, process123, true)

proc asyncCall*[T](socket: AsyncSocket, x: string, a, b, c: K): Future[T] {.async.} =
  var l = newKList()
  l.add(x.toK())
  # for x in args:
  #   l.add(x)
  l.add(a)
  l.add(b)
  l.add(c)

  let data = b9(3, l.k)
  data.byteArr[1] = 1  # sync type
  await socket.send(data.byteArr.addr, data.byteLen.int)
  r0(data)
  let k = await socket.asyncRead()
  result = get[T](k)

converter toKK*(x: float64): K =
  low.toK(x)

converter toKK*(x: string): K =
  low.toK(x)

converter toKK*(x: Sym): K =
  x.inner