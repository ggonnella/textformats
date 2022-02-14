import msgpack4nim

proc pack_type*[ByteStream](s: ByteStream, me: MatchElement) =
  s.pack(me.kind)
  case me.kind:
    of meFloat:
      s.pack(me.f_value)
    of meInt:
      s.pack(me.i_value)
    of meString:
      s.pack(me.s_value)

proc unpack_type*[ByteStream](s: ByteStream, me: var MatchElement) =
  var k: MatchElementKind
  s.unpack(k)
  me = MatchElement(kind: k)
  case k:
    of meFloat:
      s.unpack(me.f_value)
    of meInt:
      s.unpack(me.i_value)
    of meString:
      s.unpack(me.s_value)

