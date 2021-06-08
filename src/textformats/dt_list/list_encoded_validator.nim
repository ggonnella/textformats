import ../types / [datatype_definition, textformats_error]
import ../decoder

proc list_is_valid*(input: string, dd: DatatypeDefinition): bool =
  try:
    discard input.decode(dd)
    return true
  except DecodingError:
    return false

