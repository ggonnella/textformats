# standard library
import strutils, strformat
import types/datatype_definition

proc verbose_desc*(d: DatatypeDefinition, indent: int): string
proc tabular_desc*(d: DatatypeDefinition, indent: int): string
proc repr_desc*(d: DatatypeDefinition, indent: int): string

import dt_anyfloat/anyfloat_introspection
import dt_anyint/anyint_introspection
import dt_anystring/anystring_introspection
import dt_anyuint/anyuint_introspection
import dt_json/json_introspection
import dt_const/const_introspection
import dt_enum/enum_introspection
import dt_intrange/intrange_introspection
import dt_uintrange/uintrange_introspection
import dt_floatrange/floatrange_introspection
import dt_regexmatch/regexmatch_introspection
import dt_regexesmatch/regexesmatch_introspection
import dt_list/list_introspection
import dt_struct/struct_introspection
import dt_dict/dict_introspection
import dt_tags/tags_introspection
import dt_union/union_introspection
import dt_ref/ref_introspection
import shared/encoded_introspection
import shared/implicit_introspection
import shared/formatting_introspection
import shared/as_string_introspection
import shared/scope_introspection
import shared/null_value_introspection
import shared/generated_regex_introspection

proc `$`*(dd: DatatypeDefinition): string =
  dd.verbose_desc(0)

proc repr*(dd: DatatypeDefinition): string =
  dd.repr_desc(0)

proc describe(kind: DatatypeDefinitionKind): string =
  case kind:
  of ddkRef:          ref_describe
  of ddkAnyInteger:   anyint_describe
  of ddkAnyUInteger:  anyuint_describe
  of ddkAnyFloat:     anyfloat_describe
  of ddkIntRange:     intrange_describe
  of ddkUIntRange:    uintrange_describe
  of ddkFloatRange:   floatrange_describe
  of ddkAnyString:    anystring_describe
  of ddkRegexMatch:   regexmatch_describe
  of ddkRegexesMatch: regexesmatch_describe
  of ddkConst:        const_describe
  of ddkEnum:         enum_describe
  of ddkJson:         json_describe
  of ddkList:         list_describe
  of ddkStruct:       struct_describe
  of ddkDict:         dict_describe
  of ddkTags:         tags_describe
  of ddkUnion:        union_describe

proc verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx="  ".repeat(indent)
  if d.is_nil:
    return "(nil)"
  if indent == 0:
    result &= "Datatype: "
  else:
    result &= pfx
  result &= &"'{d.name}': {d.kind.describe}\n"
  case d.kind:
  of ddkRef:          result &= d.ref_verbose_desc(indent)
  of ddkIntRange:     result &= d.intrange_verbose_desc(indent)
  of ddkUIntRange:    result &= d.uintrange_verbose_desc(indent)
  of ddkFloatRange:   result &= d.floatrange_verbose_desc(indent)
  of ddkConst:        result &= d.const_verbose_desc(indent)
  of ddkEnum:         result &= d.enum_verbose_desc(indent)
  of ddkRegexMatch:   result &= d.regexmatch_verbose_desc(indent)
  of ddkRegexesMatch: result &= d.regexesmatch_verbose_desc(indent)
  of ddkList:         result &= d.list_verbose_desc(indent)
  of ddkStruct:       result &= d.struct_verbose_desc(indent)
  of ddkDict:         result &= d.dict_verbose_desc(indent)
  of ddkTags:         result &= d.tags_verbose_desc(indent)
  of ddkUnion:        result &= d.union_verbose_desc(indent)
  of ddkAnyFloat:     result &= d.anyfloat_verbose_desc(indent)
  of ddkAnyInteger:   result &= d.anyint_verbose_desc(indent)
  of ddkAnyString:    result &= d.anystring_verbose_desc(indent)
  of ddkAnyUInteger:  result &= d.anyuint_verbose_desc(indent)
  of ddkJson:         result &= d.json_verbose_desc(indent)
  result &= d.encoded_verbose_desc(indent)
  result &= d.implicit_verbose_desc(indent)
  result &= d.formatting_verbose_desc(indent)
  result &= d.as_string_verbose_desc(indent)
  result &= d.null_value_verbose_desc(indent)
  result &= d.generated_regex_verbose_desc(indent)
  result &= d.scope_verbose_desc(indent)

