import strformat
import ../types / [datatype_definition, textformats_error]

proc validate_and_remove_pfx_and_sfx*(input: string, dd: DatatypeDefinition,
                                      emsg_pfx = "", emsg_sfx = ""): string =
  var slice: Slice[int]
  if dd.pfx.len > input.len:
    raise newException(DecodingError, emsg_pfx &
            &"No prefix '{dd.pfx}' found in '{input}'" & emsg_sfx)
  if dd.sfx.len > input.len:
    raise newException(DecodingError, emsg_pfx &
            &"No suffix '{dd.sfx}' found in '{input}'" & emsg_sfx)
  slice.a = dd.pfx.len
  slice.b = input.len - 1 - dd.sfx.len
  if dd.pfx.len > 0:
    let pfx = input[0 ..< slice.a]
    if pfx != dd.pfx:
      raise newException(DecodingError, emsg_pfx &
              &"No prefix '{dd.pfx}' found in '{input}'" & emsg_sfx)
  if dd.sfx.len > 0:
    let sfx = input[slice.b + 1 ..< input.len]
    if sfx != dd.sfx:
      raise newException(DecodingError, emsg_pfx &
              &"No suffix '{dd.sfx}' found in '{input}'" & emsg_sfx)
  return input[slice]

