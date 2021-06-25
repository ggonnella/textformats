##
## Command line tool to test if the results of encoding, decoding and validation
## using a given datatype fulfill the expectations.
##

import strutils, tables, strformat, json, streams
import ../../textformats
import cli_helpers

proc test_encoded_validation*(specfile: string,
                            datatype: string, encoded: string,
                            expected_valid=false): int =
  ## test the validation of an encoded string
  let definition = get_datatype_definition(datatype)
  if encoded.is_valid(definition):
    if expected_valid:
      exit_with(ec_success, ok_pfx &
                &"'{encoded}' => valid as encoded {datatype}")
    else:
      exit_with(ec_test_unexp_valid_encoded)
  else:
    if expected_valid:
      exit_with(ec_test_invalid_encoded)
    else:
      exit_with(ec_success, ok_pfx &
                &"'{encoded}' => invalid as encoded {datatype}")

proc test_decoded_validation*(specfile: string,
                            datatype: string, decoded_json: string,
                            expected_valid=false): int =
  ## test the validation of decoded data (JSON)
  let definition = get_datatype_definition(datatype)
  try:
    let decoded = parse_float_or_json(decoded_json)
    if decoded.is_valid(definition):
      if expected_valid:
        exit_with(ec_success, ok_pfx &
          &"'{decoded_json}' => valid as decoded {datatype}")
      else:
        let
          info = &"Provided data (JSON): '{decoded_json}'\n" &
                 &"Datatype name:        '{datatype}'\n" &
                 &"Datatype definition:  {definition}"
        exit_with(ec_test_unexp_valid_decoded, info)
    else:
      if expected_valid:
        exit_with(ec_test_invalid_decoded)
      else:
        exit_with(ec_success, ok_pfx &
            &"'{decoded_json}' => invalid as decoded {datatype}")
  except JsonParsingError:
    exit_with ec_err_json_syntax

proc test_fail_encoding*(specfile: string,
                         datatype: string, decoded_json: string): int =
  ## test that encoding the provided decoded data (JSON) fails
  let definition = get_datatype_definition(datatype)
  try:
    let decoded = parse_float_or_json(decoded_json)
    try:
      let
        encoded = textformats.encode(decoded, definition)
        info = &"Provided data (JSON): '{decoded_json}'\n" &
               &"Datatype name:        '{datatype}'\n" &
               &"Datatype definition:  {definition}\n" &
               &"Encoded data:         '{encoded}'"
      exit_with(ec_test_unexp_valid_decoded, info)
    except textformats.EncodingError:
      exit_with(ec_success, ok_pfx &
                &"'{decoded_json}' => encoding as {datatype} fails")
  except JsonParsingError:
    exit_with ec_err_json_syntax

proc test_encoding*(specfile: string, datatype: string,
                    decoded_json: string, expected: string): int =
  ## encode the decoded data (JSON) and compare to the expected encoding
  let definition = get_datatype_definition(datatype)
  try:
    let decoded = parse_float_or_json(decoded_json)
    try:
      let encoded = textformats.encode(decoded, definition)
      if encoded != expected:
        let info = &"Provided data (JSON): '{decoded_json}'\n" &
                   &"Datatype name:        '{datatype}'\n" &
                   &"Datatype definition:  {definition}\n" &
                   &"Encoded data:         '{encoded}'\n" &
                   &"Expected encoded:     '{expected}'"
        exit_with(ec_test_unexp_encoding_result, info)
      else:
        exit_with(ec_success, ok_pfx &
          &"'{decoded_json}' => encoded as {datatype}: '{encoded}'")
    except textformats.EncodingError:
      exit_with(ec_test_invalid_decoded, getCurrentExceptionMsg())
  except JsonParsingError:
    exit_with ec_err_json_syntax

proc test_fail_decoding*(specfile: string,
                         datatype: string, encoded: string): int =
  ## test that decoding the provided encoded string fails
  let definition = get_datatype_definition(datatype)
  try:
    let decoded_json = $textformats.decode(encoded, definition)
    let info = &"Encoded data:          '{encoded}'\n" &
               &"Datatype name:         '{datatype}'\n" &
               &"Datatype definition:   {definition}\n" &
               &"Decoded data (JSON):   '{decoded_json}'"
    exit_with(ec_test_unexp_valid_encoded, info)
  except textformats.DecodingError:
    exit_with(ec_success, ok_pfx &
      &"'{encoded}' => decoding as {datatype} fails")

proc test_decoding*(specfile: string, datatype: string,
                    encoded: string, expected_json: string): int =
  ## decode an encoded string and compare the result to the expected data (JSON)
  let definition = get_datatype_definition(datatype)
  try:
    let decoded = textformats.decode(encoded, definition)
    try:
      let parsed_expected = parse_float_or_json(expected_json)
      if decoded != parsed_expected:
        let info = &"Encoded data:          '{encoded}'\n" &
                   &"Datatype name:         '{datatype}'\n" &
                   &"Datatype definition:   {definition}\n" &
                   &"Decoded data (JSON):   '{decoded}'\n" &
                   &"Expected data (JSON):  '{parsed_expected}'"
        exit_with(ec_test_unexp_decoding_result, info)
      else:
        let info = ok_pfx & &"'{encoded}' => decoded as {datatype}: " &
                   &"'{decoded}'"
        exit_with(ec_success, info)
    except JsonParsingError:
      exit_with ec_err_json_syntax
  except textformats.DecodingError:
    stderr.write_line getCurrentExceptionMsg()
    exit_with ec_test_invalid_encoded

when isMainModule:
  import cligen
  dispatch_multi([test_decoding, cmdname="decoding",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "encoded": short_encoded,
                               "expected_json": short_decoded},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "encoded": help_encoded,
                              "expected_json": help_expected_json}],
                     [test_encoding, cmdname="encoding",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded,
                               "expected": short_encoded},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json,
                              "expected": help_expected}],
                     [test_fail_decoding, cmdname="fail_decoding",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "encoded": short_encoded},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "encoded":  help_encoded}],
                     [test_fail_encoding, cmdname="fail_encoding",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json}],
                     [test_encoded_validation, cmdname="encoded_validation",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "encoded": short_encoded,
                               "expected_valid": short_expected_valid},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "encoded": help_encoded,
                              "expected_valid": help_expected_valid}],
                     [test_decoded_validation, cmdname="decoded_validation",
                      short = {"specfile": short_specfile,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded,
                               "expected_valid": short_expected_valid},
                      help = {"specfile": help_specfile,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json,
                              "expected_valid": help_expected_valid}],
                    )
