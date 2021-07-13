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
                 "textformats/cli/tf_test": "tf_test",
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
  for cmd in @["decode", "encode", "validate", "test", "spec"]:
    let
      infile = indir & "/tf_" & cmd & ".1.md"
      outfile = outdir & "/tf_" & cmd & ".1"
    exec("pandoc -s -t man -o " & outfile & " " & infile)
