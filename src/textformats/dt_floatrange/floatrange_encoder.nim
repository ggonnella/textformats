import json
import ../types / [datatype_definition, textformats_error, validity_report]
import floatrange_decoded_validator

proc floatrange_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  let r = value.floatrange_validity_report(dd)
  if r.valid: return $value.get_float
  else: raise newException(EncodingError, r.errmsg)

