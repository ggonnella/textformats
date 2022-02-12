#!/usr/bin/env python3
"""
Show non-standard-compliant lines of the supposedly GFA1 file

Usage: ./gfa1_show_invalid_lines.py [options] <inputfile> <gfa1spec>

Arguments:
  <inputfile>  Input file in the corrupted GFA1 format
  <gfa1spec>   Specification file describing the GFA1 format

Options:
  --show-errors, -e  Show details of parsing errors for each invalid line
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
    except DecodingError as e:
      if args["--show-errors"]:
        print(e)
      else:
        print(f"Invalid: '{line}'")
