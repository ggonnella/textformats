from collections import defaultdict, Counter

class Gfa2StatsCollector:
  def __init__(self, external_segment_data = None):
    self.lt_counts = defaultdict(int)
    self.tags = defaultdict(lambda: defaultdict(int))
    self.nseq = 0
    self.provided_seqlen = 0
    self.non_provided_seqlen = 0
    if external_segment_data is not None:
      self.segment_data = external_segment_data
    else:
      self.segment_data = defaultdict(lambda: {"is_s": False, "nref": 0})

  def lt(self, lt, n=1):
    self.lt_counts[lt] += n

  def segment(self, sid):
    self.segment_data[sid]["is_s"] = True

  def sref(self, sid):
    self.segment_data[sid]["is_s"] = True
    self.segment_data[sid]["nref"] += 1

  def gref(self, xid):
    self.segment_data[xid]["nref"] += 1

  def tag(self, tagname, tagtype):
    self.tags[tagname][tagtype] += 1

  def seq(self, seqlen, provided):
    if provided:
      self.nseq += 1
      self.provided_seqlen += seqlen
    else:
      self.non_provided_seqlen += seqlen

  def nlines(self):
    return sum(self.lt_counts.values())

  def ntags(self):
    return sum([sum(x.values()) for x in self.tags.values()])

  LINE_TYPES = ["header", "segment", "edge", "gap", "fragment", "ordered_group",
                "unordered_group", "comment", "custom_line"]

  def __str__(self):
    nlines = self.nlines()
    result = f"Number of lines: {nlines}\n"
    if nlines == 0:
      return result
    for lt in self.LINE_TYPES:
      result += f"  - {lt}: {self.lt_counts[lt]}\n"
    ntags = self.ntags()
    nsegments = self.lt_counts["segment"]
    result += "\n"
    if nsegments > 0:
      result += f"Number of segments with sequence data: {self.nseq}"
      result += f" ({self.nseq*100/nsegments:.2f}% of segments)\n"
      if self.nseq > 0:
        result += "  - total length of sequences: "+\
                  f"{self.provided_seqlen+self.non_provided_seqlen}\n"
        result += "  - total length of provided sequences: "+\
                  f"{self.provided_seqlen}\n"
        result += "  - total length of non-provided sequences: "+\
                  f"{self.non_provided_seqlen}\n"
        result += "  - average length of provided sequences: "+\
                  f"{self.provided_seqlen/self.nseq:.2f}\n"
      result += "\n"
      refcounter = Counter({s: self.segment_data[s]["nref"] for s in
        self.segment_data.keys() if self.segment_data[s]["is_s"]})
      nsref = sum(refcounter.values())
      result += f"Number of segment references: {nsref}\n"
      if nsref > 0:
        result += "  most common segments in references:\n"
        for k, v in refcounter.most_common(3):
          result += f"    - '{k}': {v} references\n"
      result += "\n"
    result += f"Total number of tags: {ntags}\n"
    if ntags > 0:
      for tn, tt_c in self.tags.items():
        for tt, c in tt_c.items():
          result += f"  - '{tn}:{tt}': {c}\n"
    return result