proc repr_desc*(d: DatatypeDefinition, indent: int): string =
  var
    pfx=" ".repeat(indent)
    idt = indent
  if d.is_nil:
    return "{pfx}null\n"
  if indent == 0:
    result &= &"{pfx}{d.name}:"
    if d.kind == ddkRef:
      result &= &" {d.target_name}\n"
      return result
    else:
      result &= "\n"
      idt = 2
  case d.kind:
  of ddkRef:          return d.ref_repr_desc(idt)
  of ddkAnyInteger:   return d.anyint_repr_desc(idt)
  of ddkAnyUInteger:  return d.anyuint_repr_desc(idt)
  of ddkAnyFloat:     return d.anyfloat_repr_desc(idt)
  of ddkAnyString:    return d.anystring_repr_desc(idt)
  of ddkJson:         return d.json_repr_desc(idt)
  of ddkIntRange:     result &= d.intrange_repr_desc(idt)
  of ddkUIntRange:    result &= d.uintrange_repr_desc(idt)
  of ddkFloatRange:   result &= d.floatrange_repr_desc(idt)
  of ddkRegexMatch:   result &= d.regexmatch_repr_desc(idt)
  of ddkRegexesMatch: result &= d.regexesmatch_repr_desc(idt)
  of ddkConst:        result &= d.const_repr_desc(idt)
  of ddkEnum:         result &= d.enum_repr_desc(idt)
  of ddkList:         result &= d.list_repr_desc(idt)
  of ddkStruct:       result &= d.struct_repr_desc(idt)
  of ddkDict:         result &= d.dict_repr_desc(idt)
  of ddkTags:         result &= d.tags_repr_desc(idt)
  of ddkUnion:        result &= d.union_repr_desc(idt)
  result &= d.encoded_repr_desc(idt)
  result &= d.implicit_repr_desc(idt)
  result &= d.formatting_repr_desc(idt)
  result &= d.as_string_repr_desc(idt)
  result &= d.scope_repr_desc(idt)
  result &= d.null_value_repr_desc(idt)

proc tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.is_nil:
    return &"{pfx}(nil)"
  if indent == 0:
    result &=  &"{pfx}Datatype definition:\n"
  result &= &"{pfx}- name: {d.name}\n"
  result &= &"{pfx}- kind: {d.kind}\n"
  result &= d.generated_regex_tabular_desc(indent)
  result &= d.null_value_tabular_desc(indent)
  result &= d.formatting_tabular_desc(indent)
  case d.kind:
  of ddkRef:          result &= d.ref_tabular_desc(indent)
  of ddkIntRange:     result &= d.intrange_tabular_desc(indent)
  of ddkUIntRange:    result &= d.uintrange_tabular_desc(indent)
  of ddkFloatRange:   result &= d.floatrange_tabular_desc(indent)
  of ddkConst:        result &= d.const_tabular_desc(indent)
  of ddkEnum:         result &= d.enum_tabular_desc(indent)
  of ddkRegexMatch:   result &= d.regexmatch_tabular_desc(indent)
  of ddkRegexesMatch: result &= d.regexesmatch_tabular_desc(indent)
  of ddkList:         result &= d.list_tabular_desc(indent)
  of ddkStruct:       result &= d.struct_tabular_desc(indent)
  of ddkDict:         result &= d.dict_tabular_desc(indent)
  of ddkTags:         result &= d.tags_tabular_desc(indent)
  of ddkUnion:        result &= d.union_tabular_desc(indent)
  of ddkAnyFloat:     result &= d.anyfloat_tabular_desc(indent)
  of ddkAnyInteger:   result &= d.anyint_tabular_desc(indent)
  of ddkAnyUInteger:  result &= d.anyuint_tabular_desc(indent)
  of ddkAnyString:    result &= d.anystring_tabular_desc(indent)
  of ddkJson:         result &= d.json_tabular_desc(indent)
  result &= d.encoded_tabular_desc(indent)
  result &= d.implicit_tabular_desc(indent)
  result &= d.as_string_tabular_desc(indent)
  result &= d.scope_tabular_desc(indent)
