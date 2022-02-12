#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "textformats_c.h"

#define HELPMSG \
"Parse EGC data from JSON and output its content in EGC format\n"\
"\n"\
"Usage: %s <inputfile> <inputspec>\n"\
"\n"\
"Arguments:\n"\
"  <inputfile>   Input file in Json format\n"\
"  <inputspec>   Specification file describing the EGC format\n"

bool parse_args(int argc, char *argv[], Specification **spec,
                const char **input_file) {
  if (argc != 3) {
    printf(HELPMSG, argv[0]);
    return true;
  }
  *input_file = argv[1];
  *spec = tf_specification_from_file(argv[2]);
  return false;
}

char* read_file(const char *filename) {
  FILE *file;
  size_t bufsize;
  char *buffer;
  file = fopen(filename, "r");
  assert(file != NULL);
  fseek(file, 0, SEEK_END);
  bufsize = ftell(file) + 1;
  buffer = malloc(bufsize);
  buffer[bufsize-1] = 0;
  assert(buffer != NULL);
  fseek(file, 0, SEEK_SET);
  fread(buffer, 1, bufsize, file);
  fclose(file);
  return buffer;
}

int main(int argc, char *argv[]) {
  Specification *spec;
  const char *input_file;
  char *input_data;
  DatatypeDefinition *def;
  NimMain();
  tf_quit_on_err = true;
  if (parse_args(argc, argv, &spec, &input_file))
    return EXIT_FAILURE;
  def = tf_get_definition(spec, "file");
  input_data = read_file(input_file);
  printf("%s\n", tf_encode_json(input_data, def));
  free(input_data);
  return EXIT_SUCCESS;
}

