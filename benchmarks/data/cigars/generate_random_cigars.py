#!/usr/bin/env python3
"""
Generate random cigar strings.

Usage:
  generate_random_cigars.py [-q] <ncigars> <avgnops>

Arguments:
  <ncigars>: how many cigar strings shall be used
  <avgnops>: how many operations shall a cigar string contain in average

Options:
  -h, --help    show this help message
  --version     show version number
"""

from docopt import docopt
from random import randint
import importlib

tqdm_spec = importlib.util.find_spec("tqdm")
has_tqdm = tqdm_spec is not None
if has_tqdm:
  from tqdm import tqdm
else:
  def tqdm(it):
    for x in it:
      yield x

maxoplen = 1024
opcodes = ["M", "I", "D"]

def generate_cigar(cigarlen):
  cigar = []
  while cigarlen > 0:
    cigarlen -= 1
    cigar.append(str(randint(1, maxoplen)))
    cigar.append(opcodes[randint(0, len(opcodes)-1)])
  return "".join(cigar)

def main(args):
  ncigars = int(args["<ncigars>"])
  avgnops = int(args["<avgnops>"])
  avail_ops = ncigars * avgnops
  cigars = []
  left = ncigars
  for cigarnum in tqdm(range(ncigars)):
    avgnops = int(avail_ops/left)
    if avgnops < 1: avgnops = 1
    if left == 1:
      cigarlen = avail_ops
    else:
      cigarlen = int(avgnops/2) + randint(1, avgnops)
    cigar = generate_cigar(cigarlen)
    print(cigar)
    avail_ops -= cigarlen
    left -= 1

if __name__ == "__main__":
  args = docopt(__doc__, version="0.1")
  main(args)


