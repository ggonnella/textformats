import json, strformat, options, tables
import regex
import ../support/json_support
import ../types / [datatype_definition, textformats_error]

proc regexmatch_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_scalar:
    raise newException(EncodingError, "Error: value is not a scalar\n" &
                       value.describe_kind & "\n")
  if dd.encoded.is_some:
    if value in dd.encoded.unsafe_get:
      return dd.encoded.unsafe_get[value]
  let decoded = dd.decoded[0]
  if decoded.is_some:
    # if value == decoded then it must be already in the encoded map
    # (this is validated by the spec_parser)
    assert(decoded.unsafe_get != value)
    raise newException(EncodingError,
               "Error: value does not match the specified required value\n" &
               &"Required value (as JSON): {decoded.unsafe_get}\n")
  if not value.is_string:
    raise newException(EncodingError, "Error: value is not a string\n" &
                       value.describe_kind & "\n")
  if not value.get_str.match(dd.regex.compiled):
    raise newException(EncodingError,
               "Error: value does not match the " &
               "specified regular expression\n" &
               &"Regular expression: {dd.regex.raw}\n")
  return $value.get_str

proc regexmatch_unsafe_encode*(value: JsonNode,
                               dd: DatatypeDefinition): string =
  if dd.encoded.is_some:
    if value in dd.encoded.unsafe_get:
      return dd.encoded.unsafe_get[value]
  assert value.is_string
  return $value.get_str
