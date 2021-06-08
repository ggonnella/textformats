#!/usr/bin/env python3
from prompt_toolkit import print_formatted_text as print, HTML
from prompt_toolkit.shortcuts import prompt
from prompt_toolkit.validation import Validator
import re
import json
import os.path
import os
import textwrap

def setup_answers():
  answer = {}
  # Y/N
  answer["yn"] = {}
  answer["yn"]["desc"]="y or n"
  answer["yn"]["errmsg"]=\
      "Please answer the question entering 'y' or 'n'. "+\
      "(or just enter for 'y')"
  yes=["y", "Y", "yes", "Yes", "YES", ""]
  no=["n", "N", "no", "No", "NO"]
  answer["yn"]["valid"] =\
    lambda text: text in yes or text in no
  answer["yn"]["decode"] =\
    lambda text: True if text in yes else False
  # name
  answer["name"] = {}
  answer["name"]["desc"]=\
                  "letters, digits "+\
                  "and underscores; starting with a lower case letter"
  answer["name"]["errmsg"]="Please enter an identifier starting with a lower "+\
                  "case letter and consisting only of letters, digits and "+\
                  "underscores"
  answer["name"]["valid"] = \
      lambda text: re.fullmatch(r"[a-z][a-zA-Z0-9_]*", text)
  # namesfx
  answer["namesfx"] = answer["name"].copy()
  answer["namesfx"]["desc"]="letters, digits and underscores"
  answer["namesfx"]["errmsg"]="Please enter an identifier "+\
                  "consisting only of letters, digits and underscores"
  answer["namesfx"]["decode"] = lambda text: re.fullmatch(r"[a-zA-Z0-9_]+", text)
  # name or nothing
  answer["optname"] = answer["name"].copy()
  answer["optname"]["valid"] = \
      lambda text: len(text.strip()) == 0 or answer["name"]["valid"](text)
  answer["optname"]["decode"] = \
      lambda t: None if len(t.strip())==0 else t.strip()
  # namesfx or nothing
  answer["optnamesfx"] = answer["optname"].copy()
  answer["optnamesfx"]["valid"] = \
      lambda text: len(text.strip()) == 0 or answer["namesfx"]["valid"](text)
  # choices helper functions
  def generate_choice(n, choice_name_and_help, default):
    choice_name, choice_help = choice_name_and_help
    if n == default: is_default = "*"
    else: is_default = " "
    n = format_answer(f"[{n}]")
    return f"{n}{is_default} {choice_name} {format_help(choice_help)}"
  def generate_choices_answer(default, *choices):
    result = {}
    result["format_desc"]=False
    result["desc"]="\n"+\
      "\n".join(
        [generate_choice(i, c, default) for i, c in enumerate(choices)])+\
      "\n\n"+\
      format_answer(
        "Enter the number of the desired option or just enter "
        "for the default value (marked by *)")
    result["default"]=default
    result["valid"] = lambda text: len(text)==0 or text in [str(i) for i in range(len(choices))]
    result["errmsg"] = f"Please enter a number between 0 and {len(choices)-1}"
    result["decode"] = lambda text: result["default"] if len(text)==0 else int(text)
    return result
  # dtkinds
  answer["dtkinds"] = generate_choices_answer(7,
     ("Single element.                 ",
       "No internal structure."),
     ("Equivalent sub-elements         ",
       "Same format(s) for each element"),
     ("Sub-elements in a fixed order.  ",
       "Each sub-element has a pre-defined name and format"),
     ("Typed sub-elements in any order.",
       "Sub-elements include a name and a type key"),
     ("Named sub-elements in any order.",
       "Sub-elements include a name (which defines the format)"),
     ("Different formats are allowed.  ",
       "Alternative formats for the element are specified"),
     ("Format already defined.         ",
       "Specified previously or imported from another spec."),
     ("Help                            ",
      "Display a longer help text."))
  # valuetype
  answer["valuetype"] = generate_choices_answer(0,
      ("String.           ", "String not validated/parsed as number."),
      ("Signed integer.   ", "Integer (if >0: '+' prefix optional)."),
      ("Unsigned integer. ", "Zero or positive, no '+' prefix."),
      ("Float.            ", "Floating point value."))
  # numtype
  answer["numtype"] = generate_choices_answer(0,
      ("Signed integer (any).        ",
                             "Integer (if >0: '+' prefix optional)"),
      ("Signed integer (in range).   ", ""),
      ("Unsigned integer (any).      ", "Zero or positive, no '+' prefix."),
      ("Unsigned integer (in range). ", ""),
      ("Float (any).                 ", "Any floating point value."),
      ("Float (in range).            ", ""))
  # single
  answer["single"] = generate_choices_answer(0,
      ("Not empty.      ", "Valid if a non-empty string."),
      ("Constant.       ", "Valid if equal to a given value."),
      ("Set element.    ", "Valid if a member of a given set of values."),
      ("Regex.          ", "Valid if matches a given regex."),
      ("Set of regexes. ", "Valid if matches one of the given regexes."),
      ("Numerical.      ", "Parsed as integer/float (any / in a range)."),
      ("Json.           ", "Parsed as single-line JSON."))
  # mapstr
  answer["mapstr"] = generate_choices_answer(0,
      ("== encoded ", "Use the same string as the encoded value."),
      ("=> string  ", "Use a different string."),
      ("=> null    ", "Use 'null'."),
      ("=> true    ", "Use 'True'."),
      ("=> false   ", "Use 'False'."),
      ("=> integer ", "Use an integer."),
      ("=> float   ", "Use a float."))
  # mapregex
  answer["mapregex"] = generate_choices_answer(0,
      ("== match   ", "Use the same string as the encoded value."),
      ("=> string  ", "Use a different string."),
      ("=> null    ", "Use 'null'."),
      ("=> true    ", "Use 'True'."),
      ("=> false   ", "Use 'False'."),
      ("=> integer ", "Use an integer."),
      ("=> float   ", "Use a float."))
  # mapemptystr
  answer["mapemptystr"] = generate_choices_answer(0,
      ("As defined. ", "No special handling of empty strings."),
      ("=> String   ", "Decode empty strings as a given string."),
      ("=> Null     ", "Decode empty strings as Null."),
      ("=> True     ", "Decode empty strings as True."),
      ("=> False    ", "Decode empty strings as False."),
      ("=> Integer  ", "Decode empty strings as a given integer."),
      ("=> Float    ", "Decode empty strings as a given float."))
  # implicit
  answer["implicit"] = generate_choices_answer(0,
      ("Null   ", "A Null value."),
      ("True   ", "A boolean True value."),
      ("False  ", "A boolean False value."),
      ("String ", "A given string value."),
      ("Integer", "A given integer value."),
      ("Float  ", "A given float value."))
  # seppfxsfx
  answer["seppfxsfx"] = generate_choices_answer(0,
      ("E0 D E1 D E2... (D not in E)    ",
         "Delimiter D never found in sub-elements E"),
      ("E0 D E1 D E2... (D in E)        ",
         "Delimiter may also occur in sub-elements"),
      ("E0 E1 E2 ...                    ",
          "No delimiter"),
      ("P E0 D E1 D E2 ... S (D not in E)",
         "as [0], plus a constant prefix and/or suffix"),
      ("P E0 D E1 D E2 ... S (D in E)    ",
         "as [1], plus a constant prefix and/or suffix"),
      ("P E0 E1 E2 ... S                 ",
         "as [2], plus a constant prefix and/or suffix"),
      ("Help                             ",
        "Show an extended help message"))
  # int
  def is_int(s):
    try:
      int(s)
      return True
    except ValueError:
      return False
  answer["int"] = {}
  answer["int"]["desc"]="integer value"
  answer["int"]["errmsg"]="Please enter an integer value"
  answer["int"]["decode"]=lambda t: int(t)
  answer["int"]["valid"]=is_int
  # optint
  answer["optint"] = answer["int"].copy()
  answer["optint"]["decode"]=lambda t: None if len(t.strip()) == 0 else int(t)
  answer["optint"]["valid"]=lambda t: len(t.strip()) == 0 or is_int(t)
  # uint
  def is_uint(s):
    try:
      return int(s) >= 0
    except ValueError:
      return False
  answer["uint"] = {}
  answer["uint"]["desc"]= "non-negative, unsigned, integer value)"
  answer["uint"]["errmsg"]="Please enter an unsigned integer value"
  answer["uint"]["decode"]=lambda t: int(t)
  answer["uint"]["valid"]=is_uint
  # optuint
  answer["optuint"] = answer["uint"].copy()
  answer["optuint"]["decode"]=lambda t: None if len(t.strip()) == 0 else int(t)
  answer["optuint"]["valid"]=lambda t: len(t.strip()) == 0 or is_uint(t)
  # float
  def is_float(s):
    try:
      float(s)
      return True
    except ValueError:
      return False
  answer["float"] = {}
  answer["float"]["desc"]= "floating point value"
  answer["float"]["errmsg"]="Please enter a floating point value"
  answer["float"]["decode"]=lambda t: float(t)
  answer["float"]["valid"]=is_float
  # optfloat
  answer["optfloat"] = answer["float"].copy()
  answer["optfloat"]["decode"]=lambda t: None if len(t.strip()) == 0 else float(t)
  answer["optfloat"]["valid"]=lambda t: len(t.strip()) == 0 or is_float(t)
  # string (empty not allowed)
  answer["string"] = {}
  answer["string"]["desc"]=\
      "string, non-empty, but can consist of only spaces"
  answer["string"]["errmsg"]="Please enter a non-empty string"
  answer["string"]["valid"]=lambda t: len(t) > 0
  # qstring (backslash codes)
  answer["qstring"] = answer["string"].copy()
  answer["qstring"]["desc"]=\
      "string, non-empty, but may consist of only spaces; "+\
          "you may use backslash codes, e.g. \\t"
  # anystring (possibly empty)
  answer["anystring"] = {}
  answer["anystring"]["desc"]="string, possibly empty"
  # optstring (empty mapped to None)
  answer["optstring"] = {}
  answer["optstring"]["desc"]="string"
  answer["optstring"]["decode"]=lambda t: None if len(t) == 0 else t
  # optqstring (backslash codes)
  answer["optqstring"] = answer["optstring"].copy()
  answer["optqstring"]["desc"]=\
      "string, possibly empty; "+\
          "you may use backslash codes, e.g. \\t"
  # create validators
  for k in answer.keys():
    answer[k]["validator"] = Validator.from_callable(
        answer[k].get("valid", lambda t: True),
        error_message=answer[k].get("errmsg", ""),
        move_cursor_to_end=True)
  return answer

