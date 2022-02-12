version = "1.0.0"
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

task benchmark, &"run {N_TIMES} times the egc parser on the example":
  echo("Preparing input data")
  exec "rm -f large.egc"
  exec "touch large.egc"
  exec &"for i in {{1..910}}; do cat {INPUT} >> large.egc; done"
  for i in {1..N_TIMES}:
    echo(&"=== {i}/{N_TIMES} ===")
    echo("\nEGC encoding and decoding text\n")
    echo("\n(1) decode EGC file to JSON file")
    exec &"{TIME} ./egc2json large.egc {SPEC} > large.json"
    echo("\n(2) write EGC file from JSON data")
    exec &"{TIME} ./json2egc large.json {SPEC} > converted.egc"
    echo("\n(3) compare output EGC file to input EGC file")
    echo("")
    exec("diff -q large.egc converted.egc && echo 'No differences found.'")
    echo("")
