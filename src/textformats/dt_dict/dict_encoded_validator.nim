import ../types / [datatype_definition, textformats_error]
import dict_decoder

proc dict_is_valid*(input: string, dd: DatatypeDefinition): bool =
  try:
    discard input.decode_dict(dd)
    return true
  except DecodingError:
    return false
