# Package

version       = "1.0.0"
author        = "Giorgio Gonnella"
description   = "Easy specification of textual formats for structured data"
license       = "ISC"
srcDir        = "src"
binDir        = "cli"
namedBin      = {"textformats/cli/tf_decode": "tf_decode",
                 "textformats/cli/tf_encode": "tf_encode",
                 "textformats/cli/tf_validate": "tf_validate",
                 "textformats/cli/tf_spec": "tf_spec"}.to_table
installExt    = @["nim"] # required for hybrid packages

# Dependencies

requires "nim >= 1.0.2",
         "cligen >= 1.5.5",
         "yaml >= 0.14",
         "regex >= 0.15",
         "nimpy"

# Tasks

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
  exec("cd C/tests && make")
task alltests, "run unit, Nim/C/Python API and CLI tests":
  exec("nimble test")
  exec("nimble clitest")
  exec("nimble pytest")
  exec("nimble ctest")
