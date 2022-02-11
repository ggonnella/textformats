default: compare

PRJDIR=../../..
INPUT=${PRJDIR}/benchmarks/data/sam/100000.lines.sam

SPEC=${PRJDIR}/spec/sam.yaml
DT=file
run_textformats_based: ${SPEC} ${INPUT} textformats_based.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@time ./textformats_based.py ${INPUT} ${SPEC} ${DT}

run_htslib_based: ${INPUT} htslib_based.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       htslib_based"
	@time ./htslib_based.py ${INPUT}

compare: ${INPUT} textformats_based.py htslib_based.py
	@echo "Input file: ${INPUT}"
	@echo ""
	@echo "Running htslib_based:"
	@time ./htslib_based.py ${INPUT} > htslib_based.out
	@echo ""
	@echo "Running textformats_based:"
	@time ./textformats_based.py ${INPUT} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@diff textformats_based.out htslib_based.out
	@echo "The two versions of the program produced the same output"

clean:
	rm -rf nimcache textformats_based.out htslib_based.out

cleanup: clean
	rm -rf __pycache__
