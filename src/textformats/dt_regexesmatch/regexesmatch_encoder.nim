import json, options, tables, strutils
import regex
import ../support/json_support
import ../types / [datatype_definition, textformats_error]

proc regexesmatch_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_scalar:
    raise newException(EncodingError, "Error: value is not a scalar\n" &
                       value.describe_kind & "\n")
  if dd.encoded.is_some:
    if value in dd.encoded.unsafe_get:
      return dd.encoded.unsafe_get[value]
  for i, r in dd.regexes_compiled:
    if dd.decoded[i].is_some:
      # if value == decoded[i] then it must be already in the encoded map
      # (this is validated by the spec_parser)
      assert(dd.decoded[i].unsafe_get != value)
    else:
      if value.is_string and value.get_str.match(r):
        return $value.get_str
  raise newException(EncodingError,
      "Error: value does not match any of the specified regular expressions\n" &
      "Regular expressions: " & dd.regexes_raw.join(", ") & "\n")

proc regexesmatch_unsafe_encode*(
         value: JsonNode, dd: DatatypeDefinition): string =
  assert(value.is_scalar)
  if dd.encoded.is_some:
    if value in dd.encoded.unsafe_get:
      return dd.encoded.unsafe_get[value]
  assert(value.is_string)
  for i, r in dd.regexes_compiled:
    if value.get_str.match(r):
      return $value.get_str
  assert(false)
