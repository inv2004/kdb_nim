import bindings
export bindings

import uuids
import endians
import times

type
  Sym* = object  # it is for high module, but it is here to support toK
    inner*: K

proc typeToKKind*[T](): KKind =
  when T is bool: KKind.kBool
  elif T is GUID: KKind.kGUID
  elif T is byte: KKind.kByte
  elif T is int16: KKind.kShort
  elif T is int32: KKind.kInt
  elif T is int: KKind.kLong
  elif T is int64: KKind.kLong
  elif T is float32: KKind.kReal
  elif T is float64: KKind.kFloat
  elif T is float: KKind.kFloat
  elif T is KSym: KKind.kSym
  elif T is Sym: KKind.kSym
  elif T is KTimestamp: KKind.kTimestamp
  elif T is KDateTime: KKind.kDateTime
  elif T is DateTime: KKind.kDateTime
  elif T is KList: KKind.kList
  elif T is string: KKind.kList
  elif T is typeof(nil): KKind.kList
  else: KKind.kList # raise newException(KError, "cannot convert type " & $T)

proc toVecKKind*(k: KKind): KKind =
  case k:
  of KKind.kBool: KKind.kVecBool
  of KKind.kGUID: KKind.kVecGUID
  of KKind.kByte: KKind.kVecByte
  of KKind.kShort: KKind.kVecShort
  of KKind.kInt: KKind.kVecInt
  of KKind.kLong: KKind.kVecLong
  of KKind.kReal: KKind.kVecReal
  of KKind.kFloat: KKind.kVecFloat
  of KKind.kSym: KKind.kVecSym
  of KKind.kTimestamp: KKind.kVecTimestamp
  of KKind.kDateTime: KKind.kVecDateTime
  else: KKind.kList

proc toK*(x: Sym): K =
  x.inner

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
  let k0 = ktn(typeToKKind[KSym]().toVecKKind().int, columns.len)
  for i, x in columns:
    k0.stringArr[i] = ss(x.cstring)
  result = K(k: k0)

proc toK*[T](v: openArray[seq[T]]): K =
  result = K(k: ktn(KKind.kList.int, v.len))
  # TODO: unimplemented

proc toK*[T](v: openArray[T]): K =
  when T is DateTime:
    result = K(k: ktn(typeToKKind[T]().toVecKKind().int, v.len))
    for i, x in v:
      result.k.dtArr[i] = x.toMillis()
  elif T is SomeNumber:
    result = K(k: ktn(typeToKKind[T]().toVecKKind().int, v.len))
    case result.k.kind
    of kVecLong:
      for i, x in v:
        result.k.longArr[i] = x.int64
    of kVecFloat:
      for i, x in v:
        result.k.floatArr[i] = x.float64
    else: raise newException(KError, "openArray proc is not supported for " & $result.k.kind)
  elif T is string:
    result = K(k: ktn(typeToKKind[T]().int, v.len))
    for i, x in v:
      let k = x.toK()
      result.k.kArr[i] = r1(k.k)
  elif T is Sym:
    result = K(k: ktn(typeToKKind[T]().toVecKKind().int, v.len))
    discard r1(result.k)
    for i, x in v:
      result.k.stringArr[i] = x.inner.k.ss
  elif T is K:
    result = K(k: ktn(typeToKKind[nil]().int, v.len))
    for i, x in v:
      result.k.kArr[i] = r1(x.k)
  else:
    raise newException(KError, "openArray proc is not supported for " & $T)

proc toK*(x: K0): K =
  K(k: r1(x))

template `%`*(x: typed): K =
  toK(x)

# proc fromK(x: K): int =
  # assert x.k.kind == KKind.kLong
  # x.k.jj.int
  
