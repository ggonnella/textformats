## Parse of encoded data of an "one_of" type, one per line, from a file

# standard library
from tables import keys, contains, `[]`
from strutils import stripLineEnd
from json import `$`, parse_json, JsonNode, `==`, JsonParsingError
#import nimprof
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

proc run_decode*(specfile: string, datatype: string, filename: string): int =
  let definition = get_datatype_definition(datatype)
  try:
    let f = open(filename)
    var
      fourlines: string
      i = 0
    for line in lines(f):
      if i < 3:
        fourlines &= line & "\n"
        i += 1
      else:
        echo (fourlines & line).decode(definition)
        fourlines = ""
        i = 0
    if i > 0:
      raise newException(ValueError, "Wrong number of lines\n")
  except ValueError:
    exit_with(ec_invalid_data_for_datatype, getCurrentExceptionMsg())

template short_specfile: untyped = 's'
template short_datatype: untyped = 't'
template short_filename: untyped = 'i'

when isMainModule:
  import cligen
  let
    help_specfile = "datatypes specification YAML file"
    help_datatype = "datatype"
    help_filename = "filename with input data"
  dispatch(run_decode,
                  short = {"specfile":     short_specfile,
                           "datatype":     short_datatype,
                           "filename": short_filename},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "filename": help_filename})
