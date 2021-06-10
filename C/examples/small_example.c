#include "c_api.h"
#include <stdio.h>

int main(void)
{
  void *spec, *datatype, *node;
  const char *encoded = "1M100D1I2M3M4M";
  printf("Encoded: %s\n", encoded);

  /* (1) initialize Nim library (at program begin) */
  NimMain();

  /* (2) parse specification and get datatype definition  */
  spec = parse_specification(
      "../../bio/benchmarks/cigars/cigar.datatypes.yaml");
  datatype = get_definition(spec, "cigar");

  /* (3) decode to a "node", convert to_string(), release memory */
  node = decode((char*)encoded, datatype);
  printf("%s\n", to_string(node));
  GC_unref_node(node);

  return 0;
}
