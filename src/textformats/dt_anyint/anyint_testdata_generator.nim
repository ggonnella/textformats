import tables
import json
import options
import ../types / [datatype_definition, testdata]
import ../support / [openrange]
import ../shared/num_testdata_generator

proc add_valid_anyint(t: var TestData) =
  let values = @[0, 1, -1, int.high, int.low]
  for v in values: t.v[$v] = %*v

proc anyint_generate_testdata*(t: var Testdata, dd: DatatypeDefinition) =
  t.add_invalid_int()
  t.add_valid_anyint()

