import unittest
import options, json
import yaml/dom
import textformats/types / [datatype_definition, match_element, textformats_error]
import textformats/support/yaml_support
import textformats/dt_const/const_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_const_def_parser":
  var
    v = get_datatypes("const_valid.yaml")
    i = get_datatypes("const_invalid.yaml")
  test "new_const_dd_ci":
    let ci = new_const_datatype_definition(v["ci"], "ci")
    check ci.kind == ddkConst
    check ci.constant_element.kind == meInt
    check ci.constant_element.i_value == 1
    check ci.decoded.len == 1
    check ci.decoded[0].is_none
    check ci.null_value.is_none
  test "new_const_dd_cf":
    let cf = new_const_datatype_definition(v["cf"], "cf")
    check cf.kind == ddkConst
    check cf.constant_element.kind == meFloat
    check cf.constant_element.f_value == 1.0
    check cf.decoded.len == 1
    check cf.decoded[0].is_none
    check cf.null_value.is_none
  test "new_const_dd_cs":
    let cs = new_const_datatype_definition(v["cs"], "cs")
    check cs.kind == ddkConst
    check cs.constant_element.kind == meString
    check cs.constant_element.s_value == "a"
    check cs.decoded.len == 1
    check cs.decoded[0].is_none
    check cs.null_value.is_none
  test "new_const_dd_ci_map":
    let cim = new_const_datatype_definition(v["ci_map"], "ci_map")
    check cim.kind == ddkConst
    check cim.constant_element.kind == meInt
    check cim.constant_element.i_value == 1
    check cim.decoded.len == 1
    check cim.decoded[0].is_some
    check cim.decoded[0].unsafe_get.kind == JString
    check cim.decoded[0].unsafe_get.get_str == "a"
    check cim.null_value.is_none
  test "new_const_dd_cf_map":
    let cif = new_const_datatype_definition(v["cf_map"], "cf_map")
    check cif.kind == ddkConst
    check cif.constant_element.kind == meFloat
    check cif.constant_element.f_value == 1.0
    check cif.decoded.len == 1
    check cif.decoded[0].is_some
    check cif.decoded[0].unsafe_get.kind == JString
    check cif.decoded[0].unsafe_get.get_str == "a"
    check cif.null_value.is_none
  test "new_const_dd_cs_map":
    let cis = new_const_datatype_definition(v["cs_map"], "cs_map")
    check cis.kind == ddkConst
    check cis.constant_element.kind == meString
    check cis.constant_element.s_value == "a"
    check cis.decoded.len == 1
    check cis.decoded[0].is_some
    check cis.decoded[0].unsafe_get.kind == JNull
    check cis.null_value.is_none
  test "new_const_dd_cs_map_n":
    let cisn = new_const_datatype_definition(v["cs_map_n"], "cs_map_n")
    check cisn.kind == ddkConst
    check cisn.constant_element.kind == meString
    check cisn.constant_element.s_value == "a"
    check cisn.decoded.len == 1
    check cisn.decoded[0].is_some
    check cisn.decoded[0].unsafe_get.kind == JNull
    check cisn.null_value.is_some
    check cisn.null_value.unsafe_get.kind == JString
    check cisn.null_value.unsafe_get.get_str == "b"
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_const_datatype_definition(def, dn)
