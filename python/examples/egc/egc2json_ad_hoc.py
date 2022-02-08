#!/usr/bin/env python3
"""
Parse the here-defined EGC format and output its content as JSON

Usage: ./egc2json_ad_hoc.py <inputfile>

Arguments:
  <inputfile>  Input file in EGC format
"""
from egc_ad_hoc import EGCParser
from docopt import docopt
import json

args = docopt(__doc__)
parser = EGCParser()
output = []
with open(args["<inputfile>"]) as f:
  for line in f:
    output.append(parser.decode(line))
print(json.dumps(output))
