##
## Validate data according to a given datatype.
##
## The input is either the encoded text representation
## or the JSON representation of the decoded data.
##

import strutils, tables, strformat, json, terminal
import ../../textformats
import cli_helpers

proc validate_encoded*(specfile: string, datatype = "default",
                       encoded = ""): int =
  ## validate an encoded string
  let
    to_validate = str_or_stdin(encoded)
    definition = get_datatype_definition(specfile, datatype)
  if to_validate.is_valid(definition):
    exit_with(ec_success, &"'{to_validate}' is a valid encoded '{datatype}'")
  else:
    exit_with(ec_vdn_invalid_encoded)

proc validate_decoded*(specfile: string,
                       datatype = "default", decoded_json = ""): int =
  ## validate decoded data (JSON)
  let
    to_validate = str_or_stdin(decoded_json)
    definition = get_datatype_definition(specfile, datatype)
  try:
    let decoded = parse_float_or_json(to_validate)
    if decoded.is_valid(definition):
      exit_with(ec_success, &"'{to_validate}' is a valid decoded '{datatype}'")
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
