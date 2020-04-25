import k_proc
export k_proc

import strutils
import times
import terminaltables

const dateFormat = initTimeFormat("yyyy-MM-dd")
const dateTimeFormat = initTimeFormat("yyyy-MM-dd\'T\'HH:mm:ss")
const timestampFormat = initTimeFormat("yyyy-MM-dd\'T\'HH:mm:ss\'.\'fffffffff")
const timespanFormat = "HH:mm:ss\'.\'fffffffff"
const timeFormat = "HH:mm:ss\'.\'fff"

proc `$`*(x: K): string

proc fmtKTable(x: K): string =
  let t = newUnicodeTable()
  t.separateRows = false
  var header: seq[string] = @[]
  for i in 0..<x.k.dict.keys.stringLen:
    header.add $x.k.dict.keys.stringArr[i]  # to remove quoted names
  t.setHeaders(header)

  for i in 0..<x.k.dict.values.kArr[0].len:
    var row: seq[string] = @[]
    for j in 0..<x.k.dict.values.kLen:
      case x.k.dict.values.kArr[j].kind
      of kVecInt: 
        row.add $x.k.dict.values.kArr[j].intArr[i]
      of kList: # TODO: temporary
        row.add $x.k.dict.values.kArr[j].kArr[i].ss
      else:
        row.add "fail: " & $x.k.dict.values.kArr[j].kind
    t.addRow(row)

  result = t.render()
  result.removeSuffix()

proc fmtKDict(x: K): string =
  result.add "{"
  for i in 0..<x.k.keys.len:
    if i > 0:
      result.add "; "
    case x.k.keys.kind
    of kVecInt: 
      result.add $x.k.keys[i]
    else:
      result.add "fail: " & $x.k.keys.kind
    # result.add $x.k.keys[i] & ": " & $x.k.values[i]
    result.add ": "
    case x.k.values.kind
    of kVecInt: 
      result.add $x.k.values[i]
    of kList: 
      result.add $x.k.values.kArr[i].ss
    else:
      result.add "fail: " & $x.k.values.kind
  result.add "}"

proc `$`*(x: K): string =
  case x.k.kind
  of kTable:
    result.add fmtKTable(x)
  of kDict:
    result.add fmtKDict(x)
  of kInt:
    result.add $x.k.ii
  of kLong:
    result.add $x.k.jj
  of kFloat:
    result.add $x.k.ff
  of kSym:
    result.add x.k.ss
  of kBool:
    result.add $x.k.bb.bool
  of kTimestamp:
    let d = initDuration(nanoseconds = x.k.ts)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(timestampFormat)
  of kDate:
    let d = initDuration(days = x.k.dd)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(dateFormat)
  of kDateTime:
    let d = initDuration(seconds = int64(86400*(x.k.dt+10957)))
    let dt = initDateTime(1, mJan, 1970, 0, 0, 0, utc()) + d
    result.add dt.format(dateTimeFormat)
  of kTimespan:
    let d = initTime(0, 0) + initDuration(nanoseconds = x.k.tp)
    result.add d.format(timespanFormat, zone = utc())
  of kTime:
    let d = initTime(0, 0) + initDuration(milliseconds = x.k.tt)
    result.add d.format(timeFormat, zone = utc())
  of kVecChar:
    result.add '"' & $cast[cstring](x.k.charArr) & '"'
  else:
    result.add $x.k.kind & ": unknown"
