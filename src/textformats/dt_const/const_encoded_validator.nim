import strutils
import ../types / [datatype_definition, match_element]

proc const_is_valid*(input: string, dd: DatatypeDefinition): bool =
  case dd.constant_element.kind:
  of meFloat:
    try: return parse_float(input) == dd.constant_element.f_value
    except ValueError: return false
  of meInt:
    try: return parse_int(input) == dd.constant_element.i_value
    except ValueError: return false
  of meString: return input == dd.constant_element.s_value

