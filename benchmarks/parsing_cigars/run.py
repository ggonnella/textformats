#!/usr/bin/env python3
import nimporter
import parse_cigars_lib as pcl
import sys
import os

if len(sys.argv) != 2:
  sys.stderr.write("Missing argument: number of cigars\n")
  sys.stderr.write("accepted values are:\n")
  sys.stderr.write("- 10k\n")
  sys.stderr.write("- 100k\n")
  sys.stderr.write("- 1_million\n")
  sys.stderr.write("Anything else will lead to an error\n")
  exit(1)

cdir="../../bio/benchmarks/cigars/"
spec=cdir+"/cigar.datatypes.yaml"
dt="cigar"
infile=cdir+"/"+sys.argv[1]+"_cigars_len100"

if not os.path.exists(infile):
  sys.stderr.write(f"File {infile} does not exist\n")
  sys.stderr.write(f"Invalid argument value {sys.argv[1]}\n")
  sys.stderr.write("accepted values are:\n")
  sys.stderr.write("- 10k\n")
  sys.stderr.write("- 100k\n")
  sys.stderr.write("- 1_million\n")
  exit(1)

sys.stderr.write("## Running parse_cigars_lib.decode: \n")
sys.stderr.write("# Parameters:\n")
sys.stderr.write(f"#   Specification: {spec}\n")
sys.stderr.write(f"#   Datatype:      {dt}\n")
sys.stderr.write(f"#   Input file:    {infile}\n")
sys.stderr.write("# ... parsing cigars ...\n")
pcl.run_decode(spec, dt, infile)
