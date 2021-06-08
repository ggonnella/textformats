import ../types / [datatype_definition, textformats_error]
import tags_decoder

proc tags_is_valid*(input: string, dd: DatatypeDefinition): bool =
  try:
    discard input.decode_tags(dd)
    return true
  except DecodingError:
    return false
