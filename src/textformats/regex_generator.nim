##
## Construct regular expressions from DatatypeDefinitions
##

# standard library
import options
import strformat
# nimble libraries
import regex
# this library
import types / [datatype_definition, specification]
import introspection
import support/error_support
import support/openrange
import shared/formatting_regex_generator

proc compute_and_get_regex*(dd: DatatypeDefinition): DatatypeRegex
proc wo_group_names*(raw: string): string
proc pfx_group_names*(raw: string, pfx: string): string
proc to_named_group*(raw: string, name: string): string

# consider adding also the following predefined datatypes:
#PrCharRE       = r"[!-~]"
#HexDigitRE     = r"[0-9A-F]"
#HexRE          = r"[0-9A-F]+"

import dt_ref/ref_regex_generator
import dt_anyint/anyint_regex_generator
import dt_intrange/intrange_regex_generator
import dt_anyuint/anyuint_regex_generator
import dt_uintrange/uintrange_regex_generator
import dt_anyfloat/anyfloat_regex_generator
import dt_floatrange/floatrange_regex_generator
import dt_anystring/anystring_regex_generator
import dt_regexmatch/regexmatch_regex_generator
import dt_regexesmatch/regexesmatch_regex_generator
import dt_const/const_regex_generator
import dt_enum/enum_regex_generator
import dt_json/json_regex_generator
import dt_list/list_regex_generator
import dt_struct/struct_regex_generator
import dt_dict/dict_regex_generator
import dt_tags/tags_regex_generator
import dt_union/union_regex_generator

const
  NamedGroup*     = r"\(\?P<([_0-9a-zA-Z]+)>(.*)\)".re
  RenamedGroup*   = r"\(\?XP(<[_0-9a-zA-Z]+>.*)\)".re

proc wo_group_names*(raw: string): string =
  result = raw
  while NamedGroup in result:
    result = result.replace(NamedGroup, r"(?:$2)")

proc pfx_group_names*(raw: string, pfx: string): string =
  result = raw
  while NamedGroup in result:
    result = result.replace(NamedGroup, r"(?XP<"&pfx&"_$1>$2)")
  while RenamedGroup in result:
    result = result.replace(RenamedGroup, r"(?P$1)")

proc to_named_group*(raw: string, name: string): string =
  "(?P<" & name & ">" & raw & ")"

proc compile_regex(dd: DatatypeDefinition) =
  try:
    let avoid_warning_tmp = dd.regex.raw.re
    dd.regex.compiled = avoid_warning_tmp
  except RegexError:
    reraise_prepend(
      &"Datatype definition: {dd}\n" &
      &"Error while trying to compile regex '{dd.regex.raw}'\n")

proc regex_apply_null_value(dd: DatatypeDefinition) =
  if dd.null_value.is_some:
    dd.regex.raw = &"(?:{dd.regex.raw})?"

proc compute_and_get_regex*(dd: DatatypeDefinition): DatatypeRegex =
  if not dd.regex_computed:
    case dd.kind:
      of ddkRef:          dd.ref_compute_regex()
      of ddkAnyInteger:   dd.anyint_compute_regex()
      of ddkAnyUInteger:  dd.anyuint_compute_regex()
      of ddkAnyFloat:     dd.anyfloat_compute_regex()
      of ddkIntRange:     dd.intrange_compute_regex()
      of ddkUIntRange:    dd.uintrange_compute_regex()
      of ddkFloatRange:   dd.floatrange_compute_regex()
      of ddkAnyString:    dd.anystring_compute_regex()
      of ddkRegexMatch:   dd.regexmatch_compute_regex()
      of ddkRegexesMatch: dd.regexesmatch_compute_regex()
      of ddkConst:        dd.const_compute_regex()
      of ddkEnum:         dd.enum_compute_regex()
      of ddkJson:         dd.json_compute_regex()
      of ddkList:         dd.list_compute_regex()
      of ddkStruct:       dd.struct_compute_regex()
      of ddkDict:         dd.dict_compute_regex()
      of ddkTags:         dd.tags_compute_regex()
      of ddkUnion:        dd.union_compute_regex()
    dd.regex_apply_formatting
    dd.regex_apply_null_value
    dd.compile_regex
    dd.regex_computed = true
  return dd.regex

proc compute_regex*(dd: DatatypeDefinition) =
  discard dd.compute_and_get_regex()

proc compute_regexes*(spec: Specification) =
  for name, definition in spec:
    definition.compute_regex
