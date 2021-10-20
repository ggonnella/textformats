#include "textformats_c.h"
#include <stdio.h>
#include <assert.h>

void decoded_processor(JsonNode* node, void* data)
{
  printf("Decoded value: %s\n", jsonnode_to_string(node));
}

int main(void)
{
  NimMain();
  Specification *fas_spec;
  DatatypeDefinition *fas_entry, *fas_header;
  JsonNode *node;

  char *header = ">ABCD some sequence";
  char *decoded_header_json =
    "{\"fastaid\":\"ABCD\",\"desc\":\"some sequence\"}";
  printf("Encoded: %s\n", header);
  fas_spec = tf_specification_from_file("../../spec/fasta.yaml");
  if (!tf_is_compiled("../../spec/fasta.yaml"))
    printf("Spec fasta.yaml is not compiled");
  else assert(false);
  tf_compile_specification("../../spec/fasta.yaml", "fasta.tfs");
  if (tf_is_compiled("fasta.tfs"))
    printf("Spec fasta.tfs is compiled");
  else assert(false);
  tf_run_specification_testfile(fas_spec, "../../spec/fasta.yaml");
  fas_entry = tf_default_definition(fas_spec);
  fas_header = tf_get_definition(fas_spec, "header");
  printf("%s\n", tf_describe(fas_header));
  printf("Datatypes: %s\n", tf_datatype_names(fas_spec));
  node = tf_decode(header, fas_header);
  printf("%s\n", jsonnode_to_string(node));
  delete_jsonnode(node);
  printf("%s\n", tf_decode_to_json(header, fas_header));
  if (tf_is_valid_encoded(header, fas_header))
    printf("%s is_valid\n", header);
  else assert(false);
  printf("%s\n", tf_encode_json(decoded_header_json, fas_header));
  node = new_j_object();
  j_object_add(node, "fastaid", new_j_string("ABCD"));
  j_object_add(node, "desc", new_j_string("some sequence"));
  printf("%s\n", tf_encode(node, fas_header));
  if (tf_is_valid_decoded(node, fas_header))
    printf("decoded is_valid\n");
  else assert(false);
  delete_jsonnode(node);
  if (tf_is_valid_decoded_json(decoded_header_json, fas_header))
    printf("%s is_valid\n", decoded_header_json);
  else assert(false);
  tf_decode_file("../../tests/testdata/bio/test.fas", false, fas_entry,
                 decoded_processor, NULL, false);
  tf_delete_definition(fas_entry);
  tf_delete_definition(fas_header);
  tf_delete_specification(fas_spec);
  return 0;
}
