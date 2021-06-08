#!/usr/bin/env python3
"""
Generate specification with random embedded data.

Usage:
  random_random_cigars.py <nlines>

Arguments:
  <nlines>: how many data lines

Options:
  -h, --help    show this help message
  --version     show version number
"""

import docopt
from random import choice, choices, random, randrange
import string

specification = """
datatypes:
  line:
    composed_of:
    - id: {regex: "[A-Z]{2}[0-9]{5}"}
    - age: {unsigned_integer: {min: 0}}
    - treatment: {accepted_values: ["control", "treatment"]}
    - outcome: {accepted_values: ["discharge", "death"]}
    - description: string
    required: 4
    sep: "\t"
"""

def random_id():
  letters = choices(string.ascii_uppercase, k=2)
  letters += choices(string.digits, k=5)
  return "".join(letters)

def random_age():
  return str(randrange(100))

def random_treatment():
  return choice(["treatment", "control"])

def random_outcome():
  return choice(["death", "discharge"])

descriptions = [
    "interesting, consider for case study",
    "overweight",
    "underweight",
    "diabetes",
    "cancer",
    "professional athlete",
    "mislabeled?",
    "initially refused treatment"
]

def random_description():
  if random() > 0.9:
    return choice(descriptions)
  else:
    return ""

def random_line():
  elements = [random_id(), random_age(),
             random_treatment(), random_outcome()]
  desc = random_description()
  if desc: elements.append(desc)
  return "\t".join(elements)

def main(args):
  print(specification)
  print("---")
  for i in range(int(args["<nlines>"])):
    print(random_line())

if __name__ == "__main__":
  args = docopt.docopt(__doc__, version="0.1")
  main(args)
