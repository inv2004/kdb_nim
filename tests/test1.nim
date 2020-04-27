# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

{.passC: "-Isrc".}

import unittest
import kdb

type
  GUID* {.importc: "U", header: "k.h".} = object
    g* {.importc.}: array[16, byte]

  
proc r0*(x: K0) {.
  importc: "r0", header: "k.h".}

test "atoms":
  check (%10.int).kind == KKind.kInt
  # check (%10.byte).k.kind == KKind.kInt


