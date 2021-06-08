import ../shared/num_decoder
export decode_int

template decode_anyuint*(input, dd: untyped): untyped =
  let val = decode_int(input)
  if val < 0:
    raise newException(DecodingError,
            "Error: negative integer value for unsigned integer.\n" &
            "Expected: non-negative integer.\n" &
            "Found: " & $val & "\n")
  %*(val)
