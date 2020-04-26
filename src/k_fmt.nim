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

proc fmtKList(x: K): string =
  result.add "("
  for i in 0..<x.k.kLen:
    if i > 0:
      result.add "; "
    result.add $r1(x.k.kArr[i])
  result.add ")"


proc fmtKTable(x: K): string =
  let t = newUnicodeTable()
  t.separateRows = false
  var header: seq[string] = @[]
  for x in x.k.dict.keys: # TODO: strange r1
    header.add $x  # to remove quoted names
  t.setHeaders(header)

  for i in 0..<x.k.dict.values.kArr[0].len:
    var row: seq[string] = @[]
    for c in x.k.dict.values:
      row.add $c[i]
    t.addRow(row)

  result = t.render()
  result.removeSuffix()

proc fmtKDict(x: K): string =
  result.add "{"
  for i in 0..<x.k.keys.len:
    if i > 0:
      result.add "; "
    result.add $x.k.keys[i] & ": " & $x.k.values[i]
  result.add "}"

proc `$`*(x: K): string =
  case x.k.kind
  of kList:
    result.add fmtKList(x)
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
    var str = newString(x.k.charLen)
    copyMem(str[0].addr, x.k.charArr.addr, x.k.charLen)
    result.add '"' & str & '"'
  else:
    result.add $x.k.kind & ": unknown"
