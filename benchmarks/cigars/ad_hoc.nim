import strutils, os, json
import opstats

const HelpMsg = """
Computes some stats on each line of a file containing CIGAR strings
This version is implemented without using TextFormats

Usage:
  $# <inputfn>

Arguments:
  <inputfn>      filename of encoded strings, one per line
"""

type
  CigarOp = object
    code: char
    length: int

proc parse_args(): string =
  if (paramCount() != 1):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  result = paramStr(1)

proc compute_and_print_stats(cigar: seq[CigarOp]) =
  var
    opstats_m = newOpStats("M")
    opstats_i = newOpStats("I")
    opstats_d = newOpStats("D")
  for cigar_op in cigar:
    if cigar_op.code == 'M':
      opstats_m.process_op(cigar_op.length)
    elif cigar_op.code == 'I':
      opstats_i.process_op(cigar_op.length)
    elif cigar_op.code == 'D':
      opstats_d.process_op(cigar_op.length)
    else:
      assert(false)
  print_all_opstats(opstats_m, opstats_i, opstats_d)

proc parse_cigarstr_charwise(line: string): seq[CigarOp] =
  var oplenstr = ""
  result = newSeq[CigarOp]()
  for c in line:
    if c.isdigit():
      oplenstr &= c
    else:
      if c notin @['M', 'I', 'D']:
        raise newException(ValueError, "unknown operation")
      let oplen = parse_int(oplenstr)
      if not oplen > 0:
        raise newException(ValueError, "Wrong operation length")
      result.add(CigarOp(code: c, length: oplen))
      oplenstr = ""
  if len(result) == 0:
    raise newException(ValueError, "Wrong number of cigar operations")

when isMainModule:
  try:
    let
      input_file = parse_args()
      file = open(input_file)
    for line in file.lines():
      let cigar = parse_cigarstr_charwise(line)
      compute_and_print_stats(cigar)
    quit(0)
  except:
    echo(getCurrentExceptionMsg())
    quit(1)
