import strutils
import strformat
import json
import ../types / [datatype_definition, textformats_error]
import ../shared/num_decoder

proc decode_floatrange*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkFloatRange
  let val = decode_float(input)
  if val < dd.min_f or (val == dd.min_f and not dd.min_incl) or
     val > dd.max_f or (val == dd.max_f and not dd.max_incl):
    let
      min_incl_str = if dd.min_incl: "included" else: "excluded"
      max_incl_str = if dd.max_incl: "included" else: "excluded"
    raise newException(DecodingError,
            "Error: Float value outside range limits\n" &
            &"Float value: {val}\n" &
            &"Minimum value: {dd.min_f} ({min_incl_str})\n" &
            &"Maximum value: {dd.max_f} ({max_incl_str})\n")
  return %*val
