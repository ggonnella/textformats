import tables

type
  Gfa2SegmentsDataValue* = tuple[is_s: bool, nref: int, slen: int]
  Gfa2SegmentsData* = TableRef[string, Gfa2SegmentsDataValue]

proc newGfa2SegmentsData*(): Gfa2SegmentsData =
  newTable[string, Gfa2SegmentsDataValue]()

proc set_is_s*(self: Gfa2SegmentsData, sid: string, incref = false) =
  if sid in self:
    self[sid].is_s = true
    if incref: self[sid].nref += 1
  else:
    self[sid] = (is_s: true, nref: (if incref: 1 else: 0), slen: 0)

proc incref*(self: Gfa2SegmentsData, xid: string) =
  if xid in self:
    self[xid].nref += 1
  else:
    self[xid] = (is_s: false, nref: 1, slen: 0)

proc nref*(self: Gfa2SegmentsData, xid: string): int =
  self[xid].nref

proc is_s*(self: Gfa2SegmentsData, xid: string): bool =
  self[xid].is_s

proc slen*(self: Gfa2SegmentsData, xid: string): int =
  self[xid].slen

proc set_slen*(self: Gfa2SegmentsData, sid: string, slen: int) =
  if sid in self:
    self[sid].slen = slen
  else:
    self[sid] = (is_s: true, nref: 0, slen: slen)

proc needkey*(self: Gfa2SegmentsData, xid: string) =
  if xid notin self:
    self[xid] = (is_s: false, nref: 0, slen: 0)

proc get_nsref*(self: Gfa2SegmentsData): int =
  for k, v in self:
    if v.is_s:
      result += v.nref

proc most_common_s*(self: Gfa2SegmentsData): CountTableRef[string] =
  result = newCountTable[string]()
  for k, v in self:
    if v.is_s:
      result[k] = v.nref
  result.sort()
