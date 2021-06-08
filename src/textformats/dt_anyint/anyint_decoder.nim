import ../shared/num_decoder
export decode_int

template decode_anyint*(input, dd: untyped): untyped =
  let val = decode_int(input)
  %*(val)
