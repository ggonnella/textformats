import tables, strformat, strutils, json
import gfa2_segments_data

type ExpIdsValue = tuple[lt: string, lid: string, lineno: int,
                         bpos: JsonNode, epos: JsonNode]

type Gfa2CrossValidator* = object
  ids*: Gfa2SegmentsData
  exp_ids*: TableRef[string, seq[ExpIdsValue]]
  lineno*: int
  n_err*: int
  lt*: string
  lid*: string

proc newGfa2CrossValidator*(): Gfa2CrossValidator =
  result.ids = newGfa2SegmentsData()
  result.exp_ids = newTable[string, seq[ExpIdsValue]]()

proc validation_err(self: var Gfa2CrossValidator, lineno: int, lt: string,
                    lid: string, what: string, values = "") =
  let ldesc = if len(lid) > 0: &"{lt} '{lid}'" else: lt
  stderr.write(&"Error in line {lineno} ({ldesc}):\n  {what}\n")
  if len(values) > 0: stderr.write(&"  {values}\n")
  stderr.write(("-".repeat(60)) & "\n")
  self.n_err = self.n_err + 1

proc check_coords(self: var Gfa2CrossValidator, refname: string, lt: string,
                  lid: string, bpos: JsonNode, epos: JsonNode,
                  lnum: int, slen: int) =
  let refstr = &"Reference to segment '{refname}': "
  if bpos["value"].getInt() > epos["value"].getInt():
    self.validation_err(lnum, lt, lid, &"{refstr}begin coordinate > " &
        "end coordinate", $(bpos["value"]) & " > " &
        $(epos["value"]))
  for i, pos_lbl in @[(bpos, "begin"), (epos, "end")]:
    let (pos, lbl) = pos_lbl
    let errmsg = &"Sequence length: {slen}; {lbl} " &
             "coordinate: " & $(pos["value"])
    if pos["value"].getInt() < slen:
      if pos["final"].getBool():
        self.validation_err(lnum, lt, lid, refstr & lbl & " coordinate " &
            "wrongly marked as final sequence position", errmsg)
    elif pos["value"].getInt() == slen:
      if not pos["final"].getBool():
        self.validation_err(lnum, lt, lid, refstr & lbl & " coordinate " &
            "is the final position but lacks '$'", errmsg)
    else:
      self.validation_err(lnum, lt, lid, refstr & lbl & " coordinate " &
          "larger than the final sequence position", errmsg)

const
  GROUP_LT = ["ordered_group", "unordered_group"]

proc check_ref(self: var Gfa2CrossValidator, refname_n: JsonNode,
               bpos: JsonNode = nil, epos: JsonNode = nil) =
  let refname = refname_n.getStr()
  if refname in self.ids:
    if self.lt notin GROUP_LT and not self.ids.is_s(refname):
      self.validation_err(self.lineno, self.lt, self.lid,
                          &"referenced line '{refname}' is not a segment")
    else:
      self.ids.incref(refname)
      if not bpos.isNil:
        self.check_coords(refname, self.lt, self.lid, bpos, epos,
                          self.lineno, self.ids.slen(refname))
  else:
    if refname notin self.exp_ids:
      self.exp_ids[refname] = newSeq[ExpIdsValue]()
    self.exp_ids[refname].add((self.lt, self.lid, self.lineno, bpos, epos))

proc process_slen(self: var Gfa2CrossValidator, slen: int, sequence: JsonNode) =
  self.ids.set_slen(self.lid, slen)
  if sequence.kind == JString:
    let exp_slen = len(sequence.getStr())
    if exp_slen != slen:
      self.validation_err(self.lineno, self.lt, self.lid,
          &"'slen' value: {slen}) != len('sequence'): {exp_slen}")

proc validate_exp(self: var Gfa2CrossValidator, slen: int) =
  if self.lid in self.exp_ids:
    for v in self.exp_ids[self.lid]:
      let (lt, lid, lnum, bpos, epos) = v
      if slen > 0:
        if not bpos.isNil:
          self.check_coords(self.lid, lt, lid, bpos, epos, lnum, slen)
      elif lt notin GROUP_LT:
        self.validation_err(lnum, lt, lid,
                            &"referenced line '{self.lid}' is not a segment")

proc process_line_id(self: var Gfa2CrossValidator,
                     line: JsonNode, field: string) =
  self.lid = if line[field].kind == JString: line[field].getStr() else: ""
  if len(self.lid) > 0:
    if self.lid in self.ids:
      self.validation_err(self.lineno, self.lt, self.lid,
                          &"ID '{self.lid}' is not unique")
    self.ids.needkey(self.lid)
    self.ids[self.lid].is_s = (self.lt == "segment")
    if self.lid in self.exp_ids:
      self.ids[self.lid].nref = len(self.exp_ids[self.lid])
      let slen = if self.lt == "segment": line["slen"].getInt() else: 0
      self.validate_exp(slen)
      self.exp_ids.del(self.lid)

proc process_gfaline*(self: var Gfa2CrossValidator, line: JsonNode,
                     ignore_this: pointer = nil) =
  self.lineno += 1
  self.lt = line["line_type"].getStr()
  if self.lt == "segment":
    self.process_line_id(line, "sid")
    self.process_slen(line["slen"].getInt(), line["sequence"])
  elif self.lt == "edge":
    self.process_line_id(line, "eid")
    self.check_ref(line["sid1"]["id"], line["beg1"], line["end1"])
    self.check_ref(line["sid2"]["id"], line["beg2"], line["end2"])
  elif self.lt == "gap":
    self.process_line_id(line, "gid")
    self.check_ref(line["sid1"]["id"])
    self.check_ref(line["sid2"]["id"])
  elif self.lt == "fragment":
    self.lid = ""
    self.check_ref(line["sid"], line["sbeg"], line["send"])
  elif self.lt == "ordered_group":
    self.process_line_id(line, "oid")
    for e in line["elements"]:
      self.check_ref(e["id"])
  elif self.lt == "unordered_group":
    self.process_line_id(line, "uid")
    for e in line["elements"]:
      self.check_ref(e)

proc post_validations*(self: var Gfa2CrossValidator) =
  for xid, v in self.exp_ids:
    for data in v:
      let (lt, lid, lnum, _, _) = data
      let refdesc = if lt in GROUP_LT: "line" else: "segment"
      self.validation_err(lnum, lt, lid,
          &"Reference to non-existing {refdesc} '{xid}'")

