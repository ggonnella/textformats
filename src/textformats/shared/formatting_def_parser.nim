import options, strformat
from re import escape_re
import regex
import yaml/dom
import ../support/yaml_support
import ../types / [def_syntax, textformats_error]

const
  SepHelp* = "separator between elements, if any " &
                "(string, default: none)"
  SepExclHelp* = "is the separator string NOT present " &
                "in the elements (even not escaped)? (bool, default: true)"
  PfxHelp* = "constant prefix before first element, if any " &
                " (string, default: none)"
  SfxHelp* = "constant suffix after last element, if any " &
                " (string, default: none)"

proc parse_sep*(node: Option[YamlNode]): string =
  node.to_string(default="", SepKey)

proc parse_sep_excl*(node: Option[YamlNode]): bool =
  node.to_bool(default=true, SepExclKey)

proc parse_pfx*(node: Option[YamlNode]): string =
  node.to_string(default="", PfxKey)

proc parse_sfx*(node: Option[YamlNode]): string =
  node.to_string(default="", SfxKey)

proc validate_separators*(sep: string, internal_sep: string,
                          internal_sep_key: string, internal_sep_lbl: string) =
  if sep.len == 0:
      raise newException(DefSyntaxError,
              &"Separator (key '{SepKey}') " &
              "cannot be an empty string\n")
  if internal_sep.len == 0:
      raise newException(DefSyntaxError,
              &"The {internal_sep_lbl} separator (key '{internal_sep_key}') " &
              "cannot be an empty string\n")
  if sep == internal_sep:
    raise newException(DefSyntaxError,
      &"The {internal_sep_lbl} separator (key '{internal_sep_key}') " &
      &"cannot be equal to the elements separator (key '{SepKey}')\n" &
      &"Found: {sep}\n")
  if sep.escape_re.re in internal_sep:
    raise newException(DefSyntaxError,
      &"The {internal_sep_lbl} separator (key '{internal_sep_key}') " &
      &"cannot contain the elements separator (key '{SepKey}')\n" &
      &"Found '{SepKey}': {sep}\n" &
      &"Found '{internal_sep_key}': {internal_sep}\n")

template validate_sep_if_sepexcl*(sepexclnode: Option[YamlNode],
                                  sepnode: Option[YamlNode]) =
    validate_requires(SepExclKey, sepexclnode, SepKey, sepnode)

proc validate_names_vs_separator*(names: seq[string], namelbl: string,
                                  sep: string, seplbl: string) =
  let sep_re = sep.escape_re.re
  for name in names:
    if sep_re in name:
      raise newException(DefSyntaxError,
              &"{namelbl} contains the specified {seplbl} separator\n" &
              &"{namelbl}: {name}\nSeparator: {sep}\n")

