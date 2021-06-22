proc nth*(n: Natural): string =
  let n_mod10 = n mod 10
  if n_mod10 <= 3:
    let n_mod100 = n mod 100
    if n_mod10 == 1 and n_mod100 != 11: return $n & "st"
    elif n_mod10 == 2 and n_mod100 != 12: return $n & "nd"
    elif n_mod100 != 13: return $n & "rd"
  return $n & "th"

