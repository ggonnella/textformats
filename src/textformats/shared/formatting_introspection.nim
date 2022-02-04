import strutils, strformat, json
import ../types / [datatype_definition, def_syntax]

proc formatting_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind == ddkList or d.kind == ddkStruct or
     d.kind == ddkDict or d.kind == ddkTags:
    result &= &"\n{pfx}- formatting:\n"
    if len(d.pfx) > 0:
      result &= &"{pfx}    before the first element is the prefix '{d.pfx}'\n"
    if len(d.sfx) > 0:
      result &= &"{pfx}    after the last element is the suffix '{d.sfx}'\n"
    if len(d.sep) > 0:
      if d.sep == "\t":
        result &= &"{pfx}    the elements are separated by tabs\n"
      elif d.sep == "\n":
        result &= &"{pfx}    the elements are separated by newlines\n"
      else:
        result &= &"{pfx}    the elements are separated by '{d.sep}'\n"
      result &= &"{pfx}    (which "
      if d.sep_excl: result &= &"is never found "
      else:          result &= &"may also be present "
      result &= "in the elements text,\n"
      result &= &"{pfx}    thus "
      if d.sep_excl: result &= &"can "
      else:          result &= &"shall not "
      result &= "be used for splitting the string into elements)\n"
    else:
      result &= &"{pfx}    the elements are justapoxed, without any separator\n"
    if d.kind == ddkTags:
      if d.tags_internal_sep == "\t":
        result &= &"{pfx}    the name, type code and value are separated by " &
                             &"'{d.tags_internal_sep}'\n"
      elif d.tags_internal_sep == "\n":
        result &= &"{pfx}    the name, type code and value are separated by " &
                             &"'{d.tags_internal_sep}'\n"
      else:
        result &= &"{pfx}    the name, type code and value are separated by " &
                             &"'{d.tags_internal_sep}'\n"
      result &= &"{pfx}    (which can be present in the value, but not in " &
                           "the name or type code)\n"
    elif d.kind == ddkDict:
      if d.dict_internal_sep == "\t":
        result &= &"{pfx}    the key and the value are separated by tabs\n"
      elif d.dict_internal_sep == "\n":
        result &= &"{pfx}    the key and the value are separated by newlines\n"
      else:
        result &= &"{pfx}    the key and the value are separated by " &
                  &"'{d.dict_internal_sep}'\n"
      result &= &"{pfx}    (which can be present in the value, but not in " &
                           "the key)\n"

proc formatting_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if len(d.pfx) > 0:
    result &= &"{pfx}{PfxKey}: {%d.pfx}\n"
  if len(d.sfx) > 0:
    result &= &"{pfx}{SfxKey}: {%d.sfx}\n"
  if len(d.sep) > 0:
    if d.sep_excl:
      result &= &"{pfx}{SplittedKey}: {%d.sep}\n"
    else:
      result &= &"{pfx}{SepKey}: {%d.sep}\n"
  if d.kind == ddkTags:
    result &= &"{pfx}{TagsInternalSepKey}: {%d.tags_internal_sep}\n"
  elif d.kind == ddkDict:
    result &= &"{pfx}{DictInternalSepKey}: {%d.dict_internal_sep}\n"

proc formatting_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind == ddkList or d.kind == ddkStruct or
     d.kind == ddkDict or d.kind == ddkTags:
    result &= &"{pfx}- prefix: '{d.pfx}'\n"
    if d.sep_excl:
      result &= &"{pfx}- splitted_by: {d.sep_excl}\n"
    else:
      result &= &"{pfx}- separator: '{d.sep}'\n"
    result &= &"{pfx}- suffix: '{d.sfx}'\n"