## Helper functions

def format_error(txt):
  return f"<b>(Error)</b> <red>{txt}</red>"

def format_help(txt):
  return f"<i><saddlebrown> {txt}</saddlebrown></i>"

def format_answer(txt):
  return f"<darkgreen> -> {txt}</darkgreen>"

def format_syntax(txt):
  return "<i><darkslategray>(syntax hint)</darkslategray></i> "+\
      f"<darksalmon>{txt}</darksalmon>"

def wrappedlines(text, fixedpfxlen):
  width = os.get_terminal_size()[0] - fixedpfxlen
  result = []
  for line in text.splitlines():
    for wrappedline in textwrap.wrap(line, width):
      result.append(wrappedline)
  return result

def sayquoted(text):
  text=str(text)
  for line in wrappedlines(text, 11):
    print(HTML(TextformatsPfx+"{}").format(text))

def say(text):
  text = str(text)
  for line in wrappedlines(text, 11):
    print(HTML(TextformatsPfx+line))

def sayerr(text):
  for line in wrappedlines(text, 7):
    print(HTML(format_error(line)))

def explain_syntax(text):
  for line in wrappedlines(text, 16):
    print(HTML(format_syntax(line)))
  print()

def show_def(name, dd):
  print()
  firstline = True
  for line in wrappedlines(dd, 6+len(name)):
    if firstline:
      print(HTML("<lightblue>  {}: {}</lightblue>").format(name, line))
      firstline = False
    else:
      print(
        HTML("<lightblue>"+" "*(6+len(name)) + "{}</lightblue>").format(line))
  print()

