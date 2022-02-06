#!/usr/bin/env python3
"""
Validate a GFA2 file

Validations implemented here:
  - segments where the sequence is given, have a valid
    value of the length field
  - all record IDs are unique
  - E, G and F lines refer to existing segments
    (which may come after them in the file order)
  - segment coordinates on edge and fragment are <= segment length
  - if the segment coordinate on edge and fragment is equal to the
    segment length, the $ end-position marker is set
  - O, U refer to existing lines
    (which may come after them in the file order)

Usage: ./gfa2_validate.py <inputfile> <gfa2spec>

Arguments:
  <inputfile>  Input file in GFA2 format
  <gfa2spec>   Specification file describing the GFA2 format

Further possible validations not implemented here:
  - check that references in O and U lines have no circularity
  - check that paths in O lines correspond to paths in the graph,
    i.e. traverse existing edges (this requires constructing the
    entire graph)
  - check that alignments fields are compatible with the given
    coordinates and sequence lenghts
"""
import sys
from textformats import Specification
from docopt import docopt

def validation_err(data, lineno, lt, lid, what, values = None):
  ldesc = lt
  if lid: ldesc += f" '{lid}'"
  sys.stderr.write(f"Error in line {lineno} ({ldesc}):\n" +\
                   f"  {what}\n")
  if values is not None:
    sys.stderr.write(f"  {values}\n")
  sys.stderr.write(("-"*60)+"\n")
  data["n_err"] += 1

def check_lid(lt, lid, data):
  if lid in data["ids"] or lid in data["sids"]:
    validation_err(data, data["lineno"], lt, lid,
                   f"ID '{lid}' is not unique")

def check_coords(data, ref, lt, lid, bpos, epos, lnum, slen):
  refstr = f"Reference to segment '{ref}': "
  if bpos["value"] > epos["value"]:
    validation_err(data, lnum, lt, lid,
        f"{refstr}begin coordinate > end coordinate",
        "{} > {}".format(bpos["value"], epos["value"]))
  for pos, lbl in [(bpos, "begin"), (epos, "end")]:
    if pos["value"] < slen:
      if pos["final"]:
        validation_err(data, lnum, lt, lid,
            refstr+lbl+" coordinate wrongly marked as final sequence position",
            f"Sequence length: {slen}; "+\
            "{} coordinate: {}".format(lbl, pos["value"]))
    elif pos["value"] == slen:
      if not pos["final"]:
        validation_err(data, lnum, lt, lid,
            refstr+lbl+" coordinate is the final position but lacks '$'",
            f"Sequence length: {slen}; "+\
            "{} coordinate: {}".format(lbl, pos["value"]))
    else:
      validation_err(data, lnum, lt, lid,
          refstr+lbl+" coordinate larger than the final sequence position",
          f"Sequence length: {slen}; "+\
          "{} coordinate: {}".format(lbl, pos["value"]))

def check_ref(ref, is_sref, lt, lid, data, bpos=None, epos=None):
  found = ref in data["sids"]
  if found and bpos:
    check_coords(data, ref, lt, lid, bpos, epos,
                 data["lineno"], data["sids"][ref])
  if not found:
    if not is_sref:
      found = ref in data["ids"]
    if not found:
      dest = "exp_sids" if is_sref else "exp_ids"
      if ref not in data[dest]:
        data[dest][ref] = []
      data[dest][ref].append((lt, lid, data["lineno"], bpos, epos))

def process_S(lt, line, data):
  lid = line["sid"]
  check_lid("segment", lid, data)
  slen = int(line["slen"])
  if lid in data["exp_sids"]:
    for lt, e_lid, lnum, bpos, epos in data["exp_sids"][lid]:
      if bpos:
        check_coords(data, lid, lt, e_lid, bpos, epos, lnum, slen)
    del data["exp_sids"][lid]
  if lid in data["exp_ids"]:
    del data["exp_ids"][lid]
  if line["sequence"] is not None:
    if len(line["sequence"]) != slen:
      validation_err(data, data["lineno"], lt, lid,
                     "The content of field 'slen' differs "+\
                     "from the length of the sequence",
                     "{} != {}".format(slen, len(line["sequence"])))
  data["sids"][lid] = slen

def process_E(lt, line, data):
  lid = line["eid"]
  if lid is not None:
    check_lid(lt, lid, data)
    if lid in data["exp_ids"]: del data["exp_ids"][lid]
    data["ids"].add(lid)
  check_ref(line["sid1"]["id"], True, lt, lid, data, line["beg1"], line["end1"])
  check_ref(line["sid2"]["id"], True, lt, lid, data, line["beg2"], line["end2"])

def process_G(lt, line, data):
  lid = line["gid"]
  if lid is not None:
    check_lid(lt, lid, data)
    if lid in data["exp_ids"]: del data["exp_ids"][lid]
    data["ids"].add(lid)
  check_ref(line["sid1"]["id"], True, lt, lid, data)
  check_ref(line["sid2"]["id"], True, lt, lid, data)

def process_F(lt, line, data):
  check_ref(line["sid"], True, lt, None, data, line["sbeg"], line["send"])

def process_O(lt, line, data):
  lid = line["oid"]
  if lid is not None:
    check_lid("Ordered Group", lid, data)
    if lid in data["exp_ids"]: del data["exp_ids"][lid]
  for e in line["elements"]:
    check_ref(e["id"], False, lt, lid, data)

def process_U(lt, line, data):
  lid = line["uid"]
  if lid is not None:
    check_lid("Unordered Group", lid, data)
    if lid in data["exp_ids"]: del data["exp_ids"][lid]
  for e in line["elements"]:
    check_ref(e, False, lt, lid, data)

def process_gfaline(line, data):
  data["lineno"]+=1
  lt = line["line_type"]
  if lt == "segment":           process_S(lt, line, data)
  elif lt == "edge":            process_E(lt, line, data)
  elif lt == "gap":             process_G(lt, line, data)
  elif lt == "fragment":        process_F(lt, line, data)
  elif lt == "ordered_group":   process_O(lt, line, data)
  elif lt == "unordered_group": process_U(lt, line, data)

def post_validations(data):
  for exp in ["exp_sids", "exp_ids"]:
    refdesc = "segment" if exp == "exp_sids" else "line"
    for xid, v in data[exp].items():
      for lt, lid, lnum, bpos, epos in v:
        ldesc = lt
        if lid: ldesc += f" '{lid}'"
        validation_err(data, lnum, lt, lid,
          "Reference to non-existing {} '{}'".format(refdesc, xid))

def main(args):
  gfa2spec = Specification(args["<gfa2spec>"])
  data = {"sids": {}, "lineno": 0, "ids": set(),
          "exp_sids": {}, "exp_ids": {}, "n_err": 0}
  gfa2spec["line"].decode_file(args["<inputfile>"], process_gfaline, data)
  post_validations(data)
  if data["n_err"] > 0:
    sys.stderr.write("Total number of errors: "+\
        "{}\n".format(data["n_err"]))
    sys.exit(1)
  else:
    sys.stderr.write("No errors: all validation passed!")
    sys.exit(0)

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)
