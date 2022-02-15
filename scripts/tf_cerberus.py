#!/usr/bin/env python3
"""
Validate TextFormats YAML/JSON specifications and testdata using Cerberus

Usage:
  tf_cerberus.py [options] <infile>

Arguments:
  <infile>: the yaml file containing the specification and/or testdata

Options:
  -q, --quiet     suppress stderr output
  -h, --help      show this help message
  --version       show version number
"""

import yaml
import docopt
import cerberus
import sys
import os

def setup_keys():
  keys = {}
  scriptpath = os.path.dirname(os.path.realpath(__file__))
  fname = scriptpath+"/../src/textformats/types/def_syntax.nim"
  with open(fname) as f:
    state = "before"
    for line in f:
      if line.strip() == "const":
        state = "inside"
      elif state == "inside":
        if len(line.strip()) > 0 and line[:2] != "  ":
          state = "after"
        else:
          elems = line.split("=")
          constname = elems[0].strip()
          if constname[-1:] == "*":
            definition = elems[1].strip()
            if definition[0] == "\"" and definition[-1:] == "\"":
              keys[constname[:-1]] = definition[1:-1]
  return keys

k = setup_keys()

def defkeys_except(key):
  return [k[dk] for dk in k.keys() if dk[-6:] == "DefKey" and dk != key]

valid_id_regex = r'^[A-Za-z_][A-Za-z0-9_]*'
ns_valid_id_regex = r'^[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z_][A-Za-z0-9_]*)*'
uintRangeDef = {"required": True, "excludes": defkeys_except("UintRangeDefKey"),
                "type": "dict",
                "schema": {k["MaxKey"]: {"type": "integer", "min": 0},
                           k["MinKey"]: {"type": "integer", "min": 0},
                           k["BaseKey"]: {"type": "integer",
                                          "allowed": [2, 8, 10, 16]}}}
intRangeDef = {"required": True, "excludes": defkeys_except("IntRangeDefKey"),
               "type": "dict",
               "schema": {k["MaxKey"]: {"type": "integer"},
                          k["MinKey"]: {"type": "integer"}}}
floatRangeDef = {"required": True,
                 "excludes": defkeys_except("FloatRangeDefKey"),
                 "type": "dict",
                 "schema": {
                    k["MaxKey"]: {"type": "float"},
                    k["MaxExcludedKey"]: {"type": "boolean",
                                          "dependencies": k["MaxKey"]},
                    k["MinKey"]: {"type": "float"},
                    k["MinExcludedKey"]: {"type": "boolean",
                                          "dependencies": k["MinKey"]}}}
encoded_rule = {"type": "dict", "maxlength": 1, "minlength": 1,
                "keysrules": {"type": "string", "empty": False}}
const_or_enum_value = [{"type": "string", "empty": False},
                       {"type": "float"}, {"type": "integer"},
                       encoded_rule]
constDef = {"required": True, "excludes": defkeys_except("ConstDefKey"),
            "anyof": const_or_enum_value}
enumDef = {"required": True, "excludes": defkeys_except("EnumDefKey"),
           "type": "list", "minlength": 2,
           "schema": {"anyof": const_or_enum_value}}
regex_value = [{"type": "string", "empty": False}, encoded_rule]
regexDef = {"required": True, "excludes": defkeys_except("RegexMatchDefKey"),
            "anyof": regex_value}
regexesDef = {"required": True,
              "excludes": defkeys_except("RegexesMatchDefKey"),
              "type": "list", "minlength": 2, "schema": {"anyof": regex_value}}
ref_or_def = [{"type": "string", "regex": ns_valid_id_regex},
              {"type": "dict", "schema": "defmapping"}]
unionDef = {"required": True, "excludes": defkeys_except("UnionDefKey"),
            "type": "list", "minlength": 2, "schema": {"anyof": ref_or_def}}
structDef = {"required": True, "excludes": defkeys_except("StructDefKey"),
             "type": "list", "minlength": 1,
             "schema": {"type": "dict", "minlength": 1, "maxlength": 1,
                        "keysrules": {"type": "string",
                                      "regex": valid_id_regex},
                        "valuesrules": {"anyof": ref_or_def}}}
