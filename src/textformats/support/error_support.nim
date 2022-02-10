template reraise_prepend*(pfx: string) =
  ## Re-raise current exception prepending `pfx` to the message.
  ##
  ## (can only be used in an except blocks)
  var e = getCurrentException()
  e.msg = pfx & e.msg
  raise

template reraise_prepend_append*(pfx: string, sfx: string) =
  ## Re-raise current exception prepending `pfx` and
  ## appending `sfx` to the message.
  ##
  ## (can only be used in an except blocks)
  var e = getCurrentException()
  e.msg = pfx & e.msg & sfx
  raise

template reraise_append*(sfx: string) =
  ## Re-raise current exception appending `sfx` to the message.
  ##
  ## (can only be used in an except blocks)
  var e = getCurrentException()
  e.msg = e.msg & sfx
  raise
