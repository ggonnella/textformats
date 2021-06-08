import tables
import json
import random
import ../types / [datatype_definition, testdata]

proc anystring_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc random_printable_string(length: int, spaced = false): string =
  let startchar = if spaced: ' ' else: '!'
  for _ in 0..<length:
    add(result, char(rand(int(startchar) .. int('~'))))

proc add_invalid_string(t: var TestData) =
  t.d.add_if_unique(newJInt(0))
  t.d.add_if_unique(newJFloat(0))
  t.d.add_if_unique(newJArray())
  t.d.add_if_unique(newJObject())

proc add_valid_anystring(t: var TestData) =
  let values = @[random_printable_string(5), "a", "A", " ", "1"]
  for v in values: t.v[$v] = %*v

proc anystring_generate_testdata*(t: var Testdata, dd: DatatypeDefinition) =
  t.add_valid_anystring()
  t.add_invalid_string()

