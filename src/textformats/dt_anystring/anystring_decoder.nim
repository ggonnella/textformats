import json
import ../types / [datatype_definition, textformats_error]

template decode_anystring*(input: string, dd: DatatypeDefinition): JsonNode =
  if input.len == 0:
    raise newException(DecodingError, "Missing required string\n")
  %*input
