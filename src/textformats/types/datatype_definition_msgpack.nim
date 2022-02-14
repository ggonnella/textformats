import msgpack4nim

proc pack_type*[ByteStream](s: ByteStream, dd: DatatypeDefinition) =
  #echo("packing...")
  #echo("  kind:" & dd.kind.repr)
  s.pack(dd.kind)
  s.pack(dd.name)
  s.pack(dd.regex)
  s.pack(dd.sep)
  s.pack(dd.sep_excl)
  s.pack(dd.pfx)
  s.pack(dd.sfx)
  #echo("  " & dd.name)
  if dd.null_value.is_some:
    s.pack(true)
    s.pack($(dd.null_value.unsafe_get))
  else:
    s.pack(false)
  s.pack(dd.decoded.len)
  for e in dd.decoded:
    if e.is_some:
      s.pack(true)
      s.pack($(e.unsafe_get))
    else:
      s.pack(false)
  if dd.encoded.is_some:
    s.pack(true)
    let t = dd.encoded.unsafe_get
    s.pack(t.len)
    for tk, tv in t.pairs:
      s.pack($tk)
      s.pack(tv)
  else:
    s.pack(false)
  s.pack(dd.implicit.len)
  for e in dd.implicit:
    s.pack(e.name)
    s.pack($(e.value))
  s.pack(dd.as_string)
  s.pack(dd.scope)
  s.pack(dd.unitsize)
  s.pack(true)
  s.pack(dd.regex_computed)
  #echo(dd.repr)
  case dd.kind:
    of ddkJson,
       ddkAnyInteger, ddkAnyUInteger,
       ddkAnyFloat, ddkAnyString, ddkRegexMatch: discard
    of ddkRef:
      #if dd.target.isNil:
      #  s.pack(false)
      #else:
      #  s.pack(true)
      #  s.pack(dd.target)
      s.pack(dd.target_name)
    of ddkIntRange:
      s.pack(dd.range_i)
    of ddkUIntRange:
      s.pack(dd.range_u)
      s.pack(dd.base)
    of ddkFloatRange:
      s.pack(dd.min_f)
      s.pack(dd.max_f)
      s.pack(dd.min_incl)
      s.pack(dd.max_incl)
    of ddkConst:
      s.pack(dd.constant_element)
    of ddkEnum:
      s.pack(dd.elements)
    of ddkRegexesMatch:
      s.pack(dd.regexes_raw)
      s.pack(dd.regexes_compiled)
    of ddkList:
      s.pack(dd.members_def)
      s.pack(dd.lenrange)
    of ddkStruct:
      s.pack(dd.members)
      s.pack(dd.n_required)
      s.pack(dd.hidden)
    of ddkDict:
      s.pack(dd.dict_members.len)
      for tk, tv in dd.dict_members:
        s.pack(tk)
        s.pack(tv)
      s.pack(dd.required_keys)
      s.pack(dd.single_keys)
      s.pack(dd.dict_internal_sep)
    of ddkTags:
      s.pack(dd.tagname_regex_raw)
      s.pack(dd.tagname_regex_compiled)
      s.pack(dd.tagtypes.len)
      for tk, tv in dd.tagtypes:
        s.pack(tk)
        s.pack(tv)
      s.pack(dd.predefined_tags)
      s.pack(dd.tags_internal_sep)
      s.pack(dd.type_key)
      s.pack(dd.value_key)
    of ddkUnion:
      s.pack(dd.choices)
      s.pack(dd.wrapped)
      s.pack(dd.branch_names)
      s.pack(dd.branch_pfx)
      s.pack(dd.branch_pfx_ensure)
  #echo("  finished")

