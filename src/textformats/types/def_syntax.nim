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
  DictDefKey* = "named_values"
  EnumDefKey* = "accepted_values"
  ListDefKey* = "list_of"
  FloatRangeDefKey* = "float"
  IntrangeDefKey* = "integer"
  UintRangeDefKey* = "unsigned_integer"
  RegexesMatchDefKey* = "regexes"
  RegexMatchDefKey* = "regex"
  StructDefKey* = "composed_of"
  TagsDefKey* = "tags"
  UnionDefKey* = "one_of"

  # additional keys for datatype definition
  # common
  NullValueKey* = "empty"
  EncodedKey* = "reverse"
  AsStringKey* = "as_string"
  # ranges
  MinKey* = "min"
  MaxKey* = "max"
  MinExcludedKey* = "min_excluded"
  MaxExcludedKey* = "max_excluded"
  # list/dict/struct/tags
  SepKey* = "sep"
  SepExclKey* = "split_by_sep"
  PfxKey* = "pfx"
  SfxKey* = "sfx"
  # list
  LenrangeMinKey*  = "minlength"
  LenrangeMaxKey*  = "maxlength"
  LenKey* = "length"
  # dict/struct/tags
  ImplicitKey* = "implicit"
  # dict
  DictInternalSepKey* = "internal_sep"
  DictRequiredKey* = "required"
  SingleKey* = "single"
  # struct
  NRequiredKey* = "required"
  # tags
  TagnameKey* = "tagname"
  TagsInternalSepKey* = "internal_sep"
  PredefinedTagsKey* = "predefined"
  # unions
  WrappedKey* = "wrapped"
  TypeLabelsKey* = "type_labels"

  # testdata syntax
  TestdataRootKey* = "testdata"
  TestdataValidKey* = "valid"
  TestdataOnewayKey* = "oneway"
  TestdataInvalidKey* = "invalid"
  TestdataEncodedKey* = "encoded"
  TestdataDecodedKey* = "decoded"
