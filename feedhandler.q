/ feedhandler.q - dummy feedhandler publishing random trades and quotes
/ Usage: q feedhandler.q [host:port]  (default: localhost:5010)
/ Publishes a batch of random rows every 500ms

syms:`AAPL`MSFT`GOOG`AMZN`TSLA`META`NVDA`JPM

/ ---- random data generators -------------------------------------------------

/ n random trades
randTrades:{[n]
  s:n?syms;
  ([] sym:s; time:n#.z.t; price:100f+n?200f; size:100*1+n?100) }

/ n random quotes
randQuotes:{[n]
  s:n?syms;
  mid:100f+n?200f;
  ([] sym:s; time:n#.z.t; bid:mid-n?1f; ask:mid+n?1f; bsize:100*1+n?50; asize:100*1+n?50) }

/ ---- connection & publish ---------------------------------------------------

.fh.tp:0Ni   / TP handle

.fh.connect:{[dst]
  .fh.tp:hopen hsym `$string dst;
  0N!"Connected to TP at ",string dst }

/ push one batch to the TP
.fh.publish:{
  n:1+`int$3?5;              / 1-4 rows each tick
  neg[.fh.tp](`.u.upd; `trade; randTrades n);
  neg[.fh.tp](`.u.upd; `quote; randQuotes n) }

/ timer tick
.z.ts:{
  @[.fh.publish; ::;
    {[e] 0N!"publish error: ",e;
         @[.fh.connect[.fh.dst];::;{0N!"reconnect failed: ",x}]}] }

/ ---- startup ----------------------------------------------------------------

.fh.dst:$[1=count .z.x; first .z.x; "localhost:5010"]
0N!"Connecting to tickerplant: ",.fh.dst
.fh.connect .fh.dst

\t 500   / publish every 500 ms
0N!"Feedhandler running — publishing trades and quotes every 500ms"
