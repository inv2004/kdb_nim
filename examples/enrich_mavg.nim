import kdb

import sequtils

type
  RequestT = object
    ts: int
    price: float

  ReplyT = object
    ts: int
    price: float
    movingSum: float

defineTable(RequestT)
defineTable(ReplyT)

let client = connect("your-server", 9999)

var sum = 0.0

while true:
  let (cmd, data) = client.read(RequestT)
  echo cmd
  echo data
  var r = data
  var resp = r.transform(ReplyT, toSeq(r.price))
  var mAvg = resp.movingSum
  for x in mAvg.mitems():
    sum += x
    x = sum
  echo resp
  client.reply(resp)

# check isCall(d)
# check d[0] == %"test"
# var t = d[1]
# for x in t.mitems[:int64]:
#     x *= 2
# client.sendSyncReply(t)
