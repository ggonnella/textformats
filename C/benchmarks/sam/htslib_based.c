#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "htslib/sam.h"
#include "htslib/hts_endian.h"
#include "htslib/kstring.h"

#define HELPMSG \
"Usage: %s <sam>\n"\
"\n"\
"Arguments:\n"\
"  <sam>        SAM file\n"\

#define XMALLOC(PTR, BUFSZ) \
  PTR = malloc(BUFSZ); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu bytes\n", BUFSZ); \
    exit(EXIT_FAILURE); \
  }

#define XCALLOC(PTR, NMEMB, MEMBSZ) \
  PTR = calloc(NMEMB, MEMBSZ); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu * %lu bytes\n",\
            NMEMB, MEMBSZ); \
    exit(EXIT_FAILURE); \
  }

#define XREALLOC(PTR, BUFSZ) \
  PTR = realloc(PTR, BUFSZ); \
  if (PTR == NULL) { \
    fprintf(stderr, "ERROR: Failed allocating %lu bytes\n", BUFSZ); \
    exit(EXIT_FAILURE); \
  }

typedef struct tag_count_t {
  char tagname0, tagname1;
  size_t count;
} tag_count_t;

typedef struct flag_count_t {
  uint16_t flag;
  size_t count;
} flag_count_t;

typedef struct counts_t {
  size_t n_tags, n_flags, n_rg, n_sq,
         alloc_tags, alloc_flags;
  tag_count_t *tag_counts;
  flag_count_t *flag_counts;
  size_t *rg_counts;
  size_t *sq_counts;
} counts_t;

#define INIT_COUNTS {0, 0, 0, 0, 0, 0, \
                     NULL, NULL, NULL, NULL}

#define ALLOC_INC 128

#define NEW_COUNT(N, ALLOC, PTR, V) \
    N += 1;\
    if (N > ALLOC) {\
      ALLOC += ALLOC_INC;\
      XREALLOC(PTR, sizeof(*(PTR)) * ALLOC);\
    }\
    PTR[N-1].count = V;\

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

void count_flag(counts_t *counts, uint16_t flag) {
  LSEARCH(counts->n_flags,
          counts->flag_counts[i].flag == flag,
          counts->flag_counts, found);
  if (!found) {
    NEW_COUNT(counts->n_flags, counts->alloc_flags, counts->flag_counts, 1);
    counts->flag_counts[counts->n_flags-1].flag = flag;
  }
}

void count_tag(counts_t *counts, uint8_t *start) {
  LSEARCH(counts->n_tags,
    counts->tag_counts[i].tagname0 == *start &&
      counts->tag_counts[i].tagname1 == *(start+1),
    counts->tag_counts, found);
  if (!found)
  {
    NEW_COUNT(counts->n_tags, counts->alloc_tags, counts->tag_counts, 1);
    counts->tag_counts[counts->n_tags-1].tagname0 = *start;
    counts->tag_counts[counts->n_tags-1].tagname1 = *(start+1);
  }
}

bool skip_tag_content(uint8_t **s, uint8_t *end) {
  (*s) += 2;
  size_t sz;
  uint8_t array_code;
  switch(**s) {
    case 'A': case 'C': case 'c': (*s) += 2; break;
    case 's': case 'S': (*s) += 3; break;
    case 'i': case 'I': case 'f': case 'F': (*s) += 5; break;
    case 'd': (*s) += 9; break;
    case 'Z': case 'H':
      while (*s < end && **s) (*s)++;
      (*s)++;
      break;
    case 'B':
      array_code = *((*s)+1);
      switch (array_code) {
        case 'c': case 'C': sz = 1; break;
        case 's': case 'S': sz = 2; break;
        case 'i': case 'I': case 'f': sz = 4; break;
        case 'd': sz = 8; break;
        default:
          fprintf(stderr,
              "Error: invalid B tag array code: '%c'\n", array_code);
          return true;
      }
      (*s) += 6 + sz * le_to_u32((*s)+2);
      break;
    default:
      fprintf(stderr, "Error: invalid tag type code: '%c'\n", **s);
      return true;
  }
  return false;
}

char* zeroterminated_rg_dup(uint8_t *start, uint8_t *end) {
  char *rg;
  size_t rg_len;
  uint8_t *rg_start = start+3, *rg_end = rg_start;
  while (rg_end < end && *rg_end)
    rg_end++;
  rg_len = rg_end - rg_start;
  XMALLOC(rg, rg_len + 1);
  strncpy(rg, (char*)rg_start, rg_len);
  rg[rg_len] = '\0';
  return rg;
}

bool count_rg(sam_hdr_t *hdr, uint8_t *start, uint8_t *end, size_t *rg_counts) {
  int rg_idx;
  char *rg = zeroterminated_rg_dup(start, end);
  if (*(start+2) != 'Z') {
    fprintf(stderr, "Error: RG tag code is not 'Z' but '%c'\n", (*(start+2)));
    return true;
  }
  if ((rg_idx = sam_hdr_line_index(hdr, "RG", rg)) < 0) {
    fprintf(stderr, "Error: Unknown RG found in alignment (%s)\n", rg);
    return true;
  }
  rg_counts[rg_idx]++;
  free(rg);
  return false;
}

