version = "1.0.0"
author = "Giorgio Gonnella"
description = "Use textformats or hts-nim for computing and printing " &
              "some statistics about a SAM file"
bin = @["htslib_based", "textformats_based"]
license = "CC-BY-SA"
#backend = "cpp"
requires "hts", "textformats"

import strformat

const
  # the following were used on Linux
  CONDADIRLINUX = "/home/gonnella/tools/miniconda/3"
  HTSLIBDIRLINUX = &"{CONDADIRLINUX}/pkgs/htslib-1.13-h9093b5e_0"
  DEFLATEDIRLINUX = &"{CONDADIRLINUX}/pkgs/libdeflate-1.7-h7f98852_5"
  # the following were used on MacOS
  CONDADIRMAC = "/usr/local/anaconda3"
  HTSLIBDIRMAC = &"{CONDADIRMAC}/pkgs/htslib-1.13-hc38c3fb_0"
  DEFLATEDIRMAC = &"{CONDADIRMAC}/pkgs/libdeflate-1.7-h35c211d_5"
  # =====> input here the directories <======
  HTSLIBDIR = HTSLIBDIRLINUX
  DEFLATEDIR = DEFLATEDIRLINUX

const
  PRJDIR = "../.."
  INPUT = &"{PRJDIR}/benchmarks/data/sam/100000.lines.sam"
  LD = &"{HTSLIBDIR}/lib:{DEFLATEDIR}/lib"
  SPEC = &"{PRJDIR}/spec/sam.yaml"
  DT = "file"

task show_htslib_based_cmd, "show command executed by run_htslib_based task":
  echo(&"time env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT}")

task run_htslib_based, "run benchmark using htslib":
  echo("### Running benchmark ###")
  echo(&"# Input file:    {INPUT}")
  echo("# Program:       htslib_based")
  exec &"time env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT}"

task show_textformats_based_cmd,
    "show command executed by run_textformats_based task":
  echo(&"time ./textformats_based {INPUT} {SPEC} {DT}")

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
  echo("Running htslib_based:")
  exec &"/usr/bin/time env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT} > htslib_based.out"
  echo("")
  echo("Running textformats_based:")
  exec &"/usr/bin/time ./textformats_based {INPUT} {SPEC} {DT} > textformats_based.out"
  exec &"diff textformats_based.out htslib_based.out"
  echo("The two versions of the program produced the same output")

