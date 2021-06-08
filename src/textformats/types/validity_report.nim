import strformat

type
  ValidityTest = object
    desc: string
    passed: bool
    errinfo: string

  ValidityReport* = object
    valid*: bool
    tests: seq[ValidityTest]

proc register*(self: var ValidityReport, desc: string,
               passed: bool, errinfo = "") =
  if not passed: self.valid = false
  self.tests.add(ValidityTest(desc: desc, passed: passed, errinfo: errinfo))

proc merge*(self: var ValidityReport, other: ValidityReport) =
  if not other.valid: self.valid = false
  for t in other.tests:
    self.tests.add(ValidityTest(
      desc: t.desc, passed: t.passed, errinfo: t.errinfo))

proc `$`*(self: ValidityTest): string =
  result = if self.passed: "[OK] " else: "[FAILED] "
  result &= self.desc
  if not self.passed and len(self.errinfo) > 0:
    result &= &" (Error: {self.errinfo})"

proc errmsg*(self: ValidityReport): string =
  for t in self.tests:
    if not t.passed:
      result = &"Failed test: {t.desc}"
      if len(t.errinfo) > 0:
        result &= &" (Error: {t.errinfo})"
      break

proc `$`*(self: ValidityReport): string =
  result = "is "
  if not self.valid: result &= "not "
  result &= "valid\n"
  for t in self.tests:
    result &= $t & "\n"
