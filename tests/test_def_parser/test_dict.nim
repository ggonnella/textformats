import unittest
import options, json, tables
import yaml/dom
import textformats/types / [datatype_definition, match_element, textformats_error]
import textformats/support/yaml_support
import textformats/dt_dict/dict_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_dict_def_parser":
  var
    v = get_datatypes("dict_valid.yaml")
    i = get_datatypes("dict_invalid.yaml")
  for dn in @["d_m2", "d_o2", "d_m1_o1",
              "d_m1", "d_o1",
              "d_m2_s1", "d_o2_s1", "d_m1_o1_s1",
              "d_m1_s1", "d_o1_s1",
              "d_m2_s2", "d_o2_s2", "d_m1_o1_s2",
              "d_fullopt"]:
    let d = new_dict_datatype_definition(v[dn], dn)
    test dn & "_new_dict_valid":
      check d.kind == ddkDict
    test dn & "_new_dict_formatting_defkeys":
      check d.sep == ","
      check d.dict_internal_sep == ":"
      if dn != "d_fullopt":
        check d.pfx == ""
        check d.sfx == ""
      else:
        check d.pfx == "<<<"
        check d.sfx == ">>>"
    test dn & "_new_dict_members_len":
      if dn in @["d_m1", "d_o1", "d_m1_s1", "d_o1_s1"]:
                                  check d.dict_members.len == 1
      elif dn != "d_fullopt":     check d.dict_members.len == 2
      else:                       check d.dict_members.len == 5
    test dn & "_new_dict_required_keys":
      if dn in @["d_o1", "d_o2", "d_o1_s1", "d_o2_s1", "d_o2_s2"]:
        check "name" notin d.required_keys
        check "a" notin d.required_keys
        check d.required_keys.len == 0
      else:
        check "name" in d.required_keys
        if dn notin @["d_m1", "d_m1_s1"]:
          if dn in @["d_m1_o1", "d_m1_o1_s1", "d_m1_o1_s2"]:
            check "a" notin d.required_keys
          else:
            check "a" in d.required_keys
    test dn & "_new_dict_single_keys":
      if dn in @["d_o1", "d_o2", "d_m1", "d_m2", "d_m1_o1"]:
        check "name" notin d.single_keys
        check "a" notin d.single_keys
        check d.single_keys.len == 0
      else:
        check "name" in d.single_keys
        if dn notin @["d_m1_s1", "d_o1_s1"]:
          if dn in @["d_o2_s1", "d_m1_o1_s1", "d_m2_s1", "d_fullopt"]:
            check "a" notin d.single_keys
          else:
            check "a" in d.single_keys
    test dn & "_new_dict_members_content":
      check d.dict_members["name"].target_name == "string"
      if dn notin @["d_m1", "d_o1", "d_m1_s1", "d_o1_s1"]:
        check d.dict_members["a"].constant_element.s_value == "a"
      if dn == "d_fullopt":
        check d.dict_members["i"].target_name == "integer"
        check d.dict_members["f"].target_name == "float"
        for mn in @["name", "a"]:
          check mn in d.required_keys
        for mn in @["name", "i"]:
          check mn in d.single_keys
        let b = d.dict_members["b"]
        check b.kind == ddkEnum
        check b.name == dn & ".b"
        check b.elements.len == 2
        check b.elements[0].s_value == "true"
        check b.elements[1].s_value == "false"
    test dn & "_new_dict_null_value":
      if dn != "d_fullopt": check d.null_value.is_none
      else: check d.null_value == (%*{"false": newJNull()}).some
    test dn & "_new_dict_implicit":
      if dn != "d_fullopt":
        check d.implicit.len == 0
      else:
        check d.implicit.len == 5
        check d.implicit[0].name == "ii"
        check d.implicit[0].value == %*1
        check d.implicit[1].value == %*1.0
        check d.implicit[2].value == %*"a"
        check d.implicit[3].value == newJNull()
        check d.implicit[4].value == %*false
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_dict_datatype_definition(def, dn)

