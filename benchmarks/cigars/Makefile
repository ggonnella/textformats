default: compare

PRJDIR=../..
INPUTDIR=${PRJDIR}/benchmarks/data/cigars
INPUTFN=100k_cigars_len100
INPUT=${INPUTDIR}/${INPUTFN}

${INPUT}:
	cd ${INPUTDIR} && make ${INPUTFN}

textformats_based: textformats_based.nim
	nim c $<

ad_hoc: ad_hoc.nim
	nim c $<

TIME=time

SPEC=${PRJDIR}/benchmarks/data/cigars/cigars.yaml
DT=cigar_str
run_textformats_based: ${SPEC} ${INPUT} textformats_based
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Output file:   textformats_based.out"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@${TIME} ./textformats_based ${INPUT} ${SPEC} ${DT} > textformats_based.out

run_ad_hoc: ${INPUT} ad_hoc
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Output file:   ad_hoc.out"
	@>&2 echo "# Program:       ad_hoc"
	@${TIME} ./ad_hoc ${INPUT} > ad_hoc.out

compare: ${INPUT} textformats_based ad_hoc
	@echo "Input file: ${INPUT}"
	@echo ""
	@echo "Running ad_hoc:"
	@${TIME} ./ad_hoc ${INPUT} > ad_hoc.out
	@echo ""
	@echo "Running textformats_based:"
	@${TIME} ./textformats_based ${INPUT} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@diff textformats_based.out ad_hoc.out
	@echo "The two versions of the program produced the same output"

clean:
	rm -rf nimcache textformats_based.out ad_hoc.out

cleanup: clean
	rm -rf ad_hoc textformats_based
