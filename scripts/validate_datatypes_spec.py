#!/usr/bin/env python3
"""
Check multitab format specification files

Usage:
  verify_spec.py [-q] <schema> <spec>

Arguments:
  <schema>: "datatypes.validation.yaml"
  <spec>: the yaml file containing the specification

Options:
  -q, --quiet   suppress stderr output
  -h, --help    show this help message
  --version     show version number
"""

import yaml
import docopt
import cerberus
import sys

def main(arguments: dict) -> int:
  with open(arguments["<schema>"]) as f:
    schema = yaml.safe_load(f)
  try:
    validator = CustomValidator(schema)
  except cerberus.schema.SchemaError as e:
    if not arguments["quiet"]:
      sys.stderr.write("Schema Error:\n")
      yaml.dump(e, sys.stdout)
    return 255
  with open(arguments["<spec>"]) as f:
    spec = yaml.safe_load(f)
  if not validator.validate(spec):
    if not arguments["quiet"]:
      sys.stderr.write("Specification Error:\n")
      yaml.dump(validator.errors, sys.stdout)
    return 1
  if not arguments["quiet"]:
    sys.stderr.write("Specification valid\n")
  return 0

if __name__ == "__main__":
  arguments = docopt.docopt(__doc__, version="0.1")
  main(arguments)

