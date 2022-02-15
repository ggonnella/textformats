from setuptools import setup
import sys
if not sys.version_info[0] == 3:
  sys.exit("Sorry, only Python 3 is supported")

def readme():
  with open('README.md') as f:
    return f.read()

setup(name='textformats',
      packages=["textformats"],
      package_data={"": ['*.so']},
      version='1.2.0',
      description='Easily defined compact human-readable data representations',
      long_description=readme(),
      long_description_content_type='text/markdown',
      url='https://github.com/ggonnella/textformats',
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
    )
