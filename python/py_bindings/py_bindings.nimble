# Package

version       = "1.2.2"
author        = "Giorgio Gonnella"
description   = "Python bindings for the TextFormats library"
license       = "ISC"
backend       = "c"
srcDir        = "src"
bin           = @["py_bindings.so"]

# Dependencies

requires "nim >= 1.6.0"
requires "nimpy == 0.2.0", "textformats == 1.2.2"
