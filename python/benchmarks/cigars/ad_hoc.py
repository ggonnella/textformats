#!/usr/bin/env python3
"""
Computes some stats on each line of a file containing CIGAR strings
This version is implemented without using TextFormats

Usage:
  ad_hoc.py <inputfn>

Arguments:
  <inputfn>  the file containing the cigars, one per line
"""

from docopt import docopt
import re
from opstats import OpStats, compute_stats, print_all_opstats

oplenset = set(["M", "I", "D"])

def parse_cigarstr_chairwise(cigarstr):
  oplen = []
  cigar = []
  for c in cigarstr:
    if c.isdigit():
      oplen.append(c)
    else:
      if c not in oplenset:
        raise RuntimeError("unknown operation")
      oplen = int("".join(oplen))
      if oplen == 0:
        raise RuntimeError("Wrong operation length")
      cigar.append({"code": c, "length": oplen})
      oplen = []
  if len(cigar) == 0:
    raise RuntimeError("Wrong number of cigar operations")
  return cigar

def parse_cigarstr_findall(cigarstr):
  cigar = []
  expected_start = 0
  for m in re.finditer(r'(?P<length>\d+)(?P<code>[MID])', cigarstr):
    if m.start() > expected_start:
      raise RuntimeError("Something is between elements")
    expected_start = m.end()+1
    oplen = int(m.group("length"))
    if oplen == 0:
      raise RuntimeError("Wrong operation length")
    cigar.append({"code": m.group("code"), "length": oplen})
  if len(cigar) == 0:
    raise RuntimeError("Wrong number of cigar operations")
  return cigar

def main(args):
  with open(args["<inputfn>"]) as f:
    for line in f:
      cigar = parse_cigarstr_chairwise(line.rstrip())
      opstats = compute_stats(cigar)
      print_all_opstats(opstats)

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)

