import json
import ../types / [datatype_definition, textformats_error, validity_report]
import uintrange_decoded_validator
import ../shared/num_encoder

proc uintrange_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  let r = value.uintrange_validity_report(dd)
  if r.valid:
    let v = value.get_biggest_int
    return v.encode_int_with_base(dd.base)
  else:
    raise newException(EncodingError, r.errmsg)
