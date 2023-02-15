##
## Validation after ref solving
##

import types/datatype_definition

import dt_struct/struct_def_parser

proc postvalidate*(dd: DatatypeDefinition) =
  case dd.kind:
    of ddkStruct:       dd.postvalidate_struct()
    else:               discard
