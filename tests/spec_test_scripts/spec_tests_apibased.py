#!/usr/bin/env python3
"""
Run all tests for a specification using the textformats Python API

Usage:
  spec_tests_apibased.py [-q] <spec> <tests>

Arguments:
  <spec>:  the yaml file containing the specification
  <tests>: the yaml file containing the tests

Options:
  -q, --quiet   suppress stderr output
  -h, --help    show this help message
  --version     show version number
"""

import yaml
import json
import textformats
import sys
from docopt import docopt

def get_as_list(d, key):
  result = d.get(key, [])
  return result if isinstance(result, list) else [result]

def test_decode(datatype_def, encoded, decoded):
  decode_result = datatype_def.decode(encoded)
  if decode_result != decoded:
    sys.stderr.write("Error: decode result is not as expected\n"+
            "Decoded: '{}'\nEncoded: '{}'\nResult of decode(): '{}'\n".
         format(decoded, encoded, decode_result))
    exit(1)
  else:
    sys.stderr.write("Successfully decoded '{}' ({}) to '{}'\n".
         format(encoded, datatype_def.name, decode_result))

def test_encode(datatype_def, encoded, decoded):
  encode_result = datatype_def.encode(decoded)
  if encode_result != encoded:
    sys.stderr.write("Error: encode result is not as expected\n"+
            "Decoded: '{}'\nEncoded: '{}'\nResult of encode(): '{}'\n".
         format(decoded, encoded, encode_result))
    exit(1)
  else:
    sys.stderr.write("Successfully encoded '{}' ({}) to '{}'\n".
         format(decoded, datatype_def.name, encode_result))

def test_encode_invalid(datatype_def, decoded):
    try:
      encoded = datatype_def.encode(decoded)
      sys.stderr.write("Unexpectedly succeded to encode invalid '{}' ({})\n".
         format(decoded, datatype_def.name))
      exit(1)
    except:
      sys.stderr.write("Successfully failed to encode invalid '{}' ({})\n".
         format(decoded, datatype_def.name))

def test_decode_invalid(datatype_def, encoded):
    try:
      decoded = datatype_def.decode(encoded)
      sys.stderr.write("Unexpectedly succeded to decode invalid '{}' ({})\n".
         format(encoded, datatype_def.name))
      exit(1)
    except:
      sys.stderr.write("Successfully failed to encode invalid '{}' ({})\n".
         format(encoded, datatype_def.name))

def test_validate_decoded(datatype_def, decoded, expect_valid):
  if expect_valid:
    if not datatype_def.is_valid_decoded(decoded):
      sys.stderr.write("Error: {} is not valid as it was expected\n".
           format(decoded))
      exit(1)
    else:
      sys.stderr.write("Successfully validated decoded '{}' ({})\n".
           format(decoded, datatype_def.name))
  else:
    if datatype_def.is_valid_decoded(decoded):
      sys.stderr.write("Error: {} is not invalid as it was expected\n".
           format(decoded))
      exit(1)
    else:
      sys.stderr.write("Success: decoded '{}' ({}) invalid as expected\n".
           format(decoded, datatype_def.name))

def test_validate_encoded(datatype_def, encoded, expect_valid):
  if expect_valid:
    if not datatype_def.is_valid_encoded(encoded):
      sys.stderr.write("Error: {} is not valid as it was expected\n".
           format(encoded))
      exit(1)
    else:
      sys.stderr.write("Successfully validated encoded '{}' ({})\n".
           format(encoded, datatype_def.name))
  else:
    if datatype_def.is_valid_encoded(encoded):
      sys.stderr.write("Error: {} is not invalid as it was expected\n".
           format(encoded))
      exit(1)
    else:
      sys.stderr.write("Success: encoded '{}' ({}) invalid as expected\n".
           format(encoded, datatype_def.name))

def test_valid(datatype_def, encoded, decoded):
  test_decode(datatype_def, encoded, decoded)
  test_validate_decoded(datatype_def, decoded, True)
  test_encode(datatype_def, encoded, decoded)
  test_validate_encoded(datatype_def, encoded, True)

def test_invalid_encoded(datatype_def, encoded):
  test_decode_invalid(datatype_def, encoded)
  test_validate_encoded(datatype_def, encoded, False)

def test_invalid_decoded(datatype_def, decoded):
  test_encode_invalid(datatype_def, decoded)
  test_validate_decoded(datatype_def, decoded, False)

def test_all_invalid(datatype_def, tests):
  if "invalid" in tests:
    if isinstance(tests["invalid"], dict):
      for encoded in get_as_list(tests["invalid"], "encoded"):
        test_invalid_encoded(datatype_def, encoded)
      for decoded in get_as_list(tests["invalid"], "decoded"):
        test_invalid_decoded(datatype_def, decoded)
    else:
      for item in get_as_list(tests, "invalid"):
        test_invalid_encoded(datatype_def, item)
        test_invalid_decoded(datatype_def, item)

def test_all_valid(datatype_def, tests):
  if "valid" in tests:
    if isinstance(tests["valid"], dict):
      for encoded, decoded in tests["valid"].items():
        test_valid(datatype_def, encoded, decoded)
    else:
      for item in get_as_list(tests, "valid"):
        test_valid(datatype_def, item, item)

def main(arguments):
  spec = textformats.Specification(arguments["<spec>"])
  with open(arguments["<tests>"]) as f:
    for doc in yaml.safe_load_all(f):
      data = doc
      # anything after the first document (if there is) can be data
      # in an embedded spec, thus skip it
      break
    for datatype, tests in data["testdata"].items():
      datatype_def = spec[datatype]
      test_all_valid(datatype_def, tests)
      test_all_invalid(datatype_def, tests)
  sys.stderr.write("\nAll tests completed with no errors\n")

if __name__ == "__main__":
  arguments = docopt(__doc__, version="0.1")
  main(arguments)

