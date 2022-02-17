version = "1.2.2"
author = "Giorgio Gonnella"
description = "Use textformats or hts-nim for computing and printing " &
              "some statistics about a SAM file"
bin = @["htslib_based", "textformats_based"]
license = "CC-BY-SA"
requires "hts", "textformats == 1.2.2"

import strformat, strutils

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
  INPUTDIR = &"{PRJDIR}/benchmarks/data/sam"
  INPUT = [&"{INPUTDIR}/100000.lines.sam",
           &"{INPUTDIR}/500000.lines.sam",
           &"{INPUTDIR}/1000000.lines.sam"]
  LD = &"{HTSLIBDIR}/lib:{DEFLATEDIR}/lib"
  SPEC = &"{PRJDIR}/spec/sam.yaml"
  DT = "file"
  TIME = "time"
  N_TIMES = 3

task show_htslib_based_cmd, "show command executed by run_htslib_based task":
  echo(&"time env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT[0]}")

task run_htslib_based, "run benchmark using htslib":
  echo("### Running benchmark ###")
  echo(&"# Input file:    {INPUT[0]}")
  echo("# Program:       htslib_based")
  exec &"{TIME} env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT[0]}"

task show_textformats_based_cmd,
    "show command executed by run_textformats_based task":
  echo(&"{TIME} ./textformats_based {INPUT[0]} {SPEC} {DT}")

task run_textformats_based, "run benchmark using textformats":
  echo("### Running benchmark ###")
  echo(&"# Input file:    {INPUT[0]}")
  echo("# Program:       textformats_based")
  echo("# Parameters:")
  echo(&"#   Specification: {SPEC}")
  echo(&"#   Datatype:      {DT}")
  exec &"{TIME} ./textformats_based {INPUT[0]} {SPEC} {DT}"

task compare, "compare results and execution time":
  echo(&"Input file: {INPUT[0]}")
  echo("")
  echo("Running htslib_based:")
  exec &"{TIME} env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT[0]} > htslib_based.out"
  echo("")
  echo("Running textformats_based:")
  exec &"{TIME} ./textformats_based {INPUT[0]} {SPEC} {DT} > textformats_based.out"
  exec &"diff textformats_based.out htslib_based.out"
  echo("The two versions of the program produced the same output")

task compare_full, &"compare {N_TIMES} times and also with 10X larger file":
  for i in 0 ..< len(INPUT):
    echo("=".repeat(50))
    echo("")
    echo(&"Input file {i+1}: {INPUT[i]}")
    echo("")
    echo("Running htslib_based:")
    echo("")
    for j in {1..N_TIMES}:
      echo(&"=== {j}/{N_TIMES} ===")
      exec &"{TIME} env LD_LIBRARY_PATH={LD} ./htslib_based {INPUT[i]} > htslib_based.out"
      echo("")
    echo("")
    echo("Running textformats_based:")
    echo("")
    for j in {1..N_TIMES}:
      echo(&"=== {j}/{N_TIMES} ===")
      exec &"{TIME} ./textformats_based {INPUT[i]} {SPEC} {DT} > textformats_based.out"
      echo("")
    echo("")
    exec &"diff textformats_based.out htslib_based.out"
    echo("The two versions of the program produced the same output")
    echo("")

