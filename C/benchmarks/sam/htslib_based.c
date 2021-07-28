#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
#include <string.h>
#include <stdbool.h>
#include "htslib/sam.h"
#include "htslib/hts_endian.h"
#include "htslib/kstring.h"

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

int init_rg_counts(sam_hdr_t *hdr, size_t **rg_counts, size_t *n_rg) {
  *n_rg = sam_hdr_count_lines(hdr, "RG");
  XCALLOC(*rg_counts, *n_rg, sizeof(**rg_counts));
  return EXIT_SUCCESS;
}

int init_sq_counts(sam_hdr_t *hdr, size_t **sq_counts, size_t *n_sq) {
  *n_sq = sam_hdr_count_lines(hdr, "SQ");
  XCALLOC(*sq_counts, *n_sq, sizeof(**sq_counts));
  return EXIT_SUCCESS;
}

typedef struct tag_count_t {
  char tagname0, tagname1;
  size_t count;
} tag_count_t;

typedef struct flag_count_t {
  uint16_t flag;
  size_t count;
} flag_count_t;

void count_flag(uint16_t flag, flag_count_t **flag_counts, size_t *n_flags) {
  size_t i;
  bool flag_found = false;
  for (i = 0; i < *n_flags; i++) {
    if ((*flag_counts)[i].flag == flag)
    {
      flag_found = true;
      (*flag_counts)[i].count += 1;
    }
  }
  if (!flag_found)
  {
    *n_flags += 1;
    XREALLOC((*flag_counts), sizeof(**flag_counts) * (*n_flags));
    (*flag_counts)[(*n_flags)-1].flag = flag;
    (*flag_counts)[(*n_flags)-1].count = 1;
  }
}

void count_tag(uint8_t *s, tag_count_t **tag_counts, size_t *n_tags) {
  size_t i;
  bool tag_found = false;
  for (i = 0; i < *n_tags; i++) {
    if ((*tag_counts)[i].tagname0 == *s
        && (*tag_counts)[i].tagname1 == *(s+1))
    {
      tag_found = true;
      (*tag_counts)[i].count += 1;
    }
  }
  if (!tag_found)
  {
    *n_tags += 1;
    XREALLOC((*tag_counts), sizeof(**tag_counts) * (*n_tags));
    (*tag_counts)[(*n_tags)-1].tagname0 = *s;
    (*tag_counts)[(*n_tags)-1].tagname1 = *(s+1);
    (*tag_counts)[(*n_tags)-1].count = 1;
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

bool process_rg_tag(sam_hdr_t *hdr, uint8_t *s,
                    uint8_t *end, size_t *rg_counts) {
  int idx;
  size_t klen;
  char *key;
  uint8_t *kstart = s+3, *kend = kstart;
  if (*(s+2) != 'Z')
  {
    fprintf(stderr, "Error: RG tag code is not 'Z' but '%c'\n", (*(s+2)));
    return true;
  }
  while (kend < end && *kend) kend++;
  klen = kend-kstart;
  XMALLOC(key, klen+1);
  strncpy(key, (char*)kstart, klen);
  key[klen] = '\0';
  if ((idx = sam_hdr_line_index(hdr, "RG", key)) < 0)
  {
    fprintf(stderr, "Error: RG tag for unknown RG '%s'\n", key);
    return true;
  }
  free(key);
  rg_counts[idx]++;
  return false;
}

bool process_tags(sam_hdr_t *hdr, bam1_t *aln, tag_count_t **tag_counts,
                  size_t *n_tags, size_t *rg_counts) {
  uint8_t *s, *end;
  s = bam_get_aux(aln);
  end = aln->data + aln->l_data;
  while (s < end) {
    count_tag(s, tag_counts, n_tags);
    if (*s == 'R' && *(s+1) == 'G')
      if (process_rg_tag(hdr, s, end, rg_counts))
        return true;
    if (skip_tag_content(&s, end)) return true;
  }
  return false;
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
  printf("alignment by flag value:\n");
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
          ks_str(&sm),
          rg_counts[i]);
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

int process_sam_file(htsFile *in, htsFile *out) {
		sam_hdr_t *hdr = NULL;
		bam1_t *aln = NULL;
    bool had_err = false;
		int sam_read1_ret;
    size_t n_tags = 0, n_flags = 0,
           *rg_counts = NULL, n_rg = 0,
           *sq_counts = NULL, n_sq = 0;
    tag_count_t *tag_counts = NULL;
    flag_count_t *flag_counts = NULL;
		if ((hdr = sam_hdr_read(in)) == NULL) {
			fprintf(stderr, "Error: couldn't read SAM file header\n");
      had_err = true;
		}
    if (!had_err)
      init_rg_counts(hdr, &rg_counts, &n_rg);
    if (!had_err)
      init_sq_counts(hdr, &sq_counts, &n_sq);
    if (!had_err && ((aln = bam_init1()) == NULL)) {
		 fprintf(stderr, "Error: Out of memory allocating BAM struct.\n");
      had_err = true;
    }
    while (!had_err && ((sam_read1_ret = sam_read1(in, hdr, aln)) >= 0)) {
      sq_counts[aln->core.tid] += 1;
      count_flag(aln->core.flag, &flag_counts, &n_flags);
      had_err = process_tags(hdr, aln, &tag_counts, &n_tags, rg_counts);
    }
    if (!had_err && (sam_read1_ret < -1)) {
      fprintf(stderr, "Error parsing input file.\n");
      had_err = true;
    }
    print_sq_counts(hdr, sq_counts, n_sq);
    free(sq_counts);
    print_rg_counts(hdr, rg_counts, n_rg);
    free(rg_counts);
    print_tag_counts(tag_counts, n_tags);
    free(tag_counts);
    print_flag_counts(flag_counts, n_flags);
    free(flag_counts);
		bam_destroy1(aln);
    sam_hdr_destroy(hdr);
		return had_err ? EXIT_FAILURE : EXIT_SUCCESS;
}

int main(int argc, char **argv) {
	htsFile *in, *out;

	if (argc < 2) {
		fprintf(stderr, "Usage: %s <in.sam>\n", argv[0]);
		return EXIT_FAILURE;
	}
	if ((in = hts_open(argv[1], "r")) == NULL) {
		fprintf(stderr, "Error opening '%s'\n", argv[1]);
		return EXIT_FAILURE;
	}
	if ((out = hts_open("-", "w")) == NULL) {
		fprintf(stderr, "Error opening '%s'\n", argv[2]);
		return EXIT_FAILURE;
	}
	if (process_sam_file(in, out) != 0) {
		fprintf(stderr, "Error extracting alignment from '%s'\n", argv[1]);
		return EXIT_FAILURE;
	}
	if (hts_close(out) < 0) {
		fprintf(stderr, "Error closing output.\n");
		return EXIT_FAILURE;
	}
	if (hts_close(in) < 0) {
		fprintf(stderr, "Error closing input.\n");
		return EXIT_FAILURE;
	}
	return EXIT_SUCCESS;
}
