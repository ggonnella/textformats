#include "c_api.h"
#include <stdio.h>

int main(void)
{
  /* (1) initialize Nim library */
  NimMain();

  char *encoded = "1M100D1I2M3M4M";
  printf("Encoded: %s\n", encoded);

  /* (2) parse specification and get datatype definition  */
  Specification *spec = specification_from_file(
      "../../bio/benchmarks/cigars/cigar.datatypes.yaml");
  DatatypeDefinition *datatype = get_definition(spec, "cigar");

  /* (3) decode to a "node", convert to_string() */
  JsonNode *node = decode(encoded, datatype);
  printf("%s\n", to_string(node));

  /* (4) tell the GC that the references are not used anymore */
  delete_node(node);
  delete_specification(spec);
  delete_definition(datatype);

  return 0;
}
