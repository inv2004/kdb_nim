
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

proc len*(t: TTable): int =
  t.inner.len

proc `$`*(t: TTable): string =
  $t.inner

proc getFieldsRec(t: NimNode): seq[(string, string)] =
  let obj = getImpl(t)[2]

  if obj[1].kind != nnkEmpty:
    result.add getFieldsRec(obj[1][0])

  let typeFields = obj[2]
  for f in typeFields.children:
    result.add ($f[0], f[1].strVal)

macro defineTable*(T: typedesc): untyped =
  let fields = getFieldsRec(getType(T)[1])

  #if obj[1].kind != nnkEmpty:
  #  echo obj[1][0].treeRepr
  #  echo getImpl(obj[1][0]).treeRepr
    # echo getImpl(getType(obj[1][0])[1])

  result = newStmtList()

  for i, (x, t) in fields:
    let code = """
proc """ & x & """*(t: TTable[""" & $T & """]): TVec[""" & t & """] =
  TVec[""" & t & """](inner: t.inner.k.dict.values[""" & $i & """])
"""

    result.add parseExpr(code)

  var code = """
proc genValues(t: TTable[""" & $T & """], x: """ & $T & """): seq[K] =
"""
  for i, (x, t) in fields:
    let val = "v" & $i
    code.add """
  let """ & val & """ = x.""" & x & """.toK()
  discard r1(""" & val & """.k)
  result.add(""" & val & """)
"""

  result.add parseExpr(code)

  result.add parseExpr("""
proc checkDefinition(_: """ & $T & """) =
  discard
""")

macro fields(t: typed): untyped =
  let fields = getFieldsRec(getType(t)[1])
  var fieldsTyped: seq[(string, KKind)] = @[]
  for (f, t) in fields:
    fieldsTyped.add((f, stringToKVecKind(t)))
 
  result = quote do:
    `fieldsTyped`

proc newTTable*(T: typedesc): TTable[T] =
  when not compiles(checkDefinition(T())):
    {.fatal: "defineTable".}
  let fields = fields(T)
  echo "newTTable: ", fields
  let kTable = newKTable(fields)
  TTable[T](inner: kTable)

template add*[T](t: var TTable[T], x: T) =
  let vals = t.genValues(x)
  t.inner.addRow(vals)

proc convertInto*[T, TT](t: TTable[T]): TTable[TT] =
  let fieldsT = getFieldsRec(getType(T)[1])
  let fieldsTT = getFieldsRec(getType(TT)[1])
  echo "from"
  echo fieldsT
  echo fieldsTT
  TTable[TT](inner: kTable)
  