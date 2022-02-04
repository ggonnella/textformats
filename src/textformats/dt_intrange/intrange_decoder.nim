import strutils, strformat, json
import ../types/datatype_definition
import ../support/openrange
import ../shared/num_decoder

proc decode_intrange*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkIntRange
  let val = decode_int(input)
  if not dd.range_i.contains(val):
    raise newException(DecodingError,
            "Error: Integer value outside range limits\n" &
            &"Integer value: {val}\n" &
            &"Minimum value: {dd.range_i.low}\n" &
            &"Maximum value: {dd.range_i.high}\n")
  return %*val
