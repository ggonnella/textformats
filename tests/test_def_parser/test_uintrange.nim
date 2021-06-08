import unittest
import options, json
import yaml/dom
import textformats/types / [datatype_definition, textformats_error]
import textformats/support / [yaml_support, openrange]
import textformats/dt_uintrange/uintrange_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_uintrange_def_parser":
  var
    v = get_datatypes("uintrange_valid.yaml")
    i = get_datatypes("uintrange_invalid.yaml")
  test "u_empty":
    let d = new_uintrange_datatype_definition(v["u_empty"], "u_empty")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "0"
    check d.range_u.highstr == OpenrangeInfStr
    check d.null_value.is_none
  test "u_min_i":
    let d = new_uintrange_datatype_definition(v["u_min_i"], "u_min_i")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "1"
    check d.range_u.highstr == OpenrangeInfStr
    check d.null_value.is_none
  test "u_min_e":
    let d = new_uintrange_datatype_definition(v["u_min_e"], "u_min_e")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "2"
    check d.range_u.highstr == OpenrangeInfStr
    check d.null_value.is_none
  test "u_max_i":
    let d = new_uintrange_datatype_definition(v["u_max_i"], "u_max_i")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "0"
    check d.range_u.highstr == "4"
    check d.null_value.is_none
  test "u_max_e":
    let d = new_uintrange_datatype_definition(v["u_max_e"], "u_max_e")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "0"
    check d.range_u.highstr == "3"
    check d.null_value.is_none
  test "u_min_max_i":
    let d = new_uintrange_datatype_definition(v["u_min_max_i"], "u_min_max_i")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "1"
    check d.range_u.highstr == "4"
    check d.null_value.is_none
  test "u_min_max_e":
    let d = new_uintrange_datatype_definition(v["u_min_max_e"], "u_min_max_e")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "2"
    check d.range_u.highstr == "3"
    check d.null_value.is_none
  test "u_n":
    let d = new_uintrange_datatype_definition(v["u_n"], "u_n")
    check d.kind == ddkUintRange
    check d.range_u.lowstr == "1"
    check d.range_u.highstr == OpenrangeInfStr
    check d.null_value == (%*(-1)).some
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_uintrange_datatype_definition(i[dn], dn)
