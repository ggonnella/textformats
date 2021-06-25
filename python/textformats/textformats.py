import nimporter
import textformats.py_bindings as tf

class Datatype:
  def __init__(self, definition):
    self.definition = definition

  def decode(self, s):
    return tf.decode(s, self.definition)

  def to_json(self, s):
    return tf.to_json(s, self.definition)

  def encode(self, i):
    return tf.encode(i, self.definition)

  def unsafe_encode(self, i):
    return tf.unsafe_encode(i, self.definition)

  def from_json(self, jsonstr):
    return tf.from_json(jsonstr, self.definition)

  def is_valid_decoded(self, s):
    return tf.is_valid_decoded(s, self.definition)

  def is_valid_encoded(self, i):
    return tf.is_valid_encoded(i, self.definition)

class Specification:
  def __init__(self, filename):
    self.spec = tf.parse_specification(filename)

  def __getitem__(self, datatype):
    dd = Datatype(tf.get_definition(self.spec, datatype))
    dd.name = datatype
    return dd
