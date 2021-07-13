import strutils
import ../support/openrange
import ../types/datatype_definition
import ../shared/num_decoder

proc uintrange_is_valid*(input: string, dd: DatatypeDefinition): bool =
  try:
    let val = decode_int(input, dd.base)
    if val < 0:
      return false
    else:
      return val.uint64 in dd.range_u
  except DecodingError:
    return false
