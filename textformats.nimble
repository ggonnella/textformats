# Package

version       = "1.2.3"
author        = "Giorgio Gonnella"
description   = "Easy specification of text formats for structured data"
license       = "ISC"
srcDir        = "src"
binDir        = "cli"
backend       = "c"
namedBin      = {"textformats/cli/tf_decode": "tf_decode",
                 "textformats/cli/tf_encode": "tf_encode",
                 "textformats/cli/tf_validate": "tf_validate",
                 "textformats/cli/tf_spec": "tf_spec"}.to_table
installExt    = @["nim"] # required for hybrid packages

# Dependencies

requires "nim >= 1.6.0",
         "cligen == 1.5.19",
         "yaml == 0.16.0",
         "regex == 0.19.0",
         "nimpy == 0.2.0",
         "msgpack4nim == 0.3.1"

# Tasks

import os

proc md2pdf(infile: string) =
  let
    outfile = changeFileExt(infile, "pdf")
    capture_title = "grep -P -o '(?<=^# ).*' " & infile & "| head -n 1"
    (title, errcode1) = gorgeEx(capture_title)
    (today, errcode2) = gorgeEx("date +%D")
  var hdr: string
  hdr =  "% " & title & "\n"
  hdr &= "% " & author & "\n"
  hdr &=  "% Version " & version & " - " & today & "\n"
  hdr &= "\\pagebreak\n"
  exec("echo " & quoteshell(hdr) & "| pandoc --toc - " &
       infile & " -o " & outfile)
  echo "    created manual " & outfile

task climan, "compile the man pages of the CLI tools":
  let
    indir = "src/textformats/cli"
    outdir = "cli/man"
  mkDir(outdir)
  for cmd in @["decode", "encode", "validate", "spec"]:
    let
      infile = indir & "/tf_" & cmd & ".1.md"
      outfile = outdir & "/tf_" & cmd & ".1"
    exec("pandoc -s -t man -o " & outfile & " " & infile)
task clitest, "test CLI tools":
  exec("cli/tests/test_cli.sh")
task pymake, "make python API package":
  exec("cd python && make")
task pytest, "test python API package":
  exec("cd python && make test")
task ctest, "test C API package":
  exec("cd C/tests && make cleanup && make")
task alltests, "run unit, Nim/C/Python API and CLI tests":
  exec("nimble test")
  exec("nimble clitest")
  exec("nimble pytest")
  exec("nimble ctest")
task manuals, "create PDF manuals using pandoc":
  let (tmpout, haspandoc) = gorgeEx("which pandoc")
  if (haspandoc == 0):
    for manual in walkDir("manuals"):
      let infile = manual.path
      if infile.endswith(".md"):
        md2pdf(infile)
    md2pdf("README.md")
  else:
    echo "  ERROR: This task requires pandoc\n" &
         "    (pandoc must be installed and the pandoc binary must be in PATH)"
