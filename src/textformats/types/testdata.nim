import tables, math, json, strutils, strformat

type Testdata* = object
  name*: string
  v*: TableRef[string, JsonNode]
  o*: TableRef[string, JsonNode]
  e*: seq[string]
  d*: seq[JsonNode]

proc new_testdata*(name: string): TestData =
  result.name = name
  result.v = newTable[string, JsonNode]()
  result.o = newTable[string, JsonNode]()
  result.e = newseq[string]()
  result.d = newseq[JsonNode]()

proc to_yaml(v: JsonNode): string =
  if v.kind == JFloat:
    let f = v.get_float
    if f == Inf: return ".Inf"
    elif f == NegInf: return "-.Inf"
    elif f.classify == fcNaN: return ".NaN"
  return $v

proc to_yaml(s: string): string =
  s.escape().replace("\\'", "'")

proc show_seq_inline(sq: seq[string] or seq[JsonNode]): string =
  result = " ["
  var i = 0
  for s in sq:
    if i > 0: result &= ", "
    result &= s.to_yaml
    i += 1
  result &= "]\n"

proc show_seq_multi_inline(sq: seq[string] or seq[JsonNode],
                           maxlen: Natural, indent: Natural,
                           maxnlines: Natural): string =
  result = " ["
  var
    i = 0
    n_lines = 1
    linelen = indent + 2
  for s in sq:
    let nextelem = s.to_yaml
    if i > 0:
      if linelen + 2 + nextelem.len > maxlen:
        result &= ",\n" & " ".repeat(indent)
        linelen = indent
        n_lines += 1
        if n_lines > maxnlines:
          return ""
      else:
        result &= ", "
        linelen += 2
    result &= nextelem
    linelen += nextelem.len
    if linelen > maxlen:
      return ""
    i += 1
  result &= "]\n"

proc show_seq_block(sq: seq[string] or seq[JsonNode],
                    indent: Natural): string =
  result = "\n"
  for s in sq:
    result &= " ".repeat(indent) & "- " & s.to_yaml & "\n"

proc show_seq(sq: seq[string] or seq[JsonNode],
              maxlen: Natural, indent: Natural, indent2: Natural): string =
  result = sq.show_seq_inline
  if result.len > maxlen:
    result = sq.show_seq_multi_inline(maxlen+18, indent+indent2, 5)
    if result.len == 0:
      result = sq.show_seq_block(indent)

proc show_table_inline(t: TableRef[string, JsonNode]): string =
  result = " {"
  var i = 0
  for k, v in t:
    if i > 0: result &= ", "
    result &= k.to_yaml & ":" & v.to_yaml
    i += 1
  result &= "}\n"

proc show_table_multi_inline(t: TableRef[string, JsonNode],
                             maxlen: Natural, indent: Natural,
                             maxnlines: Natural): string =
  result = " {"
  var
    i = 0
    n_lines = 1
    linelen = indent + 2
  for k, v in t:
    let nextelem = k.to_yaml & ":" & v.to_yaml
    if i > 0:
      if linelen + 2 + nextelem.len > maxlen:
        result &= ",\n" & " ".repeat(indent)
        linelen = indent
        n_lines += 1
        if n_lines > maxnlines:
          return ""
      else:
        result &= ", "
        linelen += 2
    result &= nextelem
    linelen += nextelem.len
    if linelen > maxlen:
      return ""
    i += 1
  result &= "}\n"

proc show_table_block(t: TableRef[string, JsonNode],
                      indent: Natural): string =
  result = "\n"
  for k, v in t:
    result &= " ".repeat(indent) & k.to_yaml & ": " & v.to_yaml & "\n"

proc show_table(t: TableRef[string, JsonNode],
                maxlen: Natural, indent: Natural,
                indent2: Natural): string =
  result = t.show_table_inline
  if result.len > maxlen:
    result = t.show_table_multi_inline(maxlen+18, indent+indent2, 5)
    if result.len == 0:
      result = t.show_table_block(indent)

proc show_valid(valid: TableRef[string, JsonNode],
                indent2: Natural): string =
  var diff_found = false
  for k, v in valid:
    if v.kind != JString or k != v.get_str:
      diff_found = true
      break
  if not diff_found:
    var keys: seq[string]
    for k in valid.keys(): keys.add(k)
    show_seq(keys, 60, 6, indent2)
  else:
    show_table(valid, 60, 6, indent2)

proc `$`*(t: TestData): string =
  result =  &"  {t.name}:\n"
  result &= "    valid:" & show_valid(t.v, 6)
  if len(t.o) > 0:
    result &= &"    oneway:" & show_valid(t.o, 7)
  result &= &"    invalid:\n"
  result &= &"      encoded:" & show_seq(t.e, 60, 8, 8)
  result &= &"      decoded:" & show_seq(t.d, 60, 8, 8)[0..^2]

