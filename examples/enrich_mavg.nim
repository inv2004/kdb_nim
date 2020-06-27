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

# let client = connect("your-server", 9999)
let client = connect("your-server", 9999)

let d = {1: s"one", 2: s"two", 3: s"three"}.toTable

while true:
  let (cmd, data) = client.read(RequestT)
  for x in data.n:
    echo x
    echo d.getOrDefault(x)
  # let resp = data.transform(ReplyT, data.n.mapIt(d.getOrDefault(it)))
  # let resp = data.transform(ReplyT, v)
  # var mAvg = resp.movingSum
  # for x in mAvg.mitems():
    # sum += x
    # x = sum
  # echo resp
  client.reply(data)
