import tables
import json
import options
import types / [datatype_definition, testdata]
export `$`

proc add_if_unique*(s: var seq[string], value: string)
proc add_if_unique*(s: var seq[JsonNode], value: JsonNode)
proc generate_testdata*(t: var TestData, dd: DatatypeDefinition)
proc get_one_v_from_subdef*(subdef: DatatypeDefinition): (string, JsonNode)
proc get_n_v_from_subdef*(subdef: DatatypeDefinition, n: Natural):
                        seq[(string, JsonNode)]
import dt_anyint/anyint_testdata_generator
import dt_intrange/intrange_testdata_generator
import dt_anyuint/anyuint_testdata_generator
import dt_uintrange/uintrange_testdata_generator
import dt_anyfloat/anyfloat_testdata_generator
import dt_floatrange/floatrange_testdata_generator
import dt_anystring/anystring_testdata_generator
import dt_regexmatch/regexmatch_testdata_generator
import dt_regexesmatch/regexesmatch_testdata_generator
import dt_const/const_testdata_generator
import dt_enum/enum_testdata_generator
import dt_json/json_testdata_generator
import dt_list/list_testdata_generator
import dt_struct/struct_testdata_generator
import dt_dict/dict_testdata_generator
import dt_tags/tags_testdata_generator
import dt_union/union_testdata_generator

proc add_if_unique*(s: var seq[string], value: string) =
  if value notin s: s.add(value)

proc add_if_unique*(s: var seq[JsonNode], value: JsonNode) =
  if value notin s: s.add(value)

template skip_special_floats(v: JsonNode) =
  # do not take special float values due to inconsistent handling
  # in older versions of json library
  if v.kind == JFloat:
    let f = v.to(float)
    if f == Inf or f == NegInf or f == NaN:
      continue

proc get_one_v_from_subdef*(subdef: DatatypeDefinition): (string, JsonNode) =
  var member_t = new_testdata("")
  member_t.generate_testdata(subdef)
  for k, v in member_t.v:
    skip_special_floats(v)
    return (k, v)

proc get_n_v_from_subdef*(subdef: DatatypeDefinition, n: Natural):
                        seq[(string, JsonNode)] =
  if n == 0:
    return newseq[(string, JsonNode)]()
  result = newseq_of_cap[(string, JsonNode)](n)
  var member_t = new_testdata("")
  member_t.generate_testdata(subdef)
  while true:
    let prevresultlen = result.len
    for k, v in member_t.v:
      skip_special_floats(v)
      result.add((k, v))
      if result.len == n:
        return
    # for this to work, each t.generate_testdata call must store at least
    # one non-float-special value in t.v
    assert result.len > prevresultlen

proc handle_null_value(t: var TestData, dd: DatatypeDefinition) =
  if dd.null_value.is_some:
    let v = %*dd.null_value.unsafe_get
    var
      shall_delete_from_t_v = false
      t_v_key_to_delete: string
    for k, val in t.v:
      if v == val:
        t.o[k] = val
        shall_delete_from_t_v = true
        t_v_key_to_delete = k
        break
    if shall_delete_from_t_v:
      t.v.del(t_v_key_to_delete)
    t.v[""] = v
    if v in t.d:
      t.d.delete(t.d.find(v))
    if "" in t.e:
      t.e.delete(t.e.find(""))
  else:
    # no special handling of empty strings;
    # if the empty string has not yet been added to valid
    # it is supposed to be invalid:
    var
      in_keys = false
      in_values = false
    for k, v in t.v:
      if k == "": in_keys = true
      if v.kind == JString and v.get_str == "": in_values = true
    for k, v in t.o:
      if k == "": in_keys = true
      if v.kind == JString and v.get_str == "": in_values = true
    if not in_keys: t.e.add_if_unique("")
    if not in_values: t.d.add_if_unique(%*"")

proc handle_as_string(t: var TestData, dd: DatatypeDefinition) =
  if dd.as_string:
    for k, val in t.v:
      t.v[k] = %*k

proc generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  case dd.kind:
  of ddkRef:          t.generate_testdata(dd.target)
  of ddkAnyInteger:   t.anyint_generate_testdata(dd)
  of ddkAnyUInteger:  t.anyuint_generate_testdata(dd)
  of ddkAnyFloat:     t.anyfloat_generate_testdata(dd)
  of ddkIntRange:     t.intrange_generate_testdata(dd)
  of ddkUIntRange:    t.uintrange_generate_testdata(dd)
  of ddkFloatRange:   t.floatrange_generate_testdata(dd)
  of ddkAnyString:    t.anystring_generate_testdata(dd)
  of ddkRegexMatch:   t.regexmatch_generate_testdata(dd)
  of ddkRegexesMatch: t.regexesmatch_generate_testdata(dd)
  of ddkConst:        t.const_generate_testdata(dd)
  of ddkEnum:         t.enum_generate_testdata(dd)
  of ddkJson:         t.json_generate_testdata(dd)
  of ddkList:         t.list_generate_testdata(dd)
  of ddkStruct:       t.struct_generate_testdata(dd)
  of ddkDict:         t.dict_generate_testdata(dd)
  of ddkTags:         t.tags_generate_testdata(dd)
  of ddkUnion:        t.union_generate_testdata(dd)
  t.handle_null_value(dd)
  t.handle_as_string(dd)

proc to_testdata*(dd: DatatypeDefinition, name: string): TestData =
  result = new_testdata(name)
  result.generate_testdata(dd)
