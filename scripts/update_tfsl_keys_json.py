#!/usr/bin/env python3
import os
import json

def setup_keys(scriptpath):
  keys = {}
  fname = scriptpath+"/../src/textformats/types/def_syntax.nim"
  with open(fname) as f:
    state = "before"
    for line in f:
      if line.strip() == "const":
        state = "inside"
      elif state == "inside":
        if len(line.strip()) > 0 and line[:2] != "  ":
          state = "after"
        else:
          elems = line.split("=")
          constname = elems[0].strip()
          if constname[-1:] == "*":
            definition = elems[1].strip()
            if definition[0] == "\"" and definition[-1:] == "\"":
              keys[constname[:-1]] = definition[1:-1]
  return keys

scriptpath = os.path.dirname(os.path.realpath(__file__))
with open(os.path.join(scriptpath, "tfsl_keys.json"), "w") as f:
  f.write(json.dumps(setup_keys(scriptpath)))
