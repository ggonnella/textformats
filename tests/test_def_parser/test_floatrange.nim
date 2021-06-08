import unittest
import options, json
import yaml/dom
import textformats/types / [datatype_definition, textformats_error]
import textformats/support/yaml_support
import textformats/dt_floatrange/floatrange_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_floatrange_def_parser":
  var
    v = get_datatypes("floatrange_valid.yaml")
    i = get_datatypes("floatrange_invalid.yaml")
  test "f_empty":
    let d = new_floatrange_datatype_definition(v["f_empty"], "f_empty")
    check d.kind == ddkFloatRange
    check d.min_f == -Inf
    check d.min_incl == true
    check d.max_f == Inf
    check d.max_incl == true
    check d.null_value.is_none
  test "f_min_i":
    let d = new_floatrange_datatype_definition(v["f_min_i"], "f_min_i")
    check d.kind == ddkFloatRange
    check d.min_f == 1.0
    check d.min_incl == true
    check d.max_f == Inf
    check d.max_incl == true
    check d.null_value.is_none
  test "f_min_e":
    let d = new_floatrange_datatype_definition(v["f_min_e"], "f_min_e")
    check d.kind == ddkFloatRange
    check d.min_f == 1.0
    check d.min_incl == false
    check d.max_f == Inf
    check d.max_incl == true
    check d.null_value.is_none
  test "f_max_i":
    let d = new_floatrange_datatype_definition(v["f_max_i"], "f_max_i")
    check d.kind == ddkFloatRange
    check d.min_f == -Inf
    check d.min_incl == true
    check d.max_f == 1.0
    check d.max_incl == true
    check d.null_value.is_none
  test "f_max_e":
    let d = new_floatrange_datatype_definition(v["f_max_e"], "f_max_e")
    check d.kind == ddkFloatRange
    check d.min_f == -Inf
    check d.min_incl == true
    check d.max_f == 1.0
    check d.max_incl == false
    check d.null_value.is_none
  test "f_min_max_i":
    let d = new_floatrange_datatype_definition(v["f_min_max_i"], "f_min_max_i")
    check d.kind == ddkFloatRange
    check d.min_f == 0.0
    check d.min_incl == true
    check d.max_f == 1.0
    check d.max_incl == true
    check d.null_value.is_none
  test "f_min_max_e":
    let d = new_floatrange_datatype_definition(v["f_min_max_e"], "f_min_max_e")
    check d.kind == ddkFloatRange
    check d.min_f == 0.0
    check d.min_incl == false
    check d.max_f == 1.0
    check d.max_incl == false
    check d.null_value.is_none
  test "f_n":
    let d = new_floatrange_datatype_definition(v["f_n"], "f_n")
    check d.kind == ddkFloatRange
    check d.min_f == 0.0
    check d.min_incl == true
    check d.max_f == Inf
    check d.max_incl == true
    check d.null_value == (%*(-1.0)).some
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_floatrange_datatype_definition(i[dn], dn)
