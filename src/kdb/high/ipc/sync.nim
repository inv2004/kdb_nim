import kdb/low
export low.listen
export low.connect
import kdb/high/table

import shared

import net

var defaultCheck = false

proc setCheck*(check: bool) =
  defaultCheck = check

proc read*(client: SocketHandle, T: typedesc, check = defaultCheck): (string, KTable[T]) =
  let d = low.read(client)
  if not isCall(d):
    raise newException(KErrorRemote, "not a ipc call")

  (d[0].getStr(), d[1].toKTable(T, check = check))

proc reply*(client: SocketHandle, x: KTable) =
  low.sendSyncReply(client, x.inner)

proc call*[T](client: SocketHandle, x: string, t: KTable): T =
  get[T](low.exec(client, x, t.inner))

proc callTable*[T](client: SocketHandle, x: string, args: varargs[K, toK], check = defaultCheck): KTable[T] =
  let res = low.exec(client, x, args)
  res.toKTable(T, check)

proc call*[T](client: SocketHandle, x: string, args: varargs[K, toK]): T =
  get[T](low.exec(client, x, args))

proc callAsync*(client: SocketHandle, x: string, args: varargs[K, toK]) =
  low.execAsync(client, x, args)

template toK*(x: typed): K =  # TODO: not sure, but varargs wants it
  low.toK(x)