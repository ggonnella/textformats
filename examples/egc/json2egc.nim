import os, json, strutils
import textformats

const HelpMsg = """
Parse EGC data from JSON and output its content in EGC format

Usage: $# <inputfile> <inputspec>

Arguments:
  <inputfile>  Input file in Json format
  <inputspec>  Specification file describing the EGC format
"""

proc parse_args(): (string, Specification) =
  if (paramCount() != 2):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  result[0] = paramStr(1)
  result[1] = specification_from_file(paramStr(2))

when isMainModule:
  try:
    let
      (input_file, spec) = parse_args()
      ddef = get_definition(spec, "file")
      input_data = parse_json(read_file(input_file))
    echo(input_data.encode(ddef))
    quit(0)
  except:
    echo(getCurrentExceptionMsg())
    quit(1)
