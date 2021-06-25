##
## Encode data according to a given datatype from a specification
##
## The input data is provided as JSON representation of the
## decoded data.
##
## The output is the encoded textual representation, according
## to the specification.
##

import strutils, json, tables
import ../../textformats
import cli_helpers

proc encode_json*(specfile: string, datatype: string, decoded_json: string):
                  int =
  ## encode decoded data (JSON) and output as encoded string
  let definition = get_datatype_definition(specfile, datatype)
  try:
    let decoded = parse_float_or_json(decoded_json)
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
