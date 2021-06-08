import tables
import strutils
import json
import ../types / [datatype_definition, testdata]

proc dict_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc dict_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  var
    encoded_parts = newseq[string]()
    decoded = newJObject()
  for name, def in dd.dict_members:
    var member_t = new_testdata("")
    member_t.generate_testdata(def)
    for k, v in member_t.v:
      # do not take special float values due to inconsistent handling
      # in older versions of json library
      if v.kind == JFloat:
        let f = v.to(float)
        if f == Inf or f == NegInf or f == NaN:
          continue
      encoded_parts.add(name & dd.dict_internal_sep & k)
      if name in dd.single_keys:
        decoded[name]=v
      else:
        if name notin decoded:
          decoded[name] = newJArray()
        decoded[name].add(v)
      break
  for name_value in dd.implicit:
    decoded[name_value[0]] = name_value[1]
  let encoded = dd.pfx & encoded_parts.join(dd.sep) & dd.sfx
  t.v[encoded] = decoded

