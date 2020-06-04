
import kdb
import macros

type
  TTable*[T] = object
    inner*: K

proc stringToKVecKind*(x: string): KKind =
  case x
  of "bool": KKind.kVecBool
  of "GUID": KKind.kVecGUID
  of "byte": KKind.kVecByte
  of "int16": KKind.kVecShort
  of "int32": KKind.kVecInt
  of "int": KKind.kVecLong
  of "int64": KKind.kVecLong
  of "float32": KKind.kVecReal
  of "float64": KKind.kVecFloat
  of "float": KKind.kVecFloat
  of "KSym": KKind.kVecSym
  of "KTimestamp": KKind.kVecTimestamp
  of "KDateTime": KKind.kVecDateTime
  of "DateTime": KKind.kVecDateTime
  of "KList": KKind.kList
  of "string": KKind.kList
  of "nil": KKind.kList
  else: raise newException(KError, "cannot convert type " & x)

macro fields(t: typedesc): untyped =
  var fields: seq[(string, KKind)] = @[]
 
  let typeFields = getImpl(getType(t)[1])[2][2]
  for f in typeFields.children:
    fields.add ($f[0], stringToKVecKind(f[1].strVal))

  result = quote do:
    `fields`

proc newTTable*(T: typedesc): TTable[T] =
  let fields = fields(T)
  echo "newTTable: ", fields
  let kTable = newKTable(fields)
  TTable[T](inner: kTable)

proc add*[T](t: var TTable[T], x: T) =
  var vals = newSeq[K]()
  for k, v in x.fieldPairs():
    vals.add v.toK()
  t.inner.addRow(vals)