def ask(text, answer_id, helpmsg=""):
  decoder = answer[answer_id].get("decode", lambda a: a)
  output = [(line, False) for line in wrappedlines(text, 11)]
  if helpmsg:
    for line in wrappedlines(helpmsg, 1):
      output.append((format_help(line), True))
  answersmsg = answer[answer_id]["desc"]
  if answer[answer_id].get("format_desc", True):
    for line in wrappedlines(answersmsg, 4):
      output.append((format_answer(line), True))
  else:
    for line in answersmsg.splitlines():
      output.append((line, True))
  if len(output) > 0:
    for i in range(len(output)-1):
      if output[i][1]:
        print(HTML(output[i][0]))
      else:
        print(HTML(TextformatsPfx+"{}").format(output[i][0]))

  validator = answer[answer_id]["validator"]
  if output[-1][1]:
    prompttxt = HTML(output[-1][0]+"\n")
  else:
    prompttxt = HTML(TextformatsPfx+"{}"+"\n").format(output[-1][0])
  return decoder(prompt(prompttxt, validator = validator))

def printhelp(helpmsg):
  for line in wrappedlines(helpmsg, 1):
    print(HTML(format_help(line)))

def sayoptional():
  say("<u>OPTIONAL</u>")

## Interaction

def get_at_least_n_values(unit, units, answerid, n):
  result = []
  while True:
    if len(result) == 0:
      value = ask(\
          f"Enter the first {unit}:", answerid)
    else:
      say(f"List of {units} entered until now: {json.dumps(result)}")
      value = ask(\
          f"Enter the next {unit} (or just enter after the last one):",
          answerid)
    if value is None:
      if len(result) < n:
        sayerr(f"You must define at least {n} different {units}.")
      else:
        say(f"List of {units}: {json.dumps(result)}")
        break
    elif value in result:
      sayerr(f"The {unit} is not unique, please choose a different one.")
    else:
      result.append(value)
  return result

def get_names(data, dtpfx, unit, units, parent):
  say(f"Please assign a name to each {unit} of '{parent}'.")
  if dtpfx:
    say(f"The names will be automatically prefixed by '{dtpfx}'.")
    print()
  return get_at_least_n_values(f"{unit} of '{parent}'",
      f"{units} of '{parent}'", "optnamesfx" if dtpfx else "optname", 2)

def register_definition(data, name, dd):
  say("The following definition will be added to the specification:")
  show_def(name, dd)
  if ask("Is the definition correct?", "yn",
       "Enter 'y' or just press enter to add the "+\
       "definition to the specification.\n"+\
       "Enter 'n' to change the definition."):
    data["file"].write(f"  {name}: {dd}\n")
    data["file"].flush()
    data["datatype_names"].append(name)
    return True
  else:
    return False

def get_emptystrvalue(name):
  opt_txt = ""
  sayoptional()
  has_mapping, v = get_mapping(
      "Define how to handle empty strings. ",
      f"Is an empty string valid according to the the definition of '{name}' "+\
      "given until now?\n"+\
      "[No] you can specify here to also "+\
      "consider empty strings valid and select a decoded value for them\n"+\
      "[Yes] you can specify here to override "+\
      "the decoded value for empty strings",
      "mapemptystr")
  if has_mapping:
    explain_syntax("The value for empty strings is specified "+\
        "using the key 'empty'")
    opt_txt += ", empty: "+json.dumps(v)
  return opt_txt

def define_datatype_oneof(data, name):
  kindnames = get_names(data, name+"_", "kind", "kinds", name)
  kindnames = [name + "_" + r for r in kindnames]
  opt_txt = get_emptystrvalue(name)
  explain_syntax("A datatype with different kinds/formats is "+\
        "specified using the key 'one_of' and a list, whose "+\
        "elements are datatype names or datatype definitions.")
  if register_definition(data, name, "{one_of: ["+\
      ", ".join(kindnames)+"]"+opt_txt+"}"):
    for kindname in kindnames:
      define_datatype(data, kindname)
    return True
  else:
    return False

def numlbl2answerid(lbl):
  if lbl == "integer": return "optint"
  elif lbl == "unsigned_integer": return "optuint"
  elif lbl == "float": return "optfloat"

def define_datatype_numerical_range(data, name, lbl):
  answerid = numlbl2answerid(lbl)
  may_exclude = lbl == "float"
  minvalue = \
    ask("Enter the minimum value (or just enter for unlimited)", answerid)
  exclmin = ""
  if minvalue is not None and may_exclude:
    if not ask("May the value be equal to the minimum value?", "yn"):
      exclmin = ", min_excluded: true"
  maxvalue = \
    ask("Enter the maximum value (or just enter for unlimited)", answerid)
  if minvalue is not None:
    while maxvalue is not None and maxvalue <= minvalue:
      sayerr("The maximum must be larger than the minimum.")
      maxvalue = \
        ask("Enter the maximum value (or just enter for unlimited)", answerid)
  exclmax = ""
  if maxvalue is not None and may_exclude:
    if not ask("May the value be equal to the maximum value?", "yn"):
      exclmax = ", max_excluded: true"
  def_txt = "{"+lbl+": {"
  if minvalue is not None:
    if maxvalue is None:
      def_txt += "min: "+str(minvalue)+exclmin
    else:
      def_txt += "min: "+str(minvalue)+exclmin+", "+\
                "max: "+str(maxvalue)+exclmax
  elif maxvalue is not None:
    def_txt += "max: "+str(maxvalue)+exclmax
  def_txt += get_emptystrvalue(name)
  def_txt += "}}"
  explain_syntax("A datatype consisting in a numeric value in a range is "+\
      "specified using the key 'integer', 'unsigned_integer' or 'float' and "+\
      "a map with the optional elements 'min', 'max' defining the limits.")
  if may_exclude:
    explain_syntax("For floats only, the optional bool keys 'min_excluded' "+\
      "and 'max_excluded' can be used to specify that the minimum/maximum "+\
      "values are not included in the range (default is False, i.e. they "+\
      "are included).")
  return register_definition(data, name, def_txt)

def define_datatype_numerical_any(data, name, lbl):
  return register_definition(data, name, lbl)

def define_datatype_any_int(data, name):
  explain_syntax("For an integer element, without range limits "+\
      "just use the string 'integer' as the definition")
  return define_datatype_numerical_any(data, name, "integer")

def define_datatype_any_uint(data, name):
  explain_syntax("For an unsigned integer element, without range limits "+\
      "just use the string 'unsigned_integer' as the definition")
  return define_datatype_numerical_any(data, name, "unsigned_integer")

