import tables
import json
import ../types / [datatype_definition, testdata]

proc json_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc add_valid_json(t: var TestData) =
  t.v["\"c\""] = newJString("c")
  t.v["1"] = newJInt(1)
  t.v["1.0"] = newJFloat(1.0)
  t.v["true"] = newJBool(true)
  t.v["false"] = newJBool(false)
  t.v["null"] = newJNull()
  var o = newJObject()
  o["a"] = newJInt(1)
  o["b"] = newJInt(2)
  t.v["{\"a\":1,\"b\":2}"] = o
  t.v["[\"d\",\"e\"]"] = %*(["d", "e"])
  t.v["{}"] = newJObject()
  t.v["[]"] = newJArray()
  t.v["\"\""] = newJString("")

proc add_invalid_json(t: var TestData) =
  t.e.add_if_unique("([}")
  t.e.add_if_unique("c")

proc json_generate_testdata*(t: var Testdata, dd: DatatypeDefinition) =
  t.add_valid_json()
  t.add_invalid_json()

