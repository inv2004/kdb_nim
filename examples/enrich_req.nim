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

const d = {1: "one", 2: "two", 3: "three"}.toTable

while true:
  let (cmd, data) = client.read(RequestT)
  let resp = data.transform(ReplyT, data.n.mapIt(d.getOrDefault(it)))
  echo resp
  client.reply(resp)
