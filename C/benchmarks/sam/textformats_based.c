#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "textformats_c.h"

#define HELPMSG \
"Usage: %s <sam> <spec> <datatype>\n"\
"\n"\
"Arguments:\n"\
"  <sam>        SAM file\n"\
"  <spec>       textformats specification\n"\
"  <datatype>   datatype to use\n"

#define XMALLOC(PTR, BUFSZ) \
  PTR = malloc(BUFSZ); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu bytes\n", BUFSZ); \
    exit(EXIT_FAILURE); \
  }

#define XREALLOC(PTR, BUFSZ) \
  PTR = realloc(PTR, BUFSZ); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu bytes\n", BUFSZ); \
    exit(EXIT_FAILURE); \
  }

typedef struct flag_count_t {
  uint16_t flag;
  size_t count;
} flag_count_t;

typedef struct str_count_t {
  char *str;
  size_t count;
} str_count_t;

typedef struct str_attr_count_t {
  char *str;
  char *attr;
  size_t count;
} str_attr_count_t;

typedef struct counts_t {
  size_t n_tags, n_flags, n_rg, n_sq,
         alloc_tags, alloc_flags, alloc_rg, alloc_sq;
  str_count_t *tag_counts;
  flag_count_t *flag_counts;
  str_attr_count_t *rg_counts;
  str_count_t *sq_counts;
} counts_t;

#define INIT_COUNTS {0, 0, 0, 0, 0, 0, 0, 0, \
                     NULL, NULL, NULL, NULL}

#define ALLOC_INC 128

#define NEW_COUNT(N, ALLOC, PTR, V) \
    N += 1;\
    if (N > ALLOC) {\
      ALLOC += ALLOC_INC;\
      XREALLOC(PTR, sizeof(*(PTR)) * ALLOC);\
    }\
    PTR[N-1].count = V;\

#define DUPSTR(DEST, S)\
  XMALLOC(DEST, strlen(S)+1);\
  strcpy(DEST, S);

#define STRNODE_DUPSTR(DEST, NODE) {\
  char *s = j_string_get(NODE);\
  DUPSTR(DEST, s);\
}

#define LSEARCH(N, CMP, COUNTS, FOUND)\
  bool FOUND = false; \
  {\
    size_t i;\
    for (i = 0; i < (N); i++) { \
      if (CMP) {\
        (COUNTS)[i].count += 1;\
        found = true;\
        break;\
      }\
    }\
  }

#define STR_LSEARCH(N, COUNTS, S, FOUND)\
  LSEARCH(N, (strcmp(COUNTS[i].str, S) == 0), COUNTS, FOUND)

void count_flag(counts_t *counts, int flag) {
  LSEARCH(counts->n_flags,
          counts->flag_counts[i].flag == flag,
          counts->flag_counts, found);
  if (!found) {
    NEW_COUNT(counts->n_flags, counts->alloc_flags, counts->flag_counts, 1);
    counts->flag_counts[counts->n_flags-1].flag = flag;
  }
}

#define DEFINE_COUNT_STR(NAME, TYPE, ERRMSG) \
void count_ ## NAME(TYPE counts, size_t n, JsonNode* node) {\
  char *s = j_string_get(node); \
  STR_LSEARCH(n, counts, s, found); \
  if (!found) {\
    fprintf(stderr, "Error: " ERRMSG " (%s)\n", s);\
    exit(1);\
  }\
}

DEFINE_COUNT_STR(sq, str_count_t*, "Unknown target sequence found in alignment");
DEFINE_COUNT_STR(rg, str_attr_count_t*, "Unknown RG found in alignment");

void count_tags(counts_t *counts, JsonNode *tags) {
  size_t i, n_tags = j_object_len(tags);
  JsonNode *rg_tag = j_object_get(tags, "RG");
  char *tagcode = j_string_get(j_object_get(rg_tag, "type"));
  if (strcmp(tagcode, "Z")) {
    fprintf(stderr, "Error: RG tag code is not 'Z' but '%s'\n", tagcode);
    exit(1);
  }
  count_rg(counts->rg_counts, counts->n_rg, j_object_get(rg_tag, "value"));
  for (i = 0; i < n_tags; i++) {
    char *tag = j_object_get_key(tags, i);
    STR_LSEARCH(counts->n_tags, counts->tag_counts, tag, found);
    if (!found) {
      NEW_COUNT(counts->n_tags, counts->alloc_tags, counts->tag_counts, 1);
      DUPSTR(counts->tag_counts[counts->n_tags-1].str, tag);
    }
  }
}

#define J_OBJECT 6

