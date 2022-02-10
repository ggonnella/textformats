import json, options, tables, strutils
import ../types / [datatype_definition, textformats_error]
import ../shared/matchelement_encoder

proc enum_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if dd.encoded.is_some:
    if value in dd.encoded.unsafe_get:
      return dd.encoded.unsafe_get[value]
  var encoded: string
  for i, me in dd.elements:
    if dd.decoded[i].is_some:
      if encode_match_elem_with_decoded(value,
                                        dd.decoded[i].unsafe_get,
                                        me, encoded):
        return encoded
    else:
      if encode_match_elem_wo_decoded(value, me, encoded):
        return encoded
  raise newException(EncodingError, "Found value {value}, expected one of: " &
          ($dd.elements).join(", ") & "\n")

proc enum_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if dd.encoded.is_some:
    if value in dd.encoded.unsafe_get:
      return dd.encoded.unsafe_get[value]
  var encoded: string
  for i, me in dd.elements:
    if dd.decoded[i].is_some:
      if encode_match_elem_with_decoded(value,
                                        dd.decoded[i].unsafe_get,
                                        me, encoded):
        return encoded
    else:
      if encode_match_elem_wo_decoded(value, me, encoded):
        return encoded
  assert(false)
