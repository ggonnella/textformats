import unittest
import json, tables
import yaml/dom
import textformats/types / [datatype_definition, match_element,
                            textformats_error]
import textformats/support/yaml_support
import textformats/dt_tags/tags_def_parser
import common
import options
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_tags_def_parser":
  var
    v = get_datatypes("tags_valid.yaml")
    i = get_datatypes("tags_invalid.yaml")
  test "t_simple":
    let d = new_tags_datatype_definition(v["t_simple"], "t_simple")
    check d.kind == ddkTags
    check d.tagtypes.len == 1
    check d.tagtypes["x"].constant_element.s_value == "x"
    check d.tagname_regex_raw == "[A-Za-z_][0-9A-Za-z_]*"
    check d.null_value.is_none
    check d.sep == ","
    check d.tags_internal_sep == ":"
    check d.pfx == ""
    check d.sfx == ""
    check d.predefined_tags.len == 0
  test "t_predefined_only":
    let d = new_tags_datatype_definition(v["t_predefined_only"],
                                         "t_predefined_only")
    check d.kind == ddkTags
    check d.tagtypes.len == 1
    check d.tagtypes["x"].constant_element.s_value == "x"
    check d.tagname_regex_raw == "(CD|ef|abc)"
    check d.null_value.is_none
    check d.sep == ","
    check d.tags_internal_sep == ":"
    check d.predefined_tags.len == 3
    check d.predefined_tags["abc"] == "x"
    check d.predefined_tags["CD"] == "x"
    check d.predefined_tags["ef"] == "x"
  test "t_fullopts":
    let d = new_tags_datatype_definition(v["t_fullopts"], "t_fullopts")
    check d.kind == ddkTags
    check d.tagtypes.len == 3
    check d.tagtypes["x"].constant_element.s_value == "x"
    check d.tagtypes["y"].target_name == "string"
    check d.tagtypes["z"].target_name == "integer"
    check d.tagname_regex_raw == "(CD|ef|abc|[a-z]{2})"
    check d.null_value == (%*0).some
    check d.sep == ","
    check d.tags_internal_sep == ":"
    check d.pfx == "<<<"
    check d.sfx == ">>>"
    check d.predefined_tags.len == 3
    check d.predefined_tags["abc"] == "x"
    check d.predefined_tags["CD"] == "x"
    check d.predefined_tags["ef"] == "z"
    check ("ii", %*1) in d.implicit
    check ("if", %*1.0) in d.implicit
    check ("is", %*"a") in d.implicit
    check ("ib", %*false) in d.implicit
    check ("in", newJNull()) in d.implicit
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_tags_datatype_definition(i[dn], dn)

