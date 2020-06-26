import kdb
import sequtils

type
  RequestT = object of RootObj
    ts: int
    price: float

  ReplyT = object of RequestT
    movingSum: float

defineTable(RequestT)
defineTable(ReplyT)

let client = connect("your-server", 9999)

var sum = 0.0

while true:
  let (cmd, data) = client.read(RequestT)               # var - because transform wants mutable
  let resp = data.transform(ReplyT, toSeq(data.price))  
  var mAvg = resp.movingSum
  for x in mAvg.mitems():
    sum += x
    x = sum
  echo resp
  client.reply(resp)
