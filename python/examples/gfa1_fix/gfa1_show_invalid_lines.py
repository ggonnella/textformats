#!/usr/bin/env python3
"""
Show non-standard-compliant lines of the supposedly GFA1 file

Usage: ./gfa1_show_invalid_lines.py <inputfile> <gfa1spec>

Arguments:
  <inputfile>  Input file in the corrupted GFA1 format
  <gfa1spec>   Specification file describing the GFA1 format
"""
from textformats import Specification
from textformats.error import DecodingError
from docopt import docopt

args = docopt(__doc__)
gfa1spec = Specification(args["<gfa1spec>"])
with open(args["<inputfile>"]) as f:
  for line in f:
    line = line.rstrip()
    try:
      gfa1spec["line"].decode(line)
    except DecodingError:
      print(f"Invalid: '{line}'")
