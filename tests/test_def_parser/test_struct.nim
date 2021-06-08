import unittest
import options, json
import yaml/dom
import textformats/types / [datatype_definition, match_element, textformats_error]
import textformats/support / [yaml_support, openrange]
import textformats/dt_struct/struct_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_struct_def_parser":
  var
    v = get_datatypes("struct_valid.yaml")
    i = get_datatypes("struct_invalid.yaml")
  test "s_single_elem":
    let d = new_struct_datatype_definition(v["s_single_elem"], "s_single_elem")
    check d.kind == ddkStruct
    check d.members.len == 1
    check d.members[0].name == "name"
    check d.members[0].def.target_name == "string"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 1
  test "s_nosep":
    let d = new_struct_datatype_definition(v["s_nosep"], "s_nosep")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^a]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_sep":
    let d = new_struct_datatype_definition(v["s_sep"], "s_sep")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_nosplit":
    let d = new_struct_datatype_definition(v["s_nosplit"], "s_nosplit")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+\\\\,[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == false
    check d.n_required == 2
  test "s_nosep_lastopt":
    let d = new_struct_datatype_definition(v["s_nosep_lastopt"],
                                           "s_nosep_lastopt")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^a]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 1
  test "s_sep_lastopt":
    let d = new_struct_datatype_definition(v["s_sep_lastopt"],
                                           "s_sep_lastopt")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 1
  test "s_nosplit_lastopt":
    let d = new_struct_datatype_definition(v["s_nosplit_lastopt"],
                                           "s_nosplit_lastopt")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+\\\\,[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == false
    check d.n_required == 1
  test "s_nosep_varlen":
    let d = new_struct_datatype_definition(v["s_nosep_varlen"],
                                           "s_nosep_varlen")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^a]+"
    check d.members[1].name == "a"
    check d.members[1].def.members_def.constant_element.s_value == "a"
    check d.members[1].def.lenrange.low == 1
    check d.members[1].def.lenrange.highstr == "Inf"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_sep_varlen":
    let d = new_struct_datatype_definition(v["s_sep_varlen"],
                                           "s_sep_varlen")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.members_def.constant_element.s_value == "a"
    check d.members[1].def.lenrange.low == 1
    check d.members[1].def.lenrange.highstr == "Inf"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_nosplit_varlen":
    let d = new_struct_datatype_definition(v["s_nosplit_varlen"],
                                           "s_nosplit_varlen")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+\\\\,[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.members_def.constant_element.s_value == "a"
    check d.members[1].def.lenrange.low == 1
    check d.members[1].def.lenrange.highstr == "Inf"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == false
    check d.n_required == 2
  test "s_sep_varlen_min":
    let d = new_struct_datatype_definition(v["s_sep_varlen_min"],
                                           "s_sep_varlen_min")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.members_def.constant_element.s_value == "a"
    check d.members[1].def.lenrange.low == 2
    check d.members[1].def.lenrange.highstr == "Inf"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_sep_varlen_max":
    let d = new_struct_datatype_definition(v["s_sep_varlen_max"],
                                           "s_sep_varlen_max")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.members_def.constant_element.s_value == "a"
    check d.members[1].def.lenrange.low == 1
    check d.members[1].def.lenrange.high == 2
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_sep_varlen_minmax":
    let d = new_struct_datatype_definition(v["s_sep_varlen_minmax"],
                                           "s_sep_varlen_minmax")
    check d.kind == ddkStruct
    check d.members.len == 2
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.members_def.constant_element.s_value == "a"
    check d.members[1].def.lenrange.low == 2
    check d.members[1].def.lenrange.high == 3
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.n_required == 2
  test "s_fullopts":
    let d = new_struct_datatype_definition(v["s_fullopts"], "s_fullopts")
    check d.kind == ddkStruct
    check d.members.len == 5
    check d.members[0].name == "name"
    check d.members[0].def.regex.raw == "[^,]+"
    check d.members[1].name == "a"
    check d.members[1].def.constant_element.s_value == "a"
    check d.members[2].name == "i"
    check d.members[2].def.target_name == "integer"
    check d.members[3].name == "f"
    check d.members[3].def.target_name == "float"
    check d.members[4].name == "b"
    check d.members[4].def.members_def.elements[0].s_value == "true"
    check d.members[4].def.members_def.elements[1].s_value == "false"
    check d.members[4].def.lenrange.low == 2
    check d.members[4].def.lenrange.high == 3
    check d.n_required == 2
    check d.null_value == (%*({"n": newJNull()})).some
    check d.sep == ","
    check d.pfx == "<<<"
    check d.sfx == ">>>"
    check d.sep_excl == true
    check ("ii", %*1) in d.implicit
    check ("if", %*1.0) in d.implicit
    check ("is", %*"a") in d.implicit
    check ("ib", %*false) in d.implicit
    check ("in", newJNull()) in d.implicit
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_struct_datatype_definition(i[dn], dn)

