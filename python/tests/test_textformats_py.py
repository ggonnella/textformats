import pytest
import textformats as tf
import json

YAML_SPEC =        "fasta.yaml"
COMPILED_SPEC =    "fasta.tfs"
BAD_YAML_SPEC =    "wrong_yaml_syntax.yaml"
NONEXISTING_SPEC = "xyz.yaml"
TESTFILE =         "good_test.yaml"
BAD_TESTFILE =     "bad_test.yaml"

EXP_DATATYPES = {"entry", "sequence", "default", "header", "sequence_line",
                 "unit_for_tests", "file", "double_header_symbol_line", "line",
                 "line_failing"}

YAML_SPEC_INLINE =     {"datatypes": {"x": {"constant": "x"}}}
BAD_YAML_SPEC_INLINE = {"datatypes": {"x": []}}
TESTDATA_INLINE =      {"testdata": {"x": {"valid": ["x"], "invalid": ["y"]}}}
BAD_TESTDATA_INLINE =  {"testdata": {"x": {"valid": ["y"]}}}
YAML_SPEC_INLINE_DT      = "x"
YAML_SPEC_INLINE_DT_REPR = "Specification({\"datatypes\": yaml.safe_load("+\
                           "'x:\\n  constant: \"x\"\\n')})['x']"
YAML_SPEC_INLINE_DT_STR  = """\
Datatype: 'x': constant value

  the constant value is string:"x"

- regular expression:
    regex which has been generated for the data type:
      'x'
    a match ensures validity of the encoded string
"""

DATA_TYPE =             "header"
NONEXISTING_DATA_TYPE = "heder"

DATA_E =        ">ABCD some sequence"
BAD_DATA_E =    "ABCD some sequence"
DATA_D =        "{\"fastaid\":\"ABCD\",\"desc\":\"some sequence\"}"
DATA_D_PRETTY = "{\n  \"fastaid\": \"ABCD\",\n  \"desc\": \"some sequence\"\n}"
BAD_DATA_D =    "{\"desc\":\"some sequence\"}"

DATAFILE =                 "test.fas"
DATA_TYPE_SCOPE_LINE =     "line"
BAD_DATA_TYPE_SCOPE_LINE = "line_failing"
DATA_TYPE_SCOPE_UNIT =     "unit_for_tests"
DATA_TYPE_SCOPE_SECTION =  "entry"
DATA_TYPE_SCOPE_FILE =     "file"

from contextlib import contextmanager

@contextmanager
def assert_nothing_raised():
  try: yield
  except Exception as e: pytest.fail(f"Unexpected exception raised: {e}")

def test_specification_construction_api(testdata):
  with pytest.raises(tf.DefSyntaxError):
    tf.Specification(BAD_YAML_SPEC_INLINE)
  with assert_nothing_raised():
    tf.Specification(YAML_SPEC_INLINE)
  with pytest.raises(tf.InvalidSpecError):
    tf.Specification(testdata(BAD_YAML_SPEC))
  with pytest.raises(tf.TextFormatsRuntimeError):
    tf.Specification(testdata(NONEXISTING_SPEC));
  with assert_nothing_raised():
    tf.Specification(testdata(YAML_SPEC));

def test_specification_compilation_api(testdata):
  with assert_nothing_raised():
    tf.Specification.compile(testdata(YAML_SPEC), testdata(COMPILED_SPEC))

def test_specification_tests_api(testdata):
  for s in [tf.Specification(testdata(YAML_SPEC)),
            tf.Specification(testdata(COMPILED_SPEC))]:
    with pytest.raises(tf.UnexpectedEncodedInvalidError):
      s.test(testdata(BAD_TESTFILE))
    with assert_nothing_raised():
      s.test(testdata(TESTFILE))
  s = tf.Specification(YAML_SPEC_INLINE)
  with pytest.raises(tf.UnexpectedEncodedInvalidError):
    s.test(BAD_TESTDATA_INLINE)
  with assert_nothing_raised():
    s.test(TESTDATA_INLINE)

