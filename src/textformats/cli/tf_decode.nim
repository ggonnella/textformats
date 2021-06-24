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
from ../../textformats import recognize_and_decode_lines
from ../../textformats import nil
import cli_helpers

proc decode_string*(specfile: string, preprocessed=false, datatype: string,
                 encoded: string): int =
  ## decode an encoded string and output as JSON
  let definition = get_datatype_definition(datatype, preprocessed)
  try:
    echo $textformats.decode(encoded, definition)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc linetypes*(specfile: string, preprocessed=false,
                                    datatype: string, infile: string): int =
  ## recognize the line type and decode each line of a file
  let definition = get_datatype_definition(datatype, preprocessed)
  try:
    for decoded in infile.recognize_and_decode_lines(definition):
      echo decoded
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc decode_units*(specfile: string, preprocessed=false,
                  datatype: string, infile: string): int =
  ## decode file as list_of units, defined by 'composed_of'
  let definition = get_datatype_definition(datatype, preprocessed)
  try:
    for decoded in textformats.decode_units(infile, definition):
      echo decoded
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc decode_lines*(specfile: string, preprocessed=false,
                   datatype: string, infile: string): int =
  ## decode file line-by-line as defined by 'composed_of'
  let definition = get_datatype_definition(datatype, preprocessed)
  proc echo_jsonnode(j: JsonNode) =
    echo j
  try:
    textformats.decode_file_linewise(infile, definition, echo_jsonnode)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc decode_embedded(specfile: string, datatype: string): int =
  ## decode lines of embedded data under a specification
  let definition = get_datatype_definition(datatype, false)
  try:
    for decoded in textformats.decode_embedded(specfile, definition):
      echo decoded
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

when isMainModule:
  import cligen
  dispatch_multi(
                 [decode_string, cmdname = "string",
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "encoded":  short_encoded},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "encoded":  help_encoded}],
                 [linetypes,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "infile":  help_infile}],
                 [decode_embedded, cmdname = "embedded",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype}],
                 [decode_units, cmdname = "units",
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "infile":  help_infile}],
                 [decode_lines, cmdname = "lines",
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "infile":  help_infile}])
