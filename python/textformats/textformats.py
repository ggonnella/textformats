#import nimporter
import json
from enum import IntEnum
import textformats.py_bindings as tf
from textformats.error import handle_textformats_errors, \
                              handle_nimpy_exception

class Datatype:
  def __init__(self, definition, name):
    self._definition = definition
    self._name = name

  @handle_textformats_errors
  def decode(self, encoded, to_json=False):
    if to_json: return tf.decode_to_json(encoded, self._definition)
    else: return tf.decode(encoded, self._definition)

  @property
  @handle_textformats_errors
  def scope(self):
    return tf.get_scope(self._definition)

  @scope.setter
  @handle_textformats_errors
  def scope(self, value):
    tf.set_scope(self._definition, value)

  @property
  @handle_textformats_errors
  def unitsize(self):
    return tf.get_unitsize(self._definition)

  @unitsize.setter
  @handle_textformats_errors
  def unitsize(self, value):
    tf.set_unitsize(self._definition, value)

  @property
  @handle_textformats_errors
  def wrapped(self):
    return tf.get_wrapped(self._definition)

  @wrapped.setter
  @handle_textformats_errors
  def wrapped(self, value):
    if value:
      tf.set_wrapped(self._definition)
    else:
      tf.unset_wrapped(self._definition)

  def decode_file(self, filename,
                  decoded_processor = lambda n, d : print(n),
                  decoded_processor_data = None,
                  decoded_processor_level = 0,
                  skip_embedded_spec=False,
                  to_json=False):
    try:
      if to_json:
        tf.decode_file_to_json(filename, self._definition,
                               skip_embedded_spec, decoded_processor,
                               decoded_processor_data, decoded_processor_level)
      else:
        tf.decode_file(filename, self._definition, skip_embedded_spec,
                       decoded_processor, decoded_processor_data,
                       decoded_processor_level)
    except tf.NimPyException as e:
      handle_nimpy_exception(e)

  def decoded_file(self, filename,
                   as_elements=False,
                   skip_embedded_spec=False,
                   to_json=False):
    if to_json:
      try:
        for value in tf.decoded_file_to_json(filename, self._definition,
                                             skip_embedded_spec, as_elements):
          yield value
      except tf.NimPyException as e:
        handle_nimpy_exception(e)
    else:
      try:
        for value in tf.decoded_file(filename, self._definition,
                                     skip_embedded_spec, as_elements):
          yield value
      except tf.NimPyException as e:
        handle_nimpy_exception(e)

  @handle_textformats_errors
  def encode(self, item, from_json=False):
    if from_json: return tf.encode_json(item, self._definition)
    else: return tf.encode(item, self._definition)

  @handle_textformats_errors
  def is_valid_decoded(self, s, json=False):
    if json: return tf.is_valid_decoded_json(s, self._definition)
    else: return tf.is_valid_decoded(s, self._definition)

  @handle_textformats_errors
  def is_valid_encoded(self, i):
    return tf.is_valid_encoded(i, self._definition)

  def __repr__(self):
    return "Specification({\"datatypes\": " +\
           "yaml.safe_load(" + repr(tf.repr(self._definition)) +\
           ")})[" + repr(self._name) + "]"

  @handle_textformats_errors
  def __str__(self):
    return tf.describe(self._definition)

class Specification:
  @handle_textformats_errors
  def __init__(self, dict_or_fn):
    if isinstance(dict_or_fn, str):
      self._source = dict_or_fn
      self._source_is_file = True
      self._spec = tf.specification_from_file(self._source)
      self._compiled = tf.is_compiled(self._source)
    else:
      self._source = json.dumps(dict_or_fn)
      self._source_is_file = False
      self._spec = tf.parse_specification(json.dumps(dict_or_fn))
      self._compiled = False

  @classmethod
  @handle_textformats_errors
  def compile(cls, inputfile, outputfile):
    tf.compile_specification(inputfile, outputfile)

  @property
  def default(self):
    return self["default"]

  @handle_textformats_errors
  def __getitem__(self, datatype):
    dd = Datatype(tf.get_definition(self._spec, datatype),
                  datatype)
    dd.name = datatype
    return dd

  @handle_textformats_errors
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
  @handle_textformats_errors
  def datatype_names(self):
    return tf.datatype_names(self._spec)

  @property
  def is_compiled(self):
    return self._compiled

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
      if self._compiled:
        src = f"- filename (compiled): {self._source}\n"
      else:
        src = f"- filename (YAML/JSON): {self._source}\n"
    else:
      if len(self._source) > self.MAX_VERBOSE_REPR:
        src = f"- content: ... ({len(self._source)} chars long)\n"
      else:
        src = f"- content: {self._source}\n"
    return "TextFormats Specification table\n" + src +\
      f"- defined/included datatypes:\n" +\
      "\n".join([f"  - {n}"for n in self.datatype_names])

class DECODED_PROCESSOR_LEVEL(IntEnum):
  WHOLE = 0
  ELEMENT = 1
  LINE = 2

def __minitest__():
  spec = Specification({"datatypes": {"foo": {"constant": "bar"}}})
  if spec["foo"].decode("bar") == "bar":
    print("minitest successfull")
