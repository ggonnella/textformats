##
## File lines reader reads a file line-by-line each time
## the consume or safe_consume functions are called.
##
## The last read line is accessible in the variable line;
## the line number in lineno; if the last line has been
## read, the eof flag is set.
##
## It is used to handle files with compound datatypes
## where the elements are in multiple lines.
## The end of the compound value is then the first
## line which cannot be part of it, according to the
## definition. The same line is then part of the next
## compound value, thus it is returned later again
## (for this reason a line is stored, and a consume proc
## must be called in order to advance to the next one)
##

import strutils, strformat
from textformats_error import TextFormatsRuntimeError

type
  FileLinesReader* = object
    line*: string
    file: File
    eof*: bool
    lineno*: int

proc safe_consume*(self: var FileLinesReader) =
  try:
    self.eof = not self.file.read_line(self.line)
  except IOError:
    raise newException(TextFormatsRuntimeError,
              "IO Error while attempting to read line from file\n" &
              &"Line number: {self.lineno}\n" &
              get_current_exception_msg().indent(2))
  self.lineno += 1

proc consume*(self: var FileLinesReader) =
  self.eof = not self.file.read_line(self.line)
  self.lineno += 1

proc newFileLinesReader*(file: File): FileLinesReader =
  result.file = file
  result.lineno = 1
  result.consume

