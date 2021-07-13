import strutils
export parse_float, parse_int
import ../types/textformats_error
export DecodingError

template decode_float*(input: string): float =
  var value: float
  try: value = parse_float(input)
  except ValueError:
    raise newException(DecodingError,
            "Error: encoded string is not a valid " &
            "representation of a floating point number\n")
  value

template decode_int*(input: string, base = 10): int =
  var value: int
  try:
    case base:
    of 10: value = parse_int(input)
    of 16: value = from_hex[int](input)
    of 2: value = from_bin[int](input)
    of 8: value = from_oct[int](input)
    else: assert(false)
  except ValueError:
    raise newException(DecodingError,
             "Error: encoded string is not a valid " &
             "representation of an integer number in base " &
             $base & "\n")
  value