proc unpack_type*[ByteStream](s: ByteStream, dd: var DatatypeDefinition) =
  #echo("unpacking...")
  var
    k: DatatypeDefinitionKind
    has_value: bool
    l: int
  s.unpack(k)
  dd = DatatypeDefinition(kind: k)
  #echo("  kind:" & dd.kind.repr)
  s.unpack(dd.name)
  #echo("  " & dd.name)
  s.unpack(dd.regex)
  s.unpack(dd.sep)
  s.unpack(dd.sep_excl)
  s.unpack(dd.pfx)
  s.unpack(dd.sfx)
  s.unpack(has_value)
  if has_value:
    var str: string
    s.unpack(str)
    dd.null_value = parseJson(str).some
  s.unpack(l)
  for i in 0 ..< l:
    s.unpack(has_value)
    if has_value:
      var str: string
      s.unpack(str)
      dd.decoded.add(parseJson(str).some)
    else:
      dd.decoded.add(none(JsonNode))
  s.unpack(has_value)
  if has_value:
    s.unpack(l)
    var t = newTable[JsonNode, string]()
    for i in 0 ..< l:
      var
        tk: string
        tv: string
      s.unpack(tk)
      s.unpack(tv)
      t[parseJson(tk)] = tv
    dd.encoded = t.some
  s.unpack(l)
  for i in 0 ..< l:
    var e: tuple[name: string, value: JsonNode]
    s.unpack(e.name)
    var str: string
    s.unpack(str)
    e.value = parseJson(str)
    dd.implicit.add(e)
  s.unpack(dd.as_string)
  s.unpack(dd.scope)
  s.unpack(dd.unitsize)
  s.unpack(dd.has_unresolved_ref)
  s.unpack(dd.regex_computed)
  #echo(dd.repr)
  case dd.kind:
    of ddkJson,
       ddkAnyInteger, ddkAnyUInteger,
       ddkAnyFloat, ddkAnyString, ddkRegexMatch:
      discard
    of ddkRef:
      #s.unpack(has_value)
      #if has_value:
      #  s.unpack(dd.target)
      s.unpack(dd.target_name)
    of ddkIntRange:
      s.unpack(dd.range_i)
    of ddkUIntRange:
      s.unpack(dd.range_u)
      s.unpack(dd.base)
    of ddkFloatRange:
      s.unpack(dd.min_f)
      s.unpack(dd.max_f)
      s.unpack(dd.min_incl)
      s.unpack(dd.max_incl)
    of ddkConst:
      s.unpack(dd.constant_element)
    of ddkEnum:
      s.unpack(dd.elements)
    of ddkRegexesMatch:
      s.unpack(dd.regexes_raw)
      s.unpack(dd.regexes_compiled)
    of ddkList:
      s.unpack(dd.members_def)
      s.unpack(dd.lenrange)
    of ddkStruct:
      s.unpack(dd.members)
      s.unpack(dd.n_required)
      s.unpack(dd.hidden)
    of ddkDict:
      s.unpack(l)
      dd.dict_members = newTable[string, DatatypeDefinition]()
      for i in 0 ..< l:
        var
          tk: string
          tv: DatatypeDefinition
        s.unpack(tk)
        s.unpack(tv)
        dd.dict_members[tk] = tv
      s.unpack(dd.required_keys)
      s.unpack(dd.single_keys)
      s.unpack(dd.dict_internal_sep)
    of ddkTags:
      s.unpack(dd.tagname_regex_raw)
      s.unpack(dd.tagname_regex_compiled)
      s.unpack(l)
      dd.tagtypes = newTable[string, DatatypeDefinition]()
      for i in 0 ..< l:
        var
          tk: string
          tv: DatatypeDefinition
        s.unpack(tk)
        s.unpack(tv)
        dd.tagtypes[tk] = tv
      s.unpack(dd.predefined_tags)
      s.unpack(dd.tags_internal_sep)
      s.unpack(dd.type_key)
      s.unpack(dd.value_key)
    of ddkUnion:
      s.unpack(dd.choices)
      s.unpack(dd.wrapped)
      s.unpack(dd.branch_names)
      s.unpack(dd.branch_pfx)
      s.unpack(dd.branch_pfx_ensure)
  #echo("  finished")
