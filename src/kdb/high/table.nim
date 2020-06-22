
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

template add*[T](t: var TTable[T], x: T) =
  checkMoved(t)
  let vals = t.genValues(x)
  t.inner.addRow(vals)

proc newTypedColumn(k: KKind, size: int): K =
  case k
  of KKind.kVecFloat: %newSeq[float](size)
  of KKind.kVecLong: %newSeq[int](size)
  else: raise newException(KError, "newKVecTyped: " & $k)

proc transform*[T](t: var TTable[T], TT: typedesc): TTable[TT] =
  checkMoved(t)
  when T is TT:
    {.warning: "transform into itself".}
  let fieldsT: seq[(string, KKind)] = fields(T)
  let fieldsTT: seq[(string, KKind)] = fields(TT)
  # echo "transform: ", union(tSet, ttSet)

  for (x, k) in fieldsTT:  # TODO: something wrong with sets module
    var found = false
    for (xx, kk) in fieldsT:
      if x == xx:
        if k != kk:
          raise newException(Exception, "transfer: type diff")
        found = true
        break
    if not found:
      # echo "add: ", x, ": ", k
      var kk = t.inner
      kk.addColumnWithKind(x, k, newTypedColumn(k, kk.len))
  
  for (x, k) in fieldsT:
    var found = false
    for (xx, kk) in fieldsTT:
      if x == xx:
        found = true
        break
    if not found:
      # echo "delete: ", x
      var kk = t.inner
      kk.deleteColumn(x)

  result = TTable[TT](inner: t.inner, moved: false)
  t.moved = true
  # echo "            to: ", fieldsTT

macro transformCheck(t: typed, tt: typed, cols: typed): untyped =
  let fieldsFrom = getFieldsRec(getType(t)[1])
  let fieldsTo = getFieldsRec(getType(tt)[1])
  echo "fieldsCheck: "
  echo "       from: ", fieldsFrom
  echo "         to: ", fieldsTo
  echo "       cols: ", cols.len

  let l = fieldsTo.len() - fieldsFrom.len() - cols.len()
  result = quote do:
    `l`

template transform2*[T](t: var TTable[T], TT: typedesc, cols: varargs[TVec[typed]]): TTable[TT] =
  checkMoved(t)
  when T is TT:
    {.warning: "transform into itself".}
  when transformCheck(typeof(T), typeof(TT), cols) != 0:
    # echo cols[0].treeRepr
    {.fatal: "transform error".}

  let fieldsT: seq[(string, KKind)] = fields(typeof(T))
  let fieldsTT: seq[(string, KKind)] = fields(TT)
  # echo "transform: ", union(tSet, ttSet)
  echo fieldsT, " => ", fieldsTT

  var toAddCount = 0
  for (x, k) in fieldsTT:  # TODO: something wrong with sets module
    var found = false
    for (xx, kk) in fieldsT:
      if x == xx:
        if k != kk:
          raise newException(Exception, "transfer: type diff")
        found = true
        break
    if not found:
      echo "add2: ", x, ": ", k
      var kk = t.inner
      toAddCount.inc()
      kk.addColumnWithKind(x, k, cols[0].inner)
  
  for (x, k) in fieldsT:
    var found = false
    for (xx, kk) in fieldsTT:
      if x == xx:
        found = true
        break
    if not found:
      # echo "delete: ", x
      var kk = t.inner
      kk.deleteColumn(x)

  t.moved = true
  TTable[TT](inner: t.inner, moved: false)
  # echo "            to: ", fieldsTT
