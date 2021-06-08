import json, options, strformat
import ../types / [datatype_definition, validity_report]
import ../support/json_support

template floatrange_min_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  value.get_float > dd.minf or (dd.min_incl and value.get_float == dd.minf)

template floatrange_max_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  value.get_float < dd.maxf or (dd.max_incl and value.get_float == dd.maxf)

template floatrange_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  value.is_float and
    value.floatrange_min_is_valid(dd) and
      value.floatrange_max_is_valid(dd)

proc floatrange_validity_report*(value: JsonNode,
                                 dd: DatatypeDefinition):
                                 ValidityReport =
  result.valid = true
  result.register("value is a float", value.is_float, value.describe_kind)
  if result.valid:
    let minincl = if dd.min_incl: "included" else: "excluded"
    result.register("value range mininum", value.floatrange_min_is_valid(dd),
                    &"minimum valid value: {dd.minf} ({minincl})")
    let maxincl = if dd.max_incl: "included" else: "excluded"
    result.register("value range maxinum", value.floatrange_max_is_valid(dd),
                    &"maximum valid value: {dd.maxf} ({maxincl})")
