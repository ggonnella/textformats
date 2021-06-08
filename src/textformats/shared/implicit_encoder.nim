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
                             "Error: invalid value for implicit key\n" &
                             &"Implicit key: {member.name}\n" &
                             &"Expected value: '{member.value}'\n" &
                             &"Found: '{value[member.name]}'\n")
        value_keys.excl(member.name)
    if value_keys.len > 0:
      raise newException(EncodingError,
                         "Error: invalid keys found in dictionary\n" &
                         &"Invalid key(s): {value_keys}\n")

