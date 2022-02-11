default: compare

PRJDIR=../../..
INPUTDIR=${PRJDIR}/benchmarks/data/sam
INPUT_1=${INPUTDIR}/100000.lines.sam
TIME=time

SPEC=${PRJDIR}/spec/sam.yaml
DT=file
run_textformats_based: ${SPEC} ${INPUT_1} textformats_based.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT_1}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@${TIME} ./textformats_based.py ${INPUT_1} ${SPEC} ${DT}

run_htslib_based: ${INPUT} htslib_based.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT_1}"
	@>&2 echo "# Program:       htslib_based"
	@${TIME} ./htslib_based.py ${INPUT}

compare: ${INPUT} textformats_based.py htslib_based.py
	@echo "Input file: ${INPUT_1}"
	@echo ""
	@echo "Running htslib_based:"
	@${TIME} ./htslib_based.py ${INPUT_1} > htslib_based.out
	@echo ""
	@echo "Running textformats_based:"
	@${TIME} ./textformats_based.py ${INPUT_1} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@diff textformats_based.out htslib_based.out
	@echo "The two versions of the program produced the same output"

N_TIMES=3

compare_full_%: ${INPUTDIR}/%.lines.sam textformats_based.py htslib_based.py
	@echo "============================================================"
	@echo "Input file: $<"
	@echo ""
	@echo "Running htslib_based:"
	@echo ""
	@for ((i=0;i<${N_TIMES};i++)); do \
		echo "=== $$[i+1]/${N_TIMES} ==="; \
		${TIME} ./htslib_based.py $< > htslib_based.out; \
		echo ""; \
	done
	@echo ""
	@echo "Running textformats_based:"
	@echo ""
	@for ((i=0;i<${N_TIMES};i++)); do \
		echo "=== $$[i+1]/${N_TIMES} ==="; \
	  ${TIME} ./textformats_based.py $< ${SPEC} ${DT} > textformats_based.out; \
		echo ""; \
	done
	@echo ""
	@diff textformats_based.out htslib_based.out
	@echo "The two versions of the program produced the same output"

compare_full: compare_full_100000 compare_full_500000 compare_full_1000000

clean:
	rm -rf nimcache textformats_based.out htslib_based.out

cleanup: clean
	rm -rf __pycache__
