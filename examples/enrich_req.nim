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

const d = {1: "one", 2: "two", 3: "three"}.toTable

let client = connect("your-server", 9999)
let rep = client.call[:bool](".u.sub", 123.456, "str", s"sym")

while true:
  let (cmd, data) = client.read(RequestT)
  let resp = data.transform(ReplyT, data.n.mapIt(d.getOrDefault(it)))
  echo resp
  client.reply(resp)
