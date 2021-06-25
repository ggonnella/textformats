##
## Common functionality for the command line interface tools
##

import json, os, streams

##
## Error messages and exit codes;
## defined here so that they are consistant among the tools
##

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
  ok_pfx* =  "[OK] "

type
  ExitCode* = enum
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
    ec_err_preproc=err_pfx &
      "The specification file is preprocessed; use a YAML specification"
    ec_err_invalid_encoded=err_pfx & "Decoding error: " & enc_in & err_inv
    ec_err_invalid_decoded=err_pfx & "Encoding error: " & dec_in & err_inv
    ec_test_error

template exit_with*(exit_code: untyped, info = "", errcodemsg = true): untyped =
  let `info` = info # local copy, to avoid multiple evaluation
  if exit_code != ec_success and errcodemsg:
    stderr.write_line $exit_code
  if info.len > 0:
    let i = if errcodemsg: 2 else: 0
    stderr.write_line ($info).indent(i)
  return exit_code.int

template fail_if_preprocessed*(specfile) =
  try:
    if unlikely(textformats.is_preprocessed(specfile)):
      exit_with(ec_err_preproc)
  except textformats.TextformatsRuntimeError:
    let e = get_current_exception()
    exit_with(ec_err_spec_io, e.msg)

template get_specification*(specfile): untyped =
  var datatypes: textformats.Specification
  try:
    datatypes = textformats.specification_from_file(specfile)
  except textformats.InvalidSpecError:
    let e = get_current_exception()
    exit_with(ec_err_spec_invalid, e.msg)
  except textformats.TextformatsRuntimeError:
    let e = get_current_exception()
    exit_with(ec_err_spec_io, e.msg)
  datatypes

template get_datatype_definition*(specfile: untyped,
                                  datatype: untyped): untyped =
  let datatypes = get_specification(specfile)
  if datatype notin datatypes:
    exit_with ec_err_def_not_found
    nil
  else: datatypes[datatype]

template parse_float_or_json*(s: string): JsonNode =
  if s == "Infinity":    %*Inf
  elif s == "-Infinity": %*NegInf
  elif s == "NaN":       %*NaN
  else:                  s.parse_json

##
## Short version of the options;
## defined here so that they are consistant among the tools
##
template short_specfile*:       untyped = 's'
template short_datatype*:       untyped = 't'
template short_decoded*:        untyped = 'd'
template short_encoded*:        untyped = 'e'
template short_expected_valid*: untyped = 'v'
template short_outfile*:        untyped = 'o'
template short_infile*:         untyped = 'i'
template short_testfile*:       untyped = 'f'

##
## Help messages for the options;
## defined here so that they are consistant among the tools
##
template help_specfile*: untyped =
  "datatypes specification (YAML or preprocessed)"
template help_specfile_yaml*: untyped =
  "datatypes specification (YAML only)"
template help_datatype*: untyped = "datatype"
template help_decoded_json*: untyped = "data to encode (JSON)"
template help_encoded*: untyped = "encoded data"
template help_expected_json*: untyped = "expected decoded data (JSON)"
template help_expected*: untyped = "expected encoded data"
template help_expected_valid*: untyped = "expected valid? (y/n)"
template help_outfile*: untyped = "output filename"
template help_infile*: untyped = "input filename"
template help_testfile*: untyped = "test data filename (YAML); " &
  "if not provided, the same file as the specification shall contain tests"
template help_opt_testfile*: untyped = "optional: test data filename (YAML);" &
  "if provided, tests are generated only for datatypes not yet present in it"