void process_decoded(JsonNode* decoded, void* data) {
  char *key;
  JsonNode *value;
  counts_t *counts = (counts_t*)data;
  assert(jsonnode_kind(decoded) == J_OBJECT);
  assert(j_object_len(decoded) == 1);
  key = j_object_get_key(decoded, 0);
  value = j_object_get(decoded, key);
  if (strcmp(key, "header.@SQ") == 0) {
    JsonNode *sn_node, *sn_node_0;
    NEW_COUNT(counts->n_sq, counts->alloc_sq, counts->sq_counts, 0);
    sn_node = j_object_get(value, "SN");
    sn_node_0 = j_array_get(sn_node, 0);
    STRNODE_DUPSTR(counts->sq_counts[counts->n_sq-1].str, sn_node_0);
    delete_jsonnode(sn_node);
    delete_jsonnode(sn_node_0);
  } else if (strcmp(key, "header.@RG") == 0) {
    JsonNode *id_node, *id_node_0, *sm_node, *sm_node_0;
    NEW_COUNT(counts->n_rg, counts->alloc_rg, counts->rg_counts, 0);
    id_node = j_object_get(value, "ID");
    id_node_0 = j_array_get(id_node, 0);
    STRNODE_DUPSTR(counts->rg_counts[counts->n_rg-1].str, id_node_0);
    delete_jsonnode(id_node);
    delete_jsonnode(id_node_0);
    sm_node = j_object_get(value, "SM");
    sm_node_0 = j_array_get(sm_node, 0);
    STRNODE_DUPSTR(counts->rg_counts[counts->n_rg-1].attr, sm_node_0);
    delete_jsonnode(sm_node);
    delete_jsonnode(sm_node_0);
  } else if (strncmp(key, "alignments", 10) == 0) {
    JsonNode *flag_node, *rname_node, *tags_node;
    flag_node = j_object_get(value, "flag");
    count_flag(counts, j_int_get(flag_node));
    delete_jsonnode(flag_node);
    rname_node = j_object_get(value, "rname");
    count_sq(counts->sq_counts, counts->n_sq, rname_node);
    delete_jsonnode(rname_node);
    tags_node = j_object_get(value, "tags");
    count_tags(counts, tags_node);
    delete_jsonnode(tags_node);
  }
  delete_jsonnode(value);
}

#define PRINT_STR_COUNTS(N, STRCOUNTS) { \
    size_t i, n = N; \
    for (i = 0; i < n; i++) \
      printf("  %s: %lu\n", (STRCOUNTS)[i].str, \
                            (STRCOUNTS)[i].count); \
  }

#define PRINT_STR_ATTR_COUNTS(N, STRCOUNTS, ATTRNAME) { \
    size_t i, n = N; \
    for (i = 0; i < n; i++) \
      printf("  %s ("ATTRNAME":%s): %lu\n", \
          (STRCOUNTS)[i].str, \
          (STRCOUNTS)[i].attr, \
          (STRCOUNTS)[i].count); \
  }

#define PRINT_FLAG_COUNTS(N, FLAGCOUNTS) { \
    size_t i, n = N; \
    for (i = 0; i < n; i++) \
      printf("  %lu: %lu\n", (FLAGCOUNTS)[i].flag, \
                             (FLAGCOUNTS)[i].count); \
  }

void print_counts(counts_t *counts) {
  printf("alignments by target sequence:\n");
  PRINT_STR_COUNTS(counts->n_sq, counts->sq_counts);
  printf("alignments by read group:\n");
  PRINT_STR_ATTR_COUNTS(counts->n_rg, counts->rg_counts, "SM");
  printf("tag counts:\n");
  PRINT_STR_COUNTS(counts->n_tags, counts->tag_counts);
  printf("alignments by flag value:\n");
  PRINT_FLAG_COUNTS(counts->n_flags, counts->flag_counts);
}

void free_counts(counts_t *counts) {
  size_t i;
  for (i = 0; i < counts->n_sq; i++)
    free(counts->sq_counts[i].str);
  free(counts->sq_counts);
  for (i = 0; i < counts->n_rg; i++) {
    free(counts->rg_counts[i].str);
    free(counts->rg_counts[i].attr);
  }
  free(counts->rg_counts);
  for (i = 0; i < counts->n_tags; i++)
    free(counts->tag_counts[i].str);
  free(counts->tag_counts);
  free(counts->flag_counts);
}

bool parse_args(int argc, char *argv[], DatatypeDefinition **def,
                char **input_file) {
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

#define TF_DECODED_PROCESSOR_LEVEL_LINE 2

int main(int argc, char *argv[]) {
  DatatypeDefinition *def;
  char *input_file;
  counts_t counts = INIT_COUNTS;
  NimMain();
  tf_quit_on_err = true;
  if (parse_args(argc, argv, &def, &input_file))
    return EXIT_FAILURE;
  tf_decode_file(input_file, false, def, process_decoded, &counts,
                 TF_DECODED_PROCESSOR_LEVEL_LINE);
  print_counts(&counts);
  free_counts(&counts);
  return EXIT_SUCCESS;
}

