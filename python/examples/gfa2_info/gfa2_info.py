#!/usr/bin/env python3
"""
Display information about the contents of a GFA2 file

Usage: ./gfa2_info.py <inputfile> <gfa2spec>

Arguments:
  <inputfile>  Input file in GFA2 format
  <gfa2spec>   Specification file describing the GFA2 format
"""
from textformats import Specification
from docopt import docopt
from info import Info

def process_gfaline(line, info):
  info.lt(line["line_type"])
  if line["line_type"] == "segment":
    info.segment(line["sid"])
    info.seq(line["slen"], line["sequence"] is not None)
  elif line["line_type"] in ["edge", "gap"]:
    info.sref(line["sid1"]["id"])
    info.sref(line["sid2"]["id"])
  elif line["line_type"] == "fragment":
    info.sref(line["sid"])
  elif line["line_type"] == "ordered_group":
    for e in line["elements"]:
      info.gref(e["id"])
  elif line["line_type"] == "unordered_group":
    for e in line["elements"]:
      info.gref(e)
  for tn, content in line.get("tags", {}).items():
    info.tag(tn, content["type"])

def main(args):
  gfa2spec = Specification(args["<gfa2spec>"])
  info = Info()
  gfa2spec["line"].decode_file(args["<inputfile>"], process_gfaline, info)
  print(info, end="")

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)
