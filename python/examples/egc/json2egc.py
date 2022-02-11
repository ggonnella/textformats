#!/usr/bin/env python3
"""
Parse EGC data from JSON and output its content as the here-defined EGC format

Usage: ./json2egc.py <inputfile> <inputspec>

Arguments:
  <inputfile>  Input file in Json format
  <inputspec>  Specification file describing the EGC format
"""
from textformats import Specification
from docopt import docopt
import json

args = docopt(__doc__)
with open(args["<inputfile>"]) as f:
  print(Specification(args["<inputspec>"])["file"].encode(f.read(),
    from_json=True))
