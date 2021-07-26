import strutils

# adapted from coproc answer in
# https://stackoverflow.com/questions/33512037/a-regular-expression-generator-for-number-ranges

template digit_range[T: int64 or uint64](start: T, stop: T): string =
  ## character class for digits or digit ranges
  assert(start < 10 and start >= 0)
  assert(stop < 10 and stop >= 0)
  assert(stop >= start)
  if start == stop: $start
  elif start == 0 and stop == 9: r"\d"
  elif stop == start+1: "[" & $start & $stop & "]"
  else: "[" & $start & "-" & $stop & "]"

template is_digit_range(str: string): bool =
  ## check if string could be the result of the digit_range template
  str == r"\d" or
  (str.len == 1 and str[0].is_digit) or
  (str[0] == '[' and str[^1] == ']' and
     str[1].is_digit and str[^2].is_digit and
       (str.len == 4 or (str.len == 5 and str[2] == '-')))

proc join_regexes(list: seq[string]): string =
  var
    optional = false
    n_added = 0
  for i in countdown(list.len-1, 0):
    let r = list[i]
    if r.len == 0: optional = true
    else:
      n_added += 1
      if result.len > 0: result &= "|"
      result &= r
  if n_added > 0:
    if n_added > 1 or (optional and not is_digit_range(result)):
      result = "(?:" & result & ")"
    if optional: result &= "?"

template get_digit_range_pfx(str: string, i: int64): string =
  var result = ""
  if str[i].is_digit: result = str[i..i]
  elif str.len > i+1 and str[i..i+1] == r"\d": result = str[i..i+1]
  elif str.len > i+3 and str[i] == '[' and str[i+1].is_digit:
    let j = if str[i+2] == '-': 1 else: 0
    if j == 0 or str.len > i+4:
      if str[i+2+j].is_digit and str[i+3+j] == ']': result = str[i..i+3+j]
  result

template min_str_len(list: seq[string]): int64 =
  var result = list[0].len
  for i in 1..<list.len:
    if list[i].len < result: result = list[i].len
  result

template fixed_digits_lcp(list: seq[string]): int64 =
  var result = 0
  let msl = min_str_len(list)
  block compute_lcp:
    while result < msl:
      let a = get_digit_range_pfx(list[0], result)
      if a.len == 0: break compute_lcp
      else:
        for i in 1..<list.len:
          let b = get_digit_range_pfx(list[i], result)
          if b != a: break compute_lcp
      result += a.len
  result

template simplify_by_lcp(list: var seq[string]) =
  if list.len > 0:
    let lcp = fixed_digits_lcp(list)
    if lcp > 0:
      let pfx = list[0][0..<lcp]
      for i in 0..<list.len:
        list[i] = list[i][lcp..^1]
      let joined = pfx & join_regexes(list)
      list.setlen(1)
      list[0] = joined

proc intrng_regex_parts[T: int64 or uint64](a: T, b: T): seq[string]

template negintrng_regex_parts(a: int64, b: int64): seq[string] =
  assert(a < 0)
  assert(a <= b)
  var result = newseq[string]()
  if a == int64.low:
    result.add($int64.low)
    result.add(intrng_regex_parts(a+1,b))
  elif b < 0:
    result.add("-" & join_regexes(intrng_regex_parts(-b, -a)))
  else:
    result.add("0")
    if -a > b: # -100, 50
      if b > 0:
        result.add("-?" & join_regexes(intrng_regex_parts(1.int64, b)))
      result.add("-" & join_regexes(intrng_regex_parts(b+1, -a)))
    else: # -50, 100
      result.add("-?" & join_regexes(intrng_regex_parts(1.int64, -a)))
      if -a < b:
        result.add(intrng_regex_parts(1.int64-a, b))
  result

template zerointrng_regex_parts[T: int64 or uint64](b: T): seq[string] =
  var result = @[digit_range(T(0), min(b, 9))]
  if b > 9:
    result &= intrng_regex_parts(T(10), b)
  result

