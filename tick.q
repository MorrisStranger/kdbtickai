/ tick.q - KX standard tickerplant with log replay support
/ Replay usage:
/   batch:    q tick.q [schema.q] [host:port] -replay /path/to/log -replaymode batch
/   realtime: q tick.q [schema.q] [host:port] -replay /path/to/log -replaymode realtime [-speed 1.0] [-timecol time]

\d .u
init:{w::t!(count t::`)#enlist(`)!()}
del:{w[x]_:w[x;;0]?y};`.u.del 0N!
sel:{$[99h=type w x;select sym from w x where sym in y;w[x]]}
pub:{[t;x]{[t;x;w]if[count x:sel[t]x;(neg first w)(`.u.upd;t;x)]}[t;x]each w[t]}
add:{$[(count w x)>i:w[x;;0]?y;[w[x;i;1]:w[x;i;1],z;w[x;i]];w[x],:enlist(y;z)];(x;`\`$(?,)prior distinct$[99h=type w x;key w x;;]w x:. x)}
sub:{if[x~`;:[(,x)sub'y;]];if[not x in key w;w[x]::()];add[x;y;z]}
end:{(neg union/[w[;;1]])@\:(`.u.end;x)}
\d .

upd:{[t;x]
 if[not -16h=type first first x;
   [if[l;l enlist(`upd;t;x)];.u.pub[t;x];:()]];
 t insert x;
 if[l;l enlist(`upd;t;x)];
 .u.pub[t;x]}

.z.ts:{.u.end .z.d}
\t 1000

.u.d:.z.d
.u.L:`:./

if[not("w"~first string .z.o)&.z.K<3.0;
  .u.l:hopen .u.L:.Q.dd[.u.L;.u.d]]

.u.init[]

/ ============================================================
/ LOG REPLAY
/ ============================================================

/ Replay state
.u.replay.msgs:()        / buffered messages for realtime mode
.u.replay.idx:0i         / current position in buffer
.u.replay.starttime:0Np  / wall-clock time replay began
.u.replay.logstart:0Np   / timestamp of first message in log
.u.replay.speed:1.0      / playback speed multiplier (2.0 = double speed)
.u.replay.timecol:`time  / column used for pacing in realtime mode

/ upd override used during log loading - publishes only, never re-logs
.u.replay.upd:{[t;x] .u.pub[t;x]}

/ Batch replay: push all messages to subscribers as fast as possible.
/ logfile: symbol or string path to the TP log
.u.replay.batch:{[logfile]
  orig:upd;
  upd::.u.replay.upd;
  @[-11!; hsym `$string logfile; {'"replay failed: ",x}];
  upd::orig;
  0N!"Batch replay complete"}

/ Buffer upd used when loading log for realtime mode
.u.replay.buffer:{[t;x] .u.replay.msgs,:enlist(t;x)}

/ Extract the leading time value from a message payload.
/ Handles both table (select first row, named col) and list payloads.
.u.replay.msgtime:{[x;col]
  $[98h=type x;
    first x col;                     / table: first row's time column
    0h=type x;
      $[col in cols first x; first(first x)col; first first x];  / list of dicts
    first x]}                        / plain list - take first element

/ Realtime replay: pace message delivery to match original timing.
/ logfile : symbol or string path to TP log
/ timecol : symbol - column name to use for timing (default .u.replay.timecol)
/ speed   : float  - playback speed multiplier (default .u.replay.speed)
.u.replay.rt:{[logfile;timecol;speed]
  .u.replay.msgs:();
  .u.replay.idx:0i;
  .u.replay.timecol:timecol;
  .u.replay.speed:speed;
  / buffer all messages
  orig:upd;
  upd::.u.replay.buffer;
  @[-11!; hsym `$string logfile; {'"replay load failed: ",x}];
  upd::orig;
  if[0=count .u.replay.msgs; 0N!"No messages to replay"; :()];
  / anchor timing: record wall clock and log start time
  .u.replay.logstart:.u.replay.msgtime[.u.replay.msgs[0;1]; timecol];
  .u.replay.starttime:.z.p;
  / switch timer to replay tick handler
  .z.ts:.u.replay.tick;
  \t 10;
  0N!"Realtime replay started: ",(string count .u.replay.msgs)," messages"}

/ Timer callback for realtime replay.
/ Flushes all messages whose scaled log-offset has elapsed since replay start.
.u.replay.tick:{
  wallElapsed:.z.p - .u.replay.starttime;
  while[.u.replay.idx < count .u.replay.msgs;
    msg:.u.replay.msgs .u.replay.idx;
    / time elapsed in log since first message, scaled by speed
    logOffset:.u.replay.speed * `timespan$.u.replay.msgtime[msg 1;.u.replay.timecol] - .u.replay.logstart;
    if[logOffset > wallElapsed; :()];   / not yet due - wait for next tick
    .u.pub[msg 0; msg 1];
    .u.replay.idx+:1i];
  / all messages sent - restore normal end-of-day timer
  .z.ts:{.u.end .z.d};
  \t 1000;
  0N!"Realtime replay complete"}

/ ============================================================
/ STARTUP: auto-replay if command-line args provided
/ q tick.q sym -replay ./tp.log -replaymode realtime -speed 2.0 -timecol time
/ ============================================================
.u.opts:.Q.opt .z.x

if[`replay in key .u.opts;
  .u.replayfile:first .u.opts`replay;
  .u.replaymode:$[`replaymode in key .u.opts; `$first .u.opts`replaymode; `batch];
  .u.replayspeed:$[`speed in key .u.opts; "F"$first .u.opts`speed; .u.replay.speed];
  .u.replaytimecol:$[`timecol in key .u.opts; `$first .u.opts`timecol; .u.replay.timecol];
  0N!"Starting ",(string .u.replaymode)," replay of: ",.u.replayfile;
  $[.u.replaymode~`realtime;
    .u.replay.rt[.u.replayfile; .u.replaytimecol; .u.replayspeed];
    .u.replay.batch .u.replayfile]]
