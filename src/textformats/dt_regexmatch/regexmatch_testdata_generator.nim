import tables, json, options
import ../types / [datatype_definition, testdata]
import ../shared/rmatch_testdata_generator

proc regexmatch_generate_testdata*(t: var Testdata, dd: DatatypeDefinition)
import ../testdata_generator

proc add_invalid_decoded_for_regex(t: var TestData, decoded: Option[JsonNode]) =
  if decoded.is_none:
    for e in t.e:
      t.d.add_if_unique(%*e)
  else:
    for d in simple_json_values:
      if d != decoded.unsafe_get:
        t.d.add_if_unique(d)
    for d in decoded.unsafe_get.json_modified():
      t.d.add_if_unique(d)

proc add_regex_values(t: var TestData, dd: DatatypeDefinition) =
  process_regex(t, dd.regex.raw, dd.decoded[0])
  t.add_invalid_encoded_for_regex(dd.regex.compiled)
  t.add_invalid_decoded_for_regex(dd.decoded[0])

proc regexmatch_generate_testdata*(t: var Testdata, dd: DatatypeDefinition) =
  t.add_regex_values(dd)
  t.handle_reverse(dd.encoded)
