type
  KError* = object of Exception

type
  KKind* = enum
    kList = 0
    kVecInt = 6
    kVecLong = 7
    kVecFloat = 9
    kVecChar = 10
    kVecSym = 11
    kVecTimestamp = 12
    kVecDate = 14
    kVecDateTime = 15
    kVecTimespan = 16
    kTable = 98
    kDict = 99
    kTimespan = 256-16
    kDateTIme = 256-15
    kDate = 256-14
    kTimestamp = 256-12
    kSym = 256-11
    kFloat = 256-9
    kLong = 256-7
    kInt = 256-6

  K* = ptr object {.packed.}
    m*: cchar
    a*: cchar
    case kind*: KKind
    of kList:
      lu*: cchar
      lr*: cint
      kLen*: clonglong
      kArr*: UncheckedArray[K]
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
    of kTable:
      tu*: cchar
      tr*: cint
      dict*: K
    of kDict:
      du*: cchar
      dr*: cint
      dn*: clonglong  # always 2
      keys*: K
      values*: K
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
    of kTimestamp:
      tsu*: cchar
      tsr*: cint
      ts*: clonglong
    of kSym:
      su*: cchar
      sr*: cint
      ss*: cstring
    of kFloat:
      fu*: cchar
      fr*: cint
      ff*: cdouble
    of kLong:
      ju*: cchar
      jr*: cint
      jj*: clonglong
    of kInt:
      iu*: cchar
      ir*: cint
      ii*: cint

