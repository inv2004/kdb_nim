import k_types
export k_types

proc kb*(x: bool): K0 {.
  importc: "kb", header: "k.h".}

proc ks*(x: cstring): K0 {.
  importc: "ks", header: "k.h".}

proc ki*(x: cint): K0 {.
  importc: "ki", header: "k.h".}

proc kf*(x: cdouble): K0 {.
  importc: "kf", header: "k.h".}

proc kd*(x: cint): K0 {.
  importc: "kd", header: "k.h".}

proc kz*(x: cdouble): K0 {.
  importc: "kz", header: "k.h".}

proc ktj*(t: byte, x: clonglong): K0 {.
  importc: "ktj", header: "k.h".}

proc kt*(x: cint): K0 {.
  importc: "kt", header: "k.h".}

proc knk*(i: int): K0 {.
  importc: "knk", header: "k.h".}

proc jk*(l: ptr K0, x: K0) {.
  importc: "jk", header: "k.h".}

proc ktn*(t:int, i: int): K0 {.
  importc: "ktn", header: "k.h".}

proc js*(l: ptr K0, x: cstring) {.
  importc: "js", header: "k.h".}

proc ja*(l: ptr K0, x: ptr cint) {.
  importc: "ja", header: "k.h".}

proc ss*(x: cstring): cstring {.
  importc: "ss", header: "k.h".}

proc xD*(k: K0, v: K0): K0 {.
  importc: "xD", header: "k.h".}

proc xT*(x: K0): K0 {.
  importc: "xT", header: "k.h".}

proc kK*(x: K0): K0 {.
  importc: "kK", header: "k.h".}

proc khp*(x: cstring, p: int): FileHandle {.
  importc: "khp", header: "k.h".}

proc k*(h: cint, x: cstring, a: K0): K0 {.
  importc: "k", header: "k.h".}

proc k*(h: cint, x: cstring, a, b: K0): K0 {.
  importc: "k", header: "k.h".}

proc k*(h: cint, x: cstring, a, b, c: K0): K0 {.
  importc: "k", header: "k.h".}

proc k*(h: cint, x: cstring, a, b, c, d: K0): K0 {.
  importc: "k", header: "k.h".}

proc checkCStructOffset*() {.
  importc: "check_c_struct_offset".}

proc checkNimStructOffset*() =
  echo "Nim-struct-offset:"
  echo "  m: ", offsetof(K0, m)
  echo "  a: ", offsetof(K0, a)
  echo "  t: ", offsetof(K0, kind)
  echo "  u: ", offsetof(K0, tu)
  echo "  r: ", offsetof(K0, tr)
  echo "  k: ", offsetof(K0, dict)
  echo "  n: ", offsetof(K0, kLen)
  echo "  g: ", offsetof(K0, kArr)

