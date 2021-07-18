#include "textformats_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include "testing_macros.h"

#define YAML_SPEC        "testdata/fasta.yaml"
#define PREPROC_SPEC     "testdata/fasta.tfs"
#define BAD_YAML_SPEC    "testdata/wrong_yaml_syntax.yaml"
#define NONEXISTING_SPEC "testdata/xyz.yaml"
#define TESTFILE         "testdata/good_test.yaml"
#define BAD_TESTFILE     "testdata/bad_test.yaml"

#define YAML_SPEC_STR      "{datatypes: {x: {constant: \"x\"}}}"
#define BAD_YAML_SPEC_STR  "{datatypes: {x: [}}"
#define TESTDATA_STR       "{testdata: {x: {valid: [\"x\"], invalid: [\"y\"]}}}"
#define BAD_TESTDATA_STR   "{testdata: {x: {valid: [\"y\"]}}}"

#define DATA_TYPE             "header"
#define NONEXISTING_DATA_TYPE "heder"

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

void test_handling_encoded_strings(DatatypeDefinition *dd)
{
  JsonNode *decoded;
  char *decoded_json;
  /* decode */
  NEXT_TEST("decoding invalid data");
  decoded = tf_decode(BAD_DATA_E, dd);
  EXPECT_FAILURE;
  NEXT_TEST("decoding valid data: no error");
  decoded = tf_decode(DATA_E, dd);
  assert(decoded != NULL);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding valid data: expected result");
  EXPECT_JSONSTR_EQ(decoded, DATA_D);
  delete_jsonnode(decoded);
  /* to_json */
  NEXT_TEST("decoding invalid data to json");
  decoded_json = tf_decode_to_json(BAD_DATA_E, dd);
  EXPECT_FAILURE;
  NEXT_TEST("decoding valid data to json: no error");
  decoded_json = tf_decode_to_json(DATA_E, dd);
  assert(decoded_json != NULL);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding valid data to json: expected result");
  EXPECT_STR_EQ(decoded_json, DATA_D);
  /* is_valid_encoded */
  NEXT_TEST("validating invalid encoded data");
  EXPECT_FALSE(tf_is_valid_encoded(BAD_DATA_E, dd));
  NEXT_TEST("validating valid encoded data");
  EXPECT_TRUE(tf_is_valid_encoded(DATA_E, dd));
}

void test_handling_decoded_data(DatatypeDefinition *dd)
{
  JsonNode *decoded;
  char *encoded;
  /* encode */
  NEXT_TEST("encoding invalid data");
  decoded = jsonnode_from_string(BAD_DATA_D);
  encoded = tf_encode(decoded, dd);
  EXPECT_FAILURE;
  delete_jsonnode(decoded);
  NEXT_TEST("encoding valid data: no error");
  decoded = jsonnode_from_string(DATA_D);
  encoded = tf_encode(decoded, dd);
  assert(encoded != NULL);
  EXPECT_NO_ERROR;
  delete_jsonnode(decoded);
  NEXT_TEST("encoding valid data: expected result");
  EXPECT_STR_EQ(encoded, DATA_E);
  /* is_valid_decoded */
  NEXT_TEST("validating invalid decoded data");
  decoded = jsonnode_from_string(BAD_DATA_D);
  EXPECT_FALSE(tf_is_valid_decoded(decoded, dd));
  delete_jsonnode(decoded);
  NEXT_TEST("validating valid decoded data");
  decoded = jsonnode_from_string(DATA_D);
  EXPECT_TRUE(tf_is_valid_decoded(decoded, dd));
  delete_jsonnode(decoded);
}

void test_handling_decoded_json(DatatypeDefinition *dd)
{
  char *encoded;
  /* from_json */
  NEXT_TEST("encoding invalid Json data");
  encoded = tf_encode_json(BAD_DATA_D, dd);
  EXPECT_FAILURE;
  NEXT_TEST("encoding valid Json data: no error");
  encoded = tf_encode_json(DATA_D, dd);
  assert(encoded != NULL);
  EXPECT_NO_ERROR;
  NEXT_TEST("encoding valid Json data: expected result");
  EXPECT_STR_EQ(encoded, DATA_E);
  /* is_valid_decoded_json */
  NEXT_TEST("validating invalid decoded Json data");
  EXPECT_FALSE(tf_is_valid_decoded_json(BAD_DATA_D, dd));
  NEXT_TEST("validating valid decoded Json data");
  EXPECT_TRUE(tf_is_valid_decoded_json(DATA_D, dd));
}

DatatypeDefinition* test_datatype_definition_api(Specification* spec) {
  DatatypeDefinition *result;
  /* tf_get_definition */
  NEXT_TEST("loading non-existing datatype");
  result = tf_get_definition(spec, NONEXISTING_DATA_TYPE);
  EXPECT_FAILURE;
  NEXT_TEST("loading valid specification");
  result = tf_get_definition(spec, DATA_TYPE);
  EXPECT_NO_ERROR;
  assert(result != NULL);
  /* describe */
  NEXT_TEST("describe datatype definition");
  printf("\n%s\n", tf_describe(result));
  EXPECT_NO_ERROR;
  return result;
}

