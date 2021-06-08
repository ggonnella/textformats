import unittest
import options, json
import yaml/dom
import textformats/types / [datatype_definition, match_element, textformats_error]
import textformats/support / [yaml_support, openrange]
import textformats/dt_list/list_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_list_def_parser":
  var
    v = get_datatypes("list_valid.yaml")
    i = get_datatypes("list_invalid.yaml")
  test "l_nosep":
    let d = new_list_datatype_definition(v["l_nosep"], "l_nosep")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 1
    check d.lenrange.highstr == "Inf"
  test "l_sep":
    let d = new_list_datatype_definition(v["l_sep"], "l_sep")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 1
    check d.lenrange.highstr == "Inf"
  test "l_nosplit":
    let d = new_list_datatype_definition(v["l_nosplit"], "l_nosplit")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == false
    check d.lenrange.low == 1
    check d.lenrange.highstr == "Inf"
  test "l_nosep_minmaxlen":
    let d = new_list_datatype_definition(v["l_nosep_minmaxlen"], "l_nosep_minmaxlen")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 2
    check d.lenrange.high == 3
  test "l_sep_minmaxlen":
    let d = new_list_datatype_definition(v["l_sep_minmaxlen"], "l_sep_minmaxlen")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 2
    check d.lenrange.high == 3
  test "l_nosplit_minmaxlen":
    let d = new_list_datatype_definition(v["l_nosplit_minmaxlen"], "l_nosplit_minmaxlen")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == false
    check d.lenrange.low == 2
    check d.lenrange.high == 3
  test "l_nosep_minlen_zero":
    let d = new_list_datatype_definition(v["l_nosep_minlen_zero"],
                                         "l_nosep_minlen_zero")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ""
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 0
    check d.lenrange.highstr == "Inf"
  test "l_sep_minlen_zero":
    let d = new_list_datatype_definition(v["l_sep_minlen_zero"],
                                         "l_sep_minlen_zero")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 0
    check d.lenrange.highstr == "Inf"
  test "l_nosplit_minlen_zero":
    let d = new_list_datatype_definition(v["l_nosplit_minlen_zero"],
                                         "l_nosplit_minlen_zero")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == false
    check d.lenrange.low == 0
    check d.lenrange.highstr == "Inf"
  test "l_sep_minlen":
    let d = new_list_datatype_definition(v["l_sep_minlen"], "l_sep_minlen")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 2
    check d.lenrange.highstr == "Inf"
  test "l_sep_maxlen":
    let d = new_list_datatype_definition(v["l_sep_maxlen"], "l_sep_maxlen")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value.is_none
    check d.sep == ","
    check d.pfx == ""
    check d.sfx == ""
    check d.sep_excl == true
    check d.lenrange.low == 1
    check d.lenrange.high == 2
  test "l_fullopts":
    let d = new_list_datatype_definition(v["l_fullopts"], "l_fullopts")
    check d.kind == ddkList
    check d.members_def.constant_element.s_value == "a"
    check d.null_value == (%*({"n": newJNull()})).some
    check d.sep == ","
    check d.pfx == "<<<"
    check d.sfx == ">>>"
    check d.sep_excl == true
    check d.lenrange.low == 2
    check d.lenrange.high == 3
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_list_datatype_definition(i[dn], dn)

