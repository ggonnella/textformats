#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "textformats_c.h"
#include "opstats.h"

#define HELPMSG \
"Computes some stats on each line of a file containing CIGAR strings\n"\
"This version is implemented using TextFormats\n"\
"\n"\
"Usage:\n"\
"  %s <inputfn> <specfn> <datatype>\n"\
"\n"\
"Arguments:\n"\
"  <inputfn>      filename of encoded strings, one per line\n"\
"  <specfn>       filename of YAML textformats specification\n"\
"  <datatype>     datatype to use\n"

void process_decoded(JsonNode* decoded, void* data) {
  unsigned long i;
  opstats_t m_stats = OPSTATS_INIT,
            i_stats = OPSTATS_INIT,
            d_stats = OPSTATS_INIT;
  for (i=0; i < j_array_len(decoded); i++) {
    JsonNode *elem = j_array_get(decoded, i),
             *opcode_elem = j_object_get(elem, "code"),
             *len_elem = j_object_get(elem, "length");
    char opcode = j_string_get(opcode_elem)[0];
    int len = j_int_get(len_elem);
    switch (opcode) {
      case 'M': PROCESS_OP(m_stats, len); break;
      case 'I': PROCESS_OP(i_stats, len); break;
      case 'D': PROCESS_OP(d_stats, len); break;
      default: assert(false);
    }
    delete_jsonnode(elem);
    delete_jsonnode(opcode_elem);
    delete_jsonnode(len_elem);
  }
  PRINT_ALL_OPSTATS(m_stats, i_stats, d_stats);
}

bool parse_args(int argc, char *argv[],
                DatatypeDefinition **def, char **input_file) {
  Specification *spec;
  if (argc != 4) {
    printf(HELPMSG, argv[0]);
    return true;
  }
  *input_file = argv[1];
  spec = tf_specification_from_file(argv[2]);
  *def = tf_get_definition(spec, argv[3]);
  return false;
}

int main(int argc, char *argv[]) {
  DatatypeDefinition *def;
  char *input_file;
  NimMain();
  tf_quit_on_err = true;
  if (parse_args(argc, argv, &def, &input_file)) exit(EXIT_FAILURE);
  tf_decode_file(input_file, false, def, process_decoded, NULL, 2);
  exit(EXIT_SUCCESS);
}

