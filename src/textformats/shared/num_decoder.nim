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

template decode_int*(input: string): int =
  var value: int
  try: value = parse_int(input)
  except ValueError:
    raise newException(DecodingError,
             "Error: encoded string is not a valid " &
             "representation of an integer number\n")
  value