listDef = {"required": True, "excludes": defkeys_except("ListDefKey"),
           "anyof": ref_or_def}
dictDef = {"required": True, "excludes": defkeys_except("DictDefKey"),
           "type": "dict", "keysrules": {"type": "string", "empty": False},
           "valuesrules": {"anyof": ref_or_def}}
tagsDef = {"required": True, "excludes": defkeys_except("TagsDefKey"),
           "type": "dict", "keysrules": {"type": "string", "empty": False},
           "valuesrules": {"anyof": ref_or_def}}
nullValueOpt = {"nullable": True}
encodedOpt = {"anyof": [
                 {"type": "string"},
                 {"type": "dict", "minlength": 1,
                  "keysrules": {"type": "string", "empty": False}}]}
asStringOpt = {"type": "boolean"}
scopeOpt = {"type": "string", "allowed": ["file", "section", "unit", "line"]}
unitSizeOpt = {"type": "integer", "min": 2}
compound_def_keys = [k["ListDefKey"], k["StructDefKey"],
                     k["DictDefKey"], k["TagsDefKey"]]
sep_keys = [k["ListDefKey"], k["StructDefKey"]]
sepOpt = {"excludes": k["SplittedKey"], "anyof":
    [{"type": "string", "dependencies": d} for d in sep_keys]}
splittedOpt = {"excludes": k["SepKey"], "anyof":
    [{"type": "string", "dependencies": d} for d in compound_def_keys]}
pfxOpt = {"anyof":
    [{"type": "string", "dependencies": d} for d in compound_def_keys]}
sfxOpt = {"anyof":
    [{"type": "string", "dependencies": d} for d in compound_def_keys]}
lenrangeMaxOpt = {"type": "integer", "min": 0, "excludes": k["LenKey"],
                  "dependencies": k["ListDefKey"]}
lenrangeMinOpt = {"type": "integer", "min": 0, "excludes": k["LenKey"],
                  "dependencies": k["ListDefKey"]}
lenOpt = {"type": "integer", "min": 0,
          "excludes": [k["LenrangeMaxKey"], k["LenrangeMinKey"]],
          "dependencies": k["ListDefKey"]}
dict_keys = [k["StructDefKey"], k["DictDefKey"], k["TagsDefKey"]]
implicitOpt = {"anyof":
               [{"type": "dict",
                 "keysrules": {"type": "string", "regex": valid_id_regex},
                 "dependencies": d} for d in dict_keys]}
# as long as DictInternalSepKey is equal to TagsInternalSepKey,
# they must be defined together
internalSepOpt = {"anyof":
    [{"type": "string", "empty": False, "dependencies": d} for d \
        in [k["DictDefKey"], k["TagsDefKey"]]]}
# as long as DictRequiredKey and NRequiredKey are equal,
# they must be defined together
dictRequiredOpt = {"type": "list",
                   "schema": {"type": "string", "empty": False},
                   "dependencies": k["DictDefKey"]}
nRequiredOpt = {"type": "integer", "min": 0, "dependencies": k['StructDefKey']}
requiredOpt = {"anyof": [dictRequiredOpt, nRequiredOpt]}
singleOpt = {"type": "list", "schema": {"type": "string", "empty": False, },
             "dependencies": k["DictDefKey"]}
hiddenOpt = {"type": "boolean", "dependencies": k["StructDefKey"]}
tagnameOpt= {"type": "string", "dependencies": k["TagsDefKey"]}
predefinedTagsOpt = {"type": "dict", "dependencies": k["TagsDefKey"],
                     "keysrules": {"type": "string", "empty": False},
                     "valuesrules": {"type": "string", "empty": False}}
wrappedOpt = {"type": "boolean", "dependencies": k["UnionDefKey"]}
branchNamesOpt = {"dependencies": k["UnionDefKey"],
                  "anyof": [{"type": "string", "allowed": ["default"]},
                            {"type": "list",
                             "schema": {"type": "string", "empty": False}}]}