def define_datatype_any_float(data, name):
  explain_syntax("For a float element, without range limits "+\
      "just use the string 'float' as the definition")
  return define_datatype_numerical_any(data, name, "float")

def define_datatype_range_int(data, name):
  return define_datatype_numerical_range(data, name, "integer")

def define_datatype_range_uint(data, name):
  return define_datatype_numerical_range(data, name, "unsigned_integer")

def define_datatype_range_float(data, name):
  return define_datatype_numerical_range(data, name, "float")

def define_datatype_num(data, name):
  question = f"Select the type and range of numeric value for '{name}'"
  return [define_datatype_any_int,
    define_datatype_range_int,
    define_datatype_any_uint,
    define_datatype_range_uint,
    define_datatype_any_float,
    define_datatype_range_float][
       ask(question, "numtype")](data, name)

def get_mapping(msg, helpmsg, answers_id):
  mapped = ask(msg, answers_id, helpmsg)
  if mapped == 0: # no
    return False, None
  elif mapped == 1: # string
    v=ask("Enter the desired string value", "optqstring")
    if v is None: v=""
  elif mapped == 2: # null
    v=None
  elif mapped == 3: # true
    v=True
  elif mapped == 4: # false
    v=False
  elif mapped == 5: # integer
    v=ask("Enter the desired integer value", "int")
  elif mapped == 6: # float
    v=ask("Enter the desired float value", "float")
  return True, v

def explain_reverse():
  explain_syntax("When muliple encoded strings have the same decoding, "+\
        "the datatype definition must contain a key 'reverse', a "+\
        "map the \"ambiguous\" decoded values to their encoding.")

def define_datatype_regexes(data, name):
  say("Enter the regular expressions in the order "+\
      "in that they shall be matched")
  items = []
  # (regex, compiled_regex, has_mapping, value)
  any_has_mapping = False
  while True:
    if len(items) > 0:
      sayquoted("Regular expressions entered until now: "+\
          json.dumps([i[0] for i in items]))
    regex = ask("Enter a regular expression "+\
        "(just enter after the last regular expression):",
        "optstring")
    if regex is None:
      if len(items) < 2:
        sayerr("You need to enter at least another regular expression.")
      else:
        break
    else:
      if regex in [i[0] for i in items]:
        sayerr("The value had already been entered, "+\
               "please enter a different one.")
      else:
        try:
          compiled = re.compile(regex)
        except re.error:
          sayerr("Invalid syntax in the regular expression")
          continue
        sayoptional()
        has_mapping, value = get_mapping("Select a decoded value for the "+\
          "matches of this regular expression. ",
          "By default, the value is the same string as the encoded value "+\
          "(i.e. the regex match). A different scalar value can be selected "+\
          "(which will then be used for all matches).", "mapregex")
        item = (regex, compiled, has_mapping, value)
        items.append(item)
        if has_mapping: any_has_mapping = True
  if any_has_mapping:
    def_txt = "["+", ".join(
        [f"{json.dumps(i[0])}: {json.dumps(i[3])}" for i in items])+"]"
    say("Since all matches of some of the regular expressions are decoded "+\
        "to the same value, it is necessary to specify which encoding "+\
        "to use for that value.")
    encoding = {}
    for regex, compiled, has_mapping, value in items:
      if has_mapping and value not in encoding:
        regexes_str = [i[0] for i in items if i[3] == value]
        compiled_regexes = [i[1] for i in items if i[3] == value]
        question = \
          f"Enter the encoded string for the decoded value: {json.dumps(value)}"
        while True:
          encoded = ask(question, "string")
          matching = False
          for r in compiled_regexes:
            if re.fullmatch(r, encoded):
              matching = True
              break
          if matching:
            encoding[value] = encoded
            break
          else:
            sayerr("The encoded string does not match any regular expression "+\
                "mapped to that decoded value.")
            sayquoted(f"Regular expressions: {regexes_str}")
            sayquoted(f"Invalid encoded string: '{encoded}'")
    explain_reverse()
    def_txt += ", reverse: "+json.dumps(encoding)
  else:
    def_txt = json.dumps([i[0] for i in items])
  opt_txt = get_emptystrvalue(name)
  return register_definition(data, name, \
      "{regexes: "+def_txt+opt_txt+"}")

def define_datatype_const_num(data, name, lbl):
  if lbl == "integer": answerid = "optint"
  elif lbl == "unsigned_integer": answerid = "optuint"
  elif lbl == "float": answerid = "optfloat"
  value = ask(f"Enter the only possible value of '{name}'", answerid)
  opt_txt = get_emptystrvalue(name)
  return register_definition(data, name, "{constant: "+str(value)+opt_txt+"}")

def define_datatype_const_str(data, name):
  k = ask(f"Enter the valid string representation of '{name}':", "string")
  sayoptional()
  has_mapping, v = get_mapping(f"Select a decoded value for '{name}'.",
      "By default, it is the string itself but "+\
      "a different value can be specified.", "mapstr")
  opt_txt = get_emptystrvalue(name)
  deftxt = json.dumps(k)
  if has_mapping: deftxt = "{"+deftxt+": "+json.dumps(v)+"}"
  return register_definition(data, name, "{constant: "+deftxt+opt_txt+"}")

def define_datatype_const_int(data, name):
  return define_datatype_const_num(data, name, "integer")

def define_datatype_const_uint(data, name):
  return define_datatype_const_num(data, name, "unsigned_integer")

def define_datatype_const_float(data, name):
  return define_datatype_const_num(data, name, "float")

def define_datatype_const(data, name):
  return [define_datatype_const_str,
   define_datatype_const_int,
   define_datatype_const_uint,
   define_datatype_const_float][
       ask("Select a type for the constant value", "valuetype")](data, name)

def define_datatype_accepted_num(data, name, lbl):
  answerid = numlbl2answerid(lbl)
  values = get_at_least_n_values(
      f"possible {lbl} value for '{name}'",
      f"possible {lbl} values for '{name}'", answerid, 2)
  opt_txt = get_emptystrvalue(name)
  return register_definition(data, name,
      "{accepted_values: ["+", ".join([str(v) for v in values])+"]"+opt_txt+"}")

def define_datatype_accepted_int(data, name):
  return define_datatype_accepted_num(data, name, "integer")

