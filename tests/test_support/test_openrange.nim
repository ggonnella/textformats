{.used.}
import unittest
import options
import textformats/support/openrange

suite "openrange":
  test "intrange_contains":
    let i = 0.int64
    check i in (int64.none, int64.none).to_openrange
    check i in (-1.int64, int64.none).to_openrange
    check i in (int64.none, 1.int64).to_openrange
    check i in (-1.int64, 1.int64).to_openrange
    check i in (0.int64, 1.int64).to_openrange
    check i in (-1.int64, 0.int64).to_openrange
    check i notin (-2.int64, -1.int64).to_openrange
    check i notin (int64.none, -1.int64).to_openrange
    check i notin (1.int64, int64.none).to_openrange
  test "intrange_valid_min":
    let i = 0.int64
    check i.valid_min((int64.none, int64.none).to_openrange)
    check i.valid_min((-1.int64, int64.none).to_openrange)
    check i.valid_min((int64.none, 1.int64).to_openrange)
    check i.valid_min((-1.int64, 1.int64).to_openrange)
    check i.valid_min((0.int64, 1.int64).to_openrange)
    check i.valid_min((-1.int64, 0.int64).to_openrange)
    check i.valid_min((-2.int64, -1.int64).to_openrange)
    check i.valid_min((int64.none, -1.int64).to_openrange)
    check not i.valid_min((1.int64, int64.none).to_openrange)
  test "intrange_valid_max":
    let i = 0.int64
    check i.valid_max((int64.none, int64.none).to_openrange)
    check i.valid_max((-1.int64, int64.none).to_openrange)
    check i.valid_max((int64.none, 1.int64).to_openrange)
    check i.valid_max((-1.int64, 1.int64).to_openrange)
    check i.valid_max((0.int64, 1.int64).to_openrange)
    check i.valid_max((-1.int64, 0.int64).to_openrange)
    check not i.valid_max((-2.int64, -1.int64).to_openrange)
    check not i.valid_max((int64.none, -1.int64).to_openrange)
    check i.valid_max((1.int64, int64.none).to_openrange)
  test "intrange_safe_inc_min":
    var
      a = (int64.none, int64.none).to_openrange
      b = (int64.high-1, int64.none).to_openrange
      c = (int64.high, int64.high).to_openrange
    check a.low == int64.low
    check b.low == int64.high-1
    check c.low == int64.high
    a.safe_inc_min
    b.safe_inc_min
    c.safe_inc_min
    check a.low == int64.low
    check b.low == int64.high
    check c.low == int64.high
  test "intrange_safe_dec_max":
    var
      a = (int64.none, int64.none).to_openrange
      b = (int64.none, int64.low+1).to_openrange
      c = (int64.none, int64.low).to_openrange
    check a.high == int64.high
    check b.high == int64.low+1
    check c.high == int64.low
    a.safe_dec_max
    b.safe_dec_max
    c.safe_dec_max
    check a.high == int64.high
    check b.high == int64.low
    check c.high == int64.low
  test "intrange_limits":
    check low((int64.none, int64.none)) == int64.low
    check high((int64.none, int64.none)) == int64.high
  test "intrange_lowstr":
    check (int64.none, int64.none).to_openrange.lowstr == "-Inf"
    check (int64.none, 0.int64).to_openrange.lowstr == "-Inf"
    check (0.int64, int64.none).to_openrange.lowstr == "0"
  test "intrange_highstr":
    check (int64.none, int64.none).to_openrange.highstr == "Inf"
    check (int64.none, 0.int64).to_openrange.highstr == "0"
    check (0.int64, int64.none).to_openrange.highstr == "Inf"
  test "intrange_has_low":
    check not (int64.none, int64.none).to_openrange.has_low
    check not (int64.none, 0.int64).to_openrange.has_low
    check (0.int64, int64.none).to_openrange.has_low
  test "intrange_has_high":
    check not (int64.none, int64.none).to_openrange.has_high
    check (int64.none, 0.int64).to_openrange.has_high
    check not (0.int64, int64.none).to_openrange.has_high
  test "intrange_dollar":
    check $(int64.none, int64.none).to_openrange == "[-Inf, Inf]"
    check $(int64.none, 0.int64).to_openrange == "[-Inf, 0]"
    check $(0.int64, int64.none).to_openrange == "[0, Inf]"
  test "intrange_validate":
    try: (int64.none, int64.none).to_openrange.validate except: check false
    try: (int64.none, 0.int64).to_openrange.validate except: check false
    try: (0.int64, int64.none).to_openrange.validate except: check false
    expect(ValueError): (2.int64, 1.int64).to_openrange.validate
  test "uintrange_contains":
    let u = 0.uint64
    check u in (uint64.none, uint64.none)
    check u in (0.uint64, uint64.none)
    check u in (uint64.none, 1.uint64)
    check u in (0.uint64, 1.uint64)
    check u notin (1.uint64, 2.uint64)
    check u notin (1.uint64, uint64.none)
  test "uintrange_valid_min":
    let u = 0.uint64
    let v = 10.uint64
    check u.valid_min((uint64.none, uint64.none).to_openrange)
    check u.valid_min((0.uint64, uint64.none).to_openrange)
    check u.valid_min((uint64.none, 1.uint64).to_openrange)
    check u.valid_min((0.uint64, 1.uint64).to_openrange)
    check not u.valid_min((1.uint64, 2.uint64).to_openrange)
    check not u.valid_min((1.uint64, uint64.none).to_openrange)
    check v.valid_min((1.uint64, 2.uint64).to_openrange)
    check v.valid_min((1.uint64, uint64.none).to_openrange)
  test "uintrange_valid_max":
    let u = 0.uint64
    let v = 10.uint64
    check u.valid_max((uint64.none, uint64.none).to_openrange)
    check u.valid_max((0.uint64, uint64.none).to_openrange)
    check u.valid_max((uint64.none, 1.uint64).to_openrange)
    check u.valid_max((0.uint64, 1.uint64).to_openrange)
    check u.valid_max((1.uint64, 2.uint64).to_openrange)
    check u.valid_max((1.uint64, uint64.none).to_openrange)
    check not v.valid_max((1.uint64, 2.uint64).to_openrange)
    check v.valid_max((1.uint64, uint64.none).to_openrange)
  test "uintrange_safe_inc_min":
    var
      a = (uint64.none, uint64.none).to_openrange
      b = (uint64.high-1, uint64.none).to_openrange
      c = (uint64.high, uint64.high).to_openrange
    check a.low == 0.uint64
    check b.low == uint64.high-1
    check c.low == uint64.high
    a.safe_inc_min
    b.safe_inc_min
    c.safe_inc_min
    check a.low == 0.uint64
    check b.low == uint64.high
    check c.low == uint64.high
  test "uintrange_safe_dec_max":
    var
      a = (uint64.none, uint64.none).to_openrange
      b = (uint64.none, 1.uint64).to_openrange
      c = (uint64.none, 0.uint64).to_openrange
    check a.high == uint64.high
    check b.high == 1.uint64
    check c.high == 0.uint64
    a.safe_dec_max
    b.safe_dec_max
    c.safe_dec_max
    check a.high == uint64.high
    check b.high == 0.uint64
    check c.high == 0.uint64
  test "uintrange_limits":
    check low((uint64.none, uint64.none)) == 0.uint64
    check high((uint64.none, uint64.none)) == uint64.high
  test "uintrange_lowstr":
    check (uint64.none, uint64.none).to_openrange.lowstr == "0"
    check (uint64.none, 0.uint64).to_openrange.lowstr == "0"
    check (1.uint64, uint64.none).to_openrange.lowstr == "1"
  test "uintrange_highstr":
    check (uint64.none, uint64.none).to_openrange.highstr == "Inf"
    check (uint64.none, 1.uint64).to_openrange.highstr == "1"
    check (0.uint64, uint64.none).to_openrange.highstr == "Inf"
  test "uintrange_has_low":
    check not (uint64.none, uint64.none).to_openrange.has_low
    check not (uint64.none, 0.uint64).to_openrange.has_low
    check (1.uint64, uint64.none).to_openrange.has_low
  test "uintrange_has_high":
    check not (uint64.none, uint64.none).to_openrange.has_high
    check (uint64.none, 1.uint64).to_openrange.has_high
    check not (0.uint64, uint64.none).to_openrange.has_high
  test "uintrange_dollar":
    check $(uint64.none, uint64.none).to_openrange == "[0, Inf]"
    check $(uint64.none, 0.uint64).to_openrange == "[0, 0]"
    check $(0.uint64, uint64.none).to_openrange == "[0, Inf]"
  test "uintrange_validate":
    try: (uint64.none, uint64.none).to_openrange.validate except: check false
    try: (uint64.none, 0.uint64).to_openrange.validate except: check false
    try: (0.uint64, uint64.none).to_openrange.validate except: check false
    expect(ValueError): (1.uint64, 0.uint64).to_openrange.validate
  test "naturalrange_contains":
    let u = 0.Natural
    check u in newOpenRange(Natural.none, Natural.none)
    check u in newOpenRange(0.Natural.some, Natural.none)
    check u in newOpenRange(Natural.none, 1.Natural.some)
    check u in newOpenRange(0.Natural.some, 1.Natural.some)
    check u notin newOpenRange[Natural](1.Natural.some, 2.Natural.some)
    check u notin newOpenRange[Natural](1.Natural.some, Natural.none)
  test "naturalrange_valid_min":
    let u = 0.Natural
    let v = 10.Natural
    check u.valid_min(
      newOpenRange[Natural](Natural.none, Natural.none))
    check u.valid_min(
      newOpenRange[Natural](0.Natural.some, Natural.none))
    check u.valid_min(
      newOpenRange[Natural](Natural.none, 1.Natural.some))
    check u.valid_min(
      newOpenRange[Natural](0.Natural.some, 1.Natural.some))
    check not u.valid_min(
      newOpenRange[Natural](1.Natural.some, 2.Natural.some))
    check not u.valid_min(
      newOpenRange[Natural](1.Natural.some, Natural.none))
    check v.valid_min(
      newOpenRange[Natural](1.Natural.some, 2.Natural.some))
    check v.valid_min(
      newOpenRange[Natural](1.Natural.some, Natural.none))
  test "naturalrange_valid_max":
    let u = 0.Natural
    let v = 10.Natural
    check u.valid_max(
      newOpenRange[Natural](Natural.none, Natural.none))
    check u.valid_max(
      newOpenRange[Natural](0.Natural.some, Natural.none))
    check u.valid_max(
      newOpenRange[Natural](Natural.none, 1.Natural.some))
    check u.valid_max(
      newOpenRange[Natural](0.Natural.some, 1.Natural.some))
    check u.valid_max(
      newOpenRange[Natural](1.Natural.some, 2.Natural.some))
    check u.valid_max(
      newOpenRange[Natural](1.Natural.some, Natural.none))
    check not v.valid_max(
      newOpenRange[Natural](1.Natural.some, 2.Natural.some))
    check v.valid_max(
      newOpenRange[Natural](1.Natural.some, Natural.none))
  test "naturalrange_safe_inc_min":
    var
      a = newOpenRange[Natural](Natural.none, Natural.none)
      b = newOpenRange[Natural]((Natural.high-1).Natural.some,
                             Natural.none)
      c = newOpenRange[Natural](Natural.high.some, Natural.none)
    check a.low == 0.Natural
    check b.low == (Natural.high-1.Natural)
    check c.low == Natural.high
    a.safe_inc_min
    b.safe_inc_min
    c.safe_inc_min
    check a.low == 0.Natural
    check b.low == Natural.high
    check c.low == Natural.high
  test "naturalrange_safe_dec_max":
    var
      a = newOpenRange[Natural](Natural.none, Natural.none)
      b = newOpenRange[Natural](Natural.none, 1.Natural.some)
      c = newOpenRange[Natural](Natural.none, 0.Natural.some)
    check a.high == Natural.high
    check b.high == 1.Natural
    check c.high == 0.Natural
    a.safe_dec_max
    b.safe_dec_max
    c.safe_dec_max
    check a.high == Natural.high
    check b.high == 0.Natural
    check c.high == 0.Natural
  test "naturalrange_limits":
    check low(newOpenRange[Natural](Natural.none, Natural.none)) ==
      0.Natural
    check high(newOpenRange[Natural](Natural.none, Natural.none)) ==
      Natural.high
  test "naturalrange_lowstr":
    check newOpenRange[Natural](Natural.none, Natural.none).lowstr ==
      "0"
    check newOpenRange[Natural](Natural.none, 0.Natural.some).lowstr == "0"
    check newOpenRange[Natural](1.Natural.some, Natural.none).lowstr == "1"
  test "naturalrange_highstr":
    check newOpenRange[Natural](Natural.none, Natural.none).highstr ==
      "Inf"
    check newOpenRange[Natural](Natural.none, 1.Natural.some).highstr == "1"
    check newOpenRange[Natural](0.Natural.some, Natural.none).highstr == "Inf"
  test "naturalrange_has_low":
    check not newOpenRange[Natural](Natural.none, Natural.none).has_low
    check not newOpenRange[Natural](Natural.none, 0.Natural.some).has_low
    check newOpenRange[Natural](1.Natural.some, Natural.none).has_low
  test "naturalrange_has_high":
    check not newOpenRange[Natural](Natural.none, Natural.none).has_high
    check newOpenRange[Natural](Natural.none, 1.Natural.some).has_high
    check not newOpenRange[Natural](0.Natural.some, Natural.none).has_high
  test "naturalrange_dollar":
    check $(newOpenRange[Natural](Natural.none, Natural.none)) ==
      "[0, Inf]"
    check $(newOpenRange[Natural](Natural.none, 1.Natural.some)) ==
      "[0, 1]"
    check $(newOpenRange[Natural](1.Natural.some, Natural.none)) ==
      "[1, Inf]"
  test "naturalrange_validate":
    try: newOpenRange[Natural](Natural.none, Natural.none).validate
    except: check false
    try: newOpenRange[Natural](Natural.none, 1.Natural.some).validate
    except: check false
    try: newOpenRange[Natural](1.Natural.some, Natural.none).validate
    except: check false
    expect(ValueError):
      newOpenRange[Natural](1.Natural.some, 0.Natural.some).validate
