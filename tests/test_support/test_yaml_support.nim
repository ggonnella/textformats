import unittest
import options
import json
import yaml
import yaml/dom
import textformats/support/yaml_support

suite "yaml_support":
  var
    n = load_dom("null").root
    b = load_dom("true").root
    b2 = load_dom("false").root
    s = load_dom("a").root
    i = load_dom("1").root
    i2 = load_dom("-1").root
    f = load_dom("1.0").root
    f2 = load_dom("-.Inf").root
    f3 = load_dom(".NaN").root
    m = load_dom("b: c").root
    m2 = load_dom("k1: v1\nk2: v2\nk3: v3").root
    q = load_dom("- 1\n- 2").root
  test "is_scalar":
    check n.is_scalar
    check b.is_scalar
    check s.is_scalar
    check i.is_scalar
    check f.is_scalar
    check not m.is_scalar
    check not q.is_scalar
  test "is_mapping":
    check not n.is_mapping
    check not b.is_mapping
    check not s.is_mapping
    check not i.is_mapping
    check not f.is_mapping
    check m.is_mapping
    check not q.is_mapping
  test "is_sequence":
    check not n.is_sequence
    check not b.is_sequence
    check not s.is_sequence
    check not i.is_sequence
    check not f.is_sequence
    check not m.is_sequence
    check q.is_sequence
  test "is_null":
    check n.is_null
    check not b.is_null
    check not s.is_null
    check not i.is_null
    check not f.is_null
    check not m.is_null
    check not q.is_null
  test "is_bool":
    check not n.is_bool
    check b.is_bool
    check b2.is_bool
    check not s.is_bool
    check not i.is_bool
    check not f.is_bool
    check not m.is_bool
    check not q.is_bool
  test "is_int":
    check not n.is_int
    check not b.is_int
    check not s.is_int
    check i.is_int
    check not f.is_int
    check not m.is_int
    check not q.is_int
  test "is_float":
    check not n.is_float
    check not b.is_float
    check not s.is_float
    check not i.is_float
    check f.is_float
    check f2.is_float
    check f3.is_float
    check not m.is_float
    check not q.is_float
  test "is_string":
    check not n.is_string
    check not b.is_string
    check s.is_string
    check not i.is_string
    check not f.is_string
    check not m.is_string
    check not q.is_string
  test "to_int":
    check i.to_int == 1
    check i2.to_int == -1
    expect(NodeValueError): discard f.to_int
    expect(NodeValueError): discard q.to_int
  test "to_uint":
    check i.to_uint == 1'u
    expect(NodeValueError): discard i2.to_uint
  test "to_natural":
    check i.to_natural == 1.Natural
    expect(NodeValueError): discard i2.to_natural
  test "to_float":
    check f.to_float == 1.0
    expect(NodeValueError): discard s.to_float
  test "to_bool":
    check b.to_bool == true
    expect(NodeValueError): discard s.to_bool
  test "to_string":
    check s.to_string == "a"
  test "to_opt_int":
    check i.some.to_opt_int == 1.some
    check (YamlNode.none).to_opt_int == int.none
    check i2.some.to_opt_int == (-1).some
    expect(NodeValueError): discard f.some.to_opt_int
    expect(NodeValueError): discard q.some.to_opt_int
  test "to_opt_uint":
    check i.some.to_opt_uint == 1'u.some
    check YamlNode.none.to_opt_uint == uint.none
    expect(NodeValueError): discard i2.some.to_opt_uint
  test "to_opt_natural":
    check i.some.to_opt_natural == 1.Natural.some
    check YamlNode.none.to_opt_natural == Natural.none
    expect(NodeValueError): discard i2.some.to_opt_natural
  test "to_opt_float":
    check f.some.to_opt_float == (1.0).some
    check YamlNode.none.to_opt_float == float.none
    expect(NodeValueError): discard s.some.to_opt_float
  test "to_opt_bool":
    check b.some.to_opt_bool == true.some
    check YamlNode.none.to_opt_bool == bool.none
    expect(NodeValueError): discard s.some.to_opt_bool
  test "to_opt_string":
    check s.some.to_opt_string == "a".some
    check YamlNode.none.to_opt_string == string.none
  test "to_int_default":
    check i.some.to_int(0) == 1
    check YamlNode.none.to_int(0) == 0
    expect(NodeValueError): discard f.some.to_int(0)
    expect(NodeValueError): discard q.some.to_int(0)
  test "to_uint_default":
    check i.some.to_uint(0) == 1'u
    check YamlNode.none.to_uint(0'u) == 0'u
    expect(NodeValueError): discard i2.some.to_uint(0'u)
  test "to_natural_default":
    check i.some.to_natural(0.Natural) == 1.Natural
    check YamlNode.none.to_natural(0.Natural) == 0.Natural
    expect(NodeValueError): discard i2.some.to_natural(0.Natural)
  test "to_float_default":
    check f.some.to_float(0.0) == 1.0
    check YamlNode.none.to_float(0.0) == 0.0
    expect(NodeValueError): discard s.some.to_float(0.0)
  test "to_bool_default":
    check b.some.to_bool(false) == true
    check YamlNode.none.to_bool(false) == false
    expect(NodeValueError): discard s.some.to_bool(false)
  test "to_string_default":
    check s.some.to_string("") == "a"
    check YamlNode.none.to_string("") == ""
  test "to_int_default_name":
    check i.some.to_int(0, "x") == 1
    check YamlNode.none.to_int(0, "x") == 0
    expect(NodeValueError): discard f.some.to_int(0, "x")
    expect(NodeValueError): discard q.some.to_int(0, "x")
  test "to_uint_default_name":
    check i.some.to_uint(0, "x") == 1'u
    check YamlNode.none.to_uint(0'u, "x") == 0'u
    expect(NodeValueError): discard i2.some.to_uint(0'u, "x")
  test "to_natural_default_name":
    check i.some.to_natural(0.Natural, "x") == 1.Natural
    check YamlNode.none.to_natural(0.Natural, "x") == 0.Natural
    expect(NodeValueError): discard i2.some.to_natural(0.Natural, "x")
  test "to_float_default_name":
    check f.some.to_float(0.0, "x") == 1.0
    check YamlNode.none.to_float(0.0, "x") == 0.0
    expect(NodeValueError): discard s.some.to_float(0.0, "x")
  test "to_bool_default_name":
    check b.some.to_bool(false, "x") == true
    check YamlNode.none.to_bool(false, "x") == false
    expect(NodeValueError): discard s.some.to_bool(false, "x")
  test "to_string_default_name":
    check s.some.to_string("", "x") == "a"
    check YamlNode.none.to_string("", "x") == ""
  test "validate_is_scalar":
    try: n.validate_is_scalar except: check false
    expect(NodeValueError): validate_is_scalar(m)
  test "validate_is_not_scalar":
    try: m.validate_is_not_scalar except: check false
    expect(NodeValueError): validate_is_not_scalar(n)
  test "validate_is_mapping":
    try: m.validate_is_mapping except: check false
    expect(NodeValueError): validate_is_mapping(n)
  test "validate_is_not_mapping":
    try: n.validate_is_not_mapping except: check false
    expect(NodeValueError): validate_is_not_mapping(m)
  test "validate_is_sequence":
    try: q.validate_is_sequence except: check false
    expect(NodeValueError): validate_is_sequence(n)
  test "validate_is_not_sequence":
    try: n.validate_is_not_sequence except: check false
    expect(NodeValueError): validate_is_not_sequence(q)
  test "validate_is_null":
    try: n.validate_is_null except: check false
    expect(NodeValueError): q.validate_is_null
  test "validate_is_bool":
    try: b.validate_is_bool except: check false
    expect(NodeValueError): n.validate_is_bool
  test "validate_is_int":
    try: i.validate_is_int except: check false
    expect(NodeValueError): n.validate_is_int
  test "validate_is_float":
    try: f.validate_is_float except: check false
    expect(NodeValueError): n.validate_is_float
  test "validate_is_string":
    try: s.validate_is_string except: check false
    expect(NodeValueError): n.validate_is_string
  test "to_json_node":
    check i.to_json_node == %*1
    check n.to_json_node == newJNull()
    check b.to_json_node == %*true
    check s.to_json_node == %*"a"
    check f.to_json_node == %*1.0
    check m.to_json_node == %*{"b": "c"}
    check q.to_json_node == %*[1, 2]
  test "to_opt_json_node":
    check i.some.to_opt_json_node == some(%*1)
    check n.some.to_opt_json_node == newJNull().some
    check b.some.to_opt_json_node == some(%*true)
    check s.some.to_opt_json_node == some(%*"a")
    check f.some.to_opt_json_node == some(%*1.0)
    check m.some.to_opt_json_node == some(%*{"b": "c"})
    check q.some.to_opt_json_node == some(%*[1, 2])
    check YamlNode.none.to_opt_json_node == JsonNode.none
  test "validate_has_key":
    try: m.validate_has_key("b") except: check false
    expect(NodeValueError): m.validate_has_key("c")
  test "validate_len":
    try: m.validate_len(1) except: check false
    expect(NodeValueError): m.validate_len(2)
    try: q.validate_len(2) except: check false
    expect(NodeValueError): q.validate_len(1)
  test "validate_minlen":
    try: m.validate_minlen(1) except: check false
    expect(NodeValueError): m.validate_minlen(2)
    try: q.validate_minlen(1) except: check false
    expect(NodeValueError): q.validate_minlen(3)
  test "get_keys":
    let keys = m2.get_keys(["k2", "k1", "k4", "k3"], 1)
    check keys[0].is_some
    check keys[0].unsafe_get.to_string == "v2"
    check keys[1].is_some
    check keys[1].unsafe_get.to_string == "v1"
    check keys[2].is_none
    check keys[3].is_some
    check keys[3].unsafe_get.to_string == "v3"
    expect(NodeValueError): discard n.get_keys(["x"], 1)
    expect(KeyMissingError):
      discard m2.get_keys(["k2", "k1", "k4", "k3"], n_required = 3)
    expect(KeyUnknownError): discard m2.get_keys(["k2", "k1"], 1)
