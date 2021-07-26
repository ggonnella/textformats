#include "textformats_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HELPMSG \
"Decode all lines of a file using TextFormats\n"\
"\n"\
"Usage:\n"\
"  %s <specfn> <datatype> <encodedfn> <operation>\n"\
"\n"\
"Arguments:\n"\
"  <specfn>       filename of YAML textformats specification\n"\
"  <datatype>     datatype to use\n"\
"  <encodedfn>    filename of encoded strings, one per line\n"\
"  <operation>    one of: decode, to_json\n"

int parse_args(int argc, char *argv[],
               DatatypeDefinition **def,
               char **input_file,
               bool *to_json) {
  Specification *spec;
  if (argc != 5)
  {
    printf(HELPMSG, argv[0]);
    return EXIT_FAILURE;
  }
  spec = tf_specification_from_file(argv[1]);
  *def = tf_get_definition(spec, argv[2]);
  *input_file = argv[3];
  if (strcmp(argv[4], "decode") == 0) *to_json = true;
  else if (strcmp(argv[4], "to_json") == 0) *to_json = false;
  else return EXIT_FAILURE;
  return EXIT_SUCCESS;
}

void decoded_processor_str(char *decoded, void* data) {
  printf("%s\n", decoded);
}

void decoded_processor_node(JsonNode* decoded, void* data) {
  printf("%s\n", jsonnode_to_string(decoded));
}

int main(int argc, char *argv[]) {
  DatatypeDefinition *def;
  char *input_file;
  bool to_json;
  NimMain();
  tf_quit_on_err = true;
  if (parse_args(argc, argv, &def, &input_file, &to_json) != EXIT_SUCCESS)
    exit(EXIT_FAILURE);
  if (to_json)
    tf_decode_file_to_json(input_file, false, def, decoded_processor_str,
                           NULL, false);
  else
    tf_decode_file(input_file, false, def, decoded_processor_node,
                   NULL, false);
  exit(EXIT_SUCCESS);
}

