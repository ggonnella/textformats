import textformats.py_bindings as tf

# Error handling:
# NimPy raises exceptions of classes which cannot be catched (as their type is
# defined when the exception is raised). Thus the TextFormats exception
# hierarchy is copied here and the errors are re-raised in the here-defined
# classes, which can be catched.
class TextFormatsError(Exception): pass
class InvalidSpecError(TextFormatsError): pass
class SpecIncludeError(InvalidSpecError): pass
class IndentifierError(InvalidSpecError): pass
class DefSyntaxError(InvalidSpecError): pass
class CircularDefError(InvalidSpecError): pass
class BrokenRefError(InvalidSpecError): pass
class DecodingError(TextFormatsError): pass
class EncodingError(TextFormatsError): pass
class TextFormatsRuntimeError(TextFormatsError): pass
class InvalidTestdataError(TextFormatsError): pass
class TestError(TextFormatsError): pass
class UnexpectedValidError(TestError): pass
class UnexpectedEncodedValidError(UnexpectedValidError): pass
class UnexpectedDecodedValidError(UnexpectedValidError): pass
class UnexpectedInvalidError(TestError): pass
class UnexpectedEncodedInvalidError(UnexpectedInvalidError): pass
class UnexpectedDecodedInvalidError(UnexpectedInvalidError): pass
class UnexpectedResultError(TestError): pass
class UnexpectedDecodingResultError(UnexpectedResultError): pass
class UnexpectedEncodingResultError(UnexpectedResultError): pass

def handle_nimpy_exception(e):
  name = e.__class__.__name__
  msg = str(e)
  pfx = "Unexpected error encountered: "
  if msg[:len(pfx)] == pfx:
    msg = msg[len(pfx):]
  raise globals()[name](msg) from None

def handle_textformats_errors(function):
  def handle_textformats_error_wrapper(*args, **kwargs):
    try: return function(*args, **kwargs)
    except tf.NimPyException as e:
      name = e.__class__.__name__
      msg = str(e)
      pfx = "Unexpected error encountered: "
      if msg[:len(pfx)] == pfx:
        msg = msg[len(pfx):]
      raise globals()[name](msg) from None
  return handle_textformats_error_wrapper
