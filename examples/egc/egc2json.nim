import os, json, strutils
import textformats

const HelpMsg = """
Parse the EGC format and output its content as JSON

Usage: $# <inputfile> <inputspec>

Arguments:
  <inputfile>  Input file in EGC format
  <inputspec>  Specification file describing the EGC format
"""

proc parse_args(): (string, Specification) =
  if (paramCount() != 2):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  result[0] = paramStr(1)
  result[1] = specification_from_file(paramStr(2))

proc process_decoded(decoded: JsonNode, data: pointer) =
  echo($decoded)

when isMainModule:
  try:
    let
      (input_file, spec) = parse_args()
      ddef = get_definition(spec, "file")
    input_file.decode_file(ddef, false, process_decoded, nil, DplWhole)
    quit(0)
  except:
    echo(getCurrentExceptionMsg())
    quit(1)
