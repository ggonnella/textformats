import ../shared/num_decoder
export decode_float

template decode_anyfloat*(input, dd: untyped): untyped =
  let val = decode_float(input)
  %*(val)
