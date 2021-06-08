import unittest
import options, json, tables
import yaml/dom
import textformats/types / [datatype_definition, textformats_error]
import textformats/support/yaml_support
import textformats/dt_regexesmatch/regexesmatch_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_regexesmatch_def_parser":
  var
    v = get_datatypes("regexesmatch_valid.yaml")
    i = get_datatypes("regexesmatch_invalid.yaml")
  test "rs_simple":
    let d = new_regexesmatch_datatype_definition(v["rs_simple"], "rs_simple")
    check d.kind == ddkRegexesMatch
    check d.regexes_raw[0] == "\\d\\d"
    check d.regexes_raw[1] == "_\\d"
    check d.decoded[0].is_none
    check d.decoded[1].is_none
    check d.encoded.is_none
    check d.null_value.is_none
  test "rs_maps":
    let d = new_regexesmatch_datatype_definition(v["rs_maps"], "rs_maps")
    check d.kind == ddkRegexesMatch
    check d.regexes_raw[0] == "\\d\\d"
    check d.regexes_raw[1] == "_\\d"
    check d.decoded[0] == (%*1).some
    check d.decoded[1] == (%*2).some
    check d.encoded.get[%*1] == "01"
    check d.encoded.get[%*2] == "_1"
    check d.null_value.is_none
  test "rs_n":
    let d = new_regexesmatch_datatype_definition(v["rs_n"], "rs_n")
    check d.kind == ddkRegexesMatch
    check d.regexes_raw[0] == "\\d\\d"
    check d.regexes_raw[1] == "_\\d"
    check d.decoded[0].is_none
    check d.decoded[1].is_none
    check d.encoded.is_none
    check d.null_value == (%*0).some
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_regexesmatch_datatype_definition(i[dn], dn)

