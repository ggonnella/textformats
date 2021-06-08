import nregex
import strutils

proc match_cigars*(filename: string): int =
  let cigarop_regex = re(r"(?:\d+)(?:[MDIP])")
  let f = open(filename)
  for line in lines(f):
    var
      cigar = line
      expected_start = 0
    stripLineEnd(cigar)
    for m in cigar.find_all(cigarop_regex):
      if m.boundaries.a > expected_start:
        raise newException(ValueError, "Something is between elements\n")
      expected_start = m.boundaries.b+1
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
