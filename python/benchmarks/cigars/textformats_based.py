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
from textformats import Specification
from opstats import OpStats, compute_stats, print_all_opstats

def process_cigar(cigar, empty):
  print_all_opstats(compute_stats(cigar))

def main(args):
  spec = Specification(args["<specfn>"])
  dd = spec[args["<datatype>"]]
  dd.decode_file(args["<inputfn>"], process_cigar)

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)

