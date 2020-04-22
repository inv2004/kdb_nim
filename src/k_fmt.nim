import k_proc
export k_proc

import strutils
import terminaltables

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
  of kString:
    result.add '"' & $x.ss & '\"'
  else:
    result.add $x.kind & ": "
    result.add "unknown"
