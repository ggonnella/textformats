import strformat
import textformats

const
  cigarsdir = "../benchmarks/data/cigars"
  encoded = "1M100D1I2M3M4M"
  encoded_wrong = "1M;100D1I2M3M4M"

echo(&"Encoded: {encoded}")

# open specification and get datatype definition
let
  spec = specification_from_file(&"{cigarsdir}/cigars.yaml")
  datatype = spec.get_definition("cigar_str")

# decode
let decoded = encoded.decode(datatype)
echo(&"[Decoding succeeded]\n{decoded}")

# failing decode example
try:
  discard encoded_wrong.decode(datatype)
except DecodingError:
  let err = getCurrentExceptionMsg()
  echo(&"[DecodingError as expected]\n{err}")