Specification* test_specification_api() {
  Specification *result;
  /* parse_specification */
  NEXT_TEST("parsing invalid specification string");
  result = tf_parse_specification(BAD_YAML_SPEC_STR);
  EXPECT_FAILURE;
  NEXT_TEST("parsing valid specification string");
  result = tf_parse_specification(YAML_SPEC_STR);
  EXPECT_NO_ERROR;
  assert(result != NULL);
  /* preprocess_specification */
  NEXT_TEST("preprocessing specfile");
  tf_preprocess_specification(YAML_SPEC, PREPROC_SPEC);
  EXPECT_NO_ERROR;
  /* specification_from_file */
  NEXT_TEST("loading specfile with syntax errors");
  result = tf_specification_from_file(BAD_YAML_SPEC);
  EXPECT_FAILURE;
  NEXT_TEST("loading non-existing specfile");
  result = tf_specification_from_file(NONEXISTING_SPEC);
  EXPECT_FAILURE;
  NEXT_TEST("loading valid preproc specification");
  result = tf_specification_from_file(PREPROC_SPEC);
  EXPECT_NO_ERROR;
  assert(result != NULL);
  tf_delete_specification(result);
  NEXT_TEST("loading valid YAML specification");
  result = tf_specification_from_file(YAML_SPEC);
  EXPECT_NO_ERROR;
  assert(result != NULL);
  /* is_preprocessed */
  NEXT_TEST("is_preprocessed on non-existing file");
  tf_is_preprocessed(NONEXISTING_SPEC);
  EXPECT_FAILURE;
  NEXT_TEST("is_preprocessed on YAML file");
  EXPECT_FALSE(tf_is_preprocessed(YAML_SPEC));
  EXPECT_NO_ERROR;
  NEXT_TEST("is_preprocessed on preproc file");
  EXPECT_TRUE(tf_is_preprocessed(PREPROC_SPEC));
  EXPECT_NO_ERROR;
  /* run_specification_testfile */
  NEXT_TEST("run failing specification testfile");
  tf_run_specification_testfile(result, BAD_TESTFILE);
  EXPECT_FAILURE;
  NEXT_TEST("run specification testfile");
  tf_run_specification_testfile(result, TESTFILE);
  EXPECT_NO_ERROR;
  NEXT_TEST("run failing specification testfile on preproc spec");
  result = tf_specification_from_file(PREPROC_SPEC);
  EXPECT_NO_ERROR;
  tf_run_specification_testfile(result, BAD_TESTFILE);
  EXPECT_FAILURE;
  NEXT_TEST("run specification testfile on preproc spec");
  tf_run_specification_testfile(result, TESTFILE);
  EXPECT_NO_ERROR;
  tf_delete_specification(result);
  /* run_specification_tests */
  NEXT_TEST("run failing specification tests from string");
  result = tf_parse_specification(YAML_SPEC_STR);
  EXPECT_NO_ERROR;
  tf_run_specification_tests(result, BAD_TESTDATA_STR);
  EXPECT_FAILURE;
  NEXT_TEST("run specification tests from string");
  tf_run_specification_tests(result, TESTDATA_STR);
  EXPECT_NO_ERROR;
  /* datatype_names */
  NEXT_TEST("datatype_names");
  char *names, *name;
  result = tf_specification_from_file(YAML_SPEC);
  names = tf_datatype_names(result);
  EXPECT_NO_ERROR;
  printf("\ndatatype names:\n");
  name = strtok(names, " ");
  while (name != NULL) {
    printf("  - %s\n", name);
    name = strtok(NULL, " ");
  }
  return result;
}

