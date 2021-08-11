import strformat

type
  OpStats* = object
    num: int
    totlen: int
    maxlen: int
    minlen: int
    code: string

proc newOpStats*(code: string): OpStats =
  result.num = 0
  result.totlen = 0
  result.maxlen = 0
  result.minlen = int.high
  result.code = code

proc process_op*(self: var OpStats, oplen: int) =
  self.num += 1
  self.totlen += oplen
  if oplen > self.maxlen:
    self.maxlen = oplen
  if oplen < self.minlen:
    self.minlen = oplen

proc `$`*(self: OpStats): string =
  return &"{self.code}={{" &
         &"{self.num}:{self.minlen}..{self.maxlen};sum={self.totlen}}}"

proc print_all_opstats*(opstats_m: OpStats,
                       opstats_i: OpStats,
                       opstats_d: OpStats) =
  echo(&"{opstats_m},{opstats_i},{opstats_d}")
