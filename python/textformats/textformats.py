import nimporter
import json
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
  def __init__(self, dict_or_fn):
    if isinstance(dict_or_fn, str):
      self._source = dict_or_fn
      self._source_is_file = True
      self._spec = tf.specification_from_file(self._source)
      self._preprocessed = tf.is_preprocessed(self._source)
    else:
      self._source = json.dumps(dict_or_fn)
      self._source_is_file = False
      self._spec = tf.parse_specification(json.dumps(dict_or_fn))
      self._preprocessed = False

  @property
  def default(self):
    return self["default"]

  def __getitem__(self, datatype):
    dd = Datatype(tf.get_definition(self._spec, datatype),
                  f"{repr(self)}[\"{datatype}\"]")
    dd.name = datatype
    return dd

  def test(self, testdata_or_filename = None):
    if testdata_or_filename is None:
      if self._source_is_file:
        tf.run_specification_testfile(self._spec, self._source)
      else:
        tf.run_specification_tests(self._spec, self._source)
    elif isinstance(testdata_or_filename, str):
      tf.run_specification_testfile(self._spec, testdata_or_filename)
    else:
      tf.run_specification_tests(self._spec, json.dumps(testdata_or_filename))

  @property
  def datatype_names(self):
    return tf.datatype_names(self._spec)

  @property
  def preprocessed(self):
    return self._preprocessed

  @property
  def filename(self):
    return self._source

  MAX_VERBOSE_REPR = 100

  def __repr__(self):
    src = self._source
    if self._source_is_file:
      src = f"\"{src}\""
    elif len(src) > self.MAX_VERBOSE_REPR:
      src = f"... ({len(self._source)})"
    return f"Specification({src})"

  def __str__(self):
    if self._source_is_file:
      if self._preprocessed:
        src = f"- filename (preprocessed): {self._source}\n"
      else:
        src = f"- filename (YAML): {self._source}\n"
    else:
      if len(self._source) > self.MAX_VERBOSE_REPR:
        src = f"- content: ... ({len(self._source)} chars long)\n"
      else:
        src = f"- content: {self._source}\n"
    preprocstr = "preprocessed" if self._preprocessed else "YAML"
    return "Textformats Specification table\n" + src +\
      f"- defined/included datatypes:\n" +\
      "\n".join([f"  - {n}"for n in datatype_names])

