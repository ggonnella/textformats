import nimporter
import textformats.py_bindings as tf

class Datatype:
  def __init__(self, definition, reprstr="Datatype"):
    self._definition = definition
    self._reprstr = reprstr

  def decode(self, encoded, to_json=False):
    if to_json: return tf.decode_to_json(encoded, self._definition)
    else: return tf.decode(encoded, self._definition)

  @property
  def scope(self):
    return tf.get_scope(self._definition)

  @scope.setter
  def scope(self, value):
    tf.set_scope(self._definition, value)

  @property
  def unitsize(self):
    return tf.get_scope(self._definition)

  @unitsize.setter
  def unitsize(self, value):
    tf.set_unitsize(self._definition, value)

  def decoded_file(self, filename, embedded=False, splitted=False,
                   wrapped=False, to_json=False):
    if to_json:
      for value in tf.decoded_file_as_json(filename, self._definition, embedded,
                                           splitted, wrapped):
        yield value
    else:
      for value in tf.decoded_file(filename, self._definition, embedded,
                                   splitted, wrapped):
        yield value

  def encode(self, item, from_json=False):
    if from_json: return tf.encode_json(item, self._definition)
    else: return tf.encode(item, self._definition)

  def is_valid_decoded(self, s, json=False):
    if json: return tf.is_valid_decoded(s, self._definition)
    else: return tf.is_valid_decoded(s, self._definition)

  def is_valid_encoded(self, i):
    return tf.is_valid_encoded(i, self._definition)

  def __repr__(self):
    return self._reprstr

  def __str__(self):
    return tf.describe(self._definition)

class Specification:
  def __init__(self, filename):
    self._spec = tf.specification_from_file(filename)
    self._preprocessed = tf.is_preprocessed(filename)
    self._filename = filename

  @property
  def default(self):
    return self["default"]

  def __getitem__(self, datatype):
    dd = Datatype(tf.get_definition(self._spec, datatype),
                  f"{repr(self)}[\"{datatype}\"]")
    dd.name = datatype
    return dd

  def test(self, filename = self._filename):
    tf.test_specification(self._spec, testfile)

  @property
  def datatype_names(self):
    return tf.datatype_names(self._spec)

  @property
  def preprocessed(self):
    return self._preprocessed

  @property
  def filename(self):
    return self._filename

  def __repr__(self):
    return f"Specification(\"{self._filename}\")"

  def __str__(self):
    preprocstr = "preprocessed" if self._preprocessed else "YAML"
    return "Textformats Specification table\n" +\
      f"- source file ({preprocstr}): {self._filename}\n" +\
      f"- defined/included datatypes:\n" +\
      "\n".join([f"  - {n}"for n in datatype_names])

