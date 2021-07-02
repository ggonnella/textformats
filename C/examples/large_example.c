#include "c_api.h"
#include <stdio.h>
#include <assert.h>

void value_processor(JsonNode* node, void* data)
{
  printf("Node: %s\n", to_string(node));
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
  fas_spec = specification_from_file("../../bio/spec/fasta.yaml");
  if (!is_preprocessed("../../bio/spec/fasta.yaml"))
    printf("Spec fasta.yaml is not preprocessed");
  else assert(false);
  preprocess_specification("../../bio/spec/fasta.yaml", "fasta.tfs");
  if (is_preprocessed("fasta.tfs"))
    printf("Spec fasta.tfs is preprocessed");
  else assert(false);
  test_specification(fas_spec, "../../bio/spec/fasta.yaml");
  fas_entry = default_definition(fas_spec);
  fas_header = get_definition(fas_spec, "header");
  printf("%s\n", describe(fas_header));
  printf("Datatypes: %s\n", datatype_names(fas_spec));
  node = decode(header, fas_header);
  printf("%s\n", to_string(node));
  delete_node(node);
  printf("%s\n", to_json(header, fas_header));
  if (is_valid_encoded(header, fas_header))
    printf("%s is_valid\n", header);
  else assert(false);
  printf("%s\n", from_json(decoded_header_json, fas_header));
  node = newJObject();
  JObject_add(node, "fastaid", newJString("ABCD"));
  JObject_add(node, "desc", newJString("some sequence"));
  printf("%s\n", encode(node, fas_header));
  if (is_valid_decoded(node, fas_header))
    printf("decoded is_valid\n");
  else assert(false);
  delete_node(node);
  if (is_valid_decoded_json(decoded_header_json, fas_header))
    printf("%s is_valid\n", decoded_header_json);
  else assert(false);
  decode_file_values("../../bio/data/test.fas", false, fas_entry,
                     value_processor, NULL, false);
  delete_definition(fas_entry);
  delete_definition(fas_header);
  delete_specification(fas_spec);
  return 0;
}
