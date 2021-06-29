import options, strformat
import yaml/dom
import ../support/yaml_support
import ../types / [def_syntax, datatype_definition, textformats_error]

const
  ScopeValues* = "one of: line, unit, section, whole, undefined"
  ScopeHelp* = "(default: undefined) which part of a file can be decoded" &
               "by this definition; " & ScopeValues
  UnitsizeHelp* = "(default: 1) how many lines does a unit contain; " &
                  &"the value is used only if {ScopeKey}=unit"

proc parse_scope*(node: Option[YamlNode]): DatatypeDefinitionScope =
  let value = node.to_string(default="undefined", ScopeKey)
  case value:
  of "undefined": ddsUndef
  of "line": ddsLine
  of "unit": ddsUnit
  of "section": ddsSection
  of "whole": ddsWhole
  else:
    raise newException(DefSyntaxError, &"Invalid value for key '{ScopeKey}'\n" &
                       &"Expected: {ScopeValues}\nFound: {value}\n")

proc parse_unitsize*(node: Option[YamlNode]): int =
  result = node.to_int(default=1, UnitsizeKey)
  if result < 1:
    raise newException(DefSyntaxError,
                       &"Invalid value for key '{UnitsizeKey}'\n" &
                       &"Expected: integer >= 1\nFound: {result}\n")

