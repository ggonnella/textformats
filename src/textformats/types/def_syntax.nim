##
## Defines the keys used in the specification
##

const
  # section keys
  DatatypesKey* = "datatypes"
  IncludeKey* = "include"
  NamespaceKey* = "namespace"
  NamespaceSeparator* = "::"

  # def keys, one and only one must be present
  ConstDefKey* = "constant"
  DictDefKey* = "labeled_list"
  EnumDefKey* = "values"
  ListDefKey* = "list_of"
  FloatRangeDefKey* = "float"
  IntRangeDefKey* = "integer"
  UintRangeDefKey* = "unsigned_integer"
  RegexesMatchDefKey* = "regexes"
  RegexMatchDefKey* = "regex"
  StructDefKey* = "composed_of"
  TagsDefKey* = "tagged_list"
  UnionDefKey* = "one_of"

  # additional keys for datatype definition
  # common
  NullValueKey* = "empty"
  EncodedKey* = "canonical"
  AsStringKey* = "as_string"
  ScopeKey* = "scope"
  UnitSizeKey* = "n_lines"
  # ranges
  MinKey* = "min"
  MaxKey* = "max"
  MinExcludedKey* = "min_excluded"
  MaxExcludedKey* = "max_excluded"
  BaseKey* = "base"
  # list/dict/struct/tags
  SepKey* = "separator"
  SplittedKey* = "splitted_by"
  PfxKey* = "prefix"
  SfxKey* = "suffix"
  # list
  LenrangeMinKey*  = "minlength"
  LenrangeMaxKey*  = "maxlength"
  LenKey* = "length"
  # dict/struct/tags
  ImplicitKey* = "implicit"
  # dict
  DictInternalSepKey* = "internal_separator"
  DictRequiredKey* = "required"
  SingleKey* = "single"
  # struct
  NRequiredKey* = "required"
  HiddenKey* = "hide_constants"
  # tags
  TagnameKey* = "tagname"
  TagsInternalSepKey* = "internal_separator"
  PredefinedTagsKey* = "predefined"
  # unions
  WrappedKey* = "wrapped"
  BranchNamesKey* = "branch_names"

  # testdata syntax
  TestdataRootKey* = "testdata"
  TestdataValidKey* = "valid"
  TestdataOnewayKey* = "oneway"
  TestdataInvalidKey* = "invalid"
  TestdataEncodedKey* = "encoded"
  TestdataDecodedKey* = "decoded"
