import os
import unittest
import textformats
import tables
const
  badspecdir = currentSourcePath.parentDir() & "/testdata/badspec/"
  goodspecdir = currentSourcePath.parentDir() & "/testdata/goodspec/"

suite "test_spec_parser":
  for filename in @["include_incomplete.yaml", "no_datatypes.yaml",
      "include_select_included.yaml", "include_select_subincluded.yaml",
      "include_select_unknown.yaml", "redefine_included.yaml",
      "redefine_subincluded.yaml", "to_be_included1.yaml",
      "to_be_included2.yaml", "unknown_keys_ignored.yaml",
      "to_be_included_namespace.yaml", "include_namespace.yaml",
      "include_include_namespace.yaml"]:
    test "valid_" & filename:
      check len(specification_from_file(goodspecdir & filename)) > 0
  for filename in @["broken_ref.yaml", "circular_aba.yaml",
      "circular_abca.yaml", "circular_abcda.yaml", "circular_dict.yaml",
      "circular_list.yaml", "circular_struct.yaml", "circular_tags.yaml",
      "circular_union.yaml", "datatype_name_dup.yaml",
      "datatype_name_empty.yaml", "datatype_name_invchar.yaml",
      "datatype_name_num.yaml", "datatype_name_startnum.yaml",
      "datatypes_scalar.yaml", "datatypes_seq.yaml", "included_map.yaml",
      "wrong_yaml_syntax.yaml", "ref_included_wo_namespace.yaml"]:
    test "invalid_" & filename:
      expect(InvalidSpecError):
        discard specification_from_file(badspecdir & filename)
  for filename in @["include_not_existing.yaml"]:
    test "invalid_" & filename:
      expect(TextFormatsRuntimeError):
        discard specification_from_file(badspecdir & filename)

