#include "jsonwrap.h"
#include "stdbool.h"
#include "stdio.h"

typedef void JsonNode;

void test_null_node() {
  printf("Test NullNode:\n");
  JsonNode *node = newJNull();
  printf("%s\n", to_string(node));
  GC_unref_node(node);
  printf("\n\n");
}

void test_bool_node() {
  printf("Test BoolNode:\n");
  JsonNode *node = newJBool(true);
  printf("%s\n", to_string(node));
  if (getBool(node))
    printf("value read from node is: true\n");
  GC_unref_node(node);
  printf("\n\n");
}

void test_int_node() {
  printf("Test IntNode:\n");
  JsonNode *node = newJInt(-10);
  printf("%s\n", to_string(node));
  printf("value read from node is: %li\n", getInt(node));
  GC_unref_node(node);
  printf("\n\n");
}

void test_float_node() {
  printf("Test FloatNode:\n");
  JsonNode *node = newJFloat(1.0);
  printf("%s\n", to_string(node));
  printf("value read from node is: %f\n", getFloat(node));
  GC_unref_node(node);
  printf("\n\n");
}

void test_string_node() {
  printf("Test StringNode:\n");
  JsonNode *node = newJString("Hello, world!");
  printf("%s\n", to_string(node));
  char *s = getStr(node);
  printf("value read from node is: \"%s\"\n", s);
  s[0]='B';
  printf("changed char 0 to B\n");
  printf("node content is now: %s\n", getStr(node));
  GC_unref_node(node);
  printf("\n\n");
}

void fill_array(JsonNode* node) {
  JsonNode *item;
  JArray_add(node, newJNull());
  JArray_add(node, newJBool(true));
  JArray_add(node, newJInt(1));
  JArray_add(node, newJFloat(1.0));
  JArray_add(node, newJString("str"));
  item = newJArray();
  JArray_add(item, newJBool(false));
  JArray_add(item, newJInt(-1));
  JArray_add(item, newJFloat(-1.0));
  JArray_add(item, newJString("rts"));
  JArray_add(node, item);
  item = newJObject();
  JObject_add(item, "b", newJBool(false));
  JObject_add(item, "i", newJInt(-1));
  JObject_add(item, "f", newJFloat(-1.0));
  JObject_add(item, "s", newJString("rts"));
  JArray_add(node, item);
}

void test_array_node() {
  printf("Test ArrayNode:\n");
  JsonNode *node = newJArray();
  printf("Before calling fill_array: %s\n", to_string(node));
  fill_array(node);
  printf("%s\n", to_string(node));
  printf("array length: %lu\n", len(node));
  printf("str value for index 3: %s\n", to_string(JArray_get(node, 3)));
  printf("int value for index 3: %li\n", getInt(JArray_get(node, 3)));
  printf("\n\n");
  GC_unref_node(node);
}

void fill_object(JsonNode* node) {
  JObject_add(node, "n", newJNull());
  JObject_add(node, "b", newJBool(false));
  JObject_add(node, "i", newJInt(1));
  JObject_add(node, "f", newJFloat(1.0));
  JObject_add(node, "s", newJString("str"));
  JObject_add(node, "e", newJArray());
  JsonNode *item = newJArray();
  JArray_add(item, newJInt(1));
  JArray_add(item, newJFloat(2.0));
  JArray_add(item, newJString("3"));
  JObject_add(node, "a", item);
}

void test_object_node() {
  printf("Test ObjectNode:\n");
  JsonNode *node = newJObject();
  printf("Before calling fill_object: %s\n", to_string(node));
  fill_object(node);
  printf("%s\n", to_string(node));
  printf("str value of key \"f\": %s\n", to_string(JObject_get(node, "f")));
  printf("float value of key \"f\": %f\n", getFloat(JObject_get(node, "f")));
  printf("changing value to 2.0...\n");
  JObject_add(node, "f", newJFloat(2.0));
  printf("float value of key \"f\": %f\n", getFloat(JObject_get(node, "f")));
  printf("\n\n");
  GC_unref_node(node);
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

