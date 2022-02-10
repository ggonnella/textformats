import json, strformat, strutils, options
import ../types / [datatype_definition, match_element]
import ../shared / [translation_decoder, num_decoder]
export translated

template prematched_decode_const*(input: string, slice: Slice[int],
                 dd: DatatypeDefinition, m: untyped, childnum: int,
                 groupspfx: string): JsonNode =
  input[slice].translated(dd)

template validate_constant(value, constant, typestr): untyped =
  if value == constant:
    return value.translated(dd)
  else:
    raise newException(DecodingError, "Expected constant: " & $constant &
                       " (" & typestr & "), found: " & $value & "\n")

proc decode_const*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkConst
  case dd.constant_element.kind:
  of meString:
    validate_constant(input, dd.constant_element.s_value, "string")
  of meFloat:
    let value = decode_float(input)
    validate_constant(value, dd.constant_element.f_value, "float")
  of meInt:
    let value = decode_int(input)
    validate_constant(value, dd.constant_element.i_value, "integer")
