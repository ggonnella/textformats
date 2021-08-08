from collections import OrderedDict

class Counts:
  def __init__(self):
    self.flag_counts = OrderedDict()
    self.tag_counts = OrderedDict()
    self.rg_counts = OrderedDict()
    self.rg_sm_values = {}
    self.sq_counts = OrderedDict()

  def init_sq(self, sq):
    self.sq_counts[sq] = 0

  def init_rg(self, rg_id, rg_sm):
    self.rg_counts[rg_id] = 0
    self.rg_sm_values[rg_id] = rg_sm

  def count_flag(self, flag):
    if not flag in self.flag_counts:
      self.flag_counts[flag] = 1
    else:
      self.flag_counts[flag] += 1

  def count_sq(self, sq):
    if not sq in self.sq_counts:
      msg = f"Error: Unknown target sequence found in alignment ({sq})"
      raise ValueError(msg)
    else:
      self.sq_counts[sq] += 1

  def count_tag(self, tagname):
    if not tagname in self.tag_counts:
      self.tag_counts[tagname] = 1
    else:
      self.tag_counts[tagname] += 1

  def count_rg(self, tagcode, tagvalue):
    if tagcode != "Z":
      msg = f"Error: RG tag code is not 'Z' but '{tagcode}'"
      raise ValueError(msg)
    if not tagvalue in self.rg_counts:
      msg = f"Error: Unknown RG found in alignment ({tagvalue})"
      raise ValueError(msg)
    else:
      self.rg_counts[tagvalue] += 1

  def print(self):
    print("alignments by target sequence:")
    for k, v in self.sq_counts.items():
      print(f"  {k}: {v}")
    print("alignments by read group:")
    for k, v in self.rg_counts.items():
      sm = self.rg_sm_values[k]
      print(f"  {k} (SM:{sm}): {v}")
    print("tag counts:")
    for k, v in self.tag_counts.items():
      print(f"  {k}: {v}")
    print("alignments by flag value:")
    for k, v in self.flag_counts.items():
      print(f"  {k}: {v}")

