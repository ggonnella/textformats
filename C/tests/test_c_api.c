#include "c_api.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#define NONEXISTING_SPEC "testdata/xyz.yaml"
#define BAD_YAML_SPEC    "testdata/wrong_yaml_syntax.yaml"
#define YAML_SPEC        "testdata/fasta.yaml"
#define GOODTEST         "testdata/good_test.yaml"
#define BADTEST          "testdata/bad_test.yaml"

#define NONEXISTING_DATA_TYPE "heder"
#define DATA_TYPE             "header"

#define DATA_E      ">ABCD some sequence"
#define BAD_DATA_E  "ABCD some sequence"
#define DATA_D      "{\"fastaid\":\"ABCD\",\"desc\":\"some sequence\"}"
#define BAD_DATA_D  "{\"desc\":\"some sequence\"}"

#define DATAFILE                  "testdata/test.fas"
#define DATA_TYPE_SCOPE_LINE      "line"
#define BAD_DATA_TYPE_SCOPE_LINE  "line_failing"
#define DATA_TYPE_SCOPE_UNIT      "unit_for_tests"
#define DATA_TYPE_SCOPE_SECTION   "entry"
#define DATA_TYPE_SCOPE_FILE      "file"

#define NEXT_TEST(STR) \
  printf("\n======== test " STR "\n\n")

#define EXPECT_FAILURE \
  if (!tf_haderr) {\
    printf("No errors, but an error was expected");\
    exit(1);\
  } else {\
    printf("[OK]: Error, as expected:\n"); \
    tf_printerr(); \
    unset_tf_err(); \
  }

#define EXPECT_NO_ERROR \
  if (tf_haderr) {\
    printf("\nUnexpected error\n");\
    tf_printerr();\
    exit(1); \
  } else printf("[OK]: no errors\n")

#define EXPECT_INT_EQ(VALUE, EXPECTED) \
  {\
    const int testint_v = VALUE, testint_e = EXPECTED;\
    if(testint_v != testint_e) {\
      printf("Error!\nValue: '%i'\nExpected: '%i'\n", testint_v, testint_e);\
      exit(1);\
    } else printf("[OK]: %i as expected\n\n", testint_v);\
  }

#define EXPECT_STR_EQ(VALUE, EXPECTED) \
  {\
    const char *teststr_v = VALUE, *teststr_e = EXPECTED;\
    if(strcmp(teststr_v, teststr_e) != 0) {\
      printf("Error!\nValue: '%s'\nExpected: '%s'\n", teststr_v, teststr_e);\
      exit(1);\
    } else printf("[OK]: '%s' as expected\n\n", teststr_v);\
  }

#define EXPECT_JSONSTR_EQ(NODE, EXP) \
  EXPECT_STR_EQ(to_string(NODE), EXP)

#define EXPECT_TRUE(VALUE) \
  if (!VALUE) { \
    printf("Error!\nValue: false\nExpected: true\n");\
    exit(1);\
  } else printf("[OK]: true as expected\n\n"); \

#define EXPECT_FALSE(VALUE) \
  if (VALUE) { \
    printf("Error!\nValue: true\nExpected: false\n");\
    exit(1);\
  } else printf("[OK]: false as expected\n\n"); \

void test_handling_encoded_strings(DatatypeDefinition *dd)
{
  JsonNode *decoded;
  char *decoded_json;
  /* decode */
  NEXT_TEST("decoding invalid data");
  decoded = decode(BAD_DATA_E, dd);
  EXPECT_FAILURE;
  NEXT_TEST("decoding valid data: no error");
  decoded = decode(DATA_E, dd);
  assert(decoded != NULL);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding valid data: expected result");
  EXPECT_JSONSTR_EQ(decoded, DATA_D);
  delete_node(decoded);
  /* to_json */
  NEXT_TEST("decoding invalid data to json");
  decoded_json = to_json(BAD_DATA_E, dd);
  EXPECT_FAILURE;
  NEXT_TEST("decoding valid data to json: no error");
  decoded_json = to_json(DATA_E, dd);
  assert(decoded_json != NULL);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding valid data to json: expected result");
  EXPECT_STR_EQ(decoded_json, DATA_D);
  /* is_valid_encoded */
  NEXT_TEST("validating invalid encoded data");
  EXPECT_FALSE(is_valid_encoded(BAD_DATA_E, dd));
  NEXT_TEST("validating valid encoded data");
  EXPECT_TRUE(is_valid_encoded(DATA_E, dd));
}

