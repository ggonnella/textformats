import strutils, os, json
import textformats
import opstats

const HelpMsg = """
Computes some stats on each line of a file containing CIGAR strings
This version is implemented using TextFormats

Usage:
  $# <inputfn> <specfn> <datatype>

Arguments:
  <inputfn>      filename of encoded strings, one per line
  <specfn>       filename of YAML textformats specification
  <datatype>     datatype to use
"""

proc parse_args(): (string, DatatypeDefinition) =
  if (paramCount() != 3):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  let spec = specification_from_file(paramStr(2))
  result[0] = paramStr(1)
  result[1] = get_definition(spec, paramStr(3))

proc process_decoded(cigar: JsonNode, data: pointer) =
  var
    opstats_m = newOpStats("M")
    opstats_i = newOpStats("I")
    opstats_d = newOpStats("D")
  for cigar_op in cigar:
    if cigar_op["code"].get_str() == "M":
      opstats_m.process_op(cigar_op["length"].get_int())
    elif cigar_op["code"].get_str() == "I":
      opstats_i.process_op(cigar_op["length"].get_int())
    elif cigar_op["code"].get_str() == "D":
      opstats_d.process_op(cigar_op["length"].get_int())
    else:
      assert(false)
  print_all_opstats(opstats_m, opstats_i, opstats_d)

when isMainModule:
  try:
    let (input_file, ddef) = parse_args()
    input_file.decode_file(ddef, false, process_decoded, nil, DplLine)
    quit(0)
  except:
    echo(getCurrentExceptionMsg())
    quit(1)
