#define NEXT_TEST(STR, ...) \
  printf("\n======== test " STR "\n\n", ##__VA_ARGS__)

#define EXPECT_FAILURE \
  if (!tf_haderr) {\
    printf("[FAILED] No errors, but an error was expected");\
    exit(1);\
  } else {\
    printf("[OK] Error, as expected:\n"); \
    tf_printerr(); \
    tf_unseterr(); \
  }

#define EXPECT_NO_ERROR \
  if (tf_haderr) {\
    printf("\n[FAILED] Unexpected error:\n");\
    tf_printerr();\
    exit(1); \
  } else printf("[OK] no errors\n")

#define EXPECT_INT_EQ(VALUE, EXPECTED) \
  {\
    const int testint_v = VALUE, testint_e = EXPECTED;\
    if(testint_v != testint_e) {\
      printf("[FAILED] Error:\nValue: '%i'\nExpected: '%i'\n", \
             testint_v, testint_e);\
      exit(1);\
    } else printf("[OK] %i as expected\n\n", testint_v);\
  }

#define EXPECT_STR_EQ(VALUE, EXPECTED) \
  {\
    const char *teststr_v = VALUE, *teststr_e = EXPECTED;\
    if(strcmp(teststr_v, teststr_e) != 0) {\
      printf("[FAILED] Error:\nValue: '%s'\nExpected: '%s'\n", \
             teststr_v, teststr_e);\
      exit(1);\
    } else printf("[OK] '%s' as expected\n\n", teststr_v);\
  }

#define EXPECT_JSONSTR_EQ(NODE, EXP) \
  EXPECT_STR_EQ(jsonnode_to_string(NODE), EXP)

#define EXPECT_TRUE(VALUE) \
  if (!VALUE) { \
    printf("[FAILED] Error:\nValue: false\nExpected: true\n");\
    exit(1);\
  } else printf("[OK] true as expected\n\n"); \

#define EXPECT_FALSE(VALUE) \
  if (VALUE) { \
    printf("[FAILED] Error:\nValue: true\nExpected: false\n");\
    exit(1);\
  } else printf("[OK] false as expected\n\n"); \

