import json
import ../types / [datatype_definition, textformats_error]

template decode_anystring*(input: string, dd: DatatypeDefinition): JsonNode =
  if input.len == 0:
    raise newException(DecodingError, "Error: empty string found\n" &
                       "Expected: string, not empty\n")
  %*input
