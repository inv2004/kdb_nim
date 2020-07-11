import kdb, asyncdispatch

proc test(x: string): string =
  "> " & x & "\c\L"

asyncCheck asyncServe(9999, test)
runForever()
