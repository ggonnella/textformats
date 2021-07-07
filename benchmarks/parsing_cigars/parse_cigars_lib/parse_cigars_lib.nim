## Benchmark parsing of encoded data all of same type, one per line, from a file

# standard library
from tables import keys, contains, `[]`
from strutils import stripLineEnd
from json import `$`, parse_json, JsonNode, `==`, JsonParsingError
# external libraries
import nimpy
# this library
from textformats import specification_from_file, decode

type
  ExitCode = enum
    ec_success
    ec_invalid_data_for_datatype="The provided data is not valid according to the datatype specification"
    ec_datatype_not_in_specification="The specification does not include the datatype"

template exit_with(exit_code: untyped, info = ""): untyped =
  let `info` = info # local copy, to avoid multiple evaluation
  if exit_code != ec_success:
    stderr.write_line $exit_code
  if info.len > 0:
    stderr.write_line $info
  return exit_code.int

template get_datatype_definition(datatype: untyped): untyped =
  let datatypes = specification_from_file(specfile)
  if datatype notin datatypes:
    exit_with ec_datatype_not_in_specification
    nil
  else: datatypes[datatype]

proc run_decode*(specfile: string, datatype: string, filename: string): int {.exportpy.} =
  let definition = get_datatype_definition(datatype)
  try:
    let f = open(filename)
    for line in lines(f):
      var encoded = line
      stripLineEnd(encoded)
      echo $encoded.decode(definition)
  except ValueError:
    exit_with(ec_invalid_data_for_datatype, getCurrentExceptionMsg())

