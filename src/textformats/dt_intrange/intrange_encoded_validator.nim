import ../types/datatype_definition
import ../support/openrange
import ../shared/num_decoder

proc intrange_is_valid*(input: string, dd: DatatypeDefinition): bool =
  assert dd.kind == ddkIntRange
  let val = decode_int(input)
  return dd.range_i.contains(val)
