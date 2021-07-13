import tables
import json
import options
import ../types / [datatype_definition, testdata]
import ../support / [openrange]
import ../shared/num_testdata_generator

proc intrange_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  t.add_invalid_int()
  var values = @[0'i64, -1'i64, 1'i64]
  values.add(dd.range_i.low)
  if dd.range_i.low > int.low:
    values.add(dd.range_i.low-1)
  values.add(dd.range_i.high)
  if dd.range_i.high < int.high:
    values.add(dd.range_i.high+1)
  t.check_range_and_add(values, dd.range_i.low, dd.range_i.high)

