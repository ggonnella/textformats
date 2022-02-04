import strutils
import strformat
import json
import ../types / [datatype_definition, textformats_error]
import ../support/openrange
import ../shared/num_decoder

proc decode_uintrange*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkUIntRange
  let val = decode_int(input, dd.base)
  if val < 0:
    raise newException(DecodingError,
            "Error: negative integer value for unsigned integer\n" &
            "Expected: non-negative integer\n" &
            "Found: " & $val & "\n")
  if not dd.range_u.contains(val.uint64):
    raise newException(DecodingError,
            "Error: unsigned integer value outside range limits\n" &
            &"Unsigned integer value: {val}\n" &
            &"Minimum value: {dd.range_u.lowstr}\n" &
            &"Maximum value: {dd.range_u.highstr}\n")
  %*(val)
