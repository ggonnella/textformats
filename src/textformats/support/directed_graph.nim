import tables, strformat, sequtils

# == Exceptions ==

type
  DirectedGraphError* = object of CatchableError
  NodeNotFoundError* =  object of DirectedGraphError
  CycleFoundError* =    object of DirectedGraphError

template raiseNodeNotFound(name: string) =
  raise newException(NodeNotFoundError, "Node '" & name & "' not found")

template raiseCycleFound(name: string) =
  raise newException(CycleFoundError, "Cycle found from node '" & name & "'")

# == GraphNode ==

type
  GraphNodeColor = enum
    gncWhite, gncGray, gncBlack

  GraphNodeObj = object
    dest: seq[GraphNode]
    name*: string
    color: GraphNodeColor
  GraphNode* = ref GraphNodeObj

iterator items*(self: GraphNode): GraphNode =
  for n in self.dest: yield n

proc `$`*(self: GraphNode): string =
  &"GraphNode(name:{self.name},color:{self.color}," &
  &"dest:{self.dest.mapit(it.name)})"

# == Graph ==

type
  GraphObj = object
    nodes: Table[string, GraphNode]
  Graph* = ref GraphObj

proc `$`*(self: Graph): string =
  &"Graph(nodes:{self.nodes})"

proc newGraph*(): Graph =
  Graph(nodes:initTable[string, GraphNode]())

iterator items*(self: Graph): GraphNode =
  for k, v in self.nodes: yield v

iterator pairs*(self: Graph): (string, GraphNode) =
  for k, v in self.nodes: yield (k, v)

proc add_node*(self: Graph, name: string) =
  self.nodes[name] = GraphNode(dest: newseq[GraphNode](),
                               name: name)

proc add_edge*(self: Graph, src: string, dest: string,
               add_nodes = false) =
  for n in [src, dest]:
    if n notin self.nodes:
      if add_nodes: self.add_node(n)
      else: raiseNodeNotFound(n)
  if self.nodes[dest] notin self.nodes[src].dest:
    self.nodes[src].dest.add(self.nodes[dest])

proc dfs_cycles(self: GraphNode): bool =
  self.color = gncGray
  for dest in self:
    if dest.color == gncGray:
      return true
    elif dest.color == gncWhite and dest.dfs_cycles:
      return true
  self.color = gncBlack
  return false

proc reset_colors(self: Graph) =
  for node in self:
    node.color = gncWhite

proc node_names*(self: Graph): seq[string] =
  result = newseq_of_cap[string](len(self.nodes))
  for k, v in self.nodes:
    result.add(k)

proc validate_dag*(self: Graph) =
  self.reset_colors
  for node in self:
    if node.color == gncWhite and node.dfs_cycles:
      raiseCycleFound(node.name)
