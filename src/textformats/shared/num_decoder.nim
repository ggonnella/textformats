import strutils
export parse_float, parse_int
import ../types/textformats_error
export DecodingError

template decode_float*(input: string): float =
  var
    value: float
    haderr = false
  try: value = parse_float(input)
  except ValueError:
    haderr = true
  if haderr:
    let msg = &"Expected floating point number, found '{input}'\n"
    raise newException(DecodingError, msg)
  value

template decode_int*(input: string, base = 10): int =
  var
    value: int
    haderr = false
  try:
    case base:
    of 10: value = parse_int(input)
    of 16: value = from_hex[int](input)
    of 2: value = from_bin[int](input)
    of 8: value = from_oct[int](input)
    else: assert(false)
  except ValueError:
    haderr = true
  if haderr:
    let msg = "Expected integer in base " & $base & ", found '" & input & "'\n"
    raise newException(DecodingError, msg)
  value