def test_specification_properties(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  assert(not s.is_compiled)
  assert set(s.datatype_names) == EXP_DATATYPES
  assert s.filename == testdata(YAML_SPEC)
  sp = tf.Specification(testdata(COMPILED_SPEC))
  assert(sp.is_compiled)
  assert set(sp.datatype_names) == EXP_DATATYPES
  assert sp.filename == testdata(COMPILED_SPEC)

def test_datatype_definition_api(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  with pytest.raises(tf.TextFormatsRuntimeError):
    s[NONEXISTING_DATA_TYPE]
  with assert_nothing_raised():
    s[DATA_TYPE]

def test_datatype_definition_desc(testdata):
  s = tf.Specification(YAML_SPEC_INLINE)
  d = s[YAML_SPEC_INLINE_DT]
  assert repr(d) == YAML_SPEC_INLINE_DT_REPR
  assert str(d) == YAML_SPEC_INLINE_DT_STR

def test_handling_encoded_strings(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  d = s[DATA_TYPE]
  with pytest.raises(tf.DecodingError):
    d.decode(BAD_DATA_E)
  assert d.decode(DATA_E) == json.loads(DATA_D)
  with pytest.raises(tf.DecodingError):
    d.decode(BAD_DATA_E, to_json=True)
  assert d.decode(DATA_E, to_json=True) == DATA_D_PRETTY
  assert not d.is_valid_encoded(BAD_DATA_E)
  assert d.is_valid_encoded(DATA_E)

def test_handling_decoded_data(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  d = s[DATA_TYPE]
  decoded = json.loads(BAD_DATA_D)
  with pytest.raises(tf.EncodingError):
    d.encode(decoded)
  assert not d.is_valid_decoded(decoded)
  decoded = json.loads(DATA_D)
  assert d.encode(decoded) == DATA_E
  assert d.is_valid_decoded(decoded)

def test_handling_decoded_json(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  d = s[DATA_TYPE]
  with pytest.raises(tf.EncodingError):
    d.encode(BAD_DATA_D, from_json=True)
  assert not d.is_valid_decoded(BAD_DATA_D, json=True)
  assert d.encode(DATA_D, from_json=True) == DATA_E
  assert d.is_valid_decoded(DATA_D, json=True)

def test_encoded_file_decoding_settings(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  dd_line = s[DATA_TYPE_SCOPE_LINE]
  dd_line_failing = s[BAD_DATA_TYPE_SCOPE_LINE]
  dd_unit = s[DATA_TYPE_SCOPE_UNIT]
  dd_section = s[DATA_TYPE_SCOPE_SECTION]
  dd_file = s[DATA_TYPE_SCOPE_FILE]
  assert dd_line.scope == "undefined"
  assert dd_line_failing.scope == "line"
  assert dd_unit.scope == "unit"
  assert dd_section.scope == "section"
  assert dd_file.scope == "file"
  with pytest.raises(tf.TextFormatsRuntimeError):
    dd_line_failing.scope = "laine"
  dd_line_failing.scope = "unit"
  assert dd_line_failing.scope == "unit"
  assert dd_unit.unitsize == 3
  assert dd_section.unitsize == 1
  with pytest.raises(tf.TextFormatsRuntimeError):
    dd_unit.unitsize = 0
  dd_unit.unitsize = 2
  assert dd_unit.unitsize == 2

def test_handling_encoded_files_w_iterator(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  dd_line = s[DATA_TYPE_SCOPE_LINE]
  dd_line_failing = s[BAD_DATA_TYPE_SCOPE_LINE]
  dd_unit = s[DATA_TYPE_SCOPE_UNIT]
  dd_section = s[DATA_TYPE_SCOPE_SECTION]
  dd_file = s[DATA_TYPE_SCOPE_FILE]
  with pytest.raises(tf.TextFormatsRuntimeError):
    for decoded in dd_line.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with pytest.raises(tf.DecodingError):
    for decoded in dd_line_failing.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with assert_nothing_raised():
    dd_line.scope = "line"
    for decoded in dd_line.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with assert_nothing_raised():
    dd_line.wrapped=True
    for decoded in dd_line.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with pytest.raises(tf.DecodingError):
    for decoded in dd_unit.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with assert_nothing_raised():
    dd_unit.unitsize = 4
    for decoded in dd_unit.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with assert_nothing_raised():
    for decoded in dd_section.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with assert_nothing_raised():
    for decoded in dd_section.decoded_file(testdata(DATAFILE), as_elements=True):
      print(decoded)
  with assert_nothing_raised():
    for decoded in dd_file.decoded_file(testdata(DATAFILE)):
      print(decoded)
  with assert_nothing_raised():
    for decoded in dd_file.decoded_file(testdata(DATAFILE), as_elements=True):
      print(decoded)
  with assert_nothing_raised():
    for decoded in dd_file.decoded_file(testdata(YAML_SPEC),
                     skip_embedded_spec=True):
      print(decoded)

def print_and_count_decoded(decoded, data):
  data["counter"] += 1
  print(decoded)

def test_handling_encoded_files_w_processor(testdata):
  s = tf.Specification(testdata(YAML_SPEC))
  dd_line = s[DATA_TYPE_SCOPE_LINE]
  dd_line_failing = s[BAD_DATA_TYPE_SCOPE_LINE]
  dd_unit = s[DATA_TYPE_SCOPE_UNIT]
  dd_section = s[DATA_TYPE_SCOPE_SECTION]
  dd_file = s[DATA_TYPE_SCOPE_FILE]
  data = {"counter": 0}
  with pytest.raises(tf.TextFormatsRuntimeError):
    dd_line.decode_file(testdata(DATAFILE),
        decoded_processor=print_and_count_decoded,
        decoded_processor_data=data)
  assert data["counter"] == 0
  with pytest.raises(tf.DecodingError):
    dd_line_failing.decode_file(testdata(DATAFILE),
        decoded_processor=print_and_count_decoded,
        decoded_processor_data=data)
  assert data["counter"] == 0
  with assert_nothing_raised():
    dd_line.scope = "line"
    dd_line.decode_file(testdata(DATAFILE),
        decoded_processor=print_and_count_decoded,
        decoded_processor_data=data)
  assert data["counter"] == 8
  data["counter"] = 0
  with assert_nothing_raised():
    dd_line.wrapped=True
    dd_line.decode_file(testdata(DATAFILE),
        decoded_processor=print_and_count_decoded,
        decoded_processor_data=data)
  assert data["counter"] == 8
  data["counter"] = 0
  with pytest.raises(tf.DecodingError):
    dd_unit.decode_file(testdata(DATAFILE),
        decoded_processor=print_and_count_decoded,
        decoded_processor_data=data)
  data["counter"] = 0
  with assert_nothing_raised():
    dd_unit.unitsize = 4
    dd_unit.decode_file(testdata(DATAFILE),
        decoded_processor=print_and_count_decoded,
        decoded_processor_data=data)
  assert data["counter"] == 2
  for level in [0, 1, 2]:
    data["counter"] = 0
    with assert_nothing_raised():
      dd_section.decode_file(testdata(DATAFILE),
          decoded_processor=print_and_count_decoded,
          decoded_processor_data=data,
          decoded_processor_level=level)
    assert data["counter"] == [2, 4, 8][level]
    data["counter"] = 0
    with assert_nothing_raised():
      dd_file.decode_file(testdata(DATAFILE),
          decoded_processor=print_and_count_decoded,
          decoded_processor_data=data,
          decoded_processor_level=level)
    assert data["counter"] == [1, 2, 8][level]
    data["counter"] = 0
    with assert_nothing_raised():
      dd_file.decode_file(testdata(YAML_SPEC),
                       skip_embedded_spec=True,
          decoded_processor=print_and_count_decoded,
          decoded_processor_data=data,
          decoded_processor_level=level)
    assert data["counter"] == [1, 2, 5][level]

