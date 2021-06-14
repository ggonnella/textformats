##
## Encode, decode and validate data according to a specification
##

import tables, strformat, json, strutils
from textformats import parse_specification, load_specification,
                     save_specification, is_valid,
                     recognize_and_decode_lines, `$`, test_specification
import textformats / [testdata_generator, spec_parser]
from textformats import nil

const
  dec_in = "Specified decoded value"
  enc_in = "Specified encoded string"
  dec_out = "Resulting decoded value"
  enc_out = "Resulting encoded string"
  err_inv = " invalid for datatype"
  err_val = " valid for datatype (expected: invalid)"
  err_dff = " different than expected"
  fld_pfx = "[Failed] "
  err_pfx = "[Error] "
  ok_pfx = "[OK] "

type

  ExitCode = enum
    ec_success
    # negative validation response
    ec_vdn_invalid_encoded=enc_in & err_inv
    ec_vdn_invalid_decoded=dec_in & err_inv
    # unexpected test results
    ec_test_invalid_encoded=fld_pfx & enc_in & err_inv
    ec_test_invalid_decoded=fld_pfx & dec_in & err_inv
    ec_test_unexp_valid_encoded=fld_pfx & enc_in & err_val
    ec_test_unexp_valid_decoded=fld_pfx & dec_in & err_val
    ec_test_unexp_encoding_result=fld_pfx & enc_out & err_dff
    ec_test_unexp_decoding_result=fld_pfx & dec_out & err_dff
    # errors
    ec_err_json_syntax=err_pfx & dec_in & ": invalid JSON syntax"
    ec_err_def_not_found=err_pfx &
      "The specification does not include the datatype"
    ec_err_spec_invalid=err_pfx & "The specification is invalid"
    ec_err_spec_io=err_pfx &
      "The specification file does not exist or cannot be read"
    ec_err_invalid_encoded=err_pfx & "Decoding error: " & enc_in & err_inv
    ec_err_invalid_decoded=err_pfx & "Encoding error: " & dec_in & err_inv
    ec_test_error

template exit_with(exit_code: untyped, info = "", errcodemsg = true): untyped =
  let `info` = info # local copy, to avoid multiple evaluation
  if exit_code != ec_success and errcodemsg:
    stderr.write_line $exit_code
  if info.len > 0:
    let i = if errcodemsg: 2 else: 0
    stderr.write_line ($info).indent(i)
  return exit_code.int

template get_specification(specfile, preprocessed: untyped): untyped =
  var datatypes: textformats.Specification
  try:
    datatypes =
      if preprocessed: load_specification(specfile)
      else: parse_specification(specfile)
  except textformats.InvalidSpecError:
    let e = get_current_exception()
    exit_with(ec_err_spec_invalid, e.msg)
  except textformats.TextformatsRuntimeError:
    let e = get_current_exception()
    exit_with(ec_err_spec_io, e.msg)
  datatypes

template get_datatype_definition(datatype: untyped,
                                 preprocessed: untyped): untyped =
  let datatypes = get_specification(specfile, preprocessed)
  if datatype notin datatypes:
    exit_with ec_err_def_not_found
    nil
  else: datatypes[datatype]

template parse_float_or_json(s: string): JsonNode =
  if s == "Infinity":    %*Inf
  elif s == "-Infinity": %*NegInf
  elif s == "NaN":       %*NaN
  else:                  s.parse_json

proc encode*(specfile: string, preprocessed=false, datatype: string,
                 decoded_json: string): int =
  ## encode decoded data (JSON) and output as encoded string
  let definition = get_datatype_definition(datatype, preprocessed)
  try:
    let decoded = parse_float_or_json(decoded_json)
    try:
      echo textformats.encode(decoded, definition)
    except textformats.EncodingError:
      exit_with(ec_err_invalid_decoded, getCurrentExceptionMsg())
  except JsonParsingError:
    exit_with ec_err_json_syntax

