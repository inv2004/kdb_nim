import bindings
export bindings

import uuids
import endians
import times

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

proc `[]=`*(x: var K0, i: int64, v: SomeNumber) =  #TODO: ~ duplicate from proc
  case x.kind
  of kVecLong: x.longArr[i] = v.int64
  of kVecFloat: x.floatArr[i] = v.float
  else: raise newException(KError, "stop")

converter toK*[T](v: openArray[T]): K =
  result = K(k: ktn(typeToKType[T](), v.len))
  for i, x in v:
    result.k[i] = x

converter toK*(x: char): K =
  K(k: kc(x))

proc toSym*(x: cstring): K =
  K(k: ks(x))

proc toSym*(x: string): K =
  toSym(x.cstring)

proc `s`*(x: string): K =
  K(k: ks(x.cstring))

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

proc toNanos*(x: DateTime): int64 =
  let d = x - initDateTime(1, mJan, 2000, 0, 0, 0, utc())
  d.inNanoseconds()

proc toMillis*(x: DateTime): float64 =
  let d = x - initDateTime(1, mJan, 2000, 0, 0, 0, utc())
  d.inMilliseconds().float64 / 86400000

converter toKTimestamp*(x: DateTime): K =
  toKTimestamp(x.toNanos())

proc toKDateTime*(x: DateTime): K =
  toKDateTime(x.toMillis())

converter toK*(x: K0): K =
  K(k: x)

template `%`*(x: untyped): K =
  toK(x)

