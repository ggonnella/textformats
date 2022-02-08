#!/usr/bin/env python3
"""
Parse EGC data from JSON and output its content as the here-defined EGC format

Usage: ./json2egc_ad_hoc.py <inputfile>

Arguments:
  <inputfile>  Input file in Json format
"""
from egc_ad_hoc import EGCParser
from docopt import docopt
import json

args = docopt(__doc__)
parser = EGCParser()
with open(args["<inputfile>"]) as f:
  data = json.load(f)
for line in data:
  print(parser.encode(line))
