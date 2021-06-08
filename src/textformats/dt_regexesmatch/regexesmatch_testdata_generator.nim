import tables, json, options
import ../types / [datatype_definition, testdata]
import ../shared/rmatch_testdata_generator

proc regexesmatch_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../testdata_generator

proc add_invalid_decoded_for_regexes(t: var TestData,
                                     all_decoded: seq[JsonNode],
                                     wo_decoded: seq[Regex]) =
  for d in all_decoded.json_modified():
    if d.kind != JString or not d.get_str.matches_any(wo_decoded):
      t.d.add_if_unique(d)
  for e in t.e:
    if %e notin all_decoded:
      t.d.add_if_unique(%e)

proc regexesmatch_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  var
    regexes = newseq[Regex](dd.regexes_raw.len)
    all_decoded = newseq[JsonNode]()
    wo_decoded = newseq[Regex]()
  for i in 0..<dd.regexes_raw.len:
    let decoded = dd.decoded[i]
    regexes[i] = dd.regexes_compiled[i]
    if decoded.is_some: all_decoded.add_if_unique(decoded.unsafe_get)
    else: wo_decoded.add(regexes[i])
    t.process_regex(dd.regexes_raw[i], decoded)
  t.add_invalid_encoded_for_regex(regexes)
  t.add_invalid_decoded_for_regexes(all_decoded, wo_decoded)
  t.handle_reverse(dd.encoded)
