import regex
import ../types/datatype_definition

proc regex_apply_formatting*(dd: DatatypeDefinition) =
  dd.regex.raw = dd.pfx.escape_re & dd.regex.raw & dd.sfx.escape_re
