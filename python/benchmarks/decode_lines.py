#!/usr/bin/env python3
"""
Decode all lines of a file using TextFormats

Usage:
  decode_lines.py <specfn> <datatype> <encodedfn> <operation>

Arguments:
  <specfn>       filename of YAML textformats specification
  <datatype>     datatype to use
  <encodedfn>    filename of encoded strings, one per line
  <operation>    one of: decode, to_json
"""

from docopt import docopt
import textformats as tf
import json

def main(args):
  spec = tf.Specification(args["<specfn>"])
  dd = spec[args["<datatype>"]]
  if (args["<operation>"] == "to_json"):
    for decoded in dd.decoded_file(args["<encodedfn>"], to_json=True):
      print(json.loads(decoded))
  else:
    for decoded in dd.decoded_file(args["<encodedfn>"]):
      print(decoded)

if __name__ == "__main__":
  args = docopt(__doc__, version="0.1")
  main(args)