def define_datatype_accepted_uint(data, name):
  return define_datatype_accepted_num(data, name, "unsigned_integer")

def define_datatype_accepted_float(data, name):
  return define_datatype_accepted_num(data, name, "float")

def define_datatype_accepted_str(data, name):
  any_has_mapping = False
  items = []
  while True:
    if len(items) > 0:
      sayquoted("Values entered until now: "+\
          json.dumps([i[0] for i in items]))
    item = ask("Enter one of the possible string values of a 'name' "+\
        "(of just enter after the last one):", "optstring")
    if item is None:
      if len(items) < 2:
        sayerr("You need to enter at least two string values.")
      else:
        break
    else:
      if item in [i[0] for i in items]:
        sayerr("The string value had already been entered, "+\
               "please enter a different one.")
      else:
        sayoptional()
        has_mapping, v = get_mapping("Select the decoded value for "+\
            "this string.", "By default, it is the string itself but "+\
            "a different value can be specified.", "mapstr")
        if has_mapping:
          items.append((item, v))
          any_has_mapping = True
        else:
          items.append((item, item))
  opt_txt = ""
  if any_has_mapping:
    def_txt = "["+", ".join(
        [f"{json.dumps(i[0])}: {json.dumps(i[1])}" for i in items])+"]"
    uniquevalues = set()
    dupvalues = set()
    for i in items:
      v = i[1]
      if v in uniquevalues: dupvalues.add(v)
      else: uniquevalues.add(v)
    if len(dupvalues) > 0:
      say("Multiple encoded strings are mapped to the same "+\
          "decoded value. Which of them shall be used to encode those values?")
      print()
      encoding = {}
      for v in dupvalues:
        valid_answers = [i[0] for i in items if i[1] == v]
        question = \
          f"Enter the encoded string for the decoded value: {json.dumps(v)}"
        encoded = ask(question, "string")
        while encoded not in valid_answers:
          sayerr("The encoded string is invalid.")
          sayquoted("It must be one of the encoded strings for which the "+\
              f"decoded value is {json.dumps(v)}.")
          sayquoted(f"Enter one of the following: {json.dumps(valid_answers)}")
          encoded = ask(question, "string")
        encoding[v] = encoded
      explain_reverse()
      opt_txt += ", reverse: "+json.dumps(encoding)
  else:
    def_txt = json.dumps([i[0] for i in items])
  opt_txt += get_emptystrvalue(name)
  return register_definition(data, name, \
      "{accepted_values: "+def_txt+opt_txt+"}")

def define_datatype_accepted(data, name):
  return [define_datatype_accepted_str,
   define_datatype_accepted_int,
   define_datatype_accepted_uint,
   define_datatype_accepted_float][
       ask("Select a type for the values in the set", "valuetype")](data, name)

def define_datatype_regex(data, name):
  k = ask("Enter the regular expression:", "string")
  while True:
    try:
      compiled = re.compile(k)
      break
    except re.error:
      sayerr("Invalid syntax in the regular expression")
      k = ask("Enter a valid regular expression:", "string")
  sayoptional()
  has_mapping, v = get_mapping(f"Select a decoded value of '{name}'",
          "By default, the value is the same string as the encoded value "+\
          "(i.e. the regex match). A different scalar value can be selected "+\
          "(which will then be used for all matches).", "mapregex")
  opt_txt = ""
  if has_mapping:
    say("All strings matching the regular expression are decoded to the "+\
        "same value. Which of these strings shall be used to "+\
        "encode that value?")
    question = \
      f"Enter the encoded string for the decoded value: {json.dumps(v)}"
    encoded = ask(question, "string")
    while not re.fullmatch(compiled, encoded):
      sayerr("The specified encoded string does "+\
          "not match the regular expression.")
      sayquoted(f"Regular expression: '{k}'")
      sayquoted(f"Specified encoded value: '{encoded}'")
      encoded = ask(question, "string")
    explain_reverse()
    opt_txt = ", reverse: {"+json.dumps(v)+":"+json.dumps(encoded)+"}"
    def_txt = "{"+json.dumps(k)+": "+json.dumps(v)+"}"
  else:
    def_txt = json.dumps(k)
  opt_txt += get_emptystrvalue(name)
  return register_definition(data, name, "{regex: "+def_txt+opt_txt+"}")

def define_datatype_json(data, name):
  return register_definition(data, name, "json")

def define_datatype_anystring(data, name):
  return register_definition(data, name, "string")

def define_datatype_single(data, name):
  question = f"Define a validation/parsing method for '{name}'"
  return [define_datatype_anystring,
    define_datatype_const,
    define_datatype_accepted,
    define_datatype_regex,
    define_datatype_regexes,
    define_datatype_num,
    define_datatype_json][
       ask(question, "single")](data, name)

def get_max_repeats(min_repeats):
  max_repeats = ask("What is the maximum number of instances of "+\
                  "the element? (just enter if no upper limit)", "optuint")
  while max_repeats is not None and max_repeats <= min_repeats:
    sayerr("Enter a number larger than {min_repeats}")
    max_repeats = ask("What is the maximum number of instances of "+\
                    "the element? (just enter if no upper limit)", "optuint")
  return max_repeats

def get_min_repeats():
  min_repeats = ask(
      "What is the minimum number of instances of the element?", "uint")
  while min_repeats < 2:
    sayerr("Enter a number larger than 1")
    min_repeats = ask(
        "What is the minimum number of instances of the element?", "uint")
  return min_repeats

