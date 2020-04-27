{.passC: "-DKXVER=3".}
{.link: "c.o".}
{.compile: "k.c".}

type
  KError* = object of Exception

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
    kTime = 256-19
    kSecond = 256-18
    kMinute = 256-17
    kTimespan = 256-16
    kDateTIme = 256-15
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
      kLen*: clonglong
      kArr*: UncheckedArray[K0]
    of kVecBool:
      vbu*: cchar
      vbr*: cint
      boolLen*: clonglong
      boolArr*: UncheckedArray[bool]
    of kVecGUID:
      vgu*: cchar
      vgr*: cint
      guidLen*: clonglong
      guidArr*: UncheckedArray[GUID]
    of kVecByte:
      vyu*: cchar
      vyr*: cint
      byteLen*: clonglong
      byteArr*: UncheckedArray[byte]
    of kVecShort:
      vhu*: cchar
      vhr*: cint
      shortLen*: clonglong
      shortArr*: UncheckedArray[cshort]
    of kVecInt:
      viu*: cchar
      vir*: cint
      intLen*: clonglong
      intArr*: UncheckedArray[cint]
    of kVecLong:
      vju*: cchar
      vjr*: cint
      longLen*: clonglong
      longArr*: UncheckedArray[clonglong]
    of kVecReal:
      vru*: cchar
      vrr*: cint
      realLen*: clonglong
      realArr*: UncheckedArray[cfloat]
    of kVecFloat:
      vfu*: cchar
      vfr*: cint
      floatLen*: clonglong
      floatArr*: UncheckedArray[cdouble]
    of kVecChar:
      vcu*: cchar
      vcr*: cint
      charLen*: clonglong
      charArr*: UncheckedArray[char]
    of kVecSym:
      vsu*: cchar
      vsr*: cint
      stringLen*: clonglong
      stringArr*: UncheckedArray[cstring]
    of kVecTimestamp:
      vtsu*: cchar
      vtsr*: cint
      tsLen*: clonglong
      tsArr*: UncheckedArray[clonglong]
    of kVecMonth:
      vmu*: cchar
      vmr*: cint
      monthLen*: clonglong
      monthArr*: UncheckedArray[cint]
    of kVecDate:
      vdu*: cchar
      vdr*: cint
      dateLen*: clonglong
      dateArr*: UncheckedArray[cint]
    of kVecDateTime:
      vdtu*: cchar
      vdtr*: cint
      dtLen*: clonglong
      dtArr*: UncheckedArray[cdouble]
    of kVecTimespan:
      vtpu*: cchar
      vtpr*: cint
      tpLen*: clonglong
      tpArr*: UncheckedArray[clonglong]
    of kVecMinute:
      vmiu*: cchar
      vmir*: cint
      minuteLen*: clonglong
      minuteArr*: UncheckedArray[cint]
    of kVecSecond:
      vseu*: cchar
      vser*: cint
      secondLen*: clonglong
      secondArr*: UncheckedArray[cint]
    of kVecTime:
      vttu*: cchar
      vttr*: cint
      timeLen*: clonglong
      timeArr*: UncheckedArray[cint]
    of kTable:
      tu*: cchar
      tr*: cint
      dict*: K0
    of kDict:
      du*: cchar
      dr*: cint
      dn*: clonglong  # always 2
      keys*: K0
      values*: K0
    of kTime:
      ttu*: cchar
      ttr*: cint
      tt*: cint
    of kSecond:
      seu*: cchar
      ser*: cint
      se*: cint
    of kMinute:
      miu*: cchar
      mir*: cint
      mi*: cint
    of kTimespan:
      tpu*: cchar
      tpr*: cint
      tp*: clonglong
    of kDateTime:
      dtu*: cchar
      dtr*: cint
      dt*: cdouble
    of kDate:
      eu*: cchar
      er*: cint
      dd*: cint
    of kMonth:
      mu*: cchar
      mr*: cint
      mo*: cint
    of kTimestamp:
      tsu*: cchar
      tsr*: cint
      ts*: clonglong
    of kSym:
      su*: cchar
      sr*: cint
      ss*: cstring
    of kChar:
      cu*: cchar
      cr*: cint
      ch*: cchar
    of kFloat:
      fu*: cchar
      fr*: cint
      ff*: cdouble
    of kReal:
      rru*: cchar
      rrr*: cint
      rr*: cfloat
    of kLong:
      ju*: cchar
      jr*: cint
      jj*: clonglong
    of kInt:
      iu*: cchar
      ir*: cint
      ii*: cint
    of kShort:
      hu*: cchar
      hr*: cint
      sh*: cshort
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