proc decode*(specfile: string, preprocessed=false, datatype: string,
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

proc validate_encoded*(specfile: string, preprocessed=false,
                           datatype: string, encoded: string): int =
  ## validate an encoded string
  let definition = get_datatype_definition(datatype, preprocessed)
  if encoded.is_valid(definition):
    exit_with(ec_success, &"'{encoded}' is a valid encoded '{datatype}'")
  else:
    exit_with(ec_vdn_invalid_encoded)

proc test_encoded_validation*(specfile: string, preprocessed=false,
                            datatype: string, encoded: string,
                            expected_valid=false): int =
  ## test the validation of an encoded string
  let definition = get_datatype_definition(datatype, preprocessed)
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

proc validate_decoded*(specfile: string, preprocessed=false,
                           datatype: string, decoded_json: string): int =
  ## validate decoded data (JSON)
  let definition = get_datatype_definition(datatype, preprocessed)
  try:
    let decoded = parse_float_or_json(decoded_json)
    if decoded.is_valid(definition):
      exit_with(ec_success, &"'{decoded_json}' is a valid decoded '{datatype}'")
    else:
      exit_with(ec_vdn_invalid_decoded)
  except JsonParsingError:
    exit_with ec_err_json_syntax

proc test_decoded_validation*(specfile: string, preprocessed=false,
                            datatype: string, decoded_json: string,
                            expected_valid=false): int =
  ## test the validation of decoded data (JSON)
  let definition = get_datatype_definition(datatype, preprocessed)
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

proc test_fail_encoding*(specfile: string, preprocessed=false,
                         datatype: string, decoded_json: string): int =
  ## test that encoding the provided decoded data (JSON) fails
  let definition = get_datatype_definition(datatype, preprocessed)
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

proc test_encoding*(specfile: string, preprocessed=false, datatype: string,
                    decoded_json: string, expected: string): int =
  ## encode the decoded data (JSON) and compare to the expected encoding
  let definition = get_datatype_definition(datatype, preprocessed)
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

proc test_fail_decoding*(specfile: string, preprocessed=false,
                         datatype: string, encoded: string): int =
  ## test that decoding the provided encoded string fails
  let definition = get_datatype_definition(datatype, preprocessed)
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

proc test_decoding*(specfile: string, preprocessed=false, datatype: string,
                    encoded: string, expected_json: string): int =
  ## decode an encoded string and compare the result to the expected data (JSON)
  let definition = get_datatype_definition(datatype, preprocessed)
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

proc show*(specfile: string, preprocessed=false,
                    datatype: string): int =
  ## show a definition in a specification file
  let definition = get_datatype_definition(datatype, preprocessed)
  echo $definition
  exit_with(ec_success)

proc preprocess*(specfile: string, outfile: string): int =
  ## preprocess a specification file
  let datatypes = parse_specification(specfile)
  datatypes.save_specification(outfile)
  exit_with(ec_success)

proc list*(specfile: string, preprocessed=false): int =
  ## list all definitions in a specification file
  let datatypes = get_specification(specfile, preprocessed)
  for datatype_name, datatype in datatypes:
    if datatype_name notin textformats.BaseDatatypes:
      echo $datatype_name
  exit_with(ec_success)

proc run_tests*(specfile: string, preprocessed=false,
                testfile: string): int =
  ## test a specification using a testdata file
  let datatypes = get_specification(specfile, preprocessed)
  try:
    datatypes.test_specification(testfile)
  except textformats.InvalidTestdataError, textformats.TestError:
    exit_with(ec_testerror, get_current_exception_msg(), false)
  exit_with(ec_success)

# not accepting preprocessed specifications because in the preprocessed
# there is no information if a datatype is defined in the specification
# itself or in an included file; thus list_specification_datatypes is only
# accepting a YAML specification
proc generate_tests*(specfile: string): int =
  ## auto-generate testdata for a specification file
  let
    datatypes = list_specification_datatypes(specfile)
    specification = parse_specification(specfile)
  echo "testdata:"
  for ddn in datatypes:
    echo specification[ddn].to_testdata(ddn)
  exit_with(ec_success)

template short_specfile: untyped = 's'
template short_datatype: untyped = 't'
template short_decoded: untyped = 'd'
template short_encoded: untyped = 'e'
template short_expected_valid: untyped = 'v'
template short_preprocessed: untyped = 'p'
template short_outfile: untyped = 'o'
template short_infile: untyped = 'i'
template short_testfile: untyped = 'f'

template help_specfile: untyped =
  "datatypes specification (YAML or preprocessed)"
template help_preprocessed: untyped =
  "specification file is preprocessed (default: YAML)"
template help_datatype: untyped = "datatype"
template help_decoded_json: untyped = "data to encode (JSON)"
template help_encoded: untyped = "encoded data"
template help_expected_json: untyped = "expected decoded data (JSON)"
template help_expected: untyped = "expected encoded data"
template help_expected_valid: untyped = "expected valid? (y/n)"
template help_outfile: untyped = "output filename"
template help_infile: untyped = "input filename"
template help_testfile: untyped = "test data filename (YAML)"

when isMainModule:
  import cligen
  include cligen/mergeCfgEnvMulMul
  dispatch_multi_gen(["test"],
                     [test_decoding, cmdname="decoding",
                      merge_names = @["textformats_cli", "test"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "encoded": short_encoded,
                               "expected_json": short_decoded},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "encoded": help_encoded,
                              "expected_json": help_expected_json}],
                     [test_encoding, cmdname="encoding",
                      merge_names = @["textformats_cli", "test"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded,
                               "expected": short_encoded},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json,
                              "expected": help_expected}],
                     [test_fail_decoding, cmdname="fail_decoding",
                      merge_names = @["textformats_cli", "test"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "encoded": short_encoded},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "encoded":  help_encoded}],
                     [test_fail_encoding, cmdname="fail_encoding",
                      merge_names = @["textformats_cli", "test"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json}],
                     [test_encoded_validation, cmdname="encoded_validation",
                      merge_names = @["textformats_cli", "test"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "encoded": short_encoded,
                               "expected_valid": short_expected_valid},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "encoded": help_encoded,
                              "expected_valid": help_expected_valid}],
                     [test_decoded_validation, cmdname="decoded_validation",
                      merge_names = @["textformats_cli", "test"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded,
                               "expected_valid": short_expected_valid},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json,
                              "expected_valid": help_expected_valid}],
                    )
  dispatch_multi_gen(["validate"],
                     [validate_encoded, cmdname="encoded",
                      merge_names = @["textformats_cli", "validate"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "encoded": short_encoded},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "encoded": help_encoded}],
                     [validate_decoded, cmdname="decoded",
                      merge_names = @["textformats_cli", "validate"],
                      short = {"specfile": short_specfile,
                               "preprocessed": short_preprocessed,
                               "datatype": short_datatype,
                               "decoded_json": short_decoded},
                      help = {"specfile": help_specfile,
                              "preprocessed": help_preprocessed,
                              "datatype": help_datatype,
                              "decoded_json": help_decoded_json}],
                    )
  dispatch_multi([encode,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "decoded_json": short_decoded},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "decoded_json": help_decoded_json}],
                 [decode,
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
                 [decode_embedded,
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype}],
                 [decode_units,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "infile":  help_infile}],
                 [decode_lines,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype,
                           "infile":  short_infile},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype,
                          "infile":  help_infile}],
                 [validate, stopwords = @["encoded", "decoded"],
                  doc = "subcommand validate: see 'validate' (help) " &
                        "or 'validate help' (full help)",
                  usage = "$doc\n",
                  suppress = @["usage", "prefix"]],
                 [list,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed}],
                 [show,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "datatype": short_datatype},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "datatype": help_datatype}],
                 [generate_tests,
                  short = {"specfile": short_specfile},
                  help = {"specfile": help_specfile}],
                 [preprocess,
                  short = {"specfile": short_specfile,
                           "outfile": short_outfile},
                  help = {"specfile": help_specfile,
                          "outfile": help_outfile}],
                 [run_tests,
                  short = {"specfile": short_specfile,
                           "preprocessed": short_preprocessed,
                           "testfile": short_testfile},
                  help = {"specfile": help_specfile,
                          "preprocessed": help_preprocessed,
                          "testfile": help_testfile}],
                 [test, stopwords = @[
                   "decoding", "encoding",
                   "fail_decoding", "fail_encoding",
                   "decoded_validation", "encoded_validation"],
                   doc = "subcommand test: " &
                         "see 'test' (help) or 'test help' (full help)",
                   usage = "$doc\n",
                   suppress = @["usage", "prefix"]])
