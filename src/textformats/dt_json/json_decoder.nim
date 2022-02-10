import json
import ../types / [datatype_definition, textformats_error]

template decode_json*(input: string, dd: DatatypeDefinition): JsonNode =
  var
    val: JsonNode
    haderr = ""
  try:
    val = input.parse_json
  except JsonParsingError:
    haderr = get_current_exception().msg
  if len(haderr) > 0:
    raise newException(DecodingError, "Inline JSON invalid, error: " & haderr)
  val
