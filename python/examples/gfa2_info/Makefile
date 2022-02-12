N_TIMES=3
TIME=time

help:
	@echo
	@echo To run the gfa_info script using a mini example which does
	@echo not require further setup or downloads do:
	@echo
	@echo "  make mini"
	@echo
	@echo To test the cross-validator on a small example with multiple issues:
	@echo
	@echo "  make invalid"
	@echo
	@echo Forthe comparative analysis the Python library \"gfapy\" is needed.
	@echo Furthermore, for a larger real-life example, a compressed GFA1 file is
	@echo downloaded, then decompressed and converted to GFA2. To obtain the
	@echo file and the check the gfapy installation, do the following before
	@echo "the first call of other commands (except mini and invalid):"
	@echo
	@echo "  make setup"
	@echo
	@echo To show the information on the larger file using
	@echo the textformats-based version use:
	@echo
	@echo "  make run"
	@echo
	@echo Then compare the results with textformats to those with gfapy:
	@echo
	@echo "  make compare"
	@echo
	@echo To repeat ${N_TIMES} times the comparative analysis
	@echo and measure execution time:
	@echo
	@echo "  make benchmark"
	@echo

GRC_URL=ftp://ftp.dfci.harvard.edu/pub/hli/minigraph
GRC_FN=GRCh38-20-0.10b
MINI_EXAMPLE_FN=../../../tests/testdata/bio/test.gfa2
SPEC=../../../spec/gfa/gfa2.yaml

.PRECIOUS: ${FN}.gfa

setup: ${GRC_FN}.gfa2
	@echo "Install Python GfaPy library"
	pip install gfapy

${GRC_FN}.gfa.gz:
	@echo "Download compressed GFA file..."
	wget ${GRC_URL}/${GRC_FN}.gfa.gz

${GRC_FN}.gfa: ${GRC_FN}.gfa.gz
	@echo "Decompress compressed GFA file..."
	gunzip ${GRC_FN}.gfa.gz

${GRC_FN}.gfa2: ${GRC_FN}.gfa
	@echo "Convert GFA1 to GFA2..."
	gfapy-convert ${GRC_FN}.gfa > ${GRC_FN}.gfa2

mini:
	@echo "Run gfa2_info with a small example file"
	./gfa2_info.py \
		../../../tests/testdata/bio/test.gfa2 \
		../../../spec/gfa/gfa2.yaml

invalid:
	@echo "Run gfa2_info on an invalid GFA2 file"
	./gfa2_info.py invalid.gfa2 \
		../../../spec/gfa/gfa2.yaml || echo "[Invalid as expected]"

run:
	./gfa2_info.py ${GRC_FN}.gfa2 ${SPEC}

compare:
	@echo "============================================================"
	@echo
	@echo "Run the comparative analysis..."
	@echo
	@echo "=== TextFormats-based gfa2_info"
	@echo
	./gfa2_info.py ${GRC_FN}.gfa2 ${SPEC} > textformats_based.out
	@echo
	@echo "=== GfaPy-based gfa2_info"
	@echo
	./gfa2_info_gfapy_based.py ${GRC_FN}.gfa2 > gfapy_based.out
	@echo
	@diff textformats_based.out gfapy_based.out
	@echo "The two versions of the program produced the same output"

benchmark:
	@echo "============================================================"
	@echo
	@echo "Run the benchmark..."
	@echo
	@echo "=== TextFormats-based gfa2_info"
	@echo
	@for ((i=0;i<${N_TIMES};i++)); do \
		echo "=== $$[i+1]/${N_TIMES} ==="; \
	  ${TIME} ./gfa2_info.py ${GRC_FN}.gfa2 ${SPEC} > textformats_based.out; \
		echo ""; \
	done
	@echo
	@echo "=== GfaPy-based gfa2_info"
	@echo
	@for ((i=0;i<${N_TIMES};i++)); do \
		echo "=== $$[i+1]/${N_TIMES} ==="; \
	  ${TIME} ./gfa2_info_gfapy_based.py ${GRC_FN}.gfa2 > gfapy_based.out; \
		echo ""; \
	done
	@diff textformats_based.out gfapy_based.out
	@echo "The two versions of the program produced the same output"
