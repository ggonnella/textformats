#!/usr/bin/env python3
"""
Parse the here-defined EGC format and output its content as JSON

Usage: ./egc2json.py <inputfile> <inputspec>

Arguments:
  <inputfile>  Input file in EGC format
  <inputspec>  Specification file describing the EGC format
"""
from textformats import Specification
from docopt import docopt

args = docopt(__doc__)
Specification(args["<inputspec>"])["file"].\
    decode_file(args["<inputfile>"], to_json = True)
