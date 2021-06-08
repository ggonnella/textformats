import unittest
import options
import yaml/dom
import textformats/types/datatype_definition
import textformats/support/yaml_support
import textformats/def_parser
import common
when defined(nimHasUsed): {.used.} # avoid UnusedImport

suite "test_ref_def_parser":
  var v = get_datatypes("ref_valid.yaml")
  test "ref_to_integer":
    let d = new_datatype_definition(v["i"], "i")
    check d.kind == ddkRef
    check d.target_name == "integer"
  test "ref_to_unsigned_integer":
    let d = new_datatype_definition(v["u"], "u")
    check d.kind == ddkRef
    check d.target_name == "unsigned_integer"
  test "ref_to_string":
    let d = new_datatype_definition(v["s"], "s")
    check d.kind == ddkRef
    check d.target_name == "string"
  test "ref_to_float":
    let d = new_datatype_definition(v["f"], "f")
    check d.kind == ddkRef
    check d.target_name == "float"
  test "ref_to_json":
    let d = new_datatype_definition(v["j"], "j")
    check d.kind == ddkRef
    check d.target_name == "json"
  test "ref_to_other":
    let d = new_datatype_definition(v["ref_s"], "ref_s")
    check d.kind == ddkRef
    check d.target_name == "s"
