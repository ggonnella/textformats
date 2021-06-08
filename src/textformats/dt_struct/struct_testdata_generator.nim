import tables, json
import ../types / [datatype_definition, testdata]

proc struct_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc finalize(t: var TestData, dd: DatatypeDefinition,
              decoded: JsonNode, encoded: string) =
  for name_value in dd.implicit:
    decoded[name_value[0]] = name_value[1]
  t.v[encoded & dd.sfx] = decoded

proc struct_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  var
    encoded = dd.pfx
    decoded = newJObject()
    i = 0
  for m in dd.members:
    let
      (e, d) = get_one_v_from_subdef(m.def)
    if i > 0: encoded &= dd.sep
    encoded &= e
    decoded[m.name] = d
    i += 1
    if i >= dd.n_required:
      t.finalize(dd, decoded.copy, encoded)
