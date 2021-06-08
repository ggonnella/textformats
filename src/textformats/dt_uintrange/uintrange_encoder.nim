import json
import ../types / [datatype_definition, textformats_error, validity_report]
import uintrange_decoded_validator

proc uintrange_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  let r = value.uintrange_validity_report(dd)
  if r.valid: return $value.get_int
  else: raise newException(EncodingError, r.errmsg)
