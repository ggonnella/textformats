class OpStats:
  def __init__(self, code):
    self.num = 0
    self.totlen = 0
    self.maxlen = 0
    self.minlen = None
    self.code = code

  def process_op(self, oplen):
    self.num += 1
    self.totlen += oplen
    if oplen > self.maxlen:
      self.maxlen = oplen
    if (self.minlen is None) or oplen < self.minlen:
      self.minlen = oplen

  def __str__(self):
    return f"{self.code}={{{self.num}:{self.minlen}..{self.maxlen};"+\
           f"sum={self.totlen}}}"

def compute_stats(cigar):
  opstats = {"M": OpStats("M"), "I": OpStats("I"), "D": OpStats("D")}
  for cigar_op in cigar:
    opstats[cigar_op["code"]].process_op(cigar_op["length"])
  return opstats

def print_all_opstats(opstats):
  print(f"{opstats['M']},{opstats['I']},{opstats['D']}")