def get_seppfxsfx(name):
  opt_txt = ""
  question = "What is the formatting of the set of sub-elements?"
  choice = ask(question, "seppfxsfx")
  while choice == 6:
    print()
    printhelp("<b>DELIMITER</b>")
    print()
    printhelp("Sub-elements can often be recognized as they are divided "+\
        "from each other by a delimiter (e.g. comma, tags, colon). ")+\
    printhelp("The delimiter is often exclusive (i.e. never found in "+\
        "the elements themselves). Choose [0] or [3] in this case.")
    printhelp("In cases the delimiter is not exclusive choose [1] or [4]. "+\
        "In case there is no delimiter choose [2] or [5]. "+\
        "In such cases, textformats tries to parse the element by using the "+
        "regular expression for the sub-elements. Depending on the "+
        "sub-elements definition, this can fail (use tests to check).")
    print()
    printhelp("<b>PREFIX / SUFFIX</b>")
    print()
    printhelp(
        "In some cases, the set of sub-elements in compound elements "+
        "prefixed and/or suffixed by a constant string (e.g. brackets)."+
        "Choose [3]/[4]/[5] in this case.")
    print()
    choice = ask(question, "seppfxsfx")
  if choice != 2 and choice != 5:
    enter_question="Enter the delimiter string"
    result = ask(enter_question, "qstring")
    opt_txt += f", sep: \"{result}\""
    if choice == 1 or choice == 4:
      opt_txt += ", split: false"
  if choice >= 3:
    enter_question="Enter the prefix string (just enter if none)"
    result = ask(enter_question, "optqstring")
    if result is not None:
      opt_txt += f", pfx: \"{result}\""
    enter_question="Enter the suffix string (just enter if none)"
    result = ask(enter_question, "optqstring")
    if result is not None:
      opt_txt += f", sfx: \"{result}\""
  return opt_txt

def get_struct_n_required(n_elements):
  sayoptional()
  say("By default, all elements are required. Alternatively, it is possible "+\
      "to require only the first x elements (0 &lt;= x &lt;= n. of "+\
      "elements).")
  while True:
    n_required = ask("How many elements are required? "+\
                     "(default: all elements)", "optuint")
    if n_required is None:
      return ""
    elif n_required <= n_elements:
      return f", required: {n_required}"
    else:
      sayerr("Too many required elements")
      say(f"Enter a number between 0 and {n_elements}")

def get_implicit(name, elements):
  implicit = {}
  while True:
    if len(implicit) == 0:
      sayoptional()
      key = ask("To include further constant elements "+\
        f"in the decoded value of all '{name}'. "+\
        "To do so, enter the name of a key for a constant element. "+\
        "Otherwise just press enter.", "optname")
    else:
      say("Keys of constant elements entered until now: "+\
          json.dumps(list(implicit.keys())))
      key = ask("If you want to include further constant elements "+\
        "enter the key name for the next constant element. "+\
        "Otherwise just press enter.", "optname")
    if key is None:
      break
    elif key in elements or key in implicit:
      sayerr(f"The key name {key} is already used. "+\
          "Choose a different one.")
      say("Keys of the variable elements: "+\
          json.dumps(elements))
    else:
      mapped = ask("Which kind of constant value to you want "+
          f"to assign to '{key}'", "implicit")
      if mapped == 0: # null
        v=None
      elif mapped == 1: # true
          v=True
      elif mapped == 2: # false
          v=False
      elif mapped == 3: # string
        v=ask("Enter the string value", "anystring")
      elif mapped == 4: # integer
        v=ask("Enter the integer value", "int")
      elif mapped == 5: # float
        v=ask("Enter the float value", "float")
      implicit[key] = v
  if len(implicit) > 0:
    return ", implicit: " + json.dumps(implicit)
  else:
    return ""

def get_elemnames(name, min_n_names):
  say(f"Please assign a name to each element of '{name}'.")
  printhelp("The names will be the dict / hash table <i>keys</i> "+\
      "for accessing the <i>decoded values</i> of the single "+\
      "elements.")
  printhelp("The datatype for each of the elements will be defined later on. "+\
       "The datatype name for each element will be its name "+\
      f"prefixed by '{name}_'.")
  print()
  elemnames = get_at_least_n_values(
      f"element of '{name}'",
      f"elements of '{name}'", "optname", min_n_names)
  return elemnames

def get_typekeys(name):
  say(f"Please assign a key to each type of tag of '{name}'.")
  printhelp("The keys will be used for determining "+\
      "the valid format of the value. ")
  printhelp("The datatype for each of the type keys will be defined later on. "+\
       "The datatype name for each type key will be its type key "+\
      f"prefixed by '{name}_'.")
  print()
  typekeys = get_at_least_n_values(
      f"type key of '{name}'",
      f"type keys of '{name}'", "optname", 1)
  return typekeys

def get_subdef_list(name, subnames):
  subdef_items = []
  for subname in subnames:
    subdt = name + "_" + subname
    subdef_items.append(f"{subname}: {subdt}")
  subdef = "[" + ", ".join(subdef_items) + "]"
  return subdef

def get_subdef_map(name, subnames):
  subdef_items = []
  for subname in subnames:
    subdt = name + "_" + subname
    subdef_items.append(f"{subname}: {subdt}")
  subdef = "{" + ", ".join(subdef_items) + "}"
  return subdef

def define_subdefs(data, name, elemnames, elbl):
  say(f"You will now define the datatype of each of the {elbl}.")
  say(f"The datatype names are prefixed by '{name}_'.")
  print()
  for elemname in elemnames:
    elemdt = name + "_" + elemname
    define_datatype(data, elemdt)

def define_datatype_struct(data, name):
  def_txt = "{composed_of: "
  elemnames = get_elemnames(name, 2)
  def_txt += get_subdef_list(name, elemnames)
  def_txt += get_struct_n_required(len(elemnames))
  def_txt += get_implicit(name, elemnames)
  def_txt += get_seppfxsfx(name)
  def_txt += get_emptystrvalue(name)
  def_txt += "}"
  if register_definition(data, name, def_txt):
    define_subdefs(data, name, elemnames, "elements")
    return True
  else:
    return False

def get_required(name, elemnames):
  validnames = elemnames.copy()
  print()
  say("By default, each sub-element is allowed to be absent or present once "+\
      "or multiple times. However, optionally, this can be changed.")
  sayoptional()
  say("You may define a list of required sub-elements, which must be present "+\
      "at least once.")
  print()
  say(f"List of the sub-elements: {json.dumps(validnames)}")
  result = []
  while len(validnames) > 0:
    value = ask("Enter the name of a required sub-element "
                 "(or just enter after the last one)",
                 "optname")
    if value is None:
      break
    elif not value in validnames:
      sayerr(f"Invalid sub-element ({value})")
      say(f"Sub-elements already marked as optional: {json.dumps(result)}")
      say("Choose a sub-element name from the one of the following:")
      say(f"Sub-elements not yet marked as optional: {json.dumps(validnames)}")
    else:
      validnames.remove(value)
      result.append(value)
  return result

