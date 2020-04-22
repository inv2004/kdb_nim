import k_proc
export k_proc

import strutils
import times
import terminaltables

const dateFormat = initTimeFormat("yyyy-MM-dd")
const dateTimeFormat = initTimeFormat("yyyy-MM-dd\'T\'HH:mm:ss")
const timestampFormat = initTimeFormat("yyyy-MM-dd\'T\'HH:mm:ss\'.\'fffffffff")
const timespanFormat = "HH:mm:ss\'.\'fffffffff"

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
  of kTimestamp:
    let d = initDuration(nanoseconds = x.ts)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(timestampFormat)
  of kDate:
    let d = initDuration(days = x.dd)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(dateFormat)
  of kDateTime:
    let d = initDuration(seconds = int64(86400*(x.dt+10957)))
    let dt = initDateTime(1, mJan, 1970, 0, 0, 0, utc()) + d
    result.add dt.format(dateTimeFormat)
  of kTimespan:
    let d = initTime(0, 0) + initDuration(nanoseconds = x.tp)
    result.add d.format(timespanFormat, zone = utc())
  of kVecChar:
    result.add '"' & $cast[cstring](x.charArr) & '"'
  else:
    result.add $x.kind & ": "
    result.add "unknown"
