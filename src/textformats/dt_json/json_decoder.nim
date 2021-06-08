import json
import ../types / [datatype_definition, textformats_error]

template decode_json*(input: string, dd: DatatypeDefinition): JsonNode =
  var val: JsonNode
  try:
    val = input.parse_json
  except JsonParsingError:
    let e = get_current_exception()
    raise newException(DecodingError,
                       "Error: invalid inline JSON\n" &
                       "Error reported by the json library:\n" &
                       e.msg)
  val
