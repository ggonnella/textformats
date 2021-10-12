#include "textformats_c.h"
#include <stdio.h>
#include <assert.h>

int main(void)
{
  /* (1) initialize Nim library */
  NimMain();

  char *encoded = "1M100D1I2M3M4M",
       *encoded_wrong = "1M;100D1I2M3M4M",
       *decoded = "[{\"length\":100,\"code\":\"M\"},"\
                   "{\"length\":10, \"code\":\"D\"}]";

  /* (2) parse specification and get datatype definition  */
  Specification *spec = tf_specification_from_file(
      "../../benchmarks/data/cigars/cigars.yaml");
  assert(!tf_haderr);
  DatatypeDefinition *datatype = tf_get_definition(spec, "cigar_str");
  assert(!tf_haderr);

  /* (3) decode to a "node", convert to_string() */
  JsonNode *node = tf_decode(encoded, datatype);
  assert(!tf_haderr);
  printf("[Decoding succeeded]\n%s\n", jsonnode_to_string(node));
  delete_jsonnode(node);

  /* (4) encode json to text representation */
  char *textrepr = tf_encode_json(decoded, datatype);
  assert(!tf_haderr);
  printf("[Encoding succeeded]\n%s\n", textrepr);

  /* (5) failing decode example */
  node = tf_decode(encoded_wrong, datatype);
  assert(tf_haderr);
  assert(node == NULL);
  printf("[%s, as expected]\n%s\n", tf_errname, tf_errmsg);
  tf_unseterr();
  assert(!tf_haderr);

  /* (6) tell the GC that the references are not used anymore */
  tf_delete_specification(spec);
  tf_delete_definition(datatype);

  return 0;
}
