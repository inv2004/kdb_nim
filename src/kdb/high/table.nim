
import kdb/low
import kdb/high/vec
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

proc len*(t: TTable): int =
  t.inner.len

proc `$`*(t: TTable): string =
  $t.inner

proc add*[T](t: var TTable[T], x: T) =
  var vals = newSeq[K]()
  for kk, v in x.fieldPairs():
    let vv = v.toK()
    discard r1(vv.k)  # TODO: r1 fix
    vals.add(vv)
  t.inner.addRow(vals)

macro defineTable*(T: typedesc): untyped =
  var fields: seq[(string, string)] = @[]

  let obj = getImpl(getType(T)[1])[2]

  let typeFields = obj[2]
  for f in typeFields.children:
    fields.add ($f[0], f[1].strVal)

  if obj[1].kind != nnkEmpty:
    echo obj[1].treeRepr
    echo getType(obj[1][0]).treeRepr

  result = newStmtList()

  for i, (x, t) in fields:
    let code = """
proc """ & x & """*(t: TTable[""" & $T & """]): TVec[""" & t & """] =
  TVec[""" & t & """](inner: t.inner.k.dict.values[""" & $i & """])
"""

    result.add parseExpr(code)

