#include "textformats_c.h"
#include <stdio.h>
#include <assert.h>

int main(void)
{
  /* (1) initialize Nim library */
  NimMain();

  char *encoded = "1M100D1I2M3M4M",
       *encoded_wrong = "1M;100D1I2M3M4M";
  printf("Encoded: %s\n", encoded);

  /* (2) parse specification and get datatype definition  */
  Specification *spec = tf_specification_from_file(
      "../../benchmarks/data/cigars/cigars.yaml");
  DatatypeDefinition *datatype = tf_get_definition(spec, "cigar");

  /* (3) decode to a "node", convert to_string() */
  JsonNode *node = tf_decode(encoded, datatype);
  assert(!tf_haderr);
  printf("[Decoding succeeded]\n%s\n", jsonnode_to_string(node));
  delete_jsonnode(node);

  /* (4) failing decode example */
  node = tf_decode(encoded_wrong, datatype);
  assert(tf_haderr);
  assert(node == NULL);
  printf("[%s, as expected]\n%s\n", tf_errname, tf_errmsg);
  tf_unseterr();
  assert(!tf_haderr);

  /* (5) tell the GC that the references are not used anymore */
  tf_delete_specification(spec);
  tf_delete_definition(datatype);

  return 0;
}
