import bindings
export bindings

import uuids
import endians
import times

proc typeToKType*[T](): int =
  when T is bool: 1
  elif T is GUID: 2
  elif T is byte: 4
  elif T is int16: 4
  elif T is int32: 6
  elif T is int: 7
  elif T is int64: 7
  elif T is float32: 8
  elif T is float64: 9
  elif T is float: 9
  elif T is KSym: 11
  elif T is KTimestamp: 12
  elif T is KDateTime: 15
  elif T is KList: 0
  elif T is string: 0
  elif T is typeof(nil): 0
  else: raise newException(KError, "cannot convert type " & $T)

converter toK*(x: type(nil)): K =
  result = K(k: ka(101))
  result.k.idg = 0

converter toK*(x: cstring): K =
  K(k: kpn(x, x.len))

converter toK*(x: string): K =
  K(k: kpn(x.cstring, x.len))

converter toK*(x: int16): K=
  K(k: kh(x))

converter toK*(x: int32): K=
  K(k: ki(x))

converter toK*(x: int): K =
  K(k: kj(x))

converter toK*(x: int64): K =
  K(k: kj(x))

converter toK*(x: float32): K =
  K(k: ke(x))

converter toK*(x: float64): K =
  K(k: kf(x))

converter toK*(x: char): K =
  K(k: kc(x))

proc toSym*(x: cstring): K =
  K(k: ks(x))

proc toSym*(x: string): K =
  toSym(x.cstring)

proc `s`*(x: string): K =
  K(k: ks(x.cstring))

proc toError*(x: string): K =
  let k0 = kerr(x.cstring)
  K(k: k0)

converter toKMonth*(x: int32): K =
  K(k: km(x))

proc toKMinute*(x: int32): K =
  K(k: kmi(x))

proc toKSecond*(x: int32): K =
  K(k: kse(x))

proc toKDate*(x: int32): K =
  K(k: kd(x))

proc toKDateTime*(x: float64): K =
  K(k: kz(x))

proc toKTimestamp*(x: int64): K =
  K(k: ktj(KKind.kTimestamp.byte, x))

proc toKTimespan*(x: int64): K =
  K(k: ktj(KKind.kTimespan.byte, x))

proc toKTime*(x: int32): K =
  K(k: kt(x))

converter toK*(x: byte): K =
  K(k: kg(x.int32))

converter toK*(x: bool): K =
  K(k: kb(x))

converter toK*(x: GUID): K =
  K(k: ku(x))

proc toGUID*(x: string): K =
  let uuid = parseUUID(x)
  let src1 = uuid.mostSigBits
  let src2 = uuid.leastSigBits
  var dst1: int64
  var dst2: int64
  bigEndian64(dst1.addr, src1.unsafeAddr)
  bigEndian64(dst2.addr, src2.unsafeAddr)

  let guid = cast[GUID]((dst1, dst2))
  K(k: ku(guid))

converter toK*(x: array[16, byte]): K =
  let guid = GUID(g: x)
  toK(guid)

proc toNanos*(x: Time): int64 =
  let seconds = x.toUnix() - 10957*86400
  seconds*1000000000 + x.nanosecond()

proc toMillis*(x: DateTime): float64 =
  let d = x - initDateTime(1, mJan, 2000, 0, 0, 0, utc())
  d.inMilliseconds().float64 / 86400000

converter toKTimestamp*(x: Time): K =
  toKTimestamp(x.toNanos())

converter toK*(x: DateTime): K =
  toKDateTime(x.toMillis())

proc toSymVec*(columns: openArray[string]): K =
  let k0 = ktn(typeToKType[KSym](), columns.len)
  for i, x in columns:
    k0.stringArr[i] = ss(x.cstring)
  result = K(k: k0)

converter toK*[T](v: openArray[T]): K =
  when T is DateTime:
    result = K(k: ktn(typeToKType[KDateTime](), v.len))
    for i, x in v:
      result.k.dtArr[i] = x.toMillis()
  when T is SomeNumber:
    result = K(k: ktn(typeToKType[T](), v.len))
    case result.k.kind
    of kVecLong:
      for i, x in v:
        result.k.longArr[i] = x.int64
    of kVecFloat:
      for i, x in v:
        result.k.floatArr[i] = x.float64
    else: raise newException(KError, "openArray converter is not supported for " & $result.kind)
  when T is K:
    result = K(k: ktn(typeToKType[nil](), v.len))
    for i, x in v:
      result.k.kArr[i] = r1(x.k)
    
  # else: raise newException(KError, "openArray converter is not supported for " & $T)

converter toK*(x: K0): K =
  K(k: x)

template `%`*(x: untyped): K =
  toK(x)

