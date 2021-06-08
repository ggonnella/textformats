import json
export `%*`
import options
export is_none, unsafe_get
import ../types/datatype_definition
export DatatypeDefinition

template translated*(value: untyped,
                     dd: DatatypeDefinition, i = 0): JsonNode =
  if dd.decoded[i].is_none: %*value
  else: %*(dd.decoded[i].unsafe_get)
