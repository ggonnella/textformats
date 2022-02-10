import strformat
import json
import sets
import ../types / [datatype_definition, textformats_error]

proc validate_nonmember_keys*(value: JsonNode, value_keys: var HashSet[string],
                       dd: DatatypeDefinition) =
  if len(value_keys) > 0:
    for member in dd.implicit:
      if member.name in value_keys:
        if value[member.name] != member.value:
          raise newException(EncodingError,
                  &"Invalid value '{value[member.name]}' " &
                  &"for '{member.name}' key, expected '{member.value}'\n")
        value_keys.excl(member.name)
    if value_keys.len > 0:
      raise newException(EncodingError,
                         &"Invalid key(s) in dictionary: {value_keys}\n")

