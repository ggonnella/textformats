import os
import unittest
import textformats
import tables
const
  badspecdir = currentSourcePath.parentDir() & "/testdata/badspec/"
  goodspecdir = currentSourcePath.parentDir() & "/testdata/goodspec/"
  ddefspecdir = currentSourcePath.parentDir() & "/testdata/spec/"
  mainspecdir = currentSourcePath.parentDir().parentDir() & "/spec/"

template test_valid_walk(globpattern: string) =
  for filename in walkfiles(globpattern):
    let fn = splitFile(filename)[1]
    test "yaml_" & fn:
      check len(specification_from_file(filename)) > 0
    test "tfs_" & fn:
      let tfsfn = ddefspecdir & fn & ".tfs"
      compile_specification(filename, tfsfn)
      check len(specification_from_file(tfsfn)) > 0

suite "test_spec_parser":
  test_valid_walk(ddefspecdir & "/*_valid.yaml")
  test_valid_walk(mainspecdir & "/*.yaml")
  test_valid_walk(mainspecdir & "/gfa/*.yaml")
  for filename in @["include_incomplete", "no_datatypes",
      "include_select_included", "include_select_subincluded",
      "include_select_unknown", "redefine_included",
      "redefine_subincluded", "to_be_included1",
      "to_be_included2", "unknown_keys_ignored",
      "to_be_included_namespace", "include_namespace",
      "include_include_namespace"]:
    test "yaml_valid_" & filename:
      check len(specification_from_file(goodspecdir & filename & ".yaml")) > 0
    test "tfs_valid_" & filename:
      compile_specification(goodspecdir & filename & ".yaml",
                            goodspecdir & filename & ".tfs")
      check len(specification_from_file(goodspecdir & filename & ".tfs")) > 0
  for filename in @["broken_ref.yaml", "circular_aba.yaml",
      "circular_abca.yaml", "circular_abcda.yaml", "circular_dict.yaml",
      "circular_list.yaml", "circular_struct.yaml", "circular_tags.yaml",
      "circular_union.yaml", "datatype_name_dup.yaml",
      "datatype_name_empty.yaml", "datatype_name_invchar.yaml",
      "datatype_name_num.yaml", "datatype_name_startnum.yaml",
      "datatypes_scalar.yaml", "datatypes_seq.yaml", "included_map.yaml",
      "wrong_yaml_syntax.yaml", "ref_included_wo_namespace.yaml",
      "empty.yaml", "spacesonly.yaml"]:
    test "invalid_" & filename:
      expect(InvalidSpecError):
        discard specification_from_file(badspecdir & filename)
  for filename in @["include_not_existing.yaml"]:
    test "invalid_" & filename:
      expect(TextFormatsRuntimeError):
        discard specification_from_file(badspecdir & filename)

