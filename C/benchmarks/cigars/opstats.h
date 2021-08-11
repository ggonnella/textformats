typedef struct opstats_t {
  unsigned long num, totlen, minlen, maxlen;
} opstats_t;

#define OPSTATS_INIT {0, 0, ULONG_MAX, 0}

#define PROCESS_OP(OPSTATS, OPLEN) {\
    (OPSTATS).num++;\
    (OPSTATS).totlen += (OPLEN);\
    if ((OPLEN) > (OPSTATS).maxlen) \
      (OPSTATS).maxlen = (OPLEN);\
    if ((OPLEN) < (OPSTATS).minlen) \
      (OPSTATS).minlen = (OPLEN);\
  }

#define PRINT_OPSTATS(CODE, OPSTATS)\
  printf(CODE"={n:%lu:%lu..%lu;sum=%lu}", \
      (OPSTATS).num, (OPSTATS).minlen, (OPSTATS).maxlen, (OPSTATS).totlen);

#define PRINT_ALL_OPSTATS(M_OPSTATS, I_OPSTATS, D_OPSTATS) \
  PRINT_OPSTATS("M", M_OPSTATS); \
  printf(","); \
  PRINT_OPSTATS("I", I_OPSTATS); \
  printf(","); \
  PRINT_OPSTATS("D", D_OPSTATS); \
  printf("\n");
