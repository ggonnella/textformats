default: compare

PRJDIR=../..
INPUT=${PRJDIR}/benchmarks/data/cigars/100k_cigars_len100

textformats_based: textformats_based.nim
	nim c $<

ad_hoc: ad_hoc.nim
	nim c $<

SPEC=${PRJDIR}/benchmarks/data/cigars/cigars.yaml
DT=cigar_str
run_textformats_based: ${SPEC} ${INPUT} textformats_based
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@time ./textformats_based ${INPUT} ${SPEC} ${DT}

run_ad_hoc: ${INPUT} ad_hoc
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       ad_hoc"
	@time ./ad_hoc ${INPUT}

compare: ${INPUT} textformats_based ad_hoc
	@echo "Input file: ${INPUT}"
	@echo ""
	@echo "Running textformats_based:"
	@time ./textformats_based ${INPUT} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@echo "Running ad_hoc:"
	@time ./ad_hoc ${INPUT} > ad_hoc.out
	@echo ""
	@diff textformats_based.out ad_hoc.out
	@echo "The two versions of the program produced the same output"

clean:
	rm -rf nimcache textformats_based.out ad_hoc.out

cleanup: clean
	rm -rf ad_hoc textformats_based
