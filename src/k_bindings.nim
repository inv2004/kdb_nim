{.compile: "k.c".}
{.passC: "-DKXVER=3".}
{.link: "c.o".}

import k_types
export k_types

proc ks*(x: cstring): K {.
  importc: "ks", header: "\"k.h\"".}

proc ki*(x: cint): K {.
  importc: "ki", header: "\"k.h\"".}

proc knk*(i: int): K {.
  importc: "knk", header: "\"k.h\"".}

proc jk*(l: ptr K, x: K) {.
  importc: "jk", header: "\"k.h\"".}

proc ktn*(t:int, i: int): K {.
  importc: "ktn", header: "\"k.h\"".}

proc js*(l: ptr K, x: cstring) {.
  importc: "js", header: "\"k.h\"".}

proc ja*(l: ptr K, x: ptr cint) {.
  importc: "ja", header: "\"k.h\"".}

proc ss*(x: cstring): cstring {.
  importc: "ss", header: "\"k.h\"".}

proc xD*(k: K, v: K): K {.
  importc: "xD", header: "\"k.h\"".}

proc xT*(x: K): K {.
  importc: "xT", header: "\"k.h\"".}

proc kK*(x: K): K {.
  importc: "kK", header: "\"k.h\"".}

proc khp*(x: cstring, p: int): FileHandle {.
  importc: "khp", header: "\"k.h\"".}

proc k*(h: cint, x: cstring, arg1: K): K {.
  importc: "k", header: "\"k.h\"".}

proc k*(h: cint, x: cstring, arg1, arg2: K): K {.
  importc: "k", header: "\"k.h\"".}

proc k*(h: cint, x: cstring, arg1, arg2, arg3: K): K {.
  importc: "k", header: "\"k.h\"".}

proc checkCStructOffset*() {.
  importc: "check_c_struct_offset".}

proc checkNimStructOffset*() =
  echo "Nim-struct-offset:"
  echo "  m: ", offsetof(K, m)
  echo "  a: ", offsetof(K, a)
  echo "  t: ", offsetof(K, kind)
  echo "  u: ", offsetof(K, tu)
  echo "  r: ", offsetof(K, tr)
  echo "  k: ", offsetof(K, dict)
  echo "  n: ", offsetof(K, kLen)
  echo "  g: ", offsetof(K, kArr)

