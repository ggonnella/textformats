import unittest
import options
import textformats/support/openrange

suite "openrange":
  test "to_openrange":
    check (int.none, int.none).to_openrange ==
      OpenRange[int](rmin: int.none, rmax: int.none)
    check (1, 2).to_openrange == OpenRange[int](rmin: 1, rmax: 2)
    check (1, int.none).to_openrange == OpenRange[int](rmin: 1, rmax: int.none)
    check (uint.none, uint.none).to_openrange ==
      OpenRange[uint](rmin: uint.none, rmax: uint.none)
    #
    # in Nim 1.2.x the following generates
    # wrong C code and does not compile correctly (it uses the methods for
    # int instead of those for Natural)
    #
    # check (Natural.none, Natural.none).to_openrange ==
    #   OpenRange[Natural](rmin: Natural.none, rmax: Natural.none)
    #
    # as a consequence in the following tests, OpenRange[Natural] is always
    # created using the constructor
  test "intrange_contains":
    let i = 0
    check i in (int.none, int.none)
    check i in (-1, int.none)
    check i in (int.none, 1)
    check i in (-1, 1)
    check i in (0, 1)
    check i in (-1, 0)
    check i notin (-2, -1)
    check i notin (int.none, -1)
    check i notin (1, int.none)
  test "intrange_valid_min":
    let i = 0
    check i.valid_min((int.none, int.none).to_openrange)
    check i.valid_min((-1, int.none).to_openrange)
    check i.valid_min((int.none, 1).to_openrange)
    check i.valid_min((-1, 1).to_openrange)
    check i.valid_min((0, 1).to_openrange)
    check i.valid_min((-1, 0).to_openrange)
    check i.valid_min((-2, -1).to_openrange)
    check i.valid_min((int.none, -1).to_openrange)
    check not i.valid_min((1, int.none).to_openrange)
  test "intrange_valid_max":
    let i = 0
    check i.valid_max((int.none, int.none).to_openrange)
    check i.valid_max((-1, int.none).to_openrange)
    check i.valid_max((int.none, 1).to_openrange)
    check i.valid_max((-1, 1).to_openrange)
    check i.valid_max((0, 1).to_openrange)
    check i.valid_max((-1, 0).to_openrange)
    check not i.valid_max((-2, -1).to_openrange)
    check not i.valid_max((int.none, -1).to_openrange)
    check i.valid_max((1, int.none).to_openrange)
  test "intrange_safe_inc_min":
    var
      a = (int.none, int.none).to_openrange
      b = (int.high-1, int.none).to_openrange
      c = (int.high, int.high).to_openrange
    check a.low == int.low
    check b.low == int.high-1
    check c.low == int.high
    a.safe_inc_min
    b.safe_inc_min
    c.safe_inc_min
    check a.low == int.low
    check b.low == int.high
    check c.low == int.high
  test "intrange_safe_dec_max":
    var
      a = (int.none, int.none).to_openrange
      b = (int.none, int.low+1).to_openrange
      c = (int.none, int.low).to_openrange
    check a.high == int.high
    check b.high == int.low+1
    check c.high == int.low
    a.safe_dec_max
    b.safe_dec_max
    c.safe_dec_max
    check a.high == int.high
    check b.high == int.low
    check c.high == int.low
  test "intrange_limits":
    check low((int.none, int.none)) == int.low
    check high((int.none, int.none)) == int.high
  test "intrange_lowstr":
    check (int.none, int.none).to_openrange.lowstr == "-Inf"
    check (int.none, 0).to_openrange.lowstr == "-Inf"
    check (0, int.none).to_openrange.lowstr == "0"
  test "intrange_highstr":
    check (int.none, int.none).to_openrange.highstr == "Inf"
    check (int.none, 0).to_openrange.highstr == "0"
    check (0, int.none).to_openrange.highstr == "Inf"
  test "intrange_has_low":
    check not (int.none, int.none).to_openrange.has_low
    check not (int.none, 0).to_openrange.has_low
    check (0, int.none).to_openrange.has_low
  test "intrange_has_high":
    check not (int.none, int.none).to_openrange.has_high
    check (int.none, 0).to_openrange.has_high
    check not (0, int.none).to_openrange.has_high
  test "intrange_dollar":
    check $(int.none, int.none).to_openrange == "[-Inf, Inf]"
    check $(int.none, 0).to_openrange == "[-Inf, 0]"
    check $(0, int.none).to_openrange == "[0, Inf]"
  test "intrange_validate":
    try: (int.none, int.none).to_openrange.validate except: check false
    try: (int.none, 0).to_openrange.validate except: check false
    try: (0, int.none).to_openrange.validate except: check false
    expect(ValueError): (2, 1).to_openrange.validate
  test "uintrange_contains":
    let u = 0'u
    check u in (uint.none, uint.none)
    check u in (0'u, uint.none)
    check u in (uint.none, 1'u)
    check u in (0'u, 1'u)
    check u notin (1'u, 2'u)
    check u notin (1'u, uint.none)
  test "uintrange_valid_min":
    let u = 0'u
    let v = 10'u
    check u.valid_min((uint.none, uint.none).to_openrange)
    check u.valid_min((0'u, uint.none).to_openrange)
    check u.valid_min((uint.none, 1'u).to_openrange)
    check u.valid_min((0'u, 1'u).to_openrange)
    check not u.valid_min((1'u, 2'u).to_openrange)
    check not u.valid_min((1'u, uint.none).to_openrange)
    check v.valid_min((1'u, 2'u).to_openrange)
    check v.valid_min((1'u, uint.none).to_openrange)
  test "uintrange_valid_max":
    let u = 0'u
    let v = 10'u
    check u.valid_max((uint.none, uint.none).to_openrange)
    check u.valid_max((0'u, uint.none).to_openrange)
    check u.valid_max((uint.none, 1'u).to_openrange)
    check u.valid_max((0'u, 1'u).to_openrange)
    check u.valid_max((1'u, 2'u).to_openrange)
    check u.valid_max((1'u, uint.none).to_openrange)
    check not v.valid_max((1'u, 2'u).to_openrange)
    check v.valid_max((1'u, uint.none).to_openrange)
  test "uintrange_safe_inc_min":
    var
      a = (uint.none, uint.none).to_openrange
      b = (uint.high-1, uint.none).to_openrange
      c = (uint.high, uint.high).to_openrange
    check a.low == 0'u
    check b.low == uint.high-1
    check c.low == uint.high
    a.safe_inc_min
    b.safe_inc_min
    c.safe_inc_min
    check a.low == 0'u
    check b.low == uint.high
    check c.low == uint.high
  test "uintrange_safe_dec_max":
    var
      a = (uint.none, uint.none).to_openrange
      b = (uint.none, 1'u).to_openrange
      c = (uint.none, 0'u).to_openrange
    check a.high == int.high.uint
    check b.high == 1'u
    check c.high == 0'u
    a.safe_dec_max
    b.safe_dec_max
    c.safe_dec_max
    check a.high == int.high.uint
    check b.high == 0'u
    check c.high == 0'u
  test "uintrange_limits":
    check low((uint.none, uint.none)) == 0'u
    check high((uint.none, uint.none)) == int.high.uint
  test "uintrange_lowstr":
    check (uint.none, uint.none).to_openrange.lowstr == "0"
    check (uint.none, 0'u).to_openrange.lowstr == "0"
    check (1'u, uint.none).to_openrange.lowstr == "1"
  test "uintrange_highstr":
    check (uint.none, uint.none).to_openrange.highstr == "Inf"
    check (uint.none, 1'u).to_openrange.highstr == "1"
    check (0'u, uint.none).to_openrange.highstr == "Inf"
  test "uintrange_has_low":
    check not (uint.none, uint.none).to_openrange.has_low
    check not (uint.none, 0'u).to_openrange.has_low
    check (1'u, uint.none).to_openrange.has_low
  test "uintrange_has_high":
    check not (uint.none, uint.none).to_openrange.has_high
    check (uint.none, 1'u).to_openrange.has_high
    check not (0'u, uint.none).to_openrange.has_high
  test "uintrange_dollar":
    check $(uint.none, uint.none).to_openrange == "[0, Inf]"
    check $(uint.none, 0'u).to_openrange == "[0, 0]"
    check $(0'u, uint.none).to_openrange == "[0, Inf]"
  test "uintrange_validate":
    try: (uint.none, uint.none).to_openrange.validate except: check false
    try: (uint.none, 0'u).to_openrange.validate except: check false
    try: (0'u, uint.none).to_openrange.validate except: check false
    expect(ValueError): (1'u, 0'u).to_openrange.validate
  test "naturalrange_contains":
    let u = 0.Natural
    check u in OpenRange[Natural](rmin: Natural.none, rmax: Natural.none)
    check u in OpenRange[Natural](rmin: 0.Natural, rmax: Natural.none)
    check u in OpenRange[Natural](rmin: Natural.none, rmax: 1.Natural)
    check u in OpenRange[Natural](rmin: 0.Natural, rmax: 1.Natural)
    check u notin OpenRange[Natural](rmin: 1.Natural, rmax: 2.Natural)
    check u notin OpenRange[Natural](rmin: 1.Natural, rmax: Natural.none)
  test "naturalrange_valid_min":
    let u = 0.Natural
    let v = 10.Natural
    check u.valid_min(
      OpenRange[Natural](rmin: Natural.none, rmax: Natural.none))
    check u.valid_min(
      OpenRange[Natural](rmin: 0.Natural, rmax: Natural.none))
    check u.valid_min(
      OpenRange[Natural](rmin: Natural.none, rmax: 1.Natural))
    check u.valid_min(
      OpenRange[Natural](rmin: 0.Natural, rmax: 1.Natural))
    check not u.valid_min(
      OpenRange[Natural](rmin: 1.Natural, rmax: 2.Natural))
    check not u.valid_min(
      OpenRange[Natural](rmin: 1.Natural, rmax: Natural.none))
    check v.valid_min(
      OpenRange[Natural](rmin: 1.Natural, rmax: 2.Natural))
    check v.valid_min(
      OpenRange[Natural](rmin: 1.Natural, rmax: Natural.none))
  test "naturalrange_valid_max":
    let u = 0.Natural
    let v = 10.Natural
    check u.valid_max(
      OpenRange[Natural](rmin: Natural.none, rmax: Natural.none))
    check u.valid_max(
      OpenRange[Natural](rmin: 0.Natural, rmax: Natural.none))
    check u.valid_max(
      OpenRange[Natural](rmin: Natural.none, rmax: 1.Natural))
    check u.valid_max(
      OpenRange[Natural](rmin: 0.Natural, rmax: 1.Natural))
    check u.valid_max(
      OpenRange[Natural](rmin: 1.Natural, rmax: 2.Natural))
    check u.valid_max(
      OpenRange[Natural](rmin: 1.Natural, rmax: Natural.none))
    check not v.valid_max(
      OpenRange[Natural](rmin: 1.Natural, rmax: 2.Natural))
    check v.valid_max(
      OpenRange[Natural](rmin: 1.Natural, rmax: Natural.none))
  test "naturalrange_safe_inc_min":
    var
      a = OpenRange[Natural](rmin: Natural.none, rmax: Natural.none)
      b = OpenRange[Natural](rmin: (Natural.high-1).Natural.some,
                             rmax: Natural.none)
      c = OpenRange[Natural](rmin: Natural.high, rmax: Natural.none)
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
      a = OpenRange[Natural](rmin: Natural.none, rmax: Natural.none)
      b = OpenRange[Natural](rmin: Natural.none, rmax: 1.Natural.some)
      c = OpenRange[Natural](rmin: Natural.none, rmax: 0.Natural.some)
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
    check low(OpenRange[Natural](rmin: Natural.none, rmax: Natural.none)) ==
      0.Natural
    check high(OpenRange[Natural](rmin: Natural.none, rmax: Natural.none)) ==
      Natural.high
  test "naturalrange_lowstr":
    check OpenRange[Natural](rmin:Natural.none, rmax: Natural.none).lowstr ==
      "0"
    check OpenRange[Natural](rmin:Natural.none, rmax:0.Natural).lowstr == "0"
    check OpenRange[Natural](rmin:1.Natural, rmax:Natural.none).lowstr == "1"
  test "naturalrange_highstr":
    check OpenRange[Natural](rmin:Natural.none, rmax: Natural.none).highstr ==
      "Inf"
    check OpenRange[Natural](rmin:Natural.none, rmax:1.Natural).highstr == "1"
    check OpenRange[Natural](rmin:0.Natural, rmax:Natural.none).highstr == "Inf"
  test "naturalrange_has_low":
    check not OpenRange[Natural](rmin:Natural.none, rmax: Natural.none).has_low
    check not OpenRange[Natural](rmin:Natural.none, rmax:0.Natural).has_low
    check OpenRange[Natural](rmin:1.Natural, rmax:Natural.none).has_low
  test "naturalrange_has_high":
    check not OpenRange[Natural](rmin:Natural.none, rmax: Natural.none).has_high
    check OpenRange[Natural](rmin:Natural.none, rmax:1.Natural).has_high
    check not OpenRange[Natural](rmin:0.Natural, rmax:Natural.none).has_high
  test "naturalrange_dollar":
    check $(OpenRange[Natural](rmin:Natural.none, rmax: Natural.none)) ==
      "[0, Inf]"
    check $(OpenRange[Natural](rmin:Natural.none, rmax:1.Natural)) ==
      "[0, 1]"
    check $(OpenRange[Natural](rmin:1.Natural, rmax:Natural.none)) ==
      "[1, Inf]"
  test "naturalrange_validate":
    try: OpenRange[Natural](rmin:Natural.none, rmax: Natural.none).validate
    except: check false
    try: OpenRange[Natural](rmin:Natural.none, rmax:1.Natural).validate
    except: check false
    try: OpenRange[Natural](rmin:1.Natural, rmax:Natural.none).validate
    except: check false
    expect(ValueError):
      OpenRange[Natural](rmin:1.Natural, rmax:0.Natural).validate
