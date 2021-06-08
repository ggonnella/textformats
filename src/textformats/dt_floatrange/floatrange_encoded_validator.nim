import strutils
import ../types/datatype_definition

proc floatrange_is_valid*(input: string, dd: DatatypeDefinition): bool =
  try:
    var f = parse_float(input)
    return (f > dd.minf or (dd.min_incl and f == dd.minf)) and
           (f < dd.maxf or (dd.max_incl and f == dd.maxf))
  except ValueError:
    return false
