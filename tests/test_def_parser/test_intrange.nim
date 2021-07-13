import unittest
import options, json
import yaml/dom
import textformats/types / [datatype_definition, textformats_error]
import textformats/support / [yaml_support, openrange]
import textformats/dt_intrange/intrange_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_intrange_def_parser":
  var
    v = get_datatypes("intrange_valid.yaml")
    i = get_datatypes("intrange_invalid.yaml")
  test "i_empty":
    let d = new_intrange_datatype_definition(v["i_empty"], "i_empty")
    check d.kind == ddkIntRange
    check d.range_i.low == int.low
    check d.range_i.high == int.high
    check d.null_value.is_none
  test "i_min_i":
    let d = new_intrange_datatype_definition(v["i_min_i"], "i_min_i")
    check d.kind == ddkIntRange
    check d.range_i.low == -1
    check d.range_i.high == int.high
    check d.null_value.is_none
  test "i_max_i":
    let d = new_intrange_datatype_definition(v["i_max_i"], "i_max_i")
    check d.kind == ddkIntRange
    check d.range_i.low == int.low
    check d.range_i.high == 1
    check d.null_value.is_none
  test "i_min_max_i":
    let d = new_intrange_datatype_definition(v["i_min_max_i"], "i_min_max_i")
    check d.kind == ddkIntRange
    check d.range_i.low == -1
    check d.range_i.high == 1
    check d.null_value.is_none
  test "i_n":
    let d = new_intrange_datatype_definition(v["i_n"], "i_n")
    check d.kind == ddkIntRange
    check d.range_i.low == -1
    check d.range_i.high == int.high
    check d.null_value == (%*(-2)).some
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_intrange_datatype_definition(i[dn], dn)
