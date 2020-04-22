import k_proc
export k_proc

import strutils
import times
import terminaltables

const dateFormat = initTimeFormat("yyyy-MM-dd")

proc `$`*(x: K): string

proc fmtKTable(x: K): string =
  let t = newUnicodeTable()
  t.separateRows = false
  var header: seq[string] = @[]
  for c in x.dict.keys:
    header.add $c.ss  # to remove quoted names
  t.setHeaders(header)

  for i in 0..<x.dict.values.kArr[0].len:
    var row: seq[string] = @[]
    for c in x.dict.values:
      row.add $c[i]
    t.addRow(row)

  result = t.render()
  result.removeSuffix()

proc fmtKDict(x: K): string =
  result.add "{"
  for i in 0..<x.keys.len:
    if i > 0:
      result.add "; "
    result.add $x.keys[i] & ": " & $x.values[i]
  result.add "}"

proc `$`*(x: K): string =
  case x.kind
  of kTable:
    result.add fmtKTable(x)
  of kDict:
    result.add fmtKDict(x)
  of kInt:
    result.add $x.ii
  of kLong:
    result.add $x.jj
  of kFloat:
    result.add $x.ff
  of kSym:
    result.add x.ss
  of kDate:
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + initDuration(days = x.dd)
    result.add dt.format(dateFormat)
  of kVecChar:
    result.add '"' & $cast[cstring](x.charArr) & '"'
  else:
    result.add $x.kind & ": "
    result.add "unknown"
