## Exception root type for all errors thrown by the library

# Note: modules under support are considered "external"
#       thus throw their own errors, which are
#       catched by the library and re-raised as TextformatsError

type

  TextformatsError* = object of CatchableError ##\
    ## Exception root for all errors thrown by the library

  InvalidSpecError*   = object of TextformatsError ##\
    ## Error while parsing the specification
  SpecIncludeError*   = object of InvalidSpecError ##\
    ## Error regarding the content of the specification 'include' key
  DatatypeNameError*  = object of InvalidSpecError ##\
    ## Error regarding a datatype name in the specification
  DefSyntaxError*     = object of InvalidSpecError ##\
    ## Raised by syntax errors in a datatype definition
  CircularDefError*   = object of InvalidSpecError ##\
    ## Raised when a circular reference is detected
  BrokenRefError*     = object of InvalidSpecError ##\
    ## Raised when a reference cannot be resolved

  DecodingError* = object of TextformatsError ##\
    ## Raised if the encoded string is invalid for the datatype
  EncodingError* = object of TextformatsError ##\
    ## Raised if the value to encode is invalid for the datatype

  TextformatsRuntimeError* = object of TextformatsError ##\
    ## Error during specification parsing, encoding, decoding or validation
    ## which does not depend on the validity of the specification or the
    ## encoded or decoded data (e.g. a file cannot be accessed)

