import kdb
import sequtils
import tables
import asyncdispatch

type
  RequestT = object of RootObj
    n: int

  ReplyT = object of RequestT
    s: Sym

defineTable(RequestT)
defineTable(ReplyT)

# q-server:
# .u.sub:{[x;y;z] system"t 1000"; .z.ts:{[x;y] -1 .Q.s2 x(`enrich;([] n:10?5))}[.z.w]; (1b; `ok)}

let client = waitFor asyncConnect("your-server", 9999)

let rep = waitFor client.asyncCall[:(bool, Sym)](".u.sub", 123.456, "str", s"sym")
echo rep

serve(client):
  proc enrich(data: KTable[RequestT]): KTable[ReplyT] =
    let newCol = data.n.mapIt(d.getOrDefault(it))
    result = data.transform(ReplyT, newCol)
    result.add(ReplyT(n: 100, s: "hundred"))
    echo result

runForever()
