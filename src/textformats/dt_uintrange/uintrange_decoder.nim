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
               "Negative value (" & $val & ") found, expected: non-negative\n")
  if not dd.range_u.contains(val.uint64):
    raise newException(DecodingError, &"Value ({val}) outside range limits: " &
            &"{dd.range_u.lowstr}..{dd.range_u.highstr}\n")
  %*(val)
