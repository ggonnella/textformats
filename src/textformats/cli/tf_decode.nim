##
## Decode a textual representation to the corresponding data,
## according to a given datatype from a specification
##
## The input is the textual representation, either as a string
## or as a file in a given format
##
## The output is the decoded data, represented as JSON.
##

import tables, strutils, json
import ../../textformats
import cli_helpers

proc decode_string*(specfile: string, datatype = "default",
                 encoded: string): int =
  ## decode an encoded string and output as JSON
  let definition = get_datatype_definition(specfile, datatype)
  try:
    echo $textformats.decode(encoded, definition)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc decode_datafile*(specfile = "", datatype = "default", infile: string,
                  scope = "auto", linewise = false,
                  wrapped = false, unitsize = 1): int =
  ## decode a file, given a datatype definition
  let
    embedded = (specfile == "")
    specsrc = block:
      if embedded:
        fail_if_preprocessed(infile)
        infile
      else:
        specfile
    definition = get_datatype_definition(specsrc, datatype)
  try:
    decode_file(infile, definition, embedded, scope, linewise, wrapped,
                unitsize)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

when isMainModule:
  import cligen
  dispatch_multi([decode_string, cmdname = "string",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "encoded":  short_encoded},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "encoded":  help_encoded}],
                 [decode_datafile, cmdname = "file",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "infile":  short_infile,
                           "scope": short_scope,
                           "linewise": short_linewise,
                           "wrapped": short_wrapped,
                           "unitsize": short_unitsize},
                  help = {"specfile": help_specfile_or_embedded,
                          "datatype": help_datatype,
                          "infile":  help_infile,
                          "scope": help_scope,
                          "linewise": help_linewise,
                          "wrapped": help_wrapped,
                          "unitsize": help_unitsize}])
