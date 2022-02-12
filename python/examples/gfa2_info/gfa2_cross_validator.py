"""
Cross-Validator for GFA2, implementing the following validations:
  - segments where the sequence is given, have a valid value of the length field
  - E, G: coordinates are <= segment length and use $ end-marker correctly
  - all record IDs are unique
  - E, G and F lines refer to existing segments; O and U to existing lines

Further possible validations not implemented here:
  - check that references in O and U lines have no circularity
  - check paths in O lines (requires constructing the entire graph)
  - check the alignments fields (length compatibility)
"""
import sys
from collections import defaultdict

class Gfa2CrossValidator:

  def __init__(self):
    self.ids      = defaultdict(lambda: {"nref": 0, "slen": 0, "is_s": False})
    self.exp_ids  = defaultdict(list)
    self.lineno = 0
    self.n_err  = 0

  def validation_err(self, lineno, lt, lid, what, values = None):
    ldesc = f"{lt} '{lid}'" if lid else lt
    sys.stderr.write(f"Error in line {lineno} ({ldesc}):\n  {what}\n")
    if values is not None: sys.stderr.write(f"  {values}\n")
    sys.stderr.write(("-"*60)+"\n")
    self.n_err += 1

  def check_coords(self, ref, lt, lid, bpos, epos, lnum, slen):
    refstr = f"Reference to segment '{ref}': "
    if bpos["value"] > epos["value"]:
      self.validation_err(lnum, lt, lid, f"{refstr}begin coordinate > " +\
          "end coordinate", "{} > {}".format(bpos["value"], epos["value"]))
    for pos, lbl in [(bpos, "begin"), (epos, "end")]:
      errmsg = f"Sequence length: {slen}; {lbl} "+\
               "coordinate: {}".format(pos["value"])
      if pos["value"] < slen:
        if pos["final"]:
          self.validation_err(lnum, lt, lid, refstr + lbl + " coordinate " +\
              "wrongly marked as final sequence position", errmsg)
      elif pos["value"] == slen:
        if not pos["final"]:
          self.validation_err(lnum, lt, lid, refstr + lbl + " coordinate " +\
              "is the final position but lacks '$'", errmsg)
      else:
        self.validation_err(lnum, lt, lid, refstr + lbl + " coordinate " +\
            "larger than the final sequence position", errmsg)

  GROUP_LT = ["ordered_group", "unordered_group"]

  def check_ref(self, ref, bpos=None, epos=None):
    found = self.ids.get(ref, None)
    if found:
      if self.lt not in self.GROUP_LT and not found["is_s"]:
        self.validation_err(self.lineno, self.lt, self.lid,
                            f"referenced line '{ref}' is not a segment")
      else:
        found["nref"] += 1
        if bpos: self.check_coords(ref, self.lt, self.lid, bpos, epos,
                                   self.lineno, found["slen"])
    else:
      self.exp_ids[ref].append((self.lt, self.lid, self.lineno, bpos, epos))

  def process_slen(self, slen, sequence):
    self.ids[self.lid]["slen"] = slen
    if sequence is not None:
      exp_slen = len(sequence)
      if exp_slen != slen:
        self.validation_err(self.lineno, self.lt, self.lid,
            f"'slen' value: {slen}) != len('sequence'): {exp_slen}")

  def validate_exp(self, slen):
    for lt, lid, lnum, bpos, epos in self.exp_ids.get(self.lid, []):
      if slen:
        if bpos: self.check_coords(self.lid, lt, lid, bpos, epos, lnum, slen)
      elif lt not in self.GROUP_LT:
        self.validation_err(lnum, lt, lid,
                            f"referenced line '{self.lid}' is not a segment")

  def process_line_id(self, line, field):
    self.lid = line[field]
    if self.lid is not None:
      if self.lid in self.ids:
        self.validation_err(self.lineno, self.lt, self.lid,
                            f"ID '{self.lid}' is not unique")
      self.ids[self.lid]["is_s"] = self.lt == "segment"
      was_exp = self.exp_ids.get(self.lid, None)
      if was_exp:
        self.ids[self.lid]["nref"] = len(was_exp)
        self.validate_exp(int(line.get("slen", 0)))
        del self.exp_ids[self.lid]

  def process_gfaline(self, line, ignore_this=None):
    self.lineno += 1
    self.lt = line["line_type"]
    if self.lt == "segment":
      self.process_line_id(line, "sid")
      self.process_slen(line["slen"], line["sequence"])
    elif self.lt == "edge":
      self.process_line_id(line, "eid")
      self.check_ref(line["sid1"]["id"], line["beg1"], line["end1"])
      self.check_ref(line["sid2"]["id"], line["beg2"], line["end2"])
    elif self.lt == "gap":
      self.process_line_id(line, "gid")
      self.check_ref(line["sid1"]["id"])
      self.check_ref(line["sid2"]["id"])
    elif self.lt == "fragment":
      self.lid = None
      self.check_ref(line["sid"], line["sbeg"], line["send"])
    elif self.lt == "ordered_group":
      self.process_line_id(line, "oid")
      for e in line["elements"]:
        self.check_ref(e["id"])
    elif self.lt == "unordered_group":
      self.process_line_id(line, "uid")
      for e in line["elements"]:
        self.check_ref(e)

  def post_validations(self):
    for xid, v in self.exp_ids.items():
      for lt, lid, lnum, bpos, epos in v:
        refdesc = "line" if lt in self.GROUP_LT else "segment"
        self.validation_err(lnum, lt, lid,
            f"Reference to non-existing {refdesc} '{xid}'")

