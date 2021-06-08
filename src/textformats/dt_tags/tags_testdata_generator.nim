import json, options, sets, tables
import ../types / [datatype_definition, testdata]
import ../shared/rmatch_testdata_generator

proc tags_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc get_random_tagnames(dd: DatatypeDefinition): HashSet[string] =
  var name_t = new_testdata("")
  name_t.process_regex(dd.tagname_regex_raw, none(JsonNode),
                       n_random_strings = dd.tagtypes.len +
                                          dd.predefined_tags.len)
  for k in name_t.o.keys:
    result.incl(k)

proc tags_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  var
    decoded = newJObject()
    encoded = dd.pfx
    names = dd.get_random_tagnames
    i = 0
  for tagname, tagtype in dd.predefined_tags:
    let
      value_def = dd.tagtypes[tagtype]
      (e, d) = value_def.get_one_v_from_subdef
    if i > 0: encoded &= dd.sep
    encoded &= tagname & dd.tags_internal_sep & tagtype &
               dd.tags_internal_sep & e
    decoded[tagname] = %*{dd.typekey: tagtype, dd.valuekey: d}
    i += 1
  block tag_generation:
    for tagtype, value_def in dd.tagtypes:
      let
        (e, d) = value_def.get_one_v_from_subdef
      if names.len == 0:
        break tag_generation
      var tagname = names.pop
      while tagname in decoded:
        if names.len == 0:
          break tag_generation
        tagname = names.pop
      if i > 0: encoded &= dd.sep
      encoded &= tagname & dd.tags_internal_sep & tagtype &
                 dd.tags_internal_sep & e
      decoded[tagname] = %*{dd.typekey: tagtype, dd.valuekey: d}
      i += 1
  encoded &= dd.sfx
  for name_value in dd.implicit:
    decoded[name_value[0]] = name_value[1]
  t.v[encoded] = decoded
