import bindings
export bindings

import uuids
import endians
import times

proc typeToKVecKind*[T](): KKind =
  when T is bool: KKind.kVecBool
  elif T is GUID: KKind.kVecGUID
  elif T is byte: KKind.kVecByte
  elif T is int16: KKind.kVecShort
  elif T is int32: KKind.kVecInt
  elif T is int: KKind.kVecLong
  elif T is int64: KKind.kVecLong
  elif T is float32: KKind.kVecReal
  elif T is float64: KKind.kVecFloat
  elif T is float: KKind.kVecFloat
  elif T is KSym: KKind.kVecSym
  elif T is KTimestamp: KKind.kVecTimestamp
  elif T is KDateTime: KKind.kVecDateTime
  elif T is DateTime: KKind.kVecDateTime
  elif T is KList: KKind.kList
  elif T is string: KKind.kList
  elif T is typeof(nil): KKind.kList
  else: raise newException(KError, "cannot convert type " & $T)

proc toK*(x: type(nil)): K =
  result = K(k: ka(101))
  result.k.idg = 0

proc toK*(x: cstring): K =
  K(k: kpn(x, x.len))

proc toK*(x: string): K =
  K(k: kpn(x.cstring, x.len))

proc toK*(x: int16): K=
  K(k: kh(x))

proc toK*(x: int32): K=
  K(k: ki(x))

proc toK*(x: int): K =
  K(k: kj(x))

proc toK*(x: int64): K =
  K(k: kj(x))

proc toK*(x: float32): K =
  K(k: ke(x))

proc toK*(x: float64): K =
  K(k: kf(x))

proc toK*(x: char): K =
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

proc toKMonth*(x: int32): K =
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

proc toK*(x: byte): K =
  K(k: kg(x.int32))

proc toK*(x: bool): K =
  K(k: kb(x))

proc toK*(x: GUID): K =
  K(k: ku(x))

proc toK*(uuid: UUID): K =
  let src1 = uuid.mostSigBits
  let src2 = uuid.leastSigBits
  var dst1: int64
  var dst2: int64
  bigEndian64(dst1.addr, src1.unsafeAddr)
  bigEndian64(dst2.addr, src2.unsafeAddr)

  let guid = cast[GUID]((dst1, dst2))
  K(k: ku(guid))

proc toGUID*(x: string): K =
  let uuid = parseUUID(x)
  toK(uuid)

proc toK*(x: array[16, byte]): K =
  let guid = GUID(g: x)
  toK(guid)

proc toNanos*(x: Time): int64 =
  let seconds = x.toUnix() - 10957*86400
  seconds*1000000000 + x.nanosecond()

proc toMillis*(x: DateTime): float64 =
  let d = x - initDateTime(1, mJan, 2000, 0, 0, 0, utc())
  d.inMilliseconds().float64 / 86400000

proc toKTimestamp*(x: Time): K =
  toKTimestamp(x.toNanos())

proc toK*(x: Time): K =
  toKTimestamp(x)

proc toK*(x: DateTime): K =
  toKDateTime(x.toMillis())

proc toSymVec*(columns: openArray[string]): K =
  let k0 = ktn(typeToKVecKind[KSym]().int, columns.len)
  for i, x in columns:
    k0.stringArr[i] = ss(x.cstring)
  result = K(k: k0)

proc toK*[T](v: openArray[T]): K =
  when T is DateTime:
    result = K(k: ktn(typeToKVecKind[T]().int, v.len))
    for i, x in v:
      result.k.dtArr[i] = x.toMillis()
  elif T is SomeNumber:
    result = K(k: ktn(typeToKVecKind[T]().int, v.len))
    case result.k.kind
    of kVecLong:
      for i, x in v:
        result.k.longArr[i] = x.int64
    of kVecFloat:
      for i, x in v:
        result.k.floatArr[i] = x.float64
    else: raise newException(KError, "openArray proc is not supported for " & $result.kind)
  elif T is string:
    result = K(k: ktn(typeToKVecKind[T]().int, v.len))
    for i, x in v:
      let k = x.toK()
      result.k.kArr[i] = r1(k.k)
  elif T is K:
    result = K(k: ktn(typeToKVecKind[nil]().int, v.len))
    for i, x in v:
      result.k.kArr[i] = r1(x.k)
  else:
    raise newException(KError, "openArray proc is not supported for " & $T)

proc toK*(x: K0): K =
  K(k: r1(x))

template `%`*(x: untyped): K =
  toK(x)

# proc fromK(x: K): int =
  # assert x.k.kind == KKind.kLong
  # x.k.jj.int
  
