
gfa2_info:
	nim c gfa2_info.nim

benchmark: gfa2_info
	time ./gfa2_info ../../python/examples/gfa2_info/GRCh38-20-0.10b.gfa2 ../../spec/gfa/gfa2.yaml

example: gfa2_info
	./gfa2_info ../../tests/testdata/bio/test.gfa2 ../../spec/gfa/gfa2.yaml

invalid: gfa2_info
	./gfa2_info ../../python/examples/gfa2_info/invalid.gfa2 ../../spec/gfa/gfa2.yaml || true