def get_single(name, elemnames):
  validnames = elemnames.copy()
  print()
  sayoptional()
  say("You may define a list of single-instance sub-elements, which can be "+\
      "present only once.")
  say(f"List of the sub-elements: {json.dumps(validnames)}")
  result = []
  while len(validnames) > 0:
    value = ask("Enter the name of a single-instance sub-element "
                 "(or just enter after the last one)",
                 "optname")
    if value is None:
      break
    elif not value in validnames:
      sayerr(f"Invalid sub-element ({value})")
      say("Sub-elements already marked as single-instance: "+\
          f"{json.dumps(result)}")
      say("Choose a sub-element name from the one of the following:")
      say("Sub-elements not yet marked as single-instance: "+\
          f"{json.dumps(validnames)}")
    else:
      validnames.remove(value)
      result.append(value)
  return result

def add_required_to_def(required):
  result = ""
  if len(required) > 0:
    result += ", required: [" + ", ".join(required) + "]"
  return result

def add_single_to_def(single):
  result = ""
  if len(single) > 0:
    result += ", single: [" + ", ".join(single) + "]"
  return result

def get_dict_tags_formatting(isep_explain, noisep_explain):
  say("The sub-elements are separated from each other by a delimiter.")
  say("The delimiter string is exclusive (not contained in the elements).")
  sep = ask("Enter the delimiter string:", "qstring")
  result = f", sep: \"{sep}\""
  say(f"In each sub-element, {isep_explain} are separated by a delimiter.")
  say(f"The delimiter string cannot be contained in {noisep_explain}.")
  say("(However, it can be contained in values).")
  isep = ask("Enter the delimiter string:", "qstring")
  result += f", internal_sep: \"{isep}\""
  sayoptional()
  say("Is there a fixed prefix string before the first sub-element?")
  pfx = ask("Enter the prefix string (or just enter if none)",
      "optqstring")
  if pfx is not None:
    result += f", pfx: \"{pfx}\""
  say("Is there a fixed suffix string after the last sub-element?")
  sfx = ask("Enter the suffix string (or just enter if none)",
      "optqstring")
  if sfx is not None:
    result += f", sfx: \"{sfx}\""
  return result

def define_datatype_dict(data, name):
  def_txt = "{named_values: "
  elemnames = get_elemnames(name, 1)
  def_txt += get_subdef_map(name, elemnames)
  required = get_required(name, elemnames)
  def_txt += add_required_to_def(required)
  single = get_single(name, elemnames)
  def_txt += add_single_to_def(single)
  def_txt += get_dict_tags_formatting("name and value", "sub-element names")
  def_txt += get_implicit(name, elemnames)
  def_txt += get_emptystrvalue(name)
  def_txt += "}"
  if register_definition(data, name, def_txt):
    define_subdefs(data, name, elemnames, "elements")
    return True
  else:
    return False

def get_name_regex():
  say("There are two possible definitions of tag names:")
  say("[1] some or no tag names and associated types are pre-defined;")
  say("    further names are allowed if they match a regular expression")
  say("[2] all tag names and associated types are pre-defined;")
  say("    no other tag names are allowed")
  regex = ask("For [1] enter a regular expression; " +
      "for [2] press enter without input", "optstring")
  while True:
    if regex is None:
      regex = ""
      compiled = None
      break
    else:
      try:
        compiled = re.compile(regex)
        break
      except re.error:
        sayerr("Invalid syntax in the regular expression")
        regex = ask("For [1] enter a valid regular expression; " +
            "for [2] press enter without input", "optstring")
  return regex, compiled

def add_name_regex_to_def(regex):
  return ", tagname: " + json.dumps(regex)

def get_predefined(name, typekeys, mandatory):
  if mandatory:
    say("You must define tag names and associated types")
  else:
    sayoptional()
    say("You may specify predefined tag names.")
    say("If these tags are present, they must have a given type.")
  result = {}
  while True:
    value = ask("Enter the name of a predefined tag name "
                 "(or just enter after the last one)",
                 "optname")
    if value is None:
      if mandatory and len(result) == 0:
        sayerr("You must define at least one tag name")
      else:
        break
    elif value in result:
      sayerr("Tag name already defined, enter a different one")
      say(f"Previously defined tag names: {json.dumps(list(result.keys()))}")
    else:
      while True:
        typekey = ask(f"Enter the type key for tag '{value}'", "name")
        if not typekey in typekeys:
          sayerr("Type key invalid")
          say(f"Valid type keys: {json.dumps(typekeys)}")
        else:
          result[value] = typekey
          break
  return result

def add_predefined_to_def(predef):
  if len(predef) == 0:
    return ""
  else:
    return ", predefined: "+json.dumps(predef)

def define_datatype_tags(data, name):
  def_txt = "{tags: "
  name_regex_raw, name_regex_compiled = get_name_regex()
  typekeys = get_typekeys(name)
  def_txt += get_subdef_map(name, typekeys)
  def_txt += add_name_regex_to_def(name_regex_raw)
  def_txt += get_dict_tags_formatting("name, type key and value",
                                      "sub-element names and type keys")
  predef = get_predefined(name, typekeys, len(name_regex_raw) == 0)
  def_txt += add_predefined_to_def(predef)
  def_txt += get_implicit(name, list(predef.keys()))
  def_txt += get_emptystrvalue(name)
  def_txt += "}"
  if register_definition(data, name, def_txt):
    define_subdefs(data, name, typekeys, "type keys")
    return True
  else:
    return False

def get_list_lenrange():
  opt_txt = ""
  print()
  sayoptional()
  minlen = ask("What is the minimum number of sub-elements? "+\
               "(just enter for the default value, 1)", "optuint")
  sayoptional()
  maxlen_question = "What is the maximum number of sub-elements? "+\
                "(or just enter if no upper limit)"
  maxlen = ask(maxlen_question, "optuint")
  while maxlen is not None and minlen is not None and maxlen < minlen:
    sayerr(f"Enter a number larger than or equal {minlen}")
    maxlen = ask(maxlen_question, "optuint")
  if minlen is not None:
    opt_txt += f", minlength: {minlen}"
  if maxlen is not None:
    opt_txt += f", maxlength: {maxlen}"
  return opt_txt

