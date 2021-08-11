#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <assert.h>
#include <limits.h>
#include "opstats.h"

#define HELPMSG \
"Computes some stats on each line of a file containing CIGAR strings\n"\
"This version is implemented without using TextFormats\n"\
"\n"\
"Usage:\n"\
"  %s <cigarsfn>\n"\
"\n"\
"Arguments:\n"\
"  <cigarsfn> input filename\n"

typedef struct {
  char code;
  unsigned long len;
} cigar_op;

#define MAXLINESIZE (size_t)4096

#define XMALLOC(PTR, BUFSIZE) \
  PTR = malloc(BUFSIZE); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu bytes\n", BUFSIZE); \
    exit(EXIT_FAILURE); \
  }

#define rstrip(STR) {\
  size_t len = strlen(STR);\
  if ((STR)[len-1] == '\n')\
    (STR)[len-1] = '\0';\
}

void process_decoded(cigar_op *decoded, unsigned long n_decoded) {
  unsigned long i;
  opstats_t m_stats = OPSTATS_INIT,
            i_stats = OPSTATS_INIT,
            d_stats = OPSTATS_INIT;
  for (i=0; i < n_decoded; i++) {
    switch (decoded[i].code) {
      case 'M': PROCESS_OP(m_stats, decoded[i].len); break;
      case 'I': PROCESS_OP(i_stats, decoded[i].len); break;
      case 'D': PROCESS_OP(d_stats, decoded[i].len); break;
      default: assert(false);
    }
  }
  PRINT_ALL_OPSTATS(m_stats, i_stats, d_stats);
}

bool inline is_opcode(const char opcode) {
  return (opcode == 'M' || opcode == 'I' || opcode == 'D');
}

bool parse_cigar(char *encoded, cigar_op **decoded, unsigned long *n_decoded) {
  bool had_err = false;
  size_t i, op = 0, num_start = 0,
         encoded_len = strlen(encoded);
  bool num_start_expected = true;
  /* count operations in cigar, to allocate the correct space */
  (*n_decoded) = 0;
  for (i = 0; i < encoded_len; i++)
    if (!isdigit(encoded[i])) (*n_decoded)++;
  XMALLOC((*decoded), (*n_decoded) * sizeof(**decoded));
  for (i = 0; i < encoded_len && !had_err; i++) {
    if (isdigit(encoded[i])) {
      if (num_start_expected) {
        if (encoded[i] == '0')
          had_err = true;
        num_start = i;
        num_start_expected = false;
      }
    } else {
      if (num_start_expected)
        had_err = true;
      if (!had_err && !is_opcode(encoded[i]))
        had_err = true;
      if (!had_err) {
        num_start_expected = true;
        assert(op < *n_decoded);
        (*decoded)[op].code = encoded[i];
        encoded[i] = 0;
        (*decoded)[op].len = atol(encoded + num_start);
        op += 1;
      }
    }
  }
  if (!num_start_expected)
    had_err = true;
  return had_err;
}

bool parse_args(int argc, char *argv[], FILE **input_file) {
  if (argc != 2) {
    printf(HELPMSG, argv[0]);
    return true;
  }
  *input_file = fopen(argv[1], "r");
  if (*input_file == NULL)
    return true;
  return false;
}

bool parse_input_file(FILE *input_file) {
  bool had_err = false;
  char *encoded = NULL;
  cigar_op *decoded = NULL;
  unsigned long n_decoded;
  XMALLOC(encoded, MAXLINESIZE+1);
  while (!had_err && fgets(encoded, MAXLINESIZE, input_file) != NULL) {
    rstrip(encoded);
    if (parse_cigar(encoded, &decoded, &n_decoded)) had_err = true;
    if (!had_err) process_decoded(decoded, n_decoded);
    free(decoded);
    decoded = NULL;
  }
  free(encoded);
  return had_err;
}

int main(int argc, char *argv[]) {
  FILE *input_file;
  if (parse_args(argc, argv, &input_file))
    exit(EXIT_FAILURE);
  if (parse_input_file(input_file))
    exit(EXIT_FAILURE);
  fclose(input_file);
  exit(EXIT_SUCCESS);
}
