#!/usr/bin/env python3
"""
Computes some stats on each line of a file containing CIGAR strings
This version is implemented using TextFormats

Usage:
  textformats_based.py <inputfn> <specfn> <datatype>

Arguments:
  <inputfn>      filename of encoded strings, one per line
  <specfn>       filename of YAML textformats specification
  <datatype>     datatype to use
"""

from docopt import docopt
import textformats as tf
from opstats import OpStats, compute_stats, print_all_opstats

def process_cigar(cigar, data):
  print_all_opstats(compute_stats(cigar))

def main(args):
  spec = tf.Specification(args["<specfn>"])
  dd = spec[args["<datatype>"]]
  dd.decode_file(args["<inputfn>"], False, process_cigar, None,
                 tf.DECODED_PROCESSOR_LEVEL.WHOLE, False)

if __name__ == "__main__":
  args = docopt(__doc__, version="0.1")
  main(args)

