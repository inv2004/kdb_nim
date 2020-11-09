#import procs
#export procs
import access
export access

import strutils
import times
import terminaltables
import uuids

const monthFormat = initTimeFormat("yyyy-MM")
const dateFormat = initTimeFormat("yyyy-MM-dd")
const dateTimeFormat = initTimeFormat("yyyy-MM-dd\'T\'HH:mm:ss\'.\'fff")
const timestampFormat = "yyyy-MM-dd\'T\'HH:mm:ss\'.\'fffffffff"
const timespanFormat = "HH:mm:ss\'.\'fffffffff"
const minuteFormat = "HH:mm"
const secondFormat = "HH:mm:ss"
const timeFormat = "HH:mm:ss\'.\'fff"

proc `$`*(x: K): string {.gcsafe.}

include procs

proc fmtKList(x: K): string =
  result.add "("
  for i in 0..<x.k.kLen:
    if i > 0:
      result.add "; "
    result.add $toK(x.k.kArr[i])
  result.add ")"

proc flatoKTable*(x: K): string =
  result.add "|"
  for i in 0..<x.k.dict.keys.len:
    if i > 0:
      result.add ", "
    result.add $x.k.dict.keys[i] & ": "
    result.add $x.k.dict.values[i]
  result.add "|"

proc fmtKTable(x: K): string {.gcsafe.} =
  let t = newUnicodeTable()
  t.separateRows = false
  var header: seq[string] = @[]
  for x in toK(x.k.dict.keys): # TODO: strange r1
    header.add $x  # to remove quoted names
  t.setHeaders(header)

  for i in 0..<x.k.dict.values.kArr[0].len:
    var row: seq[string] = @[]
    for c in toK(x.k.dict.values):
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

proc fmtKVec(x: K): string =
  result.add "["
  for i in 0..<x.k.len:
    if i > 0:
      result.add ", "
    result.add $x.k[i]
  result.add "]"

proc fmtKGUID(x: K): string =
  $x.getGUID()

proc `$`*(x: K): string {.gcsafe.} =
  if isNil(x.k):
    return "nil"
  case x.k.kind
  of kList:
    result.add fmtKList(x)
  of kTable:
    result.add fmtKTable(x)
  of kDict:
    result.add fmtKDict(x)
  of kGUID:
    result.add fmtKGUID(x)
  of kByte:
    result.add $x.k.by.int  # TODO: cannot convert via byte: fix
  of kShort:
    result.add $x.k.sh
  of kInt:
    result.add $x.k.ii
  of kLong:
    result.add if x.k.jj == 0x8000000000000000: "NaN" else: $x.k.jj
  of kReal:
    result.add $x.k.rr
  of kFloat:
    result.add $x.k.ff
  of kChar:
    result.add "'" & $x.k.ch & "'"
  of kSym:
    result.add getStr(x)
  of kBool:
    result.add $x.k.bb.bool
  of kId:
    result.add "(::)"
  of kError:
    result.add $x.k.msg
  of kTimestamp:
    result.add x.getTime().utc().format(timestampFormat)
  of kMonth:
    let d = initTimeInterval(months = x.k.mo)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(monthFormat)
  of kDate:
    let d = initDuration(days = x.k.dd)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(dateFormat)
  of kDateTime:
    result.add $x.getDateTime()
  of kTimespan:
    let d = initTime(0, 0) + initDuration(nanoseconds = x.k.tp)
    let days = int(d.toUnixFloat() / (24*3600))
    result.add $days & "D" & d.format(timespanFormat, zone = utc())
  of kMinute:
    let d = initTime(0, 0) + initDuration(minutes = x.k.mi)
    result.add d.format(minuteFormat, zone = utc())
  of kSecond:
    let d = initTime(0, 0) + initDuration(seconds = x.k.se)
    result.add d.format(secondFormat, zone = utc())
  of kTime:
    let d = initTime(0, 0) + initDuration(milliseconds = x.k.tt)
    result.add d.format(timeFormat, zone = utc())
  of kVecChar:
    result.add '"' & x.getStr() & '"'
  of kVecInt, kVecSym, kVecBool, kVecByte, kVecShort,
        kVecLong, kVecReal, kVecFloat,
        kVecMonth, kVecMinute, kVecSecond,
        kVecDateTime, kVecTimestamp, kVecTimespan:
    result.add fmtKVec(x)
  of kVecGUID:
    result.add fmtKVec(x)
  else:
    result.add $x.k.kind & ": unknown"
