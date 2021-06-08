import json
import ../types / [datatype_definition, textformats_error, validity_report]
import intrange_decoded_validator

proc intrange_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  let r = value.intrange_validity_report(dd)
  if r.valid: return $value.get_int
  else: raise newException(EncodingError, r.errmsg)
