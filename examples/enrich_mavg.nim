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

let client = connect("your-server", 9999)

let d = {1: s"one", 2: s"two", 3: s"three"}.toTable

while true:
  let (cmd, data) = client.read(RequestT)
  let resp = data.transform(ReplyT, data.n.mapIt(d.getOrDefault(it)))
  client.reply(resp)
