from setuptools import setup, Extension
from glob import glob
import subprocess
import re
import os
import shutil


errmsg="""

---------------------------------------------------------------------

PROBLEM:

For installing a source extension developed in Nim, the Nim library
is necessary. However, it could not be located in the system.

SOLUTION:

Is the Nim compiler already installed?

[Yes] => provide the Nim compiler location as follows:

           env NIM=/path/to/nim pip install textformats

[No] => install Nim, using one of the following systems
        and run 'pip install textformats' afterwards

  [pip]        pip install choosenim_install

  [conda]      conda install nim

  [choosenim]  curl https://nim-lang.org/choosenim/init.sh -sSf | sh

  [pre-compiled nim] see: https://nim-lang.org/install_unix.html

---------------------------------------------------------------------

"""

def find_nimlib():
  nim_bin = os.environ.get("NIM", None)
  if nim_bin:
    print(f"NIM env variable found, value: {nim_bin}")
  else:
    print(f"NIM env variable not found")
    nim_bin = shutil.which("nim")
    if nim_bin:
      print(f"'nim' found in PATH: {nim_bin}")
    else:
      print(f"'nim' not found in PATH: {os.get_exec_path()}")
      raise RuntimeError(errmsg)
  if shutil.which("choosenim"):
    proc = subprocess.Popen(["nim", "--version"], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    nim_ver = re.findall(r"Version (\S+)", stdout.decode("utf-8"))[0]
    nim_dir=os.path.join(os.environ["HOME"], ".choosenim", "toolchains",
                         f"nim-{nim_ver}")
  else:
    nim_dir = os.path.dirname(os.path.dirname(
                os.path.abspath(os.path.realpath(nim_bin))))
  nim_lib = os.path.join(nim_dir, "lib")
  if not os.path.exists(os.path.join(nim_lib,"nimbase.h")):
    raise RuntimeError(f"Could not find nim library header in {nim_lib}\n\n"+
                       errmsg)
  return nim_lib

setup_args = dict(
  ext_modules = [
    Extension(
      'textformats.py_bindings',
      glob("py_bindings/extension/*.c"),
      include_dirs = [find_nimlib()],
      py_limited_api = True,
      extra_compile_args=["-w"]
    )
  ]
)
setup(**setup_args)