void test_encoded_file_decoding_settings(DatatypeDefinition *dd_line,
                                         DatatypeDefinition *dd_line_failing,
                                         DatatypeDefinition *dd_unit,
                                         DatatypeDefinition *dd_section,
                                         DatatypeDefinition *dd_file)
{
  NEXT_TEST("tf_get_scope");
  EXPECT_STR_EQ(tf_get_scope(dd_line), "undefined");
  EXPECT_STR_EQ(tf_get_scope(dd_line_failing), "line");
  EXPECT_STR_EQ(tf_get_scope(dd_unit), "unit");
  EXPECT_STR_EQ(tf_get_scope(dd_section), "section");
  EXPECT_STR_EQ(tf_get_scope(dd_file), "file");
  EXPECT_NO_ERROR;
  NEXT_TEST("tf_set_scope");
  tf_set_scope(dd_line_failing, "laine");
  EXPECT_FAILURE;
  tf_set_scope(dd_line_failing, "unit");
  EXPECT_STR_EQ(tf_get_scope(dd_line_failing), "unit");
  tf_set_scope(dd_line_failing, "line");
  EXPECT_NO_ERROR;
  NEXT_TEST("tf_get_unitsize");
  EXPECT_INT_EQ(tf_get_unitsize(dd_unit), 3);
  EXPECT_INT_EQ(tf_get_unitsize(dd_section), 1);
  EXPECT_NO_ERROR;
  NEXT_TEST("set_unitsize");
  tf_set_unitsize(dd_unit, 0);
  EXPECT_FAILURE;
  tf_set_unitsize(dd_unit, 2);
  EXPECT_NO_ERROR;
  EXPECT_INT_EQ(tf_get_unitsize(dd_unit), 2);
  NEXT_TEST("tf_get_wrapped");
  EXPECT_FALSE(tf_get_wrapped(dd_line));
  EXPECT_NO_ERROR;
  NEXT_TEST("tf_set_wrapped");
  tf_set_wrapped(dd_line);
  EXPECT_TRUE(tf_get_wrapped(dd_line));
  EXPECT_NO_ERROR;
  NEXT_TEST("tf_unset_wrapped");
  tf_unset_wrapped(dd_line);
  EXPECT_FALSE(tf_get_wrapped(dd_line));
  EXPECT_NO_ERROR;
}

void decoded_processor(JsonNode* node, void* data)
{
  printf("Next decoded value found: '%s'\n", jsonnode_to_string(node));
}

void test_handling_encoded_files(Specification *spec)
{
  DatatypeDefinition *dd_line, *dd_line_failing,
                     *dd_unit, *dd_section, *dd_file;
  NEXT_TEST("loading line datatype");
  dd_line = tf_get_definition(spec, DATA_TYPE_SCOPE_LINE);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading line_failing datatype");
  dd_line_failing = tf_get_definition(spec, BAD_DATA_TYPE_SCOPE_LINE);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading unit datatype");
  dd_unit = tf_get_definition(spec, DATA_TYPE_SCOPE_UNIT);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading section datatype");
  dd_section = tf_get_definition(spec, DATA_TYPE_SCOPE_SECTION);
  EXPECT_NO_ERROR;
  NEXT_TEST("loading file datatype");
  dd_file = tf_get_definition(spec, DATA_TYPE_SCOPE_FILE);
  EXPECT_NO_ERROR;
  test_encoded_file_decoding_settings(dd_line, dd_line_failing,
                                      dd_unit, dd_section, dd_file);
  NEXT_TEST("decoding file values, scope undefined, failing");
  tf_decode_file(DATAFILE, false, dd_line,
                 decoded_processor, NULL, false);
  EXPECT_FAILURE;
  NEXT_TEST("decoding file values, scope line, failing");
  tf_decode_file(DATAFILE, false, dd_line_failing,
                 decoded_processor, NULL, false);
  EXPECT_FAILURE;
  NEXT_TEST("decoding file values, scope line");
  tf_set_scope(dd_line, "line");
  tf_decode_file(DATAFILE, false, dd_line,
                 decoded_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope line, wrapped");
  tf_set_wrapped(dd_line);
  tf_decode_file(DATAFILE, false, dd_line,
                 decoded_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope unit, failing");
  tf_decode_file(DATAFILE, false, dd_unit,
                 decoded_processor, NULL, false);
  EXPECT_FAILURE;
  NEXT_TEST("decoding file values, scope unit");
  tf_set_unitsize(dd_unit, 4);
  tf_decode_file(DATAFILE, false, dd_unit,
                 decoded_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope section");
  tf_decode_file(DATAFILE, false, dd_section,
                 decoded_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope section, elemwise");
  tf_decode_file(DATAFILE, false, dd_section,
                 decoded_processor, NULL, true);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope file");
  tf_decode_file(DATAFILE, false, dd_file,
                 decoded_processor, NULL, false);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope file, elemwise");
  tf_decode_file(DATAFILE, false, dd_file,
                 decoded_processor, NULL, true);
  EXPECT_NO_ERROR;
  NEXT_TEST("decoding file values, scope file, embedded");
  tf_decode_file(YAML_SPEC, true, dd_file,
                 decoded_processor, NULL, false);
  EXPECT_NO_ERROR;
  tf_delete_definition(dd_line);
  tf_delete_definition(dd_line_failing);
  tf_delete_definition(dd_unit);
  tf_delete_definition(dd_section);
  tf_delete_definition(dd_file);
}

int main(void)
{
  Specification *spec;
  DatatypeDefinition* dd;
  NimMain();
  printf("TextFormats C API tests");
  spec = test_specification_api();
  dd = test_datatype_definition_api(spec);
  test_handling_encoded_strings(dd);
  test_handling_decoded_data(dd);
  test_handling_decoded_json(dd);
  test_handling_encoded_files(spec);
  tf_delete_definition(dd);
  tf_delete_specification(spec);
  printf("\n==================================================");
  printf("================================================\n\n");
  printf("All tests ended successfully!\n\n");
  return 0;
}
