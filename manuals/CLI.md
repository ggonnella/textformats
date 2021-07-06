## Command line

The subdirectory ``cli`` contains the command line tools: ``tf_decode``,
``tf_encode``, ``tf_validate``, ``tf_spec`` and ``tf_test``.
They are build using the command ``nimble build``.
The man pages for each of the command are generated using ``nimble climan``.

The list of subcommands of each tool is output by ``<toolname> --help``.
The mandatory and optional arguments of each subcommand are output by
``<toolname> <SUBCOMMAND> --help``.

The tools can be used to encode, decode and validate strings or data files
from the command line, as well as tests and a number of additional
operations on specification files, as illustrated below.

### Decode

#### Decode strings

To decode an encoded string according to a datatype, and output it as the
JSON representation of the decoded data, the ``tf_decode`` tool is used.

The ``string`` subcommand requires the input string, provided using the option
``--encoded`` or ``-e``. The path to the specification file is provided through
the option ``--specfile`` or ``-s``. The datatype to be used for
decoding is selected using the ``--datatype`` or ``-t``.

#### Decode files

TODO: describe ``decoded_lines``, ``decode_units``,
``linetypes``.

### Encode data

To encode data (represented as a JSON string) to an encoded representation
according to a given datatype definition, the ``tf_encode`` tool is used.

The ``json`` subcommand requires the input string (JSON representation of
the data to encode), provided using the option ``--decoded_json`` or ``-d``.
The path to the specification file is provided through the option ``--specfile``
or ``-s``. The datatype to be used for
encoding is selected using the ``--datatype`` or ``-t``.

### Validate data

TODO: describe ``validate`` subcommand and its subsubcommands.

### Analysing a specification file

The command ``tf_spec`` provides functionality for handling specification files.
