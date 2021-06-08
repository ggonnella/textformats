##
## Parse a YAML specification node defining a datatype
## and create a DatatypeDefinition object
##

import strformat, options, strutils
import yaml / [dom,serialization, hints]
import types / [datatype_definition, def_syntax, textformats_error]
import support/yaml_support

proc new_datatype_definition*(node: YamlNode, name: string): DatatypeDefinition
proc collect_defnodes*(defroot: YamlNode, keys: openArray[string],
                      n_required = 1): seq[Option[YamlNode]]
proc validate_requires*(key1: string, optnode1: Option[YamlNode],
                        key2: string, optnode2: Option[YamlNode])

template raise_def_syntax_error*(name: string, msg: string, syntaxhelp: string,
                                 defkey = "") =
  let
    intro = "Error in the definition of datatype '" & name & "':\n"
    invalidstr = block:
      if len(defkey) > 0: "Invalid datatype of kind '" & defkey & "':\n"
      else: ""
    syntaxstr = "\n\n==== Expected datatype definition syntax ====\n\n" &
                syntaxhelp
  raise newException(DefSyntaxError,
                     intro & invalidstr & msg & syntaxstr)

template reraise_as_def_syntax_error*(name: string, syntaxhelp: string,
                                      defkey = "") =
  var e = getCurrentException()
  raise_def_syntax_error(name, e.msg, syntaxhelp, defkey)

#
# each datatype kind has a submodule, except for the base datatypes
# created by new_specification (any*, json)
#
import dt_ref/ref_def_parser
import dt_intrange/intrange_def_parser
import dt_uintrange/uintrange_def_parser
import dt_floatrange/floatrange_def_parser
import dt_regexmatch/regexmatch_def_parser
import dt_regexesmatch/regexesmatch_def_parser
import dt_const/const_def_parser
import dt_enum/enum_def_parser
import dt_list/list_def_parser
import dt_struct/struct_def_parser
import dt_dict/dict_def_parser
import dt_tags/tags_def_parser
import dt_union/union_def_parser

const
  DefKeysList = [IntRangeDefKey, UintRangeDefKey, FloatRangeDefKey,
     ConstDefKey, EnumDefKey, RegexMatchDefKey, RegexesMatchDefKey, ListDefKey,
     StructDefKey, DictDefKey, TagsDefKey, UnionDefKey]
  DefKeysListStr = DefKeysList.join(", ")
  SyntaxHelp = &"""
  (1) reference to another datatype (YAML scalar node):

    <datatype_name>: <target_datatype_name>

  (2) new definition (YAML mapping node):

    <datatype_name>:
      <defkey>: <value>
      [optional keys...]

  where <defkey> is one of: {DefKeysListStr}
  """

proc collect_defnodes*(defroot: YamlNode, keys: openArray[string],
                      n_required = 1): seq[Option[YamlNode]] =
  result = getKeys(defroot, keys, n_required,
                   "Invalid datatype definition: \n")

proc validate_requires*(key1: string, optnode1: Option[YamlNode],
                        key2: string, optnode2: Option[YamlNode]) =
  if optnode1.is_some:
    if optnode2.is_none:
      raise newException(DefSyntaxError,
              &"Key '{key1}' requires key '{key2}'\n")

proc parse_datatype_definition_map(defroot: YamlNode, name: string):
                                          DatatypeDefinition {.inline.} =
  for defkey, _ in defroot.pairs:
    case defkey.content:
    of IntRangeDefKey:   return newIntRangeDatatypeDefinition(defroot, name)
    of UintRangeDefKey:  return newUintRangeDatatypeDefinition(defroot, name)
    of FloatRangeDefKey: return newFloatRangeDatatypeDefinition(defroot, name)
    of ConstDefKey:      return newConstDatatypeDefinition(defroot, name)
    of EnumDefKey:       return newEnumDatatypeDefinition(defroot, name)
    of RegexMatchDefKey: return newRegexMatchDatatypeDefinition(defroot, name)
    of RegexesMatchDefKey:
                         return newRegexesMatchDatatypeDefinition(defroot, name)
    of ListDefKey:       return newListDatatypeDefinition(defroot, name)
    of StructDefKey:     return newStructDatatypeDefinition(defroot, name)
    of DictDefKey:       return newDictDatatypeDefinition(defroot, name)
    of TagsDefKey:       return newTagsDatatypeDefinition(defroot, name)
    of UnionDefKey:      return newUnionDatatypeDefinition(defroot, name)
    else: discard
  let emsg = "The definition YAML mapping node does not " &
    "include any of the keys for defining a datatype.\n"  &
    &"Node content (parsed YAML): {defroot}"
  raise_def_syntax_error(name, emsg, SyntaxHelp)

proc mark_unresolved_ref(dd: var DatatypeDefinition) =
  dd.has_unresolved_ref = false
  for sub in dd.children:
    if sub.has_unresolved_ref:
      dd.has_unresolved_ref = true
      break

proc newDatatypeDefinition*(node: YamlNode, name: string):
                            DatatypeDefinition {.noinit.} =
  case node.kind:
  of yScalar:
    result = newRefDatatypeDefinition(node, name)
    result.has_unresolved_ref = true
  of yMapping:
    result = parse_datatype_definition_map(node, name)
    result.mark_unresolved_ref
  of ySequence:
    let emsg = "Definition content is a YAML sequence node.\n" &
               &"Node content (as JSON): {node.to_json_node}"
    raise_def_syntax_error(name, emsg, SyntaxHelp)
