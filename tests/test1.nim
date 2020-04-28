# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

{.passC: "-Isrc".}

import unittest
import kdb

import strutils

proc r0*(x: K0) {.
  importc: "r0", header: "k.h".}

test "simple_atoms":
  check (%true).kind == KKind.kBool
  check (%10.byte).kind == KKind.kByte
  check (%10.int16).kind == KKind.kShort
  check (%10.int32).kind == KKind.kInt
  check (%10.int).kind == KKind.kLong
  check (%10.int64).kind == KKind.kLong
  check (%10.float32).kind == KKind.kReal
  check (%10.float).kind == KKind.kFloat
  check (%10.float64).kind == KKind.kFloat
  check (%'a').kind == KKind.kChar
  check toSym("aaa").kind == KKind.kSym
  check s"aaa".kind == KKind.kSym

test "guid":
  let guid1 = %[10.byte,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]
  check guid1.kind == KKind.kGUID
  let guidStr = "0a000000-0000-0000-0000-000000000001"
  let guid2 = toGUID(guidStr)
  check guid2.kind == KKind.kGUID
  check guid1.k.gg == guid2.k.gg
  check $guid1 == guidStr

