import unittest
import json
import textformats/support/json_support

suite "json_support":

  test "validate_kind":
    expect(JsonNodeKindError):
      (%*3).validate_kind(JFloat)
    expect(JsonNodeKindError):
      (%*1.0).validate_kind(JInt)
    expect(JsonNodeKindError):
      (%*[1]).validate_kind(JInt)
    try:
      (%*3).validate_kind(JInt)
      (%*1.0).validate_kind(JFloat)
      (%*[1]).validate_kind(JArray)
    except:
      check false

  test "to_int":
    check %*2 + 1 == 3
  test "to_float":
    check %*2.0 + 1.0 == 3.0
  test "to_string":
    check %*"abc" & "def" == "abcdef"
  test "to_bool":
    if %*false: check false
    if %*true: check true

  let
    i = %*3
    neg = %*(-3)
    f = %*(2.0)
    s = %*"abc"
    b_t = %*true
    b_f = %*false
    n = newJNull()
    a = %*["a", "b"]
    o = %*{"a": 1, "b": 2}
  test "is_int":
    check i.is_int
    check neg.is_int
    for x in @[f, s, b_t, b_f, n, a, o]:
      check not x.is_int
  test "is_uint":
    check i.is_uint
    check not neg.is_uint
    for x in @[f, s, b_t, b_f, n, a, o]:
      check not x.is_uint
  test "is_float":
    check f.is_float
    for x in @[i, neg, s, b_t, b_f, n, a, o]:
      check not x.is_float
  test "is_string":
    check s.is_string
    for x in @[f, i, neg, b_t, b_f, n, a, o]:
      check not x.is_string
  test "is_bool":
    check b_t.is_bool
    check b_f.is_bool
    for x in @[f, i, neg, s, n, a, o]:
      check not x.is_bool
  test "is_null":
    check n.is_null
    for x in @[f, i, neg, s, b_t, b_f, a, o]:
      check not x.is_null
  test "is_array":
    check a.is_array
    for x in @[f, i, neg, s, b_t, b_f, n, o]:
      check not x.is_array
  test "is_object":
    check o.is_object
    for x in @[f, i, neg, s, b_t, b_f, n, a]:
      check not x.is_object
  test "is_scalar":
    for x in @[f, i, neg, s, b_t, b_f, n]:
      check x.is_scalar
    for x in @[a, o]:
      check not x.is_scalar
  test "is_compound":
    for x in @[a, o]:
      check x.is_compound
    for x in @[f, i, neg, s, b_t, b_f, n]:
      check not x.is_compound
