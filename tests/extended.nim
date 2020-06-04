type T1 =
  object
    k: int
    v: string

test "table":
  let t = newTTable[T1]()
  for x in t.inner:
    echo x
  check 1 == 1
