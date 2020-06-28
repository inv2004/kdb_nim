import kdb/low
export low.waitOnPort
export low.connect
import table

import net

proc read*(client: SocketHandle, T: typedesc, check = false): (string, KTable[T]) =
  let d = low.read(client)
  if not isCall(d):
    raise newException(KErrorRemote, "not a ipc call")
  ($d[0], d[1].toTTable(T))

proc reply*(client: SocketHandle, x: KTable) =
  low.sendSyncReply(client, x.inner)

proc get[T](x: K): T =
  # assert x.kind == typeToKKind[T]()
  when T is bool:
    x.k.bb
  elif T is int64:
    x.k.ii
  elif T is int:
    x.k.ii
  elif T is float:
    x.k.ff
  elif T is seq[bool]:
    result.add toOpenArray(x.k.boolArr.addr, 0, x.k.boolLen.int - 1)
  elif T is seq[int64]:
    result.add toOpenArray(x.k.longArr.addr, 0, x.k.longLen.int - 1)
  elif T is seq[int]:
    result.add toOpenArray(x.k.longArr.addr, 0, x.k.longLen.int - 1)
  elif T is seq[float]:
    result.add toOpenArray(x.k.floatArr.addr, 0, x.k.floatLen.int - 1)
  elif T is (bool, Sym):  # TODO: remake to support tuple
    (x.k.kArr[0].bb, newSym($x.k.kArr[1].ss))
  elif T is (bool, string):  # TODO: remake to support tuple
    (x.k.kArr[0].bb, $x.k.kArr[1].ss)
  else: raise newException(KError, "get[T] is not supported for " & $T)

proc call*[T](client: SocketHandle, x: string, args: varargs[K, toK]): T =
  get[T](low.exec(client, x, args))

proc callAsync*(client: SocketHandle, x: string, args: varargs[K, toK]) =
  low.execAsync(client, x, args)

template toK*(x: typed): K =
  when x is Sym:
    x.inner
  else:
    low.toK(x)
