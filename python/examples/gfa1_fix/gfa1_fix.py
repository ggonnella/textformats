#!/usr/bin/env python3
"""
This file implements an example application of TextFormats:
fixing a wrongly formatted GFA1 output by Bandage.

Usage: ./gfa1_fix.py <inputfile> <gfa1spec> <inputspec>

Arguments:
  <inputfile>  Input file in the invalid GFA1 format
  <gfa1spec>   Specification file describing the GFA1 format
  <inputspec>  Specification file describing the invalid GFA1 format
"""
from textformats import Specification, DECODED_PROCESSOR_LEVEL
from docopt import docopt

def process_gfaline(gfaline, gfa1spec):
  # (1) fix empty sequences (instead of "*")
  #    nothing to do for segments, since the inputspec maps the empty
  #    sequences to None, which is encoded to "*" by gfa1spec
  #
  # (2) fix tags with type 'z'
  if gfaline.get("tags"):
    for tagname in gfaline["tags"].keys():
      if gfaline["tags"][tagname]["type"] == 'z':
        gfaline["tags"][tagname]["type"] = 'Z'
  #
  print(gfa1spec["line"].encode(gfaline))

args = docopt(__doc__)
# parse specifications
inputspec = Specification(args["<inputspec>"])
gfa1spec = Specification(args["<gfa1spec>"])

# output a header with version tag (not required, but nice)
header = {"line_type":"header",
          "tags":{"VN":{"type":"Z","value":"1.0"}}}
print(gfa1spec["header"].encode(header))

# fix lines of invalid format
inputspec["gfa1::line"].decode_file(args["<inputfile>"],
    process_gfaline, gfa1spec, DECODED_PROCESSOR_LEVEL.LINE)
