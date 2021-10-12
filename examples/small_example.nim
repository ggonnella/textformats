import strformat
import textformats
import json

const
  cigarsdir = "../benchmarks/data/cigars"
  encoded = "1M100D1I2M3M4M"
  encoded_wrong = "1M;100D1I2M3M4M"
  decoded = "[{\"length\":100,\"code\":\"M\"}," &
             "{\"length\":10,\"code\":\"D\"}]"

echo(&"Encoded: {encoded}")

# open specification and get datatype definition
let
  spec = specification_from_file(&"{cigarsdir}/cigars.yaml")
  datatype = spec.get_definition("cigar_str")

# decode
let decoded1 = encoded.decode(datatype)
echo(&"[Decoding succeeded]\n{decoded1}")

# encode
let encoded2 = parse_json(decoded).encode(datatype)
echo(&"[Encoding succeeded]\n{encoded2}")

# failing decode example
try:
  discard encoded_wrong.decode(datatype)
except DecodingError:
  let err = getCurrentExceptionMsg()
  echo(&"[DecodingError as expected]\n{err}")
