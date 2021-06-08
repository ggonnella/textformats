import re
import json
import strutils

proc match_cigars*(filename: string): int =
  let cigarop_regex = re(r"(\d+)([MDIP])")
  let f = open(filename)
  for line in lines(f):
    var
      cigar = line
      boundaries: tuple[first, last: int] = (-1, 0)
      c: array[2, (int, int)]
      expected_start = 0
      results = newJArray()
    stripLineEnd(cigar)
    while true:
      boundaries = cigar.find_bounds(cigarop_regex, c, boundaries.first+1)
      if boundaries.first < 0: break
      if boundaries.first > expected_start:
        raise newException(ValueError, "Something is between elements\n")
      expected_start = boundaries.last+1
      let length = cigar[c[0][0]..c[0][1]].parse_int
      let code = cigar[c[1][0]..c[1][1]]
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
