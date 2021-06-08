import json
import strformat
import options
import ../support/json_support
import ../types / [datatype_definition, textformats_error]
import ../shared/matchelement_encoder

proc const_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_scalar:
    raise newException(EncodingError,
            "Error: value is not a scalar value\n" &
            value.describe_kind & "\n")
  var encoded: string
  if dd.decoded[0].is_some:
    if encode_match_elem_with_decoded(value,
                                      dd.decoded[0].unsafe_get,
                                      dd.constant_element, encoded):
      return encoded
  else:
    if encode_match_elem_wo_decoded(value, dd.constant_element, encoded):
      return encoded
  raise newException(EncodingError,
              "Error: value does not match specified constant\n" &
              &"Constant: {dd.constant_element}\n")

proc const_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  var encoded: string
  if dd.decoded[0].is_some:
    if encode_match_elem_with_decoded(value,
                                      dd.decoded[0].unsafe_get,
                                      dd.constant_element, encoded):
      return encoded
  else:
    if encode_match_elem_wo_decoded(value, dd.constant_element, encoded):
      return encoded
  assert(false)
