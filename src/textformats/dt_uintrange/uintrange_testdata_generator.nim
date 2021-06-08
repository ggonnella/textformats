import tables
import json
import options
import ../types / [datatype_definition, testdata]
import ../support / [openrange]
import ../shared/num_testdata_generator

proc uintrange_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  t.add_invalid_uint()
  var values = @[0'u, 1'u]
  if dd.range_u.low > 0'u:
    values.add(dd.range_u.low-1'u)
    values.add(dd.range_u.low)
  values.add(dd.range_u.high)
  if dd.range_u.high < int.high.uint:
    values.add(dd.range_u.high+1'u)
  t.check_range_and_add(values, dd.range_u.low, dd.range_u.high)
