##
## Validate data according to a given datatype.
##
## The input is either the encoded text representation
## or the JSON representation of the decoded data.
##

import strutils, tables, strformat, json
import ../../textformats
import cli_helpers

proc validate_encoded*(specfile: string,
                           datatype: string, encoded: string): int =
  ## validate an encoded string
  let definition = get_datatype_definition(datatype)
  if encoded.is_valid(definition):
    exit_with(ec_success, &"'{encoded}' is a valid encoded '{datatype}'")
  else:
    exit_with(ec_vdn_invalid_encoded)

proc validate_decoded*(specfile: string,
                       datatype: string, decoded_json: string): int =
  ## validate decoded data (JSON)
  let definition = get_datatype_definition(datatype)
  try:
    let decoded = parse_float_or_json(decoded_json)
    if decoded.is_valid(definition):
      exit_with(ec_success, &"'{decoded_json}' is a valid decoded '{datatype}'")
    else:
      exit_with(ec_vdn_invalid_decoded)
  except JsonParsingError:
    exit_with ec_err_json_syntax

when isMainModule:
  import cligen
  dispatch_multi([validate_encoded, cmdname="encoded",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "encoded": short_encoded},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "encoded": help_encoded}],
                     [validate_decoded, cmdname="decoded",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json}])
