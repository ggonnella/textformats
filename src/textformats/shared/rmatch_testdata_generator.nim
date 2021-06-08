import tables, json, strformat, options, strtabs, osproc, strutils, os
import regex
export regex
import ../types/testdata
import ../testdata_generator

proc handle_reverse*(t: var TestData, e: Option[TableRef[JsonNode, string]]) =
  if e.is_some:
    for decoded, canonical in e.unsafe_get:
      if canonical in t.o: t.o.del(canonical)
      t.v[canonical] = decoded
  else:
    for k, v in t.o:
      t.v[k] = v
    t.o = newTable[string, JsonNode]()

proc normalize_regex(rgx: string): string =
  result = rgx.replace(   re"^\\w",      "[a-zA-Z]")
  result = result.replace(re"(?<!\)\\w", "[a-zA-Z]")
  result = result.replace(re"^\\d",      "[0-9]")
  result = result.replace(re"(?<!\)\\d", "[0-9]")

iterator exrex(rgx: string, n_random_strings: int,
               max_range_size: int): string =
  let r = normalize_regex(rgx).quote_shell
  for line in exec_cmd_ex(&"for i in {{1..{n_random_strings}}}; " &
                            &"do exrex -l {max_range_size} -r {r}; " &
                           "done").output.split_lines:
    yield line

proc process_regex*(t: var TestData, rgx: string,
                   decoded: Option[JsonNode],
                   n_random_strings = 10,
                   max_range_size = 5) =
  for line in exrex(rgx, n_random_strings, max_range_size):
    if line.len > 0 and line notin t.o:
      let d = if decoded.is_some: decoded.unsafe_get else: %*line
      t.o[line] = d

template matches_any*(k: string, regexes: seq[Regex]): bool =
  var result = false
  for r in regexes:
    if k.match(r):
      result = true
      break
  result

template add_if_invalid_and_not_matching(t: var TestData, k: string,
                                         r: Regex or seq[Regex]) =
  let k_local = k
  if k_local notin t.o and k_local notin t.e:
    var m = when r is Regex: k_local.match(r) else: k_local.matches_any(r)
    if not m: t.e.add(k_local)

proc reverse(str: string): string =
  result = ""
  for index in countdown(str.high, 0):
    result.add(str[index])

proc add_invalid_encoded_for_regex*(t: var TestData, rgx: Regex or seq[Regex]) =
  t.add_if_invalid_and_not_matching("X", rgx)
  for k in t.o.keys:
    if k.len > 1:
      t.add_if_invalid_and_not_matching(k[0..^2], rgx)
    t.add_if_invalid_and_not_matching(k & "X", rgx)
    t.add_if_invalid_and_not_matching(k.reverse, rgx)

let simple_json_values* = block:
  var
    array1elem = newJArray()
    object1elem = newJObject()
  array1elem.add(newJInt(0))
  object1elem["a"] = newJInt(0)
  @[newJString("A"), newJString("1"), newJInt(-1), newJInt(0), newJInt(1),
    newJFloat(1.0), newJObject(), newJArray(), newJBool(true), newJBool(false),
    newJNull(), array1elem, object1elem]

proc json_modified*(json_value: JsonNode): seq[JsonNode] =
  result = newseq[JsonNode]()
  case json_value.kind:
  of JNull: discard
  of JBool: result.add(if json_value.get_bool: %*false else: %*true)
  of JInt:
    let i = json_value.get_int
    if i < int.high: result.add(%*(i+1))
    if i > int.low: result.add(%*(i-1))
  of JFloat:
    let f = json_value.get_float
    if f+1 != Inf: result.add(%*(f+1.0))
    if f-1 != NegInf: result.add(%*(f-1.0))
  of JString:
    let s = json_value.get_str
    if s.len > 0: result.add(%*(s[0..^2]))
    result.add(%*(s&"X"))
  of JArray:
    if json_value.len > 0:
      var a2 = newJArray()
      for i in 0..<json_value.len-1:
        a2.add(%(json_value[i]))
      result.add(a2)
    var a3 = json_value.copy
    a3.add(%"X")
    result.add(a3)
  of JObject:
    var o2 = json_value.copy
    o2["X"] = %*"x"
    result.add(o2)

proc json_modified*(j: seq[JsonNode]): seq[JsonNode] =
  result = newseq[JsonNode]()
  for d in j:
    for m in json_modified(d):
      if m notin j:
        result.add_if_unique(m)
