#!/usr/bin/env python3
"""
Run all tests for a specification using textformats-cli

Usage:
  spec_tests_clibased.py [options] <spec> <tests>

Arguments:
  <spec>:  the yaml file containing the specification
  <tests>: the yaml file containing the tests

Testdata syntax:

testdata:
  <datatype>:
    ... # testdata, see below

# (1) no transformations, decode(string) == string

valid: ["string1", "string2", ...]
invalid: ["string1", "string2", ...]

# (2) bijective transformations, encode(decode(string)) == string
valid: {"encoded1": "decoded1", ...}
invalid:
  encoded: ["encoded3", ...]
  decoded: ["decoded3", ...]

# (3) general case

valid: {"encoded1": "decoded1", ...} # decoding/encoding tested
oneway: {"encoded2": "decoded1", ...} # only decoding tested
invalid:
  encoded: ["encoded3", ...]
  decoded: ["decoded3", ...]

Options:
  -p, --preprocess  preprocess the specification
  -q, --quiet       suppress stderr output
  -h, --help        show this help message
  --version         show version number
"""

import yaml
import json
import sh
import os
import docopt
from functools import partial

testdir = os.path.dirname(os.path.realpath(__file__))
textformats = sh.Command(testdir + "/../cli/textformats_cli")
preprocess = partial(textformats, "preprocess", _fg=True)
test_decode = partial(textformats, "test", "decoding", _fg=True)
test_encode = partial(textformats, "test", "encoding", _fg=True)
test_validate_decoded = partial(textformats, "test", "decoded_validation", _fg=True)
test_validate_encoded = partial(textformats, "test", "encoded_validation", _fg=True)
test_decode_invalid = partial(textformats, "test", "fail_decoding", _fg=True)
test_encode_invalid = partial(textformats, "test", "fail_encoding", _fg=True)

def test_valid_encoded(specfile, preprocessed, datatype, encoded, decoded):
  test_decode(s=specfile, p=preprocessed, t=datatype, e=encoded, d=decoded)
  test_validate_encoded(s=specfile, p=preprocessed, t=datatype, e=encoded,
                        v=True)

def test_valid_decoded(specfile, preprocessed, datatype, encoded, decoded):
  test_encode(s=specfile, p=preprocessed, t=datatype, e=encoded, d=decoded)
  test_validate_decoded(s=specfile, p=preprocessed, t=datatype, d=decoded,
                        v=True)

def test_invalid_encoded(specfile, preprocessed, datatype, encoded):
  test_decode_invalid(s=specfile, p=preprocessed, t=datatype, e=encoded)
  test_validate_encoded(s=specfile, p=preprocessed, t=datatype, e=encoded,
                        v=False)

def test_invalid_decoded(specfile, preprocessed, datatype, decoded):
  test_encode_invalid(s=specfile, p=preprocessed, t=datatype, d=decoded)
  test_validate_decoded(s=specfile, p=preprocessed, t=datatype, d=decoded,
                        v=False)

def get_as_list(d, key):
  result = d.get(key, [])
  return result if isinstance(result, list) else [result]

def test_all_invalid(specfile, preprocessed, datatype, tests):
  key = "invalid"
  if key in tests:
    if isinstance(tests[key], dict):
      for encoded in get_as_list(tests[key], "encoded"):
        test_invalid_encoded(specfile, preprocessed, datatype, encoded)
      for decoded in get_as_list(tests[key], "decoded"):
        test_invalid_decoded(specfile, preprocessed, datatype,
                             json.dumps(decoded))
    else:
      for item in get_as_list(tests, key):
        test_invalid_encoded(specfile, preprocessed, datatype, item)
        test_invalid_decoded(specfile, preprocessed, datatype, json.dumps(item))

def test_all_valid(specfile, preprocessed, datatype, tests):
  key = "valid"
  if key in tests:
    if isinstance(tests[key], dict):
      for encoded, decoded in tests[key].items():
        test_valid_encoded(specfile, preprocessed, datatype, encoded,
                           json.dumps(decoded))
        test_valid_decoded(specfile, preprocessed, datatype, encoded,
                           json.dumps(decoded))
    else:
      for item in get_as_list(tests, key):
        test_valid_encoded(specfile, preprocessed, datatype,
                           item, json.dumps(item))
        test_valid_decoded(specfile, preprocessed, datatype,
                           item, json.dumps(item))

def test_all_secondary(specfile, preprocessed, datatype, tests):
  key = "oneway"
  if key in tests:
    for encoded, decoded in tests[key].items():
      test_valid_encoded(specfile, preprocessed, datatype, encoded,
                         json.dumps(decoded))

def main(arguments):
  specfile = arguments["<spec>"]
  preprocessed=arguments["--preprocess"]
  mainkey="testdata"
  if preprocessed:
    preprocessed_specfile=specfile+".textformats"
    preprocess(s=specfile, o=preprocessed_specfile)
    specfile=preprocessed_specfile
  with open(arguments["<tests>"]) as f:
    data = yaml.safe_load(f)
    for datatype, tests in data[mainkey].items():
      test_all_valid(specfile, preprocessed, datatype, tests)
      test_all_secondary(specfile, preprocessed, datatype, tests)
      test_all_invalid(specfile, preprocessed, datatype, tests)

if __name__ == "__main__":
  arguments = docopt.docopt(__doc__, version="0.1")
  main(arguments)

