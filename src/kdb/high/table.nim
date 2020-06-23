
import kdb/low
import kdb/high/vec

import macros

type
  TTable*[T] = object
    inner*: K
    moved: bool

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

proc checkMoved(t: TTable) =
  if t.moved: raise newException(ValueError, "table has been transformed already")

proc len*(t: TTable): int =
  checkMoved(t)
  t.inner.len

proc `$`*(t: TTable): string =
  checkMoved(t)
  $t.inner

proc getFieldsRec(t: NimNode): seq[(string, string)] =
  let obj = getImpl(t)[2]

  if obj[1].kind != nnkEmpty:
    result.add getFieldsRec(obj[1][0])

  let typeFields = obj[2]

  for f in typeFields.children:
    assert f.kind == nnkIdentDefs
    var fieldNames = newSeq[string]()
    for ff in f.children:
      case ff.kind
      of nnkIdent: fieldNames.add ff.strVal
      of nnkSym:
        for x in fieldNames:
          result.add (x, ff.strVal)
      of nnkEmpty: discard
      else: raise newException(Exception, "unexpected construction: " & $ff.treeRepr)

proc calcToAdd[T: KKind | string](f: seq[(string, T)], t: seq[(string, T)]): seq[(string, T)] =
  for (x, k) in t:  # TODO: something wrong with sets module
    var found = false
    for (xx, kk) in f:
      if x == xx:
        if k != kk:
          raise newException(Exception, "transfer: type diff")
        found = true
        break
    if not found:
      # echo "add2: ", x, ": ", k
      result.add((x, k))

proc calcToDelete[T: KKind | string](f: seq[(string, T)], t: seq[(string, T)]): seq[string] =
  for (x, k) in f:
    var found = false
    for (xx, kk) in t:
      if x == xx:
        found = true
        break
    if not found:
      # echo "delete: ", x
      result.add(x)


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
    @`fieldsTyped`

proc newTTable*(T: typedesc): TTable[T] =
  when not compiles(checkDefinition(T())):
    {.fatal: "defineTable".}
  let fields = fields(T)
  # echo "newTTable: ", fields
  let kTable = newKTable(fields)
  TTable[T](inner: kTable, moved: false)

proc toTTable*(k: K, T: typedesc): TTable[T] =
  when not compiles(checkDefinition(T())):
    {.fatal: "defineTable".}
  TTable[T](inner: k, moved: false)

template add*[T](t: var TTable[T], x: T) =
  checkMoved(t)
  let vals = t.genValues(x)
  t.inner.addRow(vals)

proc newTypedColumn(k: KKind, size: int): K =
  case k
  of KKind.kVecFloat: %newSeq[float](size)
  of KKind.kVecLong: %newSeq[int](size)
  else: raise newException(KError, "newKVecTyped: " & $k)

macro transformCheck(t: typed, tt: typed, j: varargs[typed]): untyped =
  if getType(t) == getType(tt):
    warning("transform into itself")

  let fieldsFrom = getFieldsRec(getType(t)[1])
  let fieldsTo = getFieldsRec(getType(tt)[1])
#  echo "fieldsCheck: "
#  echo "       from: ", fieldsFrom
#  echo "         to: ", fieldsTo

  let toAdd = calcToAdd(fieldsFrom, fieldsTo)
  let toDel = calcToDelete(fieldsFrom, fieldsTo)

  if j.len > 0:
    var i = 0
    for x in toAdd:
      let jType = getType(j[0])[1].strVal
#      echo "          j: ", jType
#      echo x[1], "-", jType
      if x[1] != jType:
        error("transform error: expected: " & x[1] & ", provided: " & jType)
      inc(i)
    if i < j.len:
      error("transform error: too many columns provided")

  var toAddKind: seq[(string, KKind)] = @[]
  for (f, t) in toAdd:
    toAddKind.add((f, stringToKVecKind(t)))

  result = quote do:
    checkMoved(t)
    (@`toAddKind`, @`toDel`)

proc transform*[T](t: var TTable[T], TT: typedesc): TTable[TT] =
  let toChange = transformCheck(T, TT)

  var kk = t.inner
  for (x, k) in toChange[0]:
    kk.addColumnWithKind(x, k, newTypedColumn(k, kk.len))

  for x in toChange[1]:
    kk.deleteColumn(x)

  t.moved = true
  result = TTable[TT](inner: t.inner, moved: false)

proc transform*[T, J](t: var TTable[T], TT: typedesc, col1: openArray[J]): TTable[TT] =
  let toChange = transformCheck(T, TT, J)

  var kk = t.inner
  let addCol1 = toChange[0][0]
  kk.addColumnWithKind(addCol1[0], addCol1[1], toK(col1))

  for x in toChange[1]:
    kk.deleteColumn(x)

  t.moved = true
  TTable[TT](inner: t.inner, moved: false)

proc transform*[T, J, JJ](t: var TTable[T], TT: typedesc, col1: openArray[J], col2: openArray[JJ]): TTable[TT] =  # TODO: template? macros?
  let toChange = transformCheck(T, TT, J, JJ)

  var kk = t.inner
  let addCol1 = toChange[0][0]
  kk.addColumnWithKind(addCol1[0], addCol1[1], toK(col1))
  let addCol2 = toChange[0][1]
  kk.addColumnWithKind(addCol2[0], addCol2[1], toK(col2))

  for x in toChange[1]:
    kk.deleteColumn(x)

  t.moved = true
  TTable[TT](inner: t.inner, moved: false)

proc transform*[T, J, JJ, JJJ](t: var TTable[T], TT: typedesc, col1: openArray[J], col2: openArray[JJ], col3: openArray[JJJ]): TTable[TT] =
  let toChange = transformCheck(T, TT, J, JJ, JJJ)

  var kk = t.inner
  let addCol1 = toChange[0][0]
  kk.addColumnWithKind(addCol1[0], addCol1[1], toK(col1))
  let addCol2 = toChange[0][1]
  kk.addColumnWithKind(addCol2[0], addCol2[1], toK(col2))
  let addCol3 = toChange[0][2]
  kk.addColumnWithKind(addCol3[0], addCol3[1], toK(col3))

  for x in toChange[1]:
    kk.deleteColumn(x)

  t.moved = true
  TTable[TT](inner: t.inner, moved: false)
