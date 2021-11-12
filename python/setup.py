from setuptools import setup
import nimporter

def readme():
  with open('../README.md') as f:
    return f.read()

import sys
if not sys.version_info[0] == 3:
  sys.exit("Sorry, only Python 3 is supported")

setup(name='textformats',
      packages=["textformats", "textformats/py_bindings"],
      package_data={"": ['*.nim', "*.nimble", "*.nims"]},
      version='1.1.0',
      description='Easily defined compact human-readable data representations',
      long_description=readme(),
      url='https://github.com/ggonnella/gfapy',
      keywords="bioinformatics genomics sequences GFA assembly graphs",
      author='Giorgio Gonnella',
      author_email='gonnella@zbh.uni-hamburg.de',
      license='ISC',
      # see https://pypi.python.org/pypi?%3Aaction=list_classifiers
      classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: End Users/Desktop',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: ISC License (ISCL)',
        'Operating System :: MacOS :: MacOS X',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Software Development :: Libraries',
      ],
      scripts=[],
      zip_safe=False,
      test_suite="nose.collector",
      tests_require=['nose'],
      ext_modules=nimporter.build_nim_extensions()
    )
