# hard to include c-header in nim :)
import os

{.passC: "-DKXVER=3".}
{.passC: "-I" & currentSourcePath.parentDir().parentDir().}
{.link: currentSourcePath.parentDir().parentDir().parentDir() & "/c.o".}
{.compile: "k.c".}

type
  KError* = object of Exception
  KErrorRemote* = object of Exception

type
  KSym* = object
  KTimestamp* = object
  KDateTime* = object
  KList* = object

type
  KKind* {.size: 1.} = enum
    kList = 0
    kVecBool = 1
    kVecGUID = 2
    kVecByte = 4
    kVecShort = 5
    kVecInt = 6
    kVecLong = 7
    kVecReal = 8
    kVecFloat = 9
    kVecChar = 10
    kVecSym = 11
    kVecTimestamp = 12
    kVecMonth = 13
    kVecDate = 14
    kVecDateTime = 15
    kVecTimespan = 16
    kVecMinute = 17
    kVecSecond = 18
    kVecTime = 19
    kTable = 98
    kDict = 99
    kId = 101
    kError = 128
    kTime = 256-19
    kSecond = 256-18
    kMinute = 256-17
    kTimespan = 256-16
    kDateTime = 256-15
    kDate = 256-14
    kMonth = 256-13
    kTimestamp = 256-12
    kSym = 256-11
    kChar = 256-10
    kFloat = 256-9
    kReal = 256-8
    kLong = 256-7
    kInt = 256-6
    kShort = 256-5
    kByte = 256-4
    kGUID = 256-2
    kBool = 256-1

  GUID* {.importc: "U", header: "k.h".} = object
    g* {.importc.}: array[16, byte]

  K0* = ptr object {.packed.}
    m*: cchar
    a*: cchar
    case kind*: KKind
    of kList:
      lu*: cchar
      lr*: cint
      kLen*: int64
      kArr*: UncheckedArray[K0]
    of kVecBool:
      vbu*: cchar
      vbr*: cint
      boolLen*: int64
      boolArr*: UncheckedArray[bool]
    of kVecGUID:
      vgu*: cchar
      vgr*: cint
      guidLen*: int64
      guidArr*: UncheckedArray[GUID]
    of kVecByte:
      vyu*: cchar
      vyr*: cint
      byteLen*: int64
      byteArr*: UncheckedArray[byte]
    of kVecShort:
      vhu*: cchar
      vhr*: cint
      shortLen*: int64
      shortArr*: UncheckedArray[int16]
    of kVecInt:
      viu*: cchar
      vir*: cint
      intLen*: int64
      intArr*: UncheckedArray[int32]
    of kVecLong:
      vju*: cchar
      vjr*: cint
      longLen*: int64
      longArr*: UncheckedArray[int64]
    of kVecReal:
      vru*: cchar
      vrr*: cint
      realLen*: int64
      realArr*: UncheckedArray[float32]
    of kVecFloat:
      vfu*: cchar
      vfr*: cint
      floatLen*: int64
      floatArr*: UncheckedArray[float64]
    of kVecChar:
      vcu*: cchar
      vcr*: cint
      charLen*: int64
      charArr*: UncheckedArray[char]
    of kVecSym:
      vsu*: cchar
      vsr*: cint
      stringLen*: int64
      stringArr*: UncheckedArray[cstring]
    of kVecTimestamp:
      vtsu*: cchar
      vtsr*: cint
      tsLen*: int64
      tsArr*: UncheckedArray[int64]
    of kVecMonth:
      vmu*: cchar
      vmr*: cint
      monthLen*: int64
      monthArr*: UncheckedArray[int32]
    of kVecDate:
      vdu*: cchar
      vdr*: cint
      dateLen*: int64
      dateArr*: UncheckedArray[int32]
    of kVecDateTime:
      vdtu*: cchar
      vdtr*: cint
      dtLen*: int64
      dtArr*: UncheckedArray[float64]
    of kVecTimespan:
      vtpu*: cchar
      vtpr*: cint
      tpLen*: int64
      tpArr*: UncheckedArray[int64]
    of kVecMinute:
      vmiu*: cchar
      vmir*: cint
      minuteLen*: int64
      minuteArr*: UncheckedArray[int32]
    of kVecSecond:
      vseu*: cchar
      vser*: cint
      secondLen*: int64
      secondArr*: UncheckedArray[int32]
    of kVecTime:
      vttu*: cchar
      vttr*: cint
      timeLen*: int64
      timeArr*: UncheckedArray[int32]
    of kTable:
      tu*: cchar
      tr*: cint
      dict*: K0
    of kDict:
      du*: cchar
      dr*: cint
      dn*: int64  # always 2
      keys*: K0
      values*: K0
    of kId:
      idu*: cchar
      idr*: cint
      idg*: byte
    of kError:
      eru*: cchar
      err*: cint
      msg*: cstring
    of kTime:
      ttu*: cchar
      ttr*: cint
      tt*: int32
    of kSecond:
      seu*: cchar
      ser*: cint
      se*: int32
    of kMinute:
      miu*: cchar
      mir*: cint
      mi*: int32
    of kTimespan:
      tpu*: cchar
      tpr*: cint
      tp*: int64
    of kDateTime:
      dtu*: cchar
      dtr*: cint
      dt*: float64
    of kDate:
      eu*: cchar
      er*: cint
      dd*: int32
    of kMonth:
      mu*: cchar
      mr*: cint
      mo*: int32
    of kTimestamp:
      tsu*: cchar
      tsr*: cint
      ts*: int64
    of kSym:
      su*: cchar
      sr*: cint
      ss*: cstring
    of kChar:
      cu*: cchar
      cr*: cint
      ch*: char
    of kFloat:
      fu*: cchar
      fr*: cint
      ff*: float64
    of kReal:
      rru*: cchar
      rrr*: cint
      rr*: float32
    of kLong:
      ju*: cchar
      jr*: cint
      jj*: int64
    of kInt:
      iu*: cchar
      ir*: cint
      ii*: int32
    of kShort:
      hu*: cchar
      hr*: cint
      sh*: int16
    of kByte:
      yu*: cchar
      yr*: cint
      by*: byte
    of kGUID:
      gu*: cchar
      gr*: cint
      gn*: clonglong # probably 2
      gg*: GUID
    of kBool:
      bu*: cchar
      br*: cint
      bb*: bool

  K* = object
    k*: K0

proc r0*(x: K0) {.
  importc: "r0", header: "k.h".}

proc r1*(x: K0): K0 {.
  importc: "r1", header: "k.h".}

proc `=destroy`*(x: var K) =
  if x.k != nil:
    # let rc = cast[ptr UncheckedArray[cint]](x.k)[1]
    # echo "destroy K: ", x.k.kind, " rc = ", rc
    r0(x.k)

proc `=`*(a: var K, b: K) =
  `=destroy`(a)
  a.k = r1(b.k)

proc `=sink`*(a: var K; b: K) =
  `=destroy`(a)
  a.k = b.k

