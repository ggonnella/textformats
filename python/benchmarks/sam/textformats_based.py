#!/usr/bin/env python3
"""
Usage: textformats_based.py <sam> <spec> <datatype>

Arguments:
  <sam>        SAM file
  <spec>       textformats specification
  <datatype>   datatype to use
"""
from docopt import docopt
from textformats import Specification
from counts import Counts

def process_decoded(decoded, c):
  for key, value in decoded.items():
    if key == "header.@SQ":
      c.init_sq(value["SN"][0])
    elif key == "header.@RG":
      c.init_rg(value["ID"][0], value["SM"][0])
    elif key[:10] == "alignments":
      c.count_flag(value["flag"])
      c.count_sq(value["rname"])
      for tagname, tag in value["tags"].items():
        c.count_tag(tagname)
        if tagname == "RG":
          c.count_rg(tag["type"], tag["value"])

DECODED_PROCESSOR_LEVEL_LINE = 2

if __name__ == "__main__":
  arguments = docopt(__doc__, version="1.0.0")
  input_file = arguments["<sam>"]
  spec = Specification(arguments["<spec>"])
  ddef = spec[arguments["<datatype>"]]
  c = Counts()
  ddef.decode_file(input_file, False, process_decoded, c,
      DECODED_PROCESSOR_LEVEL_LINE, False)
  c.print()
