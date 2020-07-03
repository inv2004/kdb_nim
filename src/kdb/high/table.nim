import kdb/low
import kdb/high/vec

import kdb/high/sym

import sequtils
import macros

type
  KTable*[T] = ref object
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
  of "Sym": KKind.kVecSym
  of "KTimestamp": KKind.kVecTimestamp
  of "KDateTime": KKind.kVecDateTime
  of "DateTime": KKind.kVecDateTime
  of "KList": KKind.kList
  of "string": KKind.kList
  of "nil": KKind.kList
  else: raise newException(KError, "cannot convert type " & x)

proc checkMoved(t: KTable) =
  if t.moved: raise newException(ValueError, "table has been transformed already")

proc len*(t: KTable): int =
  checkMoved(t)
  t.inner.len

proc cols*(t: KTable): seq[string] =
  t.inner.cols

proc `$`*(t: KTable): string =
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

proc newBracketExpr(a, b: NimNode): NimNode =
  result = newNimNode(nnkBracketExpr)
  result.add a
  result.add b

proc newDiscardStmt(x: NimNode): NimNode =
  result = newNimNode(nnkDiscardStmt)
  result.add x

proc newCommand(a, b: NimNode): NimNode =
  result = newNimNode(nnkCommand)
  result.add a
  result.add b

macro defineTable*(T: typedesc): untyped =
  let fields = getFieldsRec(getType(T)[1])

  result = newStmtList()

  let getFunc = bindSym("get")
  let r1Func = bindSym("r1")
  let toKFunc = bindSym("toK")
  let kType = bindSym("K")

  let typeDefId = ident($T)

  for i, (x, t) in fields:
    let xId = ident(x)
    let tId = ident(t)
    let iId = newIntLitNode(i)

    result.add quote do:
      proc `xId`*(t: KTable[`typeDefId`]): KVec[`tId`] =
        KVec[`tId`](inner: `getFunc`[`kType`](t.inner.k.dict.values, `iId`))

  var params = newSeq[NimNode]()
  params.add newBracketExpr(ident "seq", kType)
  params.add newIdentDefs(ident "t", newBracketExpr(ident "KTable", typeDefId))
  params.add newIdentDefs(ident "x", typeDefId)

  var body = newStmtList()
  for i, (x, _) in fields:
    let val = ident("v" & $i)
    body.add newLetStmt(val, newCall(newDotExpr(newDotExpr(ident"x", ident x), toKFunc)))
    body.add newDiscardStmt(newCall(r1Func, newDotExpr(val, ident"k")))
    body.add newCommand(newDotExpr(ident"result", ident"add"), val)

  let g = newProc(ident("genValues"), params, body)
  result.add g

  result.add quote do:
    proc checkDefinition(_: `typeDefId`) =
      discard

macro fields(t: typed): untyped =
  let fields = getFieldsRec(getType(t)[1])
  var fieldsTyped: seq[(string, KKind)] = @[]
  for (f, t) in fields:
    fieldsTyped.add((f, stringToKVecKind(t)))
 
  result = quote do:
    @`fieldsTyped`

proc newTTable*(T: typedesc): KTable[T] =
  when not compiles(checkDefinition(T())):
    {.fatal: "defineTable".}
  let fields = fields(T)
  # echo "newTTable: ", fields
  let kTable = newKTable(fields)
  KTable[T](inner: kTable, moved: false)

proc toTTable*(k: K, T: typedesc): KTable[T] =
  when not compiles(checkDefinition(T())):
    {.fatal: "defineTable".}
  let fields = fields(T)
  KTable[T](inner: k, moved: false)

template add*[T](t: var KTable[T], x: T) =
  checkMoved(t)
  let vals = t.genValues(x)
  # t.inner.addRow(vals)
  addRow(t.inner, vals)

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
      echo "          j: ", jType
      echo x[1], " - ", jType
      if x[1] != jType:
        if not (x[1] == "Sym" and jType == "string"):
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

proc transform*[T](t: var KTable[T], TT: typedesc): KTable[TT] =
  let toChange = transformCheck(T, TT)

  for (x, k) in toChange[0]:
    t.inner.addColumnWithKind(x, k, newTypedColumn(k, t.inner.len))

  for x in toChange[1]:
    t.inner.deleteColumn(x)

  t.moved = true
  result = KTable[TT](inner: t.inner, moved: false)

proc toKOrSym[T](k: KKind, x: openArray[T]): K =
  when T is string:
    if k == KKind.kVecSym:
      toK(x.mapIt(newSym(it)))
    else:
      toK(x)
  else:
    toK(x)

proc transform*[T, J](t: KTable[T], TT: typedesc, col1: openArray[J]): KTable[TT] =
  let toChange = transformCheck(T, TT, J)

  let addCol1 = toChange[0][0]
  t.inner.addColumnWithKind(addCol1[0], addCol1[1], toKOrSym(addCol1[1], col1))

  for x in toChange[1]:
    t.inner.deleteColumn(x)

  t.moved = true
  KTable[TT](inner: t.inner, moved: false)

proc transform*[T, J, JJ](t: KTable[T], TT: typedesc, col1: openArray[J], col2: openArray[JJ]): KTable[TT] =  # TODO: template? macros?
  let toChange = transformCheck(T, TT, J, JJ)

  let addCol1 = toChange[0][0]
  t.inner.addColumnWithKind(addCol1[0], addCol1[1], toKOrSym(addCol1[1], col1))
  let addCol2 = toChange[0][1]
  t.inner.addColumnWithKind(addCol2[0], addCol2[1], toKOrSym(addCol2[1], col2))

  for x in toChange[1]:
    kk.deleteColumn(x)

  t.moved = true
  KTable[TT](inner: t.inner, moved: false)

proc transform*[T, J, JJ, JJJ](t: KTable[T], TT: typedesc, col1: openArray[J], col2: openArray[JJ], col3: openArray[JJJ]): KTable[TT] =
  let toChange = transformCheck(T, TT, J, JJ, JJJ)

  let addCol1 = toChange[0][0]
  t.inner.addColumnWithKind(addCol1[0], addCol1[1], toKOrSym(addCol1[1], col1))
  let addCol2 = toChange[0][1]
  t.inner.addColumnWithKind(addCol2[0], addCol2[1], toKOrSym(addCol2[1], col3))
  let addCol3 = toChange[0][2]
  t.inner.addColumnWithKind(addCol3[0], addCol3[1], toKOrSym(addCol3[1], col3))

  for x in toChange[1]:
    kk.deleteColumn(x)

  t.moved = true
  KTable[TT](inner: t.inner, moved: false)

# dumpTree:
#   proc genValues(t: KTable[T1], x: T1): seq[K] =
#     let v1 = x.price.toK()
#     discard r1(v1.k)
#     result.add(v1)
#     let v2 = x.name.toK()
#     discard r1(v2.k)
#     result.add(v2)

