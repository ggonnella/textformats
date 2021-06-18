import tables
import json
import options
import ../types / [datatype_definition, testdata]
import ../support/openrange

proc list_generate_testdata*(t: var TestData, dd: DatatypeDefinition)

import ../testdata_generator

proc add_empty_list(t: var TestData, dd: DatatypeDefinition) =
  var encoded = dd.pfx & dd.sfx
  let decoded = newJArray()
  t.v[encoded] = decoded

proc list_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  if 0 in dd.lenrange:
    add_empty_list(t, dd)
  else:
    t.d.add_if_unique(newJArray())
  if dd.lenrange.high > 0:
    var
      member_t = new_testdata("")
      encoded = dd.pfx
      decoded = newJArray()
      n_added = 0
    member_t.generate_testdata(dd.members_def)
    while true:
      for k, v in member_t.v:
        # do not take special float values due to inconsistent handling
        # in older versions of json library
        if v.kind == JFloat:
          let f = v.to(float)
          if f == Inf or f == NegInf or f == NaN:
            continue
        if n_added > 0: encoded &= dd.sep
        encoded &= k
        decoded.add(v)
        n_added += 1
        if n_added == 1:
          if 1 in dd.lenrange:
            t.v[encoded & dd.sfx] = decoded.copy
            if dd.lenrange.high == 1:
              return
          else:
            t.e.add_if_unique(encoded & dd.sfx)
            t.d.add_if_unique(decoded.copy)
        if n_added >= dd.lenrange.low:
          t.v[encoded & dd.sfx] = decoded
          return
        else:
          t.e.add_if_unique(encoded & dd.sfx)
          t.d.add_if_unique(decoded.copy)
