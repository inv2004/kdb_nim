import format
export format


proc connect*(hostname: string, port: int): FileHandle =
  result = khp(hostname, port)
  if result <= 0:
    raise newException(KError, "Connection error")

proc execIntenal(h: FileHandle, s: string, args: varargs[K]): K0 =
  case args.len
  of 0: result = k(h, s.cstring, nil)
  of 1: result = k(h, s.cstring, args[0].k, nil)
  of 2: result = k(h, s.cstring, args[0].k, args[1].k, nil)
  of 3: result = k(h, s.cstring, args[0].k, args[1].k, args[2].k, nil)
  else: raise newException(KError, "Cannot exec with more than 3 arguments")

  if result.kind == KKind.kError:
    raise newException(KErrorRemote, $result.msg)

proc exec*(h: FileHandle, s: string, args: varargs[K]): K =
  let k0 = execIntenal(h, s, args)

  if k0.kind == KKind.kError:
    var str = newString(result.k.charLen)
    copyMem(str[0].addr, result.k.charArr.addr, result.k.charLen)
    r0(k0)

    raise newException(KErrorRemote, str)
  else:
    K(k: k0)

proc exec0*(h: FileHandle, s: string): K =
  exec(h, s, nil.toK())

proc execAsync*(h: FileHandle, s: string, args: varargs[K]) =
  discard execIntenal(-h, s, args)

proc execAsync0*(h: FileHandle, s: string, args: varargs[K]) =
  execAsync(h, s, nil.toK())

proc read*(h: FileHandle): K =
  let k0 = k(h, nil)
  K(k: k0)
