#include strformat, strutils
#from textformats_error import TextformatsRuntimeError

type
  LinesReader* = object
    line*: string
    file: File
    eof*: bool
    lineno*: int

proc consume*(self: var LinesReader) =
#  try:
  self.eof = not self.file.read_line(self.line)
#  except IOError:
#    raise newException(TextformatsRuntimeError,
#              "IO Error while attempting to read line from file\n" &
#              &"Line number: {self.lineno}\n" &
#              get_current_exception_msg().indent(2))
  self.lineno += 1

proc newLinesReader*(file: File): LinesReader =
  result.file = file
  result.lineno = 1
  result.consume