template posintrng_regex_parts[T: int64 or uint64](a, b: T): seq[string] =
  var result: seq[string]
  let
    a_pfx = ($a)[0..^2]
    a_lsd = a mod 10
    b_lsd = b mod 10
  if a div 10 == b div 10:
    result = @[a_pfx & digit_range(a_lsd, b_lsd)]
  else:
    result = newseq[string]()
    let b_pfx = ($b)[0..^2]
    if a_lsd != 0:
      result.add(a_pfx & digit_range(a_lsd, 9))
    let c = (a+9) div 10
    var d = b div 10
    if b_lsd < 9: d -= 1
    if d >= c:
      var subresult = intrng_regex_parts(c, d)
      simplify_by_lcp(subresult)
      result.add(join_regexes(subresult) & r"\d")
    if b_lsd != 9:
      let dr =
        when T is int64: digit_range(0.int64, b_lsd)
        else: digit_range(0.uint64, b_lsd)
      result.add(b_pfx & dr)
    simplify_by_lcp(result)
  result

# generate list of regular expressions for the positive int64egers range [a,b]
proc intrng_regex_parts[T: int64 or uint64](a: T, b: T): seq[string] =
  if b < a: result = @[]
  elif a == b: result = @[$a]
  elif a < 0:
    when a is int64: result = negintrng_regex_parts(a, b)
  elif a == 0: result = zerointrng_regex_parts(b)
  else: result = posintrng_regex_parts(a, b)

proc intrng_regex*(a: int64, b: int64): string =
  join_regexes(intrng_regex_parts(a, b))

proc uintrng_regex*(a: uint64, b: uint64): string =
  join_regexes(intrng_regex_parts(a, b))

proc uint_gt_regex*(a: uint64): string =
  var parts = newseq[string]()
  let
    n_digits = len($a)
    upto = uint64(parse_int("9".repeat(n_digits)))
  parts = intrng_regex_parts(a, upto)
  parts.add("[1-9][0-9]{" & $n_digits & ",}")
  return join_regexes(parts)

proc uint_lt_regex*(a: uint64): string =
  return uintrng_regex(0, a)

proc int_gt_regex*(a: int64): string =
  if a == 0:
    return r"(?:[+-]?0|\+?[1-9][0-9]*)"
  elif a > 0:
    return r"\+?" & uint_gt_regex(a.uint64)
  else:
    var parts = intrng_regex_parts(0.int64, -a)
    parts.add(r"\+?[1-9][0-9]*")
    return join_regexes(parts)

proc int_lt_regex*(a: int64): string =
  if a == 0:
    return r"(?:[+-]?0|-[1-9][0-9]*)"
  elif a < 0:
    return r"-" & uint_gt_regex(a.uint64)
  else:
    var parts = intrng_regex_parts(0.int64, a)
    parts.add(r"-[1-9][0-9]*")
    return join_regexes(parts)

when is_main_module:
  echo(intrng_regex(21.int64,29.int64))
  import regex
  block exhaustive_tests:
    proc test_range[T: int64 or uint64](a: T, b: T) =
      let r =
        when T is int64: re(intrng_regex(a, b))
        else:          re(uintrng_regex(a, b))
      for n in a..b:
        do_assert(($n).match(r))
    let n = [-1000,-999,-134,-101,-100,-99,-35,
             -10,-1,0,1,10,35,99,100,101,134,999,1000]
    for i in 0..<n.len:
      for j in i..<n.len:
        test_range(n[i].int64, n[j].int64)
        if n[i] > 0 and n[j] > 0:
          test_range(n[i].uint64, n[j].uint64)
  block extreme_values_int64:
    let
      r1 = intrng_regex(int64.low,0).re
      r2 = intrng_regex(int64.low,int64.high).re
      r3 = intrng_regex(0,int64.high).re
    for r in @[r1, r2]:
      do_assert(($int64.low).match(r))
      do_assert(($(int64.low+1)).match(r))
    for r in @[r1, r2, r3]:
      do_assert("0".match(r))
    for r in @[r2, r3]:
      do_assert(($(int64.high-1)).match(r))
      do_assert(($(int64.high)).match(r))
  block extreme_values_uint64:
    let r = uintrng_regex(0.uint64,uint64.high).re
    do_assert("0".match(r))
    do_assert(($uint64.high).match(r))
    do_assert(($(uint64.high-1)).match(r))

