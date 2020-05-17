import format
export format

import net
import endians

proc connect*(hostname: string, port: int): SocketHandle =
  result = khp(hostname, port)
  if result.int <= 0:
    raise newException(KError, "Connection error")

proc execIntenal(h: SocketHandle, s: string, args: varargs[K]): K0 =
  case args.len
  of 0: result = k(h, s.cstring, nil)
  of 1: result = k(h, s.cstring, args[0].k, nil)
  of 2: result = k(h, s.cstring, args[0].k, args[1].k, nil)
  of 3: result = k(h, s.cstring, args[0].k, args[1].k, args[2].k, nil)
  else: raise newException(KError, "Cannot exec with more than 3 arguments")

  if result.kind == KKind.kError:
    raise newException(KErrorRemote, $result.msg)

proc exec*(h: SocketHandle, s: string, args: varargs[K]): K =
  let k0 = execIntenal(h, s, args)

  if k0.kind == KKind.kError:
    var str = newString(result.k.charLen)
    copyMem(str[0].addr, result.k.charArr.addr, result.k.charLen)
    r0(k0)

    raise newException(KErrorRemote, str)
  else:
    K(k: k0)

proc exec0*(h: SocketHandle, s: string): K =
  exec(h, s, nil.toK())

proc execAsync*(h: SocketHandle, s: string, args: varargs[K]) =
  let negSocket = (-(h.int)).SocketHandle
  discard execIntenal(negSocket, s, args)

proc execAsync0*(h: SocketHandle, s: string, args: varargs[K]) =
  execAsync(h, s, nil.toK())

proc read*(h: SocketHandle): K =
  let k0 = k(h, nil)
  K(k: k0)

proc sendAsync*(h: SocketHandle, v: K) =
  let socket = newSocket(h)
   
  let data = b9(3, v.k)
  data.byteArr[1] = 0  # async type
  let sent = socket.send(data.byteArr.addr, data.byteLen.int)
  assert sent == data.byteLen
  r0(data)

proc sendSyncReply*(h: SocketHandle, v: K) =
  let socket = newSocket(h)

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
    socket.send(data)
  else:
    let data = b9(3, v.k)
    data.byteArr[1] = 2  # response type
    let sent = socket.send(data.byteArr.addr, data.byteLen.int)
    assert sent == data.byteLen
    r0(data)

proc isCall*(x: K): bool =
  (x.kind == KKind.kList or x.kind == kVecSym) and x.len >= 2
