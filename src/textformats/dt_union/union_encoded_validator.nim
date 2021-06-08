import ../types/datatype_definition

proc union_is_valid*(input: string, dd: DatatypeDefinition): bool
import ../encoded_validator

proc union_is_valid*(input: string, dd: DatatypeDefinition): bool =
  for c in dd.choices:
    if input.is_valid(c): return true
  return false
