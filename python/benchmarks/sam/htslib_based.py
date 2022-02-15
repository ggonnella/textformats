#!/usr/bin/env python3
"""
Usage: htslib_based.py <sam>

Arguments:
  <sam>        SAM file
"""
from docopt import docopt
import pysam
from counts import Counts

def process_sam(input_file, c):
  sam = pysam.AlignmentFile(input_file)
  for sq in sam.header.references:
    c.init_sq(sq)
  hdr = sam.header.to_dict()
  for rg in hdr["RG"]:
    c.init_rg(rg["ID"], rg["SM"])
  for aln in sam:
    c.count_flag(aln.flag)
    c.count_sq(sam.header.references[aln.rname])
    for (tagname, tagvalue) in aln.tags:
      c.count_tag(tagname)
      if tagname == "RG":
        c.count_rg("Z", tagvalue)

if __name__ == "__main__":
  arguments = docopt(__doc__)
  input_file = arguments["<sam>"]
  c = Counts()
  process_sam(input_file, c)
  c.print()