defmapping = {
    k["IntRangeDefKey"]: intRangeDef,
    k["UintRangeDefKey"]: uintRangeDef,
    k["FloatRangeDefKey"]: floatRangeDef,
    k["ConstDefKey"]: constDef,
    k["EnumDefKey"]: enumDef,
    k["StructDefKey"]: structDef,
    k["ListDefKey"]: listDef,
    k["UnionDefKey"]: unionDef,
    k["RegexMatchDefKey"]: regexDef,
    k["RegexesMatchDefKey"]: regexesDef,
    k["DictDefKey"]: dictDef,
    k["TagsDefKey"]: tagsDef,
    k["NullValueKey"]: nullValueOpt,
    k["EncodedKey"]: encodedOpt,
    k["AsStringKey"]: asStringOpt,
    k["ScopeKey"]: scopeOpt,
    k["UnitSizeKey"]: unitSizeOpt,
    k["SepKey"]: sepOpt,
    k["SplittedKey"]: splittedOpt,
    k["PfxKey"]: pfxOpt,
    k["SfxKey"]: sfxOpt,
    k["LenrangeMaxKey"]: lenrangeMaxOpt,
    k["LenrangeMinKey"]: lenrangeMinOpt,
    k["LenKey"]: lenOpt,
    k["ImplicitKey"]: implicitOpt,
    k["DictInternalSepKey"]: internalSepOpt,
    k["DictRequiredKey"]: requiredOpt,
    k["SingleKey"]: singleOpt,
    k["HiddenKey"]: hiddenOpt,
    k["TagnameKey"]: tagnameOpt,
    k["PredefinedTagsKey"]: predefinedTagsOpt,
    k["WrappedKey"]: wrappedOpt,
    k["BranchNamesKey"]: branchNamesOpt,
  }

cerberus.schema_registry.add("defmapping", defmapping)

valid_testdata = {"anyof": [{"type": "list", "schema": {"type": "string"}},
                            {"type": "dict", "keysrules": {"type": "string"}}]}
invalid_dict_testdata = {"type": "dict", "schema":
     {k["TestdataEncodedKey"]: {"type": "list", "schema": {"type": "string"}},
      k["TestdataDecodedKey"]: {"type": "list"}}}
testdata_schema = {
    "type": "dict",
    "keysrules": {"type": "string", "regex": ns_valid_id_regex},
    "valuesrules": {"type": "dict",
      "schema": {
        k["TestdataValidKey"]: valid_testdata,
        k["TestdataOnewayKey"]: valid_testdata,
        k["TestdataInvalidKey"]: {"anyof": [
            {"type": "list", "schema": {"type": "string"}},
            invalid_dict_testdata]}
      }}
  }

include_elem = {"anyof": [{"type": "string", "empty": False},
                          {"type": "dict", "minlength": 1, "maxlength": 1,
                           "keysrules": {"type": "string", "empty": False},
                           "valuesrules": {"type": "list", "minlength": 1,
                             "schema":
                               {"type": "string", "regex": ns_valid_id_regex}}}]}
include_schema = {"anyof": [include_elem,
                            {"type": "list", "schema": include_elem}]}
namespace_schema = {"type": "string", "regex": valid_id_regex}
datatypes_schema = {
    "type": "dict",
    "keysrules": {"type": "string", "regex": ns_valid_id_regex},
    "valuesrules": {"anyof": ref_or_def}
  }

schema = {k["TestdataRootKey"]: testdata_schema,
          k["IncludeKey"]: include_schema,
          k["NamespaceKey"]: namespace_schema,
          k["DatatypesKey"]: datatypes_schema}


def main(arguments: dict) -> int:
  validator = cerberus.Validator(schema)
  validator.allow_unknown = True
  document = None
  with open(arguments["<infile>"]) as f:
    for d in yaml.safe_load_all(f):
      document = d
      break
  if not validator.validate(document):
    if not arguments["--quiet"]:
      sys.stderr.write("Specification Error:\n")
      yaml.dump(validator.errors, sys.stdout)
    return 1
  if not arguments["--quiet"]:
    sys.stderr.write("Specification valid\n")
  return 0

if __name__ == "__main__":
  arguments = docopt.docopt(__doc__)
  main(arguments)