bool count_tags(counts_t *counts, sam_hdr_t *hdr, bam1_t *aln) {
  uint8_t *start = bam_get_aux(aln),
          *end = aln->data + aln->l_data;
  while (start < end) {
    count_tag(counts, start);
    if (*start == 'R' && *(start+1) == 'G')
      if (count_rg(hdr, start, end, counts->rg_counts))
        return true;
    if (skip_tag_content(&start, end))
      return true;
  }
  return false;
}

void count_sq(counts_t *counts, size_t seqnum) {
  assert(seqnum < counts->n_sq);
  counts->sq_counts[seqnum]++;
}

bool process_sam_file(htsFile *in, sam_hdr_t *hdr, counts_t *counts) {
	bam1_t *aln = NULL;
  bool had_err = false;
	int sam_read1_ret;
  counts->n_rg = sam_hdr_count_lines(hdr, "RG");
  XCALLOC(counts->rg_counts, counts->n_rg, sizeof(*(counts->rg_counts)));
  counts->n_sq = sam_hdr_count_lines(hdr, "SQ");
  XCALLOC(counts->sq_counts, counts->n_sq, sizeof(*(counts->sq_counts)));
  if ((aln = bam_init1()) == NULL) {
	  fprintf(stderr, "Error: Out of memory allocating BAM struct.\n");
    had_err = true;
  }
  while (!had_err && ((sam_read1_ret = sam_read1(in, hdr, aln)) >= 0)) {
    count_flag(counts, aln->core.flag);
    count_sq(counts, aln->core.tid);
    had_err = count_tags(counts, hdr, aln);
  }
  if (!had_err && (sam_read1_ret < -1)) {
    fprintf(stderr, "Error parsing input file.\n");
    had_err = true;
  }
	bam_destroy1(aln);
	return had_err;
}

void print_tag_counts(tag_count_t *tag_counts, size_t n_tags) {
  size_t i;
  printf("tag counts:\n");
  for (i = 0; i < n_tags; i++) {
    printf("  %c%c: %lu\n", tag_counts[i].tagname0,
                            tag_counts[i].tagname1,
                            tag_counts[i].count);
  }
}

void print_flag_counts(flag_count_t *flag_counts, size_t n_flags) {
  size_t i;
  printf("alignments by flag value:\n");
  for (i = 0; i < n_flags; i++) {
    printf("  %u: %lu\n", flag_counts[i].flag,
                          flag_counts[i].count);
  }
}

void print_rg_counts(sam_hdr_t *hdr, size_t *rg_counts, size_t n_rg) {
  size_t i;
  printf("alignments by read group:\n");
  kstring_t sm = KS_INITIALIZE;
  for (i = 0; i < n_rg; i++) {
    sam_hdr_find_tag_pos(hdr, "RG", i, "SM", &sm);
    printf("  %s (SM:%s): %lu\n",
          sam_hdr_line_name(hdr, "RG", i),
          ks_str(&sm), rg_counts[i]);
  }
  ks_free(&sm);
}

void print_sq_counts(sam_hdr_t *hdr, size_t *sq_counts, size_t n_sq) {
  size_t i;
  printf("alignments by target sequence:\n");
  for (i = 0; i < n_sq; i++) {
    printf("  %s: %lu\n",
          hdr->target_name[i],
          sq_counts[i]);
  }
}

void print_counts(counts_t *counts, sam_hdr_t *hdr) {
  print_sq_counts(hdr, counts->sq_counts, counts->n_sq);
  print_rg_counts(hdr, counts->rg_counts, counts->n_rg);
  print_tag_counts(counts->tag_counts, counts->n_tags);
  print_flag_counts(counts->flag_counts, counts->n_flags);
}

void free_counts(counts_t *counts) {
  size_t i;
  free(counts->sq_counts);
  free(counts->rg_counts);
  free(counts->tag_counts);
  free(counts->flag_counts);
}

bool parse_args(int argc, char *argv[], htsFile **input_file) {
	if (argc != 2) {
    printf(HELPMSG, argv[0]);
    return true;
	}
  (*input_file) = hts_open(argv[1], "r");
  if (*input_file == NULL) {
		fprintf(stderr, "Error opening '%s'\n", argv[1]);
    return true;
	}
  return false;
}

int main(int argc, char **argv) {
	htsFile *input_file;
	sam_hdr_t *hdr = NULL;
  counts_t counts = INIT_COUNTS;
  if (parse_args(argc, argv, &input_file))
    return EXIT_FAILURE;
  hdr = sam_hdr_read(input_file);
  if (hdr == NULL) {
    fprintf(stderr, "Error: couldn't read SAM file header\n");
		return EXIT_FAILURE;
  }
	if (process_sam_file(input_file, hdr, &counts)) {
		fprintf(stderr, "Error processing file '%s'\n", argv[1]);
		return EXIT_FAILURE;
	}
	if (hts_close(input_file) < 0) {
		fprintf(stderr, "Error closing input.\n");
		return EXIT_FAILURE;
	}
  print_counts(&counts, hdr);
  free_counts(&counts);
  sam_hdr_destroy(hdr);
  fflush(stdout);
	return EXIT_SUCCESS;
}
