#!/usr/bin/env python3
"""
Parse a file with one cigar string per line, without using TextParser

Usage:
  parse_cigars.py <filename> <method>

Arguments:
  <filename>  the file containing the cigars, one per line
  <method>    either "chairwise" or "findall"
"""

from docopt import docopt
import re

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
  with open(args["<filename>"]) as f:
    for line in f:
      if args["<method>"] == "charwise":
        cigar = parse_cigarstr_chairwise(line.rstrip())
      elif args["<method>"] == "findall":
        cigar = parse_cigarstr_findall(line.rstrip())
      else:
        raise RuntimeError("Method is not available")
      print(cigar)

if __name__ == "__main__":
  args = docopt(__doc__, version="0.1")
  main(args)

