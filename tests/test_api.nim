##
## Test library API
##
## The same test is done with the C and Python wrappers.
##

import os, sets, json
import unittest
import textformats

const
  testdata = currentSourcePath.parentDir() & "/testdata/api/"
  YAML_SPEC =        "fasta.yaml"
  COMPILED_SPEC =    "fasta.tfs"
  BAD_YAML_SPEC =    "wrong_yaml_syntax.yaml"
  NONEXISTING_SPEC = "xyz.yaml"
  TESTFILE =         "good_test.yaml"
  BAD_TESTFILE =     "bad_test.yaml"

  EXP_DATATYPES = toHashSet(["entry", "sequence", "default", "header", "sequence_line",
                   "unit_for_tests", "file", "double_header_symbol_line", "line",
                   "line_failing"])

  YAML_SPEC_INLINE =     "{\"datatypes\": {\"x\": {\"constant\": \"x\"}}}"
  BAD_YAML_SPEC_INLINE = "{\"datatypes\": {\"x\": []}}"
  TESTDATA_INLINE =      "{\"testdata\": {\"x\": {\"valid\": [\"x\"], \"invalid\": [\"y\"]}}}"
  BAD_TESTDATA_INLINE =  "{\"testdata\": {\"x\": {\"valid\": [\"y\"]}}}"
  YAML_SPEC_INLINE_DT      = "x"
  YAML_SPEC_INLINE_DT_REPR = "x:\n  constant: \"x\"\n"
  YAML_SPEC_INLINE_DT_STR  = """
Datatype: 'x': constant value

  the constant value is string:"x"

- regular expression:
    regex which has been generated for the data type:
      'x'
    a match ensures validity of the encoded string
"""

  DATA_TYPE =             "header"
  NONEXISTING_DATA_TYPE = "heder"

  DATA_E =     ">ABCD some sequence"
  BAD_DATA_E =  "ABCD some sequence"
  DATA_D =      "{\"fastaid\":\"ABCD\",\"desc\":\"some sequence\"}"
  BAD_DATA_D =  "{\"desc\":\"some sequence\"}"

  DATAFILE =                 "test.fas"
  DATA_TYPE_SCOPE_LINE =     "line"
  BAD_DATA_TYPE_SCOPE_LINE = "line_failing"
  DATA_TYPE_SCOPE_UNIT =     "unit_for_tests"
  DATA_TYPE_SCOPE_SECTION =  "entry"
  DATA_TYPE_SCOPE_FILE =     "file"

