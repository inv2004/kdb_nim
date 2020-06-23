import kdb/low
export low.waitOnPort
export low.connect
import table

import net

proc read*(client: SocketHandle, T: typedesc, checkSchema = false): (string, TTable[T]) =
  let d = low.read(client)
  if not isCall(d):
    raise newException(KErrorRemote, "not a ipc call")
  ($d[0], d[1].toTTable(T))

proc reply*(client: SocketHandle, x: TTable) =
  low.sendSyncReply(client, x.inner)
