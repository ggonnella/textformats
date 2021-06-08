#include "c_api.h"
#include <stdio.h>

int main(void)
{
  void *table, *mydef, *node;
  const char *encoded = "1M100D1I2M3M4M";
  printf("Encoded: %s\n", encoded);
  NimMain();
  table = parse_specification("../../data/cigars/cigar.datatypes.yaml");
  mydef = get_definition(table, "cigar");
  node = decode((char*)encoded, mydef);
  printf("%s\n", to_string(node));
  GC_unref_node(node);
  return 0;
}
