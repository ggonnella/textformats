import json
import ../types/datatype_definition

proc json_is_valid*(input: string, dd: DatatypeDefinition): bool =
  try:
    discard parse_json(input)
    return true
  except JsonParsingError:
    return false

