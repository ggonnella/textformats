import nimporter
import textformats.py_bindings as tf

class Datatype:
  def __init__(self, definition, reprstr="Datatype"):
    self._definition = definition
    self._reprstr = reprstr
    self._scope = tf.get_scope(definition)
    self._unitsize = tf.get_unitsize(definition)

  def decode(self, encoded, to_json=False):
    if to_json: return tf.to_json(encoded, self._definition)
    else: return tf.decode(encoded, self._definition)

  ValidScopes = ["line", "unit", "section", "file", "auto"]

  @property
  def scope(self):
    return self._scope

  @scope.setter
  def scope(self, value):
    if value not in Datatype.ValidScopes:
      raise f"Error: scope must be one of {', '.join(Datatype.ValidScopes)}"
    if value == "auto":
      self._scope = tf.get_scope(self._definition)
      if self._scope == "undefined":
        raise "Error: setting scope to auto, i.e. to the value set " +\
              "in the 'scope' key of the datatype definition, " +\
              "but no value is set in the definition"
    else:
      self._scope = value

  @property
  def unitsize(self):
    return self._unitsize

  @unitsize.setter
  def unitsize(self, value):
    if value == "auto":
      self._unitsize = tf.get_unitsize(self._definition)
    elif not isinstance(value, int) or value < 1:
      raise "Error: the unitsize property must be set to 'auto', i.e. to "+\
            "the value set in the 'unitsize' key of the datatype definition "+\
            "or to an integer value > 1"
    else:
      self._unitsize = value

  def decoded_file_values(self, filename, embedded=False, elemwise=False,
                          wrapped=False, to_json=False):
    if self.scope == "undefined":
      raise "Error: undefined scope\n" +\
            "Hint: set the Datatype scope either using the 'scope' key " +\
            "of the datatype definition, or setting the scope property of " +\
            "this object"
    elif self.scope == "unit":
      if self.unitsize <= 1:
        raise f"Error: unitsize value invalid ({self.unitsize})\n" +\
              "set the Datatype unitsize to a value > 1 either using "+\
              "the 'unitsize' key of the datatype definition, or "+\
              "setting the unitsize property of this object"
    if to_json:
      for value in tf.file_values_to_json(filename, self._definition, embedded,
                                       self.scope, elemwise, wrapped,
                                       self.unitsize):
        yield value
    else:
      for value in tf.decoded_file_values(filename, self._definition, embedded,
                                       self.scope, elemwise, wrapped,
                                       self.unitsize):
        yield value

  def encode(self, item, from_json=False, unsafe=False):
    if unsafe:
      if from_json: return tf.unsafe_from_json(item, self._definition)
      else: return tf.unsafe_encode(item, self._definition)
    else:
      if from_json: return tf.from_json(item, self._definition)
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

  def test(self, filename):
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

