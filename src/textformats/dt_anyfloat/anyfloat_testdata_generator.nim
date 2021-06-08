import tables
import json
import ../types / [datatype_definition, testdata]
import ../support / [openrange]
import ../shared/num_testdata_generator

proc add_valid_anyfloat(t: var TestData) =
  let values = @[0.0, 1.0, -1.0, Inf, NegInf]
  for v in values: t.v[$v] = %*v

proc anyfloat_generate_testdata*(t: var Testdata, dd: DatatypeDefinition) =
  t.add_invalid_float()
  t.add_valid_anyfloat()
