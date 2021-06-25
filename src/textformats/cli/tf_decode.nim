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

proc decode_string*(specfile: string, datatype: string,
                 encoded: string): int =
  ## decode an encoded string and output as JSON
  let definition = get_datatype_definition(specfile, datatype)
  try:
    echo $textformats.decode(encoded, definition)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc d_units*(specfile: string, datatype: string, infile: string): int =
  ## decode file as list_of units, defined by 'composed_of'
  let definition = get_datatype_definition(specfile, datatype)
  try:
    for decoded in textformats.decode_units(infile, definition):
      echo decoded
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc d_lines*(specfile: string, datatype: string, infile: string): int =
  ## decode file line-by-line as defined by 'composed_of'
  let definition = get_datatype_definition(specfile, datatype)
  proc echo_jsonnode(j: JsonNode) =
    echo j
  try:
    textformats.decode_file_linewise(infile, definition, echo_jsonnode)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc linewise(specfile = "", datatype: string,
              infile: string, wrapped = false, group_by = 1): int =
  ## decode file line by line (or in group of a predefined number
  ## of lines) using a given datatype
  let
    embedded = (specfile == "")
    specsrc = if embedded: infile else: specfile
  if embedded:
    fail_if_preprocessed(infile)
  let
    definition = get_datatype_definition(specsrc, datatype)
  try:
    for decoded in textformats.decoded_lines(infile, definition,
                     embedded, wrapped, group_by):
      echo decoded
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

when isMainModule:
  import cligen
  dispatch_multi(
                 [decode_string, cmdname = "string",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "encoded":  short_encoded},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "encoded":  help_encoded}],
                 [linewise,
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "infile":  help_infile}],
                 [d_units, cmdname = "units",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "infile":  help_infile}],
                 [d_lines, cmdname = "lines",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "infile":  help_infile}])
