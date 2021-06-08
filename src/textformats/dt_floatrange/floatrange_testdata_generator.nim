import tables
import json
import ../types / [datatype_definition, testdata]
import ../shared/num_testdata_generator

proc floatrange_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  t.add_invalid_float()
  var values = @[0.0, -1.0, 1.0, NegInf, Inf]
  if dd.min_f > float.low:
    values.add(dd.min_f)
    if dd.min_f - 1.0 > float.low:
      values.add(dd.min_f - 1.0)
  if dd.max_f < float.high:
    values.add(dd.max_f)
    if dd.max_f + 1.0 < float.high:
      values.add(dd.max_f + 1.0)
  t.check_range_and_add(values, dd.min_f, dd.max_f, dd.min_incl, dd.max_incl)

