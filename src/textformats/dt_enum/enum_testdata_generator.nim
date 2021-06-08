import tables, json, options, sets
import ../types / [datatype_definition, testdata]

proc enum_generate_testdata*(t: var TestData, dd: DatatypeDefinition)
import ../shared/matchelement_testdata_generator

proc fix_invalid_encoded(t: var TestData) =
  var t_e_new = newseq[string]()
  for e in t.e:
    if e notin t.v and e notin t.o:
      t_e_new.add(e)
  t.e = t_e_new

proc fix_invalid_decoded(t: var TestData) =
  var t_d_new = newseq[JsonNode]()
  for d in t.d:
    var found = false
    for v in t.v.values:
      if d == v:
        found = true
        break
    if not found:
      for v in t.o.values:
        if d == v:
          found = true
          break
    if not found:
      t_d_new.add(d)
  t.d = t_d_new

proc handle_reverse(t: var TestData, e: Option[TableRef[JsonNode, string]]) =
  if e.is_some:
    let e1 = e.unsafe_get
    var moved_to_o: HashSet[string]
    for k, v in t.v:
      if v in e1:
        if k != e1[v]:
          discard t.o.has_key_or_put(k, v)
          moved_to_o.incl(k)
    for k in moved_to_o: t.v.del(k)

proc enum_generate_testdata*(t: var TestData, dd: DatatypeDefinition) =
  for i in 0..<dd.elements.len:
    t.add_constant_values(dd.elements[i], dd.decoded[i])
  t.fix_invalid_encoded()
  t.fix_invalid_decoded()
  t.handle_reverse(dd.encoded)
