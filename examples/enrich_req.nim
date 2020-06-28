import kdb
import sequtils
import tables

type
  RequestT = object of RootObj
    n: int

  ReplyT = object of RequestT
    s: Sym

defineTable(RequestT)
defineTable(ReplyT)

const d = {1: 1.1, 2: 2.2, 3: 3.3}.toTable

# q-server:
# .u.sub:{[x;y;z] system"t 1000"; .z.ts:{[x;y] x(`enrich;([] n:10?5))}[.z.w]; (1b; `ok)}

let client = connect("your-server", 9999)
let rep = client.call[:(bool, Sym)](".u.sub", 123.456, "str", s"sym")
echo rep

while true:
  let (cmd, data) = client.read(RequestT, check = true)
  let newCol = data.n.mapIt(d.getOrDefault(it))
  var resp = data.transform(ReplyT, newCol)
  resp.add(ReplyT(n: 100, s: "hundred"))
  echo resp
  client.reply(resp)
