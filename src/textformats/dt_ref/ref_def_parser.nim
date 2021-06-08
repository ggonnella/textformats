import yaml/dom
import ../types/datatype_definition

template newRefDatatypeDefinition*(defroot: YamlNode, name: string):
                                   DatatypeDefinition =
  assert(node.kind == yScalar)
  let tname = defroot.content # using content anything is interpreted as string
                              # i.e. also bool, int, float, null, etc
  DatatypeDefinition(kind: ddkRef, name: name, target_name: tname)

