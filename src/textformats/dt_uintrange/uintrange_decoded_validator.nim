import json, options, strformat
import ../types / [datatype_definition, validity_report]
import ../support / [json_support, openrange]

proc uintrange_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  if value.is_int and value.get_biggest_int >= 0:
    value.get_biggest_int.uint64 in dd.range_u
  else:
    false

proc uintrange_validity_report*(value: JsonNode,
                               dd: DatatypeDefinition):
                               ValidityReport =
  result.valid = true
  result.register("value is an integer", value.is_int, value.describe_kind)
  result.register("value is >= 0", value.get_biggest_int >= 0)
  if result.valid:
    let u = value.get_biggest_int.uint64
    result.register("value >= range mininum", u.valid_min(dd.range_u),
                    &"minimum valid value: {dd.range_u.lowstr}")
    result.register("value <= range maxinum", u.valid_max(dd.range_u),
                    &"maximum valid value: {dd.range_u.highstr}")
