import json
import ../types/testdata
import ../shared/num_encoder
import ../testdata_generator

let
  InvalidEncodedNumeric* = ["$", "[]", "{}"]
  InvalidDecodedNumeric* = [newJString("$"), newJArray(), newJObject()]

template check_range_and_add*[T: uint64 or int64 or float](
                     t: var TestData, values: seq[T], min_i: T, max_i: T,
                     min_incl = true, max_incl = true, base = 10) =
  for i in values:
    when T is uint64:
      let
        k = encode_int_with_base(i.int64, base)
        v = %*(i.int)
    else:
      let
        k = $i
        v = %*i
    if ((i > min_i or (i == min_i and min_incl)) and
        (i < max_i or (i == max_i and max_incl))):
      if k notin t.v:
        t.v[k] = v
    else:
      if k notin t.e:
        t.e.add(k)
        t.d.add(v)

proc add_invalid_numeric*(t: var TestData) =
  for e in InvalidEncodedNumeric:
    t.e.add_if_unique(e)
  for d in InvalidDecodedNumeric:
    t.d.add_if_unique(d)

proc add_invalid_int*(t: var TestData) =
  add_invalid_numeric(t)
  t.e.add_if_unique("1.0")
  t.d.add_if_unique(newJFloat(1.0))

proc add_invalid_uint*(t: var TestData) =
  add_invalid_int(t)
  t.e.add_if_unique("-1")
  t.d.add_if_unique(newJInt(-1))

proc add_invalid_float*(t: var TestData) =
  add_invalid_numeric(t)

