#!/usr/bin/env python3
"""
Run specification tests using TextFormats CLI tf_test tool

Note:
  this is much slower than using tf_spec and
  should only be used for debugging

Usage:
  tf_test_spec.py [options] <spec> <tests>

Arguments:
  <spec>:  the yaml file containing the specification
  <tests>: the yaml file containing the tests

Options:
  -p, --precompile  compile the specification
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
textformats = sh.Command(testdir + "/../../cli/tf_test")
precompile = partial(textformats, "compile", _fg=True)
test_decode = partial(textformats, "decoding", _fg=True)
test_encode = partial(textformats, "encoding", _fg=True)
test_validate_decoded = partial(textformats, "decoded_validation", _fg=True)
test_validate_encoded = partial(textformats, "encoded_validation", _fg=True)
test_decode_invalid = partial(textformats, "fail_decoding", _fg=True)
test_encode_invalid = partial(textformats, "fail_encoding", _fg=True)

def test_valid_encoded(specfile, datatype, encoded, decoded):
  test_decode(s=specfile, t=datatype, e=encoded, d=decoded)
  test_validate_encoded(s=specfile, t=datatype, e=encoded, v=True)

def test_valid_decoded(specfile, datatype, encoded, decoded):
  test_encode(s=specfile, t=datatype, e=encoded, d=decoded)
  test_validate_decoded(s=specfile, t=datatype, d=decoded, v=True)

def test_invalid_encoded(specfile, datatype, encoded):
  test_decode_invalid(s=specfile, t=datatype, e=encoded)
  test_validate_encoded(s=specfile, t=datatype, e=encoded, v=False)

def test_invalid_decoded(specfile, datatype, decoded):
  test_encode_invalid(s=specfile, t=datatype, d=decoded)
  test_validate_decoded(s=specfile, t=datatype, d=decoded, v=False)

def get_as_list(d, key):
  result = d.get(key, [])
  return result if isinstance(result, list) else [result]

def test_all_invalid(specfile, datatype, tests):
  key = "invalid"
  if key in tests:
    if isinstance(tests[key], dict):
      for encoded in get_as_list(tests[key], "encoded"):
        test_invalid_encoded(specfile, datatype, encoded)
      for decoded in get_as_list(tests[key], "decoded"):
        test_invalid_decoded(specfile, datatype, json.dumps(decoded))
    else:
      for item in get_as_list(tests, key):
        test_invalid_encoded(specfile, datatype, item)
        test_invalid_decoded(specfile, datatype, json.dumps(item))

def test_all_valid(specfile, datatype, tests):
  key = "valid"
  if key in tests:
    if isinstance(tests[key], dict):
      for encoded, decoded in tests[key].items():
        test_valid_encoded(specfile, datatype, encoded, json.dumps(decoded))
        test_valid_decoded(specfile, datatype, encoded, json.dumps(decoded))
    else:
      for item in get_as_list(tests, key):
        test_valid_encoded(specfile, datatype, item, json.dumps(item))
        test_valid_decoded(specfile, datatype, item, json.dumps(item))

def test_all_secondary(specfile, datatype, tests):
  key = "oneway"
  if key in tests:
    for encoded, decoded in tests[key].items():
      test_valid_encoded(specfile, datatype, encoded, json.dumps(decoded))

def main(arguments):
  specfile = arguments["<spec>"]
  precompile=arguments["--precompile"]
  mainkey="testdata"
  if precompile:
    precompiled_specfile=os.path.splitext(specfile)[0]+".tfs"
    precompile(s=specfile, o=precompiled_specfile)
    specfile=precompiled_specfile
  with open(arguments["<tests>"]) as f:
    for doc in yaml.safe_load_all(f):
      data = doc
      # anything after the first document (if there is) can be data
      # in an embedded spec, thus skip it
      break
    for datatype, tests in data[mainkey].items():
      test_all_valid(specfile, datatype, tests)
      test_all_secondary(specfile, datatype, tests)
      test_all_invalid(specfile, datatype, tests)

if __name__ == "__main__":
  arguments = docopt.docopt(__doc__, version="0.1")
  main(arguments)

