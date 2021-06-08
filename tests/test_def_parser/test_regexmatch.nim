import unittest
import options, json, tables
import yaml/dom
import textformats/types / [datatype_definition, textformats_error]
import textformats/support/yaml_support
import textformats/dt_regexmatch/regexmatch_def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_regexmatch_def_parser":
  var
    v = get_datatypes("regexmatch_valid.yaml")
    i = get_datatypes("regexmatch_invalid.yaml")
  test "r_simple":
    let d = new_regexmatch_datatype_definition(v["r_simple"], "r_simple")
    check d.kind == ddkRegexMatch
    check d.regex.raw == "\\d\\d"
    check d.decoded[0].is_none
    check d.encoded.is_none
    check d.null_value.is_none
  test "r_map":
    let d = new_regexmatch_datatype_definition(v["r_map"], "r_map")
    check d.kind == ddkRegexMatch
    check d.regex.raw == "\\d\\d"
    check d.decoded[0] == (%*1).some
    check d.encoded.get[%*1] == "01"
    check d.null_value.is_none
  test "r_n":
    let d = new_regexmatch_datatype_definition(v["r_n"], "r_n")
    check d.kind == ddkRegexMatch
    check d.regex.raw == "\\d\\d"
    check d.decoded[0].is_none
    check d.encoded.is_none
    check d.null_value == (%*0).some
  for dn, def in i:
    test "invalid_" & dn:
      expect(InvalidSpecError):
        discard new_regexmatch_datatype_definition(i[dn], dn)
