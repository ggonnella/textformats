import ../types / [datatype_definition, testdata]
import ../shared/matchelement_testdata_generator

proc const_generate_testdata*(t: var Testdata, dd: DatatypeDefinition) =
  t.add_constant_values(dd.constant_element, dd.decoded[0])
