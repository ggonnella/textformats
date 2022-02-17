import strformat, tables
import gfa2_segments_data

type Gfa2StatsCollector* = object
  lt_counts: TableRef[string, int]
  tags: TableRef[string, int]
  nseq*: int
  provided_seqlen: int
  non_provided_seqlen: int
  segments_data: Gfa2SegmentsData

proc newGfa2StatsCollector*(segments_data: Gfa2SegmentsData = nil):
                           Gfa2StatsCollector =
  result.lt_counts = newTable[string, int]()
  result.tags = newTable[string, int]()
  if segments_data.isnil:
    result.segments_data = newGfa2SegmentsData()
  else:
    result.segments_data = segments_data

proc lt*(self: Gfa2StatsCollector, lt: string, n=1) =
  if lt notin self.lt_counts:
    self.lt_counts[lt] = n
  else:
    self.lt_counts[lt] += n

proc segment*(self: var Gfa2StatsCollector, sid: string) =
  self.segments_data.set_is_s(sid)

proc sref*(self: var Gfa2StatsCollector, sid: string) =
  self.segments_data.set_is_s(sid, true)

proc gref*(self: var Gfa2StatsCollector, xid: string) =
  self.segments_data.incref(xid)

proc tag*(self: var Gfa2StatsCollector, tagname: string, tagtype: string) =
  let tk = tagname & ":" & tagtype
  if tk notin self.tags:
    self.tags[tk] = 1
  else:
    self.tags[tk] += 1

proc seq*(self: var Gfa2StatsCollector, seqlen: int, provided: bool) =
  if provided:
    self.nseq += 1
    self.provided_seqlen += seqlen
  else:
    self.non_provided_seqlen += seqlen

proc get_nlines*(self: Gfa2StatsCollector): int =
  for lt, count in self.lt_counts:
    result += count

proc get_ntags*(self: Gfa2StatsCollector): int =
  for tk, count in self.tags:
    result += count

const LINE_TYPES =
  @["header", "segment", "edge", "gap", "fragment", "ordered_group",
    "unordered_group", "comment", "custom_line"]

proc `$`*(self: Gfa2StatsCollector): string =
  let nlines = self.get_nlines()
  result &= &"Number of lines: {nlines}\n"
  if nlines == 0: return
  for lt in LINE_TYPES:
    let count = if lt in self.lt_counts: self.lt_counts[lt] else: 0
    result &= &"  - {lt}: {count}\n"
  let
    ntags = self.get_ntags()
    nsegments = self.lt_counts["segment"]
  result &= "\n"
  if nsegments > 0:
    result &= &"Number of segments with sequence data: {self.nseq}"
    result &= &" ({self.nseq*100/nsegments:.2f}% of segments)\n"
    if self.nseq > 0:
      result &= "  - total length of sequences: " &
             &"{self.provided_seqlen+self.non_provided_seqlen}\n"
      result &= "  - total length of provided sequences: " &
             &"{self.provided_seqlen}\n"
      result &= "  - total length of non-provided sequences: " &
             &"{self.non_provided_seqlen}\n"
      result &= "  - average length of provided sequences: " &
             &"{self.provided_seqlen/self.nseq:.2f}\n"
      result &= "\n"
      let nsref = self.segments_data.get_nsref()
      result &= &"Number of segment references: {nsref}\n"
      if nsref > 0:
        result &= "  most common segments in references:\n"
        var i = 0
        for k, v in self.segments_data.most_common_s():
          result &= &"    - '{k}': {v} references\n"
          i += 1
          if (i == 3):
            break
      result &= "\n"
    result &= &"Total number of tags: {ntags}\n"
    if ntags > 0:
      for tk, count in self.tags:
        result &= &"  - '{tk}': {count}\n"
    return result
