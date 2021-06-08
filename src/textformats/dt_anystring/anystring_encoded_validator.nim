template anystring_is_valid*(input: string, dd: untyped): bool =
  input.len > 0
