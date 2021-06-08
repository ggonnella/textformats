import tables

proc keys_string*[A, B](t: Table[A,B] or TableRef[A,B]): string =
  var i = 0
  result = "["
  for k in t.keys:
    if i > 0:
      result &= ", "
    result &= k
    i += 1
  result &= "]"

