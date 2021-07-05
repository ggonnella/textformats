#include <stdbool.h>
#include <stdio.h>
#include <assert.h>
#include "jsonwrap.h"
#include "jsonkind.h"

void test_null_node() {
  printf("Test NullNode:\n");
  JsonNode *node = new_j_null();
  assert(json_node_kind(node) == J_NULL);
  printf("%s\n", jsonnode_to_string(node));
  delete_jsonnode(node);
  printf("\n\n");
}

void test_bool_node() {
  printf("Test BoolNode:\n");
  JsonNode *node = new_j_bool(true);
  assert(json_node_kind(node) == J_BOOL);
  printf("%s\n", jsonnode_to_string(node));
  if (j_bool_get(node))
    printf("value read from node is: true\n");
  delete_jsonnode(node);
  printf("\n\n");
}

void test_int_node() {
  printf("Test IntNode:\n");
  JsonNode *node = new_j_int(-10);
  assert(json_node_kind(node) == J_INT);
  printf("%s\n", jsonnode_to_string(node));
  printf("value read from node is: %li\n", j_int_get(node));
  delete_jsonnode(node);
  printf("\n\n");
}

void test_float_node() {
  printf("Test FloatNode:\n");
  JsonNode *node = new_j_float(1.0);
  assert(json_node_kind(node) == J_FLOAT);
  printf("%s\n", jsonnode_to_string(node));
  printf("value read from node is: %f\n", j_float_get(node));
  delete_jsonnode(node);
  printf("\n\n");
}

void test_string_node() {
  printf("Test StringNode:\n");
  JsonNode *node = new_j_string("Hello, world!");
  assert(json_node_kind(node) == J_STRING);
  printf("%s\n", jsonnode_to_string(node));
  char *s = j_string_get(node);
  printf("value read from node is: \"%s\"\n", s);
  s[0]='B';
  printf("changed char 0 to B\n");
  printf("node content is now: %s\n", j_string_get(node));
  delete_jsonnode(node);
  printf("\n\n");
}

void fill_array(JsonNode* node) {
  JsonNode *item;
  j_array_add(node, new_j_null());
  j_array_add(node, new_j_bool(true));
  j_array_add(node, new_j_int(1));
  j_array_add(node, new_j_float(1.0));
  j_array_add(node, new_j_string("str"));
  item = new_j_array();
  j_array_add(item, new_j_bool(false));
  j_array_add(item, new_j_int(-1));
  j_array_add(item, new_j_float(-1.0));
  j_array_add(item, new_j_string("rts"));
  j_array_add(node, item);
  item = new_j_object();
  j_object_add(item, "b", new_j_bool(false));
  j_object_add(item, "i", new_j_int(-1));
  j_object_add(item, "f", new_j_float(-1.0));
  j_object_add(item, "s", new_j_string("rts"));
  j_array_add(node, item);
}

void test_array_node() {
  printf("Test ArrayNode:\n");
  JsonNode *node = new_j_array();
  assert(json_node_kind(node) == J_ARRAY);
  printf("Before calling fill_array: %s\n", jsonnode_to_string(node));
  fill_array(node);
  printf("%s\n", jsonnode_to_string(node));
  printf("array length: %lu\n", j_array_len(node));
  printf("str value for index 3: %s\n", jsonnode_to_string(j_array_get(node, 3)));
  printf("int value for index 3: %li\n", j_int_get(j_array_get(node, 3)));
  printf("\n\n");
  delete_jsonnode(node);
}

void fill_object(JsonNode* node) {
  j_object_add(node, "n", new_j_null());
  j_object_add(node, "b", new_j_bool(false));
  j_object_add(node, "i", new_j_int(1));
  j_object_add(node, "f", new_j_float(1.0));
  j_object_add(node, "s", new_j_string("str"));
  j_object_add(node, "e", new_j_array());
  JsonNode *item = new_j_array();
  j_array_add(item, new_j_int(1));
  j_array_add(item, new_j_float(2.0));
  j_array_add(item, new_j_string("3"));
  j_object_add(node, "a", item);
}

void test_object_node() {
  printf("Test ObjectNode:\n");
  JsonNode *node = new_j_object();
  assert(json_node_kind(node) == J_OBJECT);
  printf("Before calling fill_object: %s\n", jsonnode_to_string(node));
  fill_object(node);
  printf("%s\n", jsonnode_to_string(node));
  printf("str value of key \"f\": %s\n", jsonnode_to_string(j_object_get(node, "f")));
  printf("float value of key \"f\": %f\n", j_float_get(j_object_get(node, "f")));
  printf("changing value to 2.0...\n");
  j_object_add(node, "f", new_j_float(2.0));
  printf("float value of key \"f\": %f\n", j_float_get(j_object_get(node, "f")));
  printf("\n\n");
  delete_jsonnode(node);
}

int main() {
  NimMain();
  test_null_node();
  test_bool_node();
  test_int_node();
  test_float_node();
  test_string_node();
  test_array_node();
  test_object_node();
  return 0;
}

