version = "1.0.0"
author = "Giorgio Gonnella"
description = "Use textformats or hts-nim for computing and printing " &
              "some statistics about a SAM file"
bin = @["htslib_based", "textformats_based"]
license = "CC-BY-SA"
requires "hts", "textformats"

import strformat

const
  HTSLIBDIR = &"/usr/local/anaconda3/pkgs/htslib-1.13-hc38c3fb_0"
  DEFLATEDIR = "/usr/local/anaconda3/pkgs/libdeflate-1.7-h35c211d_5"

const
  PRJDIR = "../.."
  INPUT = &"{PRJDIR}/benchmarks/data/sam/100000.lines.sam"
  LD = &"{HTSLIBDIR}/lib:{DEFLATEDIR}/lib"
  SPEC = &"{PRJDIR}/bio/spec/sam.yaml"
  DT = "file"

task run_htslib_based, "run benchmark using htslib":
  echo("### Running benchmark ###")
  echo(&"# Input file:    {INPUT}")
  echo("# Program:       htslib_based")
  exec &"time env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT}"

task run_textformats_based, "run benchmark using textformats":
  echo("### Running benchmark ###")
  echo(&"# Input file:    {INPUT}")
  echo("# Program:       textformats_based")
  echo("# Parameters:")
  echo(&"#   Specification: {SPEC}")
  echo(&"#   Datatype:      {DT}")
  exec &"time ./textformats_based {INPUT} {SPEC} {DT}"

task compare, "compare results and execution time":
  echo(&"Input file: {INPUT}")
  echo("")
  echo("Running textformats_based:")
  exec &"time ./textformats_based {INPUT} {SPEC} {DT} > textformats_based.out"
  echo("")
  echo("Running htslib_based:")
  exec &"time env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT} > htslib_based.out"
  exec &"diff textformats_based.out htslib_based.out"
  echo("The two versions of the program produced the same output")

