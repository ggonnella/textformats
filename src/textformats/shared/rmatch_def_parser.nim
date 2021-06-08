import yaml/dom
import ../support/yaml_support
import ../types/textformats_error

proc to_regex_raw*(n: YamlNode, errmsg: string): string =
  case n.kind:
    of yScalar:
      result = n.to_string
    of yMapping:
      n.validate_len(1, errmsg)
      for k, v in n:
        k.validate_is_scalar(errmsg)
        result = k.to_string
    of ySequence:
      raise newException(DefSyntaxError, errmsg)
