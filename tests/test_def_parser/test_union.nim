import unittest
import json
import yaml/dom
import textformats/types / [datatype_definition, match_element,
                            textformats_error]
import textformats/support/yaml_support
import textformats/dt_union/union_def_parser
import common
import options
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_union_def_parser":
  var
    v = get_datatypes("union_valid.yaml")
    i = get_datatypes("union_invalid.yaml")
  test "u":
    let d = new_union_datatype_definition(v["u"], "u")
    check d.kind == ddkUnion
    check d.choices.len == 3
    check d.choices[0].constant_element.s_value == "a"
    check d.choices[1].target_name == "json"
    check d.choices[2].target_name == "string"
    check d.null_value.is_none
    check d.wrapped == false
  test "u_n":
    let d = new_union_datatype_definition(v["u_n"], "u_n")
    check d.kind == ddkUnion
    check d.choices.len == 3
    check d.choices[0].constant_element.s_value == "a"
    check d.choices[1].target_name == "json"
    check d.choices[2].target_name == "string"
    check d.null_value == (%*false).some
    check d.wrapped == false
  test "u_w":
    let d = new_union_datatype_definition(v["u_w"], "u_w")
    check d.kind == ddkUnion
    check d.choices.len == 3
    check d.choices[0].constant_element.s_value == "a"
    check d.choices[1].target_name == "json"
    check d.choices[2].target_name == "string"
    check d.null_value.is_none
    check d.wrapped == true
    check d.branch_names == @["u_w[1]", "json", "string"]
  test "u_w_default":
    let d = new_union_datatype_definition(v["u_w_default"], "u_w_default")
    check d.kind == ddkUnion
    check d.choices.len == 3
    check d.choices[0].constant_element.s_value == "a"
    check d.choices[1].target_name == "json"
    check d.choices[2].target_name == "string"
    check d.null_value.is_none
    check d.wrapped == true
    check d.branch_names == @["u_w_default[1]", "json", "string"]
  test "u_w_l":
    let d = new_union_datatype_definition(v["u_w_l"], "u_w_l")
    check d.kind == ddkUnion
    check d.choices.len == 3
    check d.choices[0].constant_element.s_value == "a"
    check d.choices[1].target_name == "json"
    check d.choices[2].target_name == "string"
    check d.null_value.is_none
    check d.wrapped == true
    check d.branch_names == @["a", "json", "string"]
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_union_datatype_definition(i[dn], dn)
