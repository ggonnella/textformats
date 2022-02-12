#include <stdio.h>
#include <stdlib.h>
#include "textformats_c.h"

#define HELPMSG \
"Parse the EGC format and output its content as JSON\n"\
"\n"\
"Usage: %s <inputfile> <inputspec>\n"\
"\n"\
"Arguments:\n"\
"  <inputfile>   Input file in EGC format\n"\
"  <inputspec>   Specification file describing the EGC format\n"

void process_decoded(char* decoded, void* data) {
  printf("%s", decoded);
}

bool parse_args(int argc, char *argv[], Specification **spec,
                char **input_file) {
  if (argc != 3) {
    printf(HELPMSG, argv[0]);
    return true;
  }
  *input_file = argv[1];
  *spec = tf_specification_from_file(argv[2]);
  return false;
}

#define TF_DECODED_PROCESSOR_LEVEL_WHOLE 0

int main(int argc, char *argv[]) {
  Specification *spec;
  char *input_file;
  DatatypeDefinition *def;
  NimMain();
  tf_quit_on_err = true;
  if (parse_args(argc, argv, &spec, &input_file))
    return EXIT_FAILURE;
  def = tf_get_definition(spec, "file");
  tf_decode_file_to_json(input_file, false, def, process_decoded, NULL,
                 TF_DECODED_PROCESSOR_LEVEL_WHOLE);
  return EXIT_SUCCESS;
}

