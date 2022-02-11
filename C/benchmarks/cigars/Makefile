default: compare

TIME=time

NIMLIB:=$(shell ../../scripts/find_nimbase.sh)

PRJDIR=../../..

nimcache/textformats_c.h: ${PRJDIR}/C/textformats_c.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking \
	    	--header:textformats_c.h --nimcache:nimcache $<

textformats_based: nimcache/textformats_c.h textformats_based.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o textformats_based.c -lm

ad_hoc: ad_hoc.c
	gcc -DNDEBUG -o $@ -O3 $<

INPUTDIR=${PRJDIR}/benchmarks/data/cigars
INPUT=${INPUTDIR}/100k_cigars_len100

${INPUT}:
	cd ${INPUTDIR} && make $(shell basename ${INPUT})

SPEC=${PRJDIR}/benchmarks/data/cigars/cigars.yaml
DT=cigar_str
run_textformats_based: ${SPEC} ${INPUT} textformats_based
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@${TIME} ./textformats_based ${SPEC} ${DT} ${INPUT}

run_ad_hoc: ${INPUT} ad_hoc
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       ad_hoc"
	@${TIME} ./ad_hoc ${INPUT}

compare: ${INPUT} textformats_based ad_hoc
	@echo "Input file: ${INPUT}"
	@echo ""
	@echo "Running textformats_based:"
	@${TIME} ./textformats_based ${INPUT} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@echo "Running ad_hoc:"
	@${TIME} ./ad_hoc ${INPUT} > ad_hoc.out
	@echo ""
	@diff textformats_based.out ad_hoc.out
	@echo "The two versions of the program produced the same output"

clean:
	rm -rf nimcache textformats_based.out ad_hoc.out

cleanup: clean
	rm -rf textformats_based ad_hoc

