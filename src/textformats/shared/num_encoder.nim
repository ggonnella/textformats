import math, strutils

proc encode_int_with_base*(v: int64, base: int): string =
  assert(v >= 0)
  case base:
  of 10:
    return $v
  of 16:
    let l = if v == 0: 1 else: floor(log(v.float, 16)).int + 1
    return to_hex(v, l)
  of 2:
    let l = if v == 0: 1 else: floor(log(v.float, 2)).int + 1
    return to_bin(v, l)
  of 8:
    let l = if v == 0: 1 else: floor(log(v.float, 8)).int + 1
    return to_oct(v, l)
  else:
    assert(false)
