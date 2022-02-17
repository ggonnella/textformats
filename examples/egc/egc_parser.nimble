version = "1.2.2"
author = "Giorgio Gonnella"
description = "Use TextFormats for parsing the ECG format"
bin = @["egc2json", "json2egc"]
license = "CC-BY-SA"
requires "textformats"

import strformat, strutils

const
  PRJDIR = "../.."
  DATADIR = &"{PRJDIR}/python/examples/egc"
  INPUT = &"{DATADIR}/example.egc"
  SPEC = &"{DATADIR}/egc.yaml"
  N_TIMES = 3
  TIME = "time"

task setup, &"prepare the binaries and the test files":
  echo("Compiling the binaries")
  exec "nimble build"
  echo("")
  echo("Preparing input data")
  exec "rm -f large.egc"
  exec "touch large.egc"
  exec &"for i in {{1..18200}}; do cat {INPUT} >> large.egc; done"
  exec "head -n 100000 large.egc > 100000.lines.egc"
  exec "head -n 500000 large.egc > 500000.lines.egc"
  exec "head -n 1000000 large.egc > 1000000.lines.egc"
  echo("")

task benchmark, &"run {N_TIMES} times the egc parser on the test files":
  for i in {1..N_TIMES}:
    for j in ["100000", "500000", "1000000"]:
      echo(&"=== {i}/{N_TIMES} ===")
      echo(&"\nEGC test: {j} lines\n")
      echo("\n(1) decode EGC file to JSON file")
      exec &"{TIME} ./egc2json {j}.lines.egc {SPEC} > {j}.json"
      echo("\n(2) write EGC file from JSON data")
      exec &"{TIME} ./json2egc {j}.json {SPEC} > {j}.out.egc"
      echo("")
      if i == 1:
        echo("\n(3) compare output EGC file to input EGC file")
        exec(&"diff -q {j}.lines.egc {j}.out.egc && " &
             "echo 'No differences found.'")
        echo("")

task clean, &"remove all generated files except the binaries":
  exec "rm -f large.egc *.lines.egc *.json *.out.egc"

task cleanup, &"like clean, but remove also binaries":
  exec "nimble clean"
  exec "rm -f json2egc egc2json"
