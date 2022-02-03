#!/usr/bin/env python3
"""
Display information about the contents of a GFA2 file
(version based on GfaPy)

Usage: ./gfapy_based.py <inputfile>

Arguments:
  <inputfile>  Input file in the GFA2 format
"""
from docopt import docopt
from gfapy import Gfa, is_placeholder
from info import Info

LTYPES = {"S": "segment", "H": "header", "E": "edge", "G": "gap",
          "F": "fragment", "O": "ordered_group", "U": "unordered_group",
          "#": "comment"}

def process_gfaline(line, info):
  lt = LTYPES.get(line.record_type, "custom_line")
  if lt != "header":
    info.lt(lt)
  if lt == "segment":
    info.segment(line.sid)
    info.seq(line.slen, not is_placeholder(line.sequence))
  elif lt in ["edge", "gap"]:
    info.sref(line.sid1.sid)
    info.sref(line.sid2.sid)
  elif lt == "fragment":
    info.sref(line.sid.sid)
  elif lt == "ordered_group":
    for e in line.items:
      if e.record_type == "S":
        info.sref(e.sid)
  elif lt == "unordered_group":
    for e in line.items:
      if e.record_type == "S":
        info.sref(e.sid)
  #for tn, content in line.tags, {}).items():
  #  info.tag(tn, content["type"])

def main(args):
  info = Info()
  gfa = Gfa.from_file(args["<inputfile>"])
  for line in gfa.lines:
    process_gfaline(line, info)
  info.lt("header", gfa.n_input_header_lines)
  print(info, end="")

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)
