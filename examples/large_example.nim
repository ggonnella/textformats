import strformat, tables, json
import textformats

const
  specdir = "../bio"
  biotestdir = "../tests/testdata/bio"
  header = ">ABCD some sequence"
let
  decoded_header = %{"fastaid": "ABCD", "desc": "some sequence"}.to_table

echo(&"Encoded: {header}")
assert(not is_compiled(&"{specdir}/fasta.yaml"))
echo("Spec fasta.yaml is not compiled")
compile_specification(&"{specdir}/fasta.yaml", "fasta.tfs")
let spec = specification_from_file("fasta.tfs")
assert(is_compiled("fasta.tfs"))
echo("Spec fasta.tfs is compiled")
spec.run_specification_testfile(&"{specdir}/fasta.yaml")

let
  fas_entry = spec.get_definition("default")
  fas_header = spec.get_definition("header")
echo($fas_header)
echo($spec.datatype_names())

echo($header.decode(fas_header))
assert(header.is_valid(fas_header))
echo(&"\"{header}\" is a valid encoded fas_header")
echo(decoded_header.encode(fas_header))
assert(decoded_header.is_valid(fas_header))
echo(&"\"{decoded_header}\" is a valid decoded fas_header")

proc decoded_processor(decoded: JsonNode, processor_data: pointer) =
  echo("Decoded value: " & $decoded)

echo("\nDecode file, level \"whole\"")
decode_file(&"{biotestdir}/test.fas", fas_entry, false, decoded_processor,
    nil, DplWhole)
echo("\nDecode file, level \"element\"")
decode_file(&"{biotestdir}/test.fas", fas_entry, false, decoded_processor,
    nil, DplElement)
echo("\nDecode file, level \"line\"")
decode_file(&"{biotestdir}/test.fas", fas_entry, false, decoded_processor,
    nil, DplLine)
