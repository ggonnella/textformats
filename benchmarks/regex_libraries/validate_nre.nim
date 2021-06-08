import nre
import strutils

proc match_cigars*(filename: string): int =
  let cigar_regex = re(r"(?:(?:\d+)(?:[MDIP]))+")
  let f = open(filename)
  for line in lines(f):
    var cigar = line
    stripLineEnd(cigar)
    let m = cigar.match(cigar_regex)
    if m.isNone or m.get.match_bounds.b != cigar.len-1:
      raise newException(ValueError, "error")
  return 0

template short_filename: untyped = 'i'

when isMainModule:
  import cligen
  let
    help_filename = "filename with input data"
  dispatch(match_cigars,
                  short = {"filename": short_filename},
                  help = {"filename": help_filename})
