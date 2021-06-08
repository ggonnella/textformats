import tables
import json
import options
import ../types / [match_element, testdata]
import ../testdata_generator
import num_testdata_generator

proc add_invalid_decoded_values(t: var TestData, v: JsonNode) =
  if v.kind != JNull:
    t.d.add_if_unique(newJNull())
  if v.kind != JBool:
    t.d.add_if_unique(newJBool(true))
  else:
    t.d.add_if_unique(newJBool(not v.get_bool()))
  if v.kind != JInt:
    t.d.add_if_unique(newJInt(1))
  else:
    let i = v.get_int()
    if i < int.high:
      t.d.add_if_unique(newJInt(i+1))
    if i > int.low:
      t.d.add_if_unique(newJInt(i-1))
    for d in InvalidDecodedNumeric:
      t.d.add_if_unique(d)
  if v.kind != JFloat:
    t.d.add_if_unique(newJFloat(1.0))
  else:
    let f = v.get_float()
    if f < float.high:
      t.d.add_if_unique(newJFloat(f+1.0))
    if f > float.low:
      t.d.add_if_unique(newJFloat(f-1.0))
    for d in InvalidDecodedNumeric:
      t.d.add_if_unique(d)
  if v.kind != JArray:
    t.d.add_if_unique(newJArray())
  else:
    var v1 = copy(v)
    v1.add(newJInt(1))
    t.d.add_if_unique(v1)
  if v.kind != JObject:
    t.d.add_if_unique(newJObject())
  else:
    var k1 = "c"
    for k in v.keys:
      k1 = k & "c"
      if k1 notin v:
        break
    if k1 notin v:
      var v1 = copy(v)
      v1[k1] = newJInt(1)
      t.d.add_if_unique(v1)

proc add_invalid_encoded_float(t: var TestData, f: float) =
  var e: string
  if f < float.high:
    e = $(f + 1.0)
  if e notin t.v:
    t.e.add_if_unique(e)
  if f > float.low:
    e = $(f - 1.0)
  if e notin t.v:
    t.e.add_if_unique(e)

proc add_invalid_encoded_int(t: var TestData, i: int) =
  var e: string
  if i < int.high:
    e = $(i + 1)
  if e notin t.v:
    t.e.add_if_unique(e)
  if i > int.low:
    e = $(i - 1)
  if e notin t.v:
    t.e.add_if_unique(e)

proc add_invalid_encoded_strings(t: var TestData, s: string) =
  var e: string
  e = s & "c"
  if e notin t.v:
    t.e.add_if_unique(e)
  e = s[0..^2]
  if e.len > 0 and e notin t.v:
    t.e.add_if_unique(e)

proc add_constant_values*(t: var TestData, me: MatchElement,
                          d: Option[JsonNode]) =
  # uses has_key_or_put to avoid overwriting higher-precedence values
  var v: JsonNode
  case me.kind:
  of meFloat:
    v = if d.is_some: %*d.unsafe_get else: %*me.f_value
    let k = $me.f_value
    if k notin t.o: discard t.v.has_key_or_put(k, v)
    if me.f_value >= 0:
      let k1 = "+" & k
      if k1 notin t.v: discard t.o.has_key_or_put(k1, v)
    if me.f_value.int.float == me.f_value:
      let k1 = $(me.f_value.int)
      if k1 notin t.v: discard t.o.has_key_or_put(k1, v)
    add_invalid_encoded_float(t, me.f_value)
  of meInt:
    v = if d.is_some: %*d.unsafe_get else: %*me.i_value
    let k = $me.i_value
    if k notin t.o: discard t.v.has_key_or_put(k, v)
    if me.i_value >= 0:
      let k1 = "+" & k
      if k1 notin t.v: discard t.o.has_key_or_put(k1, v)
      if me.i_value == 0:
        if "-0" notin t.v: discard t.o.has_key_or_put("-0", v)
    add_invalid_encoded_int(t, me.i_value)
  of meString:
    v = if d.is_some: %*d.unsafe_get else: %*me.s_value
    discard t.v.has_key_or_put(me.s_value, v)
    add_invalid_encoded_strings(t, me.s_value)
  add_invalid_decoded_values(t, v)