suite "test_api":

  test "specification_construction_API":
    expect(DefSyntaxError):
      discard parse_specification(BAD_YAML_SPEC_INLINE)
    discard parse_specification(YAML_SPEC_INLINE)
    expect(InvalidSpecError):
      discard specification_from_file(testdata & BAD_YAML_SPEC)
    expect(TextFormatsRuntimeError):
      discard specification_from_file(testdata & NONEXISTING_SPEC)
    discard specification_from_file(testdata & YAML_SPEC)

  test "specification_compiling_API":
    check not is_compiled(testdata & YAML_SPEC)
    compile_specification(testdata & YAML_SPEC, testdata & COMPILED_SPEC)
    check is_compiled(testdata & COMPILED_SPEC)

  test "specification_tests_API":
    for s in @[specification_from_file(testdata & YAML_SPEC),
               specification_from_file(testdata & COMPILED_SPEC)]:
      expect(UnexpectedEncodedInvalidError):
        s.run_specification_testfile(testdata & BAD_TESTFILE)
      s.run_specification_testfile(testdata & TESTFILE)
    let s = parse_specification(YAML_SPEC_INLINE)
    expect(UnexpectedEncodedInvalidError):
      s.run_specification_tests(BAD_TESTDATA_INLINE)
    s.run_specification_tests(TESTDATA_INLINE)

  test "specification_properties":
    let s = specification_from_file(testdata & YAML_SPEC)
    check toHashSet(s.datatype_names) == EXP_DATATYPES

  test "datatype_definition_API":
    let s = specification_from_file(testdata & YAML_SPEC)
    expect(TextFormatsRuntimeError):
      discard s.get_definition(NONEXISTING_DATA_TYPE)
    discard s.get_definition(DATA_TYPE)

  test "datatype_definition_desc":
    let
      s = parse_specification(YAML_SPEC_INLINE)
      d = s.get_definition(YAML_SPEC_INLINE_DT)
    check repr(d) == YAML_SPEC_INLINE_DT_REPR
    check $d == YAML_SPEC_INLINE_DT_STR

  test "handling_encoded_strings":
    let
      s = specification_from_file(testdata & YAML_SPEC)
      d = s.get_definition(DATA_TYPE)
    expect(DecodingError):
      discard BAD_DATA_E.decode(d)
    check DATA_E.decode(d) == parseJson(DATA_D)
    check not BAD_DATA_E.is_valid(d)
    check DATA_E.is_valid(d)

  test "handling_decoded_data":
    let
      s = specification_from_file(testdata & YAML_SPEC)
      d = s.get_definition(DATA_TYPE)
    let
      bad_decoded = parseJson(BAD_DATA_D)
      decoded = parseJson(DATA_D)
    expect(EncodingError):
      discard bad_decoded.encode(d)
    check not bad_decoded.is_valid(d)
    check decoded.encode(d) == DATA_E
    check decoded.is_valid(d)

  test "encoded_file_decoding_settings":
    let
      s = specification_from_file(testdata & YAML_SPEC)
      dd_line = s.get_definition(DATA_TYPE_SCOPE_LINE)
      dd_line_failing = s.get_definition(BAD_DATA_TYPE_SCOPE_LINE)
      dd_unit = s.get_definition(DATA_TYPE_SCOPE_UNIT)
      dd_section = s.get_definition(DATA_TYPE_SCOPE_SECTION)
      dd_file = s.get_definition(DATA_TYPE_SCOPE_FILE)
    check dd_line.get_scope() == "undefined"
    check dd_line_failing.get_scope() == "line"
    check dd_unit.get_scope() == "unit"
    check dd_section.get_scope() == "section"
    check dd_file.get_scope() == "file"
    expect(TextFormatsRuntimeError):
      dd_line_failing.set_scope("laine")
    dd_line_failing.set_scope("unit")
    check dd_line_failing.get_scope() == "unit"
    check dd_unit.get_unitsize() == 3
    check dd_section.get_unitsize() == 1
    expect(TextFormatsRuntimeError):
      dd_unit.set_unitsize(0)
    dd_unit.set_unitsize(2)
    check dd_unit.get_unitsize() == 2

  test "handling_encoded_files_w_iterator":
    let
      s = specification_from_file(testdata & YAML_SPEC)
      dd_line = s.get_definition(DATA_TYPE_SCOPE_LINE)
      dd_line_failing = s.get_definition(BAD_DATA_TYPE_SCOPE_LINE)
      dd_unit = s.get_definition(DATA_TYPE_SCOPE_UNIT)
      dd_section = s.get_definition(DATA_TYPE_SCOPE_SECTION)
      dd_file = s.get_definition(DATA_TYPE_SCOPE_FILE)
    expect(TextFormatsRuntimeError):
      for decoded in (testdata & DATAFILE).decoded_file(dd_line):
        echo(decoded)
    expect(DecodingError):
      for decoded in (testdata & DATAFILE).decoded_file(dd_line_failing):
        echo(decoded)
    dd_line.set_scope("line")
    for decoded in (testdata & DATAFILE).decoded_file(dd_line):
      echo(decoded)
    #[
    dd_line.set_wrapped()
    for decoded in (testdata & DATAFILE).decoded_file(dd_line):
      echo(decoded)
    expect(DecodingError):
      for decoded in (testdata & DATAFILE).decoded_file(dd_unit):
        echo(decoded)
    dd_unit.set_unitsize(4)
    for decoded in (testdata & DATAFILE).decoded_file(dd_unit):
      echo(decoded)
    for decoded in (testdata & DATAFILE).decoded_file(dd_section):
      echo(decoded)
    for decoded in (testdata & DATAFILE).decoded_file(dd_section,
                                           yield_elements=true):
      echo(decoded)
    for decoded in (testdata & DATAFILE).decoded_file(dd_file):
      echo(decoded)
    for decoded in (testdata & DATAFILE).decoded_file(dd_file,
                                           yield_elements=true):
      echo(decoded)
    for decoded in (testdata & YAML_SPEC).decoded_file(dd_file,
                                            skip_embedded_spec=true):
      echo(decoded)
    ]#

  proc process_decoded(n: JsonNode, data: pointer) =
    echo($n)

  test "handling_encoded_files_w_processor_function":
    let
      s = specification_from_file(testdata & YAML_SPEC)
      dd_line = s.get_definition(DATA_TYPE_SCOPE_LINE)
      dd_line_failing = s.get_definition(BAD_DATA_TYPE_SCOPE_LINE)
      dd_unit = s.get_definition(DATA_TYPE_SCOPE_UNIT)
      dd_section = s.get_definition(DATA_TYPE_SCOPE_SECTION)
      dd_file = s.get_definition(DATA_TYPE_SCOPE_FILE)
    expect(TextFormatsRuntimeError):
      (testdata & DATAFILE).decode_file(dd_line,
         decoded_processor=process_decoded)
    expect(DecodingError):
      (testdata & DATAFILE).decode_file(dd_line_failing,
         decoded_processor=process_decoded)
    dd_line.set_scope("line")
    (testdata & DATAFILE).decode_file(dd_line,
      decoded_processor=process_decoded)
    dd_line.set_wrapped()
    (testdata & DATAFILE).decode_file(dd_line,
      decoded_processor=process_decoded)
    expect(DecodingError):
      (testdata & DATAFILE).decode_file(dd_unit)
    dd_unit.set_unitsize(4)
    (testdata & DATAFILE).decode_file(dd_unit,
      decoded_processor=process_decoded)
    for l in @[DplWhole, DplElement, DplLine]:
      (testdata & DATAFILE).decode_file(dd_section,
        decoded_processor_level=l,
        decoded_processor=process_decoded)
      (testdata & DATAFILE).decode_file(dd_file,
        decoded_processor_level=l,
        decoded_processor=process_decoded)
      (testdata & YAML_SPEC).decode_file(dd_file, skip_embedded_spec=true,
        decoded_processor_level=l,
        decoded_processor=process_decoded)
