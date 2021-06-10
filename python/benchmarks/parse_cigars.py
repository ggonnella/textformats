#!/usr/bin/env python3
"""
Parse all cigars in file using a Python-based simple parser

Usage:
  parse_cigars_python.py [-s] <filename> <method>

Options:
  -s, --show  print the cigars (default: parse, but do not show the result)

Arguments:
  <filename>  the file containing the cigars, one per line
  <method>    either "python" or "textformats"
"""

from docopt import docopt
import re

oplenset = set(["M", "I", "D"])

def parse_cigar(cigarstr):
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

def parse_cigar_findall(cigarstr):
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
  if "textformats" in args["<method>"]:
    specfname = "../../bio/benchmarks/cigars/cigar.datatypes.yaml"
    import textformats as st
    spec = st.Specification(specfname)
    cigardef = spec["cigar"]
  show = args["--show"]
  with open(args["<filename>"]) as f:
    for line in f:
      if args["<method>"] == "textformats":
        cigar = cigardef.to_json(line.rstrip())
      elif args["<method>"] == "textformats-decode":
        cigar = cigardef.decode(line.rstrip())
      elif args["<method>"] == "charwise":
        cigar = parse_cigar(line.rstrip())
      elif args["<method>"] == "python":
        cigar = parse_cigar_findall(line.rstrip())
      else:
        raise RuntimeError("Method is not available")
      if show:
        print(cigar)

if __name__ == "__main__":
  args = docopt(__doc__, version="0.1")
  main(args)

