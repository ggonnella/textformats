import strutils
import ../types / [datatype_definition, match_element]

proc enum_is_valid*(input: string, dd: DatatypeDefinition): bool =
  for me in dd.elements:
    case me.kind:
    of meFloat:
      try:
        if parse_float(input) == me.f_value:
          return true
      except ValueError: continue
    of meInt:
      try:
        if parse_int(input) == me.i_value:
          return true
      except ValueError: continue
    of meString:
      if input == me.s_value:
        return true
  return false

