import textformats/support/error_support
import unittest

suite "error_support":
  test "reraise_prepend":
    try:
      try:
        raise newException(ValueError, "0")
      except ValueError:
        reraise_prepend("<")
    except ValueError:
      var e = getCurrentException()
      check e.msg == "<0"

  test "reraise_append":
    try:
      try:
        raise newException(ValueError, "0")
      except ValueError:
        reraise_append(">")
    except ValueError:
      var e = getCurrentException()
      check e.msg == "0>"

  test "reraise_prepend_append":
    try:
      try:
        raise newException(ValueError, "0")
      except ValueError:
        reraise_prepend_append("<", ">")
    except ValueError:
      var e = getCurrentException()
      check e.msg == "<0>"
