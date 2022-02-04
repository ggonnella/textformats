import json, strformat
import ../types / [datatype_definition, validity_report]
import ../support / [json_support, openrange]

proc intrange_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  value.is_int and (value.get_biggest_int.int64 in dd.range_i)

proc intrange_validity_report*(value: JsonNode,
                               dd: DatatypeDefinition):
                               ValidityReport =
  result.valid = true
  result.register("value is an integer", value.is_int, value.describe_kind)
  if result.valid:
    result.register("value >= range mininum",
                    value.get_biggest_int.int64.valid_min(dd.range_i),
                    &"minimum valid value: {dd.range_i.lowstr}")
    result.register("value <= range maxinum",
                    value.get_biggest_int.int64.valid_max(dd.range_i),
                    &"maximum valid value: {dd.range_i.highstr}")
