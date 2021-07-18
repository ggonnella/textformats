import pytest
import os

@pytest.fixture
def testdata():
  return lambda fn: os.path.join(\
      os.path.join(os.path.dirname(__file__),"../../tests/testdata/api"), fn)