def define_datatype_list(data, name):
  opt_txt = ""
  itemname = name+"_item"
  say("The datatype for the sub-elements will be defined later.")
  say(f"It will be called: '{itemname}'.")
  opt_txt += get_list_lenrange()
  opt_txt += get_seppfxsfx(name)
  opt_txt += get_emptystrvalue(name)
  if register_definition(data, name, "{list_of: "+itemname+opt_txt+"}"):
    say(f"Define the datatype of the sub-elements of {name}.")
    say(f"Name of sub-elements datatype: '{itemname}'.")
    print()
    define_datatype(data, itemname)
    return True
  else:
    return False

def define_datatype_ref(data, name):
  included_backup = data["included"].copy()
  external_datatype_names_backup = data["external_datatype_names"].copy()
  if len(data["datatype_names"]) > 0:
    say("Datatypes defined in this specification until now:")
    for dt in data["datatype_names"]:
      say(f"- {dt}")
  else:
    say("No datatype has been yet defined in this specification.")
  if len(data["external_datatype_names"]) > 0:
    say("Datatypes included from external specifications until now")
    for dt in data["external_datatype_names"]:
      say(f"- {dt}")
  target = ask("What is the name of the previously defined datatype?",
      "name", "enter the complete datatype name "+\
      "(i.e. including any automatically prepended prefix)")
  if target not in data["datatype_names"] and \
      target not in data["external_datatype_names"]:
    included = data["included"]
    if len(data["datatype_names"]) > 0:
      say(f"The datatype '{target}' has not been "+\
          "defined in this specification.")
    say(f"The specification defining '{target}' needs to be included.")
    if len(included) == 0:
      fn = ask("Enter the name of the specification file.", "string",
          "Enter the path of the file relative to the current directory")
      included.append(fn)
    else:
      say("Previously included specification files:")
      for fn in included:
        say(f"- {fn}")
      fn = ask("If you would like to include a further specification file, "+\
          "enter the filename (otherwise just enter)", "optstring",
          "Enter the path of the file relative to the current directory")
      if fn is not None:
        included.append(fn)
    data["external_datatype_names"].append(target)
  if register_definition(data, name, target):
    return True
  else:
    data["included"] = included_backup
    data["external_datatype_names"] = external_datatype_names_backup
    return False

def define_datatype_dtkinds_help(data, name):
  printhelp(format_answer("[0]")+
            "\nThe element is not parsed into sub-elements. "
            "Examples: identifiers, symbols, numerical values, "
            "free text descriptions.")
  printhelp(format_answer("[1]")+
            "\nThe element is a list/array/sequence of sub-elements. "
            "Each sub-element is equivalent, i.e. it has no name "
            "and the format does not depend on its position.")
  printhelp(format_answer("[2]")+
            "\nThe element is a structure/dict/tuple/object of sub-elements in "
            "a fixed order. Each sub-element has a name and format, which "
            "depends on its position in the element. ")
  printhelp(format_answer("[3]")+
            "\nThe element is a list of tags; i.e. "
            "sub-elements, given in any order, prefixed by "
            "a name and a tag type key. "
            "The names can be pre-defined or validated by a regex. "
            "The format depends on the tag key.")
  printhelp(format_answer("[4]")+
            "\nThe element is a named dictionary/tuple; i.e. "
            "sub-elements, given in any order, prefixed "
            "by a name, which defines the required format. "
            "All names are pre-defined. "
            "Sub-elements can be mandatory or optional.")
  printhelp(format_answer("[5]")+
            "\nDifferent sub-formats (with their own syntax) can "
            "be used for the element.")
  printhelp(format_answer("[6]")+
            "\nRe-use a datatype already defined: "
            "(1) A datatype previously defined during "
            "this interactive session or (2) a datatype defined in an external "
            "specification.")
  print("")
  return False

def define_datatype(data, name):
  question = f"Describe the internal structure of '{name}' values:"
  while True:
    if [define_datatype_single,
     define_datatype_list,
     define_datatype_struct,
     define_datatype_tags,
     define_datatype_dict,
     define_datatype_oneof,
     define_datatype_ref,
     define_datatype_dtkinds_help][
         ask(question, "dtkinds")](data, name):
       break

def format_included(included):
  included_txt = ""
  if len(included) > 0:
    included_txt = "included:"
    if len(included) == 1:
      included_txt += " " + included[0]
    else:
      for i in included:
        included_txt += "\n" + "  - " + i
  return included_txt+"\n"

def finalize_specification(data):
  data["file"].write(format_included(data["included"]))
  data["file"].flush()
  data["file"].close()
  print()
  say("The specification is complete")
  sayquoted("It has been written to file {}".format(data["filename"]))

def introduction():
  data = {"included": [],
          "datatype_names": [],
          "external_datatype_names": [],
          "basetype": "line",
          "file": None,
          "filename": None,
          "missing_definitions": []}
  say("<maroon>Welcome</maroon> "
      "to the interactive <i>textformats</i> specification wizard.")
  specname = ask("Enter a name for the specification:", "name")
  filename_help = "File path (absolute or relative).\n"+\
                  "Suggested file suffix: '.textformats.yaml'"
  sayoptional()
  filename = ask("Please enter a specification filename "+\
      f"or press enter for the default ('{specname}.textformats.yaml')",
      "optstring", filename_help)
  if filename==None:
    filename=specname+".textformats.yaml"
  while os.path.exists(filename):
    filename = ask(
        f"The file '{filename}' already exists and will not be overwritten.\n"+\
        "Please enter another filename:", "string",
        filename_help)
  data["file"] = open(filename, "w")
  data["filename"] = filename
  data["file"].write(f"# specification of '{specname}'\n")
  data["file"].write("# generated by genspec\n")
  data["file"].write("datatypes:\n")
  sayoptional()
  data["basetype"] = ask(
    "Please enter the name of the main datatype to define "+
    f"or press enter for the default ('{specname}_line')",
    "optname",
    "The suggested name is a good choice when "+\
    "specifying a file format. It does not imply that there is only one "+\
    "kind of lines (different kinds can be later defined).")
  if data["basetype"] == None:
    data["basetype"] = f"{specname}_line"
  return data

def main():
  data = introduction()
  define_datatype(data, data["basetype"])
  finalize_specification(data)

TextformatsPfx="<darkslategray>[<i>textformats</i>]</darkslategray> "
answer = setup_answers()
main()
