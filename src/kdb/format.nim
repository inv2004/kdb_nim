#import procs
#export procs
import access
export access

import strutils
import times
import terminaltables
import uuids
import endians

const monthFormat = initTimeFormat("yyyy-MM")
const dateFormat = initTimeFormat("yyyy-MM-dd")
const dateTimeFormat = initTimeFormat("yyyy-MM-dd\'T\'HH:mm:ss\'.\'fff")
const timestampFormat = "yyyy-MM-dd\'T\'HH:mm:ss\'.\'fffffffff"
const timespanFormat = "HH:mm:ss\'.\'fffffffff"
const minuteFormat = "HH:mm"
const secondFormat = "HH:mm:ss"
const timeFormat = "HH:mm:ss\'.\'fff"

proc `$`*(x: K): string

include procs

proc fmtKList(x: K): string =
  result.add "("
  for i in 0..<x.k.kLen:
    if i > 0:
      result.add "; "
    result.add $r1(x.k.kArr[i])
  result.add ")"

proc flatTable*(x: K): string =
  result.add "|"
  for i in 0..<x.k.dict.keys.len:
    if i > 0:
      result.add ", "
    result.add $x.k.dict.keys[i] & ": "
    result.add $x.k.dict.values[i]
  result.add "|"

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

proc fmtKVec(x: K): string =
  result.add "["
  for i in 0..<x.k.len:
    if i > 0:
      result.add ", "
    result.add $x.k[i]
  result.add "]"

proc fmtKGUID(x: K): string =
  var twoInts64 = cast[ptr UncheckedArray[int64]](x.k.gg.g.addr)
  var most: int64
  var least: int64
  bigEndian64(most.addr, twoInts64[0].addr)
  bigEndian64(least.addr, twoInts64[1].addr)
  let u = initUUID(most, least)
  $u

proc `$`*(x: K): string =
  if x.k == nil:
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
    result.add $x.k.jj
  of kReal:
    result.add $x.k.rr
  of kFloat:
    result.add $x.k.ff
  of kChar:
    result.add "'" & $x.k.ch & "'"
  of kSym:
    # var str = newString(4)
    # copyMem(str[0].addr, x.k.ss.addr, 4)
    result.add $x.k.ss
  of kBool:
    result.add $x.k.bb.bool
  of kId:
    result.add "(::)"
  of kError:
    result.add $x.k.msg
  of kTimestamp:
    let seconds = (x.k.ts div 1000000000) + 10957*86400
    let nanos = x.k.ts mod 1000000000
    let t = initTime(seconds, nanos)
    result.add t.utc().format(timestampFormat)
  of kMonth:
    let d = initTimeInterval(months = x.k.mo)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(monthFormat)
  of kDate:
    let d = initDuration(days = x.k.dd)
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(dateFormat)
  of kDateTime:
    let d = initDuration(milliseconds = int64(86400000*x.k.dt))
    let dt = initDateTime(1, mJan, 2000, 0, 0, 0, utc()) + d
    result.add dt.format(dateTimeFormat)
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
    var str = newString(x.k.charLen)
    if str.len > 0:
      copyMem(str[0].addr, x.k.charArr.addr, x.k.charLen)
    result.add '"' & str & '"'
  of kVecInt, kVecSym, kVecBool, kVecByte, kVecShort,
        kVecLong, kVecReal, kVecFloat,
        kVecMonth, kVecMinute, kVecSecond,
        kVecDateTime, kVecTimestamp, kVecTimespan:
    result.add fmtKVec(x)
  of kVecGUID:
    result.add fmtKVec(x)
  else:
    result.add $x.k.kind & ": unknown"
