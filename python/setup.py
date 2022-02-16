from setuptools import setup, Extension
from setuptools.command.install import install
from distutils.command.build import build

from glob import glob
import subprocess
import re
import os
import shutil

BASEPATH = os.path.dirname(os.path.abspath(__file__))

# inspired by https://github.com/Turbo87/py-xcsoar/blob/master/setup.py
class TfBuilder(build):
  def run(self):
    build.run(self)
    build_path = os.path.abspath(self.build_temp)
    cmd = ['make', 'bindings_cp',
           'OUT=' + os.path.join(build_path, 'py_bindings')]
    target_files = [os.path.join(build_path,
                    'py_bindings', 'py_bindings.so')]
    def compile():
      subprocess.call(cmd, cwd=BASEPATH)
    self.execute(compile, [], 'Compiling py bindings')
    self.mkpath(os.path.join(self.build_lib, "textformats"))
    if not self.dry_run:
      for target in target_files:
        self.copy_file(target,
                       os.path.join(self.build_lib, "textformats"))

class TfInstaller(install):
  def initialize_options(self):
    install.initialize_options(self)
    self.build_scripts = None

  def finalize_options(self):
    install.finalize_options(self)
    self.set_undefined_options('build', ('build_scripts', 'build_scripts'))

  def run(self):
    install.run(self)
    #self.mkpath(os.path.join(self.install_lib, "textformats"))
    #self.copy_file(os.path.join(self.build_lib, 'textformats',
    #  'py_bindings.so'),
    #               os.path.join(self.install_lib, 'textformats',
    #                            'py_bindings.so'))
    self.copy_tree(self.build_lib, self.install_lib)

errmsg="""

---------------------------------------------------------------------

PROBLEM:

For installing a source extension developed in Nim, the Nim compiler
is necessary. However, it could not be located in the system.

SOLUTION:

Is the Nim compiler already installed?

[Yes] => in case the compiler is not in the PATH,
         provide the Nim compiler location as follows:

           env PATH=$PATH:/path/to/nim/ pip install textformats

[No] => install Nim, using one of the following systems
        and run 'pip install textformats' afterwards

  [pip]        pip install choosenim_install

  [conda]      conda install nim

  [choosenim]  curl https://nim-lang.org/choosenim/init.sh -sSf | sh

  [pre-compiled nim] see: https://nim-lang.org/install_unix.html

---------------------------------------------------------------------

"""

def check_nim():
  nim_bin = shutil.which("nim")
  if nim_bin:
    print(f"'nim' found in PATH: {nim_bin}")
  else:
    print(f"'nim' not found in PATH: {os.get_exec_path()}")
    raise RuntimeError(errmsg)

check_nim()

setup_args = dict(
  cmdclass = {
    'build': TfBuilder,
    'install': TfInstaller
  }
)
setup(**setup_args)
