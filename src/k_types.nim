type
  KError* = object of Exception

type
  KKind* = enum
    kList = 0,
    kVecInt = 6,
    kVecLong = 7,
    kVecSym = 11,
    kTable = 98,
    kDict = 99,
    kString = 256-11
    kLong = 256-7,
    kInt = 256-6,

  K* = ptr object {.packed.}
    m*: cchar
    a*: cchar
    case kind*: KKind
    of kTable:
      tu*: cchar
      tr*: cint
      dict*: K
    of kDict:
      du*: cchar
      dr*: cint
      dn*: clonglong     # always 2
      keys*: K
      values*: K
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
    of kVecSym:
      vsu*: cchar
      vsr*: cint
      stringLen*: clonglong
      stringArr*: UncheckedArray[cstring]
    of kInt:
      iu*: cchar
      ir*: cint
      ii*: cint
    of kLong:
      ju*: cchar
      jr*: cint
      jj*: clonglong
    of kString:
      su*: cchar
      sr*: cint
      ss*: cstring

