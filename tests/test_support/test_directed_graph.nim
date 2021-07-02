{.used.}
import unittest
import sets
import textformats/support/directed_graph

suite "directed_graph":
  var g = newGraph()
  let names = @["a", "b", "c", "d", "e", "f"].to_hash_set
  test "new_graph":
    var emptyset: HashSet[string]
    check g.node_names.to_hash_set == emptyset
  test "add_node":
    g.add_node("a")
    check g.node_names.to_hash_set == @["a"].to_hash_set
  test "add_edge":
    g.add_edge("a", "b", true)
    check g.node_names.to_hash_set == @["a", "b"].to_hash_set
  test "validate_no_cycles":
    try: g.validate_dag() except: check false
    g.add_edge("a", "c", true)
    g.add_edge("a", "d", true)
    g.add_edge("b", "e", true)
    g.add_edge("b", "f", true)
    g.add_edge("c", "f", true)
    check g.node_names.to_hash_set == names
    try: g.validate_dag() except: check false
  test "items_iterator":
    var items_result: HashSet[string]
    for item in g: items_result.incl(item.name)
    check items_result == names
  test "pairs_iterator":
    var
      pairs_result_k: HashSet[string]
      pairs_result_v: HashSet[string]
    for k, v in g:
      pairs_result_k.incl(k)
      pairs_result_v.incl(v.name)
    check pairs_result_k == names
    check pairs_result_v == names
  test "validate_cycles1":
    g.add_edge("f", "a")
    expect(CycleFoundError): g.validate_dag()
