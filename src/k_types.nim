type
  KError* = object of Exception

type
  KKind* = enum
    kList = 0,
    kVecInt = 6,
    kVecSym = 11,
    kTable = 98,
    kDict = 99
    kInt = 256-6
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
    of kVecSym:
      vsu*: cchar
      vsr*: cint
      stringLen*: clonglong
      stringArr*: UncheckedArray[cstring]
    of kInt:
      iu*: cchar
      ir*: cint
      ii*: cint
