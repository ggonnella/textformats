## MatchElement
##
## An element defining a string matching rule, which can be:
## - a constant string
## - a constant integer or float
##   (which is to be converted into the corresponding string)

import strformat, json

type
  MatchElementKind* = enum
    meFloat, meInt, meString
  MatchElement* = ref MatchElementObj
  MatchElementObj = object
    case kind*: MatchElementKind
      of meFloat:  f_value*: float
      of meInt:    i_value*: int64
      of meString: s_value*: string

include match_element_msgpack

proc to_string*(self: MatchElement): string =
  case self.kind:
    of meFloat:  result = $self.f_value
    of meInt:    result = $self.i_value
    of meString: result = self.s_value

proc to_json*(self: MatchElement): string =
  case self.kind:
    of meFloat:  result = $(%self.f_value)
    of meInt:    result = $(%self.i_value)
    of meString: result = $(%self.s_value)

proc `$`*(self: MatchElement): string =
  case self.kind:
    of meFloat:  result = &"float:{self.f_value}"
    of meInt:    result = &"int:{self.i_value}"
    of meString: result = &"string:{%*self.s_value}"