void test_handling_decoded_data(DatatypeDefinition *dd)
{
  JsonNode *decoded;
  char *encoded;
  /* encode */
  NEXT_TEST("encoding invalid data");
  decoded = parseJson(BAD_DATA_D);
  encoded = encode(decoded, dd);
  EXPECT_FAILURE;
  delete_node(decoded);
  NEXT_TEST("encoding valid data: no error");
  decoded = parseJson(DATA_D);
  encoded = encode(decoded, dd);
  assert(encoded != NULL);
  EXPECT_NO_ERROR;
  delete_node(decoded);
  NEXT_TEST("encoding valid data: expected result");
  EXPECT_STR_EQ(encoded, DATA_E);
  /* unsafe_encode */
  NEXT_TEST("unsafe encoding valid data: no error");
  encoded = from_json(DATA_D, dd);
  EXPECT_NO_ERROR;
  NEXT_TEST("unsafe encoding valid data: expected result");
  EXPECT_STR_EQ(encoded, DATA_E);
  /* is_valid_decoded */
  NEXT_TEST("validating invalid decoded data");
  decoded = parseJson(BAD_DATA_D);
  EXPECT_FALSE(is_valid_decoded(decoded, dd));
  delete_node(decoded);
  NEXT_TEST("validating valid decoded data");
  decoded = parseJson(DATA_D);
  EXPECT_TRUE(is_valid_decoded(decoded, dd));
  delete_node(decoded);
}

void test_handling_decoded_json(DatatypeDefinition *dd)
{
  char *encoded;
  /* from_json */
  NEXT_TEST("encoding invalid Json data");
  encoded = from_json(BAD_DATA_D, dd);
  EXPECT_FAILURE;
  NEXT_TEST("encoding valid Json data: no error");
  encoded = from_json(DATA_D, dd);
  assert(encoded != NULL);
  EXPECT_NO_ERROR;
  NEXT_TEST("encoding valid Json data: expected result");
  EXPECT_STR_EQ(encoded, DATA_E);
  /* unsafe_from_json */
  NEXT_TEST("unsafe encoding valid Json data: no error");
  encoded = unsafe_from_json(DATA_D, dd);
  EXPECT_NO_ERROR;
  NEXT_TEST("unsafe encoding valid Json data: expected result");
  EXPECT_STR_EQ(encoded, DATA_E);
  /* is_valid_decoded_json */
  NEXT_TEST("validating invalid decoded Json data");
  EXPECT_FALSE(is_valid_decoded_json(BAD_DATA_D, dd));
  NEXT_TEST("validating valid decoded Json data");
  EXPECT_TRUE(is_valid_decoded_json(DATA_D, dd));
}

DatatypeDefinition* test_datatype_definition_api(Specification* spec) {
  DatatypeDefinition *result;
  /* get_definition */
  NEXT_TEST("loading non-existing datatype");
  result = get_definition(spec, NONEXISTING_DATA_TYPE);
  EXPECT_FAILURE;
  NEXT_TEST("loading valid specification");
  result = get_definition(spec, DATA_TYPE);
  EXPECT_NO_ERROR;
  assert(result != NULL);
  /* describe */
  NEXT_TEST("describe datatype definition");
  printf("\n%s\n", describe(result));
  EXPECT_NO_ERROR;
  return result;
}

Specification* test_specification_api() {
  Specification *result;
  /* specification_from_file */
  NEXT_TEST("loading specfile with syntax errors");
  result = specification_from_file(BAD_YAML_SPEC);
  EXPECT_FAILURE;
  NEXT_TEST("loading non-existing specfile");
  result = specification_from_file(NONEXISTING_SPEC);
  EXPECT_FAILURE;
  NEXT_TEST("loading valid specification");
  result = specification_from_file(YAML_SPEC);
  EXPECT_NO_ERROR;
  assert(result != NULL);
  /* is_preprocessed */
  NEXT_TEST("is_preprocessed on non-existing file");
  is_preprocessed(NONEXISTING_SPEC);
  EXPECT_FAILURE;
  NEXT_TEST("is_preprocessed on YAML file");
  EXPECT_FALSE(is_preprocessed(YAML_SPEC));
  EXPECT_NO_ERROR;
  /* test_specification */
  NEXT_TEST("run failing specification tests");
  test_specification(result, BADTEST);
  EXPECT_FAILURE;
  NEXT_TEST("run specification tests");
  test_specification(result, GOODTEST);
  EXPECT_NO_ERROR;
  /* datatype_names */
  NEXT_TEST("datatype_names");
  char *names = datatype_names(result);
  printf("datatype names: %s\n", names);
  EXPECT_NO_ERROR;
  return result;
}

