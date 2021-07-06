##
## Encode data according to a given datatype from a specification
##
## The input data is provided as JSON representation of the
## decoded data.
##
## The output is the encoded textual representation, according
## to the specification.
##

import strutils, json, tables, terminal
import ../../textformats
import cli_helpers

proc encode_json*(specfile: string, datatype = "default", decoded_json = ""):
                  int =
  ## encode decoded data (JSON) and output as encoded string
  let
    definition = get_datatype_definition(specfile, datatype)
    to_encode = str_or_stdin(decoded_json)
  try:
    let decoded = parse_float_or_json(to_encode)
    try:
      echo encode(decoded, definition)
    except EncodingError:
      exit_with(ec_err_invalid_decoded, getCurrentExceptionMsg())
  except JsonParsingError:
    exit_with ec_err_json_syntax

when isMainModule:
  import cligen
  dispatch_multi([encode_json, cmdname = "json",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "decoded_json": short_decoded},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "decoded_json": help_decoded_json}])
