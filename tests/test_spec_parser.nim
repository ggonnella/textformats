import os, streams
import unittest
import textformats
import tables
const
  badspecdir = currentSourcePath.parentDir() & "/testdata/badspec/"
  goodspecdir = currentSourcePath.parentDir() & "/testdata/goodspec/"

suite "test_spec_parser":
  for filename in @["broken_ref.yaml", "circular_aba.yaml",
      "circular_abca.yaml", "circular_abcda.yaml", "circular_dict.yaml",
      "circular_list.yaml", "circular_struct.yaml", "circular_tags.yaml",
      "circular_union.yaml", "datatype_name_dup.yaml",
      "datatype_name_empty.yaml", "datatype_name_invchar.yaml",
      "datatype_name_num.yaml", "datatype_name_startnum.yaml",
      "datatypes_scalar.yaml", "datatypes_seq.yaml", "included_map.yaml",
      "include_not_existing.yaml", "wrong_yaml_syntax.yaml"]:
    test "invalid_" & filename:
      expect(InvalidSpecError):
        discard parse_specification(badspecdir & filename)
  for filename in @["include_incomplete.yaml", "no_datatypes.yaml",
      "include_select_included.yaml", "include_select_subincluded.yaml",
      "include_select_unknown.yaml", "redefine_included.yaml",
      "redefine_subincluded.yaml", "to_be_included1.yaml",
      "to_be_included2.yaml", "unknown_keys_ignored.yaml"]:
    test "valid_" & filename:
      check len(parse_specification(goodspecdir & filename)) > 0