void test_encoded_file_decoding_settings(DatatypeDefinition *dd_line,
                                         DatatypeDefinition *dd_line_failing,
                                         DatatypeDefinition *dd_unit,
                                         DatatypeDefinition *dd_section,
                                         DatatypeDefinition *dd_file)
{
  NEXT_TEST("get_scope");
  EXPECT_STR_EQ(get_scope(dd_line), "undefined");
  EXPECT_STR_EQ(get_scope(dd_line_failing), "line");
  EXPECT_STR_EQ(get_scope(dd_unit), "unit");
  EXPECT_STR_EQ(get_scope(dd_section), "section");
  EXPECT_STR_EQ(get_scope(dd_file), "file");
  EXPECT_NO_ERROR;
  NEXT_TEST("set_scope");
  set_scope(dd_line_failing, "laine");
  EXPECT_FAILURE;
  set_scope(dd_line_failing, "unit");
  EXPECT_STR_EQ(get_scope(dd_line_failing), "unit");
  set_scope(dd_line_failing, "line");
  EXPECT_NO_ERROR;
  NEXT_TEST("get_unitsize");
  EXPECT_INT_EQ(get_unitsize(dd_unit), 3);
  EXPECT_INT_EQ(get_unitsize(dd_section), 1);
  EXPECT_NO_ERROR;
  NEXT_TEST("set_unitsize");
  set_unitsize(dd_unit, 0);
  EXPECT_FAILURE;
  set_unitsize(dd_unit, 2);
  EXPECT_NO_ERROR;
  EXPECT_INT_EQ(get_unitsize(dd_unit), 2);
  NEXT_TEST("get_wrapped");
  EXPECT_FALSE(get_wrapped(dd_line));
  EXPECT_NO_ERROR;
  NEXT_TEST("set_wrapped");
  set_wrapped(dd_line);
  EXPECT_TRUE(get_wrapped(dd_line));
  EXPECT_NO_ERROR;
  NEXT_TEST("unset_wrapped");
  unset_wrapped(dd_line);
  EXPECT_FALSE(get_wrapped(dd_line));
  EXPECT_NO_ERROR;
}

void value_processor(JsonNode* node, void* data)
{
  printf("Next decoded value found: '%s'\n", to_string(node));
}

void test_handling_encoded_files(Specification *spec)
{
  DatatypeDefinition *dd_line, *dd_line_failing,
                     *dd_unit, *dd_section, *dd_file;
  NEXT_TEST("loading line datatype");
  dd_line = get_definition(spec, DATA_TYPE_SCOPE_LINE);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading line_failing datatype");
  dd_line_failing = get_definition(spec, BAD_DATA_TYPE_SCOPE_LINE);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading unit datatype");
  dd_unit = get_definition(spec, DATA_TYPE_SCOPE_UNIT);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading section datatype");
  dd_section = get_definition(spec, DATA_TYPE_SCOPE_SECTION);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading file datatype");
  dd_file = get_definition(spec, DATA_TYPE_SCOPE_FILE);
  EXPECT_NO_ERROR;
  test_encoded_file_decoding_settings(dd_line, dd_line_failing,
                                      dd_unit, dd_section, dd_file);
  NEXT_TEST("decoding file values, scope undefined, failing");
  decode_file_values(DATAFILE, false, dd_line,
                     value_processor, NULL, false);
  EXPECT_FAILURE;
  NEXT_TEST("decoding file values, scope line, failing");
  decode_file_values(DATAFILE, false, dd_line_failing,
                     value_processor, NULL, false);
  EXPECT_FAILURE;
  NEXT_TEST("decoding file values, scope line");
  set_scope(dd_line, "line");
  decode_file_values(DATAFILE, false, dd_line,
                     value_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope line, wrapped");
  set_wrapped(dd_line);
  decode_file_values(DATAFILE, false, dd_line,
                     value_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope unit, failing");
  decode_file_values(DATAFILE, false, dd_unit,
                     value_processor, NULL, false);
  EXPECT_FAILURE;
  NEXT_TEST("decoding file values, scope unit");
  set_unitsize(dd_unit, 4);
  decode_file_values(DATAFILE, false, dd_unit,
                     value_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope section");
  decode_file_values(DATAFILE, false, dd_section,
                     value_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope section, elemwise");
  decode_file_values(DATAFILE, false, dd_section,
                     value_processor, NULL, true);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope file");
  decode_file_values(DATAFILE, false, dd_file,
                     value_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope file, elemwise");
  decode_file_values(DATAFILE, false, dd_file,
                     value_processor, NULL, true);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope file, embedded");
  decode_file_values(YAML_SPEC, true, dd_file,
                     value_processor, NULL, false);
  EXPECT_NO_ERROR;
  delete_definition(dd_line);
  delete_definition(dd_line_failing);
  delete_definition(dd_unit);
  delete_definition(dd_section);
  delete_definition(dd_file);
}

int main(void)
{
  Specification *spec;
  DatatypeDefinition* dd;
  NimMain();
  printf("Textformats C API tests");
  spec = test_specification_api();
  dd = test_datatype_definition_api(spec);
  test_handling_encoded_strings(dd);
  test_handling_decoded_data(dd);
  test_handling_decoded_json(dd);
  test_handling_encoded_files(spec);
  delete_definition(dd);
  delete_specification(spec);
  printf("\n==================================================");
  printf("================================================\n\n");
  printf("All tests ended successfully!\n\n");
  return 0;
}
