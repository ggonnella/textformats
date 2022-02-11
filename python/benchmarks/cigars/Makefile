default: compare

TIME=time

PRJDIR=../../..
INPUT=${PRJDIR}/benchmarks/data/cigars/100k_cigars_len100

SPEC=${PRJDIR}/benchmarks/data/cigars/cigars.yaml
DT=cigar_str
run_textformats_based: ${SPEC} ${INPUT} textformats_based.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@${TIME} ./textformats_based.py ${INPUT} ${SPEC} ${DT}

run_ad_hoc: ${INPUT} ad_hoc.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       ad_hoc"
	@${TIME} ./ad_hoc.py ${INPUT}

compare: ${INPUT} textformats_based.py ad_hoc.py
	@echo "Input file: ${INPUT}"
	@echo ""
	@echo "Running ad_hoc:"
	@${TIME} ./ad_hoc.py ${INPUT} > ad_hoc.out
	@echo ""
	@echo "Running textformats_based:"
	@${TIME} ./textformats_based.py ${INPUT} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@diff textformats_based.out ad_hoc.out
	@echo "The two versions of the program produced the same output"

clean:
	rm -rf nimcache textformats_based.out ad_hoc.out
