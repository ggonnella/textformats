import unittest
import options, json, tables
import yaml/dom
import textformats/types / [datatype_definition, match_element, textformats_error]
import textformats/support/yaml_support
import textformats/dt_enum/enum_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_enum_def_parser":
  var
    v = get_datatypes("enum_valid.yaml")
    i = get_datatypes("enum_invalid.yaml")
  test "e_simple":
    let d = new_enum_datatype_definition(v["e_simple"], "e_simple")
    check d.kind == ddkEnum
    check d.elements.len == 3
    check d.elements[0].i_value == 1
    check d.elements[1].s_value == "a"
    check d.elements[2].f_value == 1.0
    for n in 0..2: check d.decoded[n].is_none
    check d.null_value.is_none
  test "e_null_value":
    let d = new_enum_datatype_definition(v["e_null_value"], "e_null_value")
    check d.kind == ddkEnum
    check d.elements.len == 3
    for n in 0..2: check d.decoded[n].is_none
    check d.null_value == (%*0).some
  test "e_map":
    let d = new_enum_datatype_definition(v["e_map"], "e_map")
    check d.kind == ddkEnum
    check d.elements.len == 3
    check d.decoded[0] == (%*true).some
    check d.decoded[1].is_none
    check d.decoded[2] == newJNull().some
    check d.encoded.is_none
  test "e_map_rev":
    let d = new_enum_datatype_definition(v["e_map_rev"], "e_map_rev")
    check d.kind == ddkEnum
    check d.elements.len == 3
    check d.decoded[0] == (%*true).some
    check d.decoded[1] == (%*true).some
    check d.decoded[2].is_none
    check d.encoded.is_some
    check d.encoded.unsafe_get[%*true] == "1"
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_enum_datatype_definition(def, dn)

