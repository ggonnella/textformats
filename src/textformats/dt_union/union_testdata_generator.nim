import tables, sequtils, json
import ../types / [datatype_definition, testdata]

import ../decoded_validator
import ../encoded_validator
#
# this module cannot be easily be made independent from the validators
# since it's difficult to generate a union set of valid and invalid values
#

proc union_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc valid_for_any(v: string or JsonNode, dd: DatatypeDefinition,
                   a: int, b: int): bool =
  for j in a..b:
    let cj = dd.choices[j]
    if v.is_valid(cj):
      return true
  return false

template wrapped(value: JsonNode, dd: DatatypeDefinition): JsonNode =
  if dd.wrapped: %{dd.branch_names[i]: value}
  else: value

proc union_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  for i in 0..<dd.choices.len:
    let c = dd.choices[i]
    var member_t = new_testdata("")
    member_t.generate_testdata(c)
    for v in member_t.d:
      let vw = v.wrapped(dd)
      if vw notin to_seq(t.v.values) and vw notin to_seq(t.o.values):
        if (i == 0 or not v.valid_for_any(dd, 0, i-1)) and
            (i == dd.choices.len - 1 or
              not v.valid_for_any(dd, i+1, dd.choices.len-1)):
          t.d.add_if_unique(vw)
    for k in member_t.e:
      if k notin t.v and k notin t.o:
        if (i == 0 or not k.valid_for_any(dd, 0, i-1)) and
          (i == dd.choices.len - 1 or
            not k.valid_for_any(dd, i+1, dd.choices.len-1)):
          t.e.add_if_unique(k)
    for k, v in member_t.v:
      let vw = v.wrapped(dd)
      if k notin t.o and k notin t.v:
        if i == 0 or not k.valid_for_any(dd, 0, i-1):
          if i == 0 or not v.valid_for_any(dd, 0, i-1):
            t.v[k] = vw
          else:
            t.o[k] = vw
          if vw in t.d: t.d.del(t.d.find(vw))
          if k in t.e: t.e.del(t.e.find(k))
    for k, v in member_t.o:
      let vw = v.wrapped(dd)
      if k notin t.o and k notin t.v:
        if i == 0 or not k.valid_for_any(dd, 0, i-1):
          t.o[k] = vw
          if vw in t.d: t.d.del(t.d.find(vw))
          if k in t.e: t.e.del(t.e.find(k))
