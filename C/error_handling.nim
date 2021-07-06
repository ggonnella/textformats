##
## Module for handling Nim exceptions in C
##

import strutils

var
  tf_haderr*      {.exportc.}: bool    = false
  tf_errname*     {.exportc.}: cstring = "".cstring
  tf_errmsg*      {.exportc.}: cstring = "".cstring
  tf_quit_on_err* {.exportc.}: bool = false

template seterr*() =
 tf_haderr  = true
 tf_errname = get_current_exception().name
 tf_errmsg  = get_current_exception_msg().cstring

template assert_no_failure*(actions) =
  try:
    actions
  except:
    assert(false)

template on_failure_seterr_and_return*(errval, actions) =
  try:
    actions
  except:
    seterr()
    if tf_quit_on_err:
      tf_printerr()
      quit(1)
    return errval

template on_failure_seterr_and_return*(actions) =
  on_failure_seterr_and_return(result, actions)

template on_failure_seterr*(actions) =
  try:
    actions
  except:
    seterr()
    if tf_quit_on_err:
      tf_printerr()
      quit(1)

proc tf_unseterr*() {.exportc, raises: [].} =
  tf_haderr = false
  tf_errname = "".cstring
  tf_errmsg = "".cstring

proc tf_printerr*() {.exportc, raises: [].} =
  assert_no_failure:
    stderr.write_line("Error (" & $tf_errname & "):\n" &
                      ($tf_errmsg).indent(2) & "\n")

proc tf_checkerr*() {.exportc, raises: [].} =
  if tf_haderr:
    tf_printerr()
    quit(1)

