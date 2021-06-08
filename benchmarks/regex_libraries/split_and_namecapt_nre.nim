import nre
import json
import strutils

proc match_cigars*(filename: string): int =
  let cigarop_regex = re(r"(?P<length>\d+)(?P<code>[MDIP])")
  let f = open(filename)
  for line in lines(f):
    var
      cigar = line
      expected_start = 0
      results = newJArray()
    stripLineEnd(cigar)
    for m in cigar.find_iter(cigarop_regex):
      if m.match_bounds.a > expected_start:
        raise newException(ValueError, "Something is between elements\n")
      expected_start = m.match_bounds.b+1
      let
        length = parse_int(cigar[m.captureBounds["length"]])
        code = cigar[m.captureBounds["code"]]
      var cigarop = newJObject()
      cigarop["length"] = %*length
      cigarop["code"] = %*code
      results.add(cigarop)
    if expected_start != cigar.len:
      raise newException(ValueError, "Something is after the last element\n")
  return 0

template short_filename: untyped = 'i'

when isMainModule:
  import cligen
  let
    help_filename = "filename with input data"
  dispatch(match_cigars,
                  short = {"filename": short_filename},
                  help = {"filename": help_filename})
