#include "textformats_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HELPMSG \
"Parse a file containing encoded strings using the C API\n"\
"\n"\
"Usage:\n"\
"  %s <specfn> <datatype> <encodedfn> <operation>\n"\
"\n"\
"Arguments:\n"\
"  <specfn>       filename of YAML textformats specification\n"\
"  <datatype>     datatype to use\n"\
"  <encodedfn>    filename of encoded strings, one per line\n"\
"  <operation>    one of: decode, to_json\n"

typedef enum {
  OpDecode,
  OpToJson
} TextformatsOperation;

int parse_args(int argc, char *argv[],
               DatatypeDefinition **def,
               FILE **input_file,
               TextformatsOperation *op) {
  Specification *spec;
  if (argc != 5)
  {
    printf(HELPMSG, argv[0]);
    return EXIT_FAILURE;
  }
  spec = tf_specification_from_file(argv[1]);
  *def = tf_get_definition(spec, argv[2]);
  *input_file = fopen(argv[3], "r");
  if (*input_file == NULL)
    return EXIT_FAILURE;
  if (strcmp(argv[4], "decode") == 0) *op = OpDecode;
  else if (strcmp(argv[4], "to_json") == 0) *op = OpToJson;
  else return EXIT_FAILURE;
  return EXIT_SUCCESS;
}

#define MAXLINESIZE 1023

#define XMALLOC(PTR, BUFSIZE) \
  PTR = malloc(BUFSIZE); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu bytes\n", BUFSIZE); \
    exit(EXIT_FAILURE); \
  }

#define rstrip(STR) \
{\
  size_t len = strlen(STR);\
  if ((STR)[len-1] = '\n')\
    (STR)[len-1] = '\0';\
}

int input_file_decode(DatatypeDefinition *def, FILE *input_file)
{
    JsonNode* node;
    char *encoded, *decoded;
    XMALLOC(encoded, MAXLINESIZE+1);
    while (fgets(encoded, MAXLINESIZE, input_file) != NULL)
    {
      rstrip(encoded);
      node = (JsonNode*)tf_decode(encoded, def);
      decoded = jsonnode_to_string(node);
      printf("%s\n", decoded);
      delete_jsonnode(node);
    }
    free(encoded);
}

int input_file_to_json(DatatypeDefinition *def, FILE *input_file)
{
    char *encoded, *decoded;
    XMALLOC(encoded, MAXLINESIZE+1);
    while (fgets(encoded, MAXLINESIZE, input_file) != NULL)
    {
      rstrip(encoded);
      decoded = tf_decode_to_json(encoded, def);
      tf_checkerr();
      printf("%s\n", decoded);
    }
    free(encoded);
}

int main(int argc, char *argv[]) {
  DatatypeDefinition *def;
  FILE *input_file;
  TextformatsOperation op;
  int (*operation)(DatatypeDefinition*, FILE*);
  NimMain();
  tf_quit_on_err = true;
  if (parse_args(argc, argv, &def, &input_file, &op) != EXIT_SUCCESS)
    exit(EXIT_FAILURE);
  operation = (op == OpToJson) ? input_file_to_json : input_file_decode;
  if (operation(def, input_file) != EXIT_SUCCESS)
    exit(EXIT_FAILURE);
  fclose(input_file);
  exit(EXIT_SUCCESS);
}
