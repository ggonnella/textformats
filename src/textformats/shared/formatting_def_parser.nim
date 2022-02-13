import strformat
import regex
import ../support/yaml_support
import ../types / [def_syntax, textformats_error]

const
  SepHelp* = "separator between elements, which also be contained in the " &
             "elements (string, default: none)"
  SplittedHelp* = "separator between elements, which is never contained in " &
             "the elements (also not escaped), thus can be used to split " &
             "them (string, default: none)"
  SplittedLastHelp* = "separator between elements, which is never contained " &
             "in the elements (also not escaped), with the possible " &
             "exception of the last element (if all elements are present); " &
             "thus it can be used to split the elements (string, default: none)"
  PfxHelp* = "constant prefix before first element, if any " &
                " (string, default: none)"
  SfxHelp* = "constant suffix after last element, if any " &
                " (string, default: none)"

proc parse_sep*(sep_node: OptYamlNode,
                splitted_node: OptYamlNode): (string, bool) =
  if sep_node.is_some:
    if splitted_node.is_some:
      raise newException(DefSyntaxError,
              &"The keys '{SepKey}' and '{SplittedKey}' " &
              "are mutually exclusive\n")
    else:
      let sep = sep_node.to_string(default="", SepKey)
      return (sep, false)
  elif splitted_node.is_some:
      let sep = splitted_node.to_string(default="", SplittedKey)
      return (sep, len(sep) > 0)
  else:
    return ("", false)

proc parse_pfx*(node: OptYamlNode): string =
  node.to_string(default="", PfxKey)

proc parse_sfx*(node: OptYamlNode): string =
  node.to_string(default="", SfxKey)

proc validate_separators*(sep: string, internal_sep: string,
                          internal_sep_key: string, internal_sep_lbl: string) =
  if sep.len == 0:
      raise newException(DefSyntaxError,
              &"Separator (key '{SplittedKey}') " &
              "cannot be an empty string\n")
  if internal_sep.len == 0:
      raise newException(DefSyntaxError,
              &"The {internal_sep_lbl} separator (key '{internal_sep_key}') " &
              "cannot be an empty string\n")
  if sep == internal_sep:
    raise newException(DefSyntaxError,
      &"The {internal_sep_lbl} separator (key '{internal_sep_key}') " &
      &"cannot be equal to the elements separator (key '{SplittedKey}')\n" &
      &"Found: {sep}\n")
  if sep.escape_re.re in internal_sep:
    raise newException(DefSyntaxError,
      &"The {internal_sep_lbl} separator (key '{internal_sep_key}') " &
      &"cannot contain the elements separator (key '{SplittedKey}')\n" &
      &"Found '{SplittedKey}': {sep}\n" &
      &"Found '{internal_sep_key}': {internal_sep}\n")

proc validate_names_vs_separator*(names: seq[string], namelbl: string,
                                  sep: string, seplbl: string) =
  let sep_re = sep.escape_re.re
  for name in names:
    if sep_re in name:
      raise newException(DefSyntaxError,
              &"{namelbl} contains the specified {seplbl} separator\n" &
              &"{namelbl}: {name}\nSeparator: {sep}\n")

