NIMVERSION=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${NIMVERSION}/lib
HTSLIBVERSION=1.13
HTSLIBDIR=/usr/local/anaconda3/pkgs/htslib-${HTSLIBVERSION}-hc38c3fb_0
DEFLATEDIR=/usr/local/anaconda3/pkgs/libdeflate-1.7-h35c211d_5

default: compare

PRJDIR=../../..

nimcache/textformats_c.h: ${PRJDIR}/C/textformats_c.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking \
	    	--header:textformats_c.h \
	    	--nimcache:nimcache $<

textformats_based: nimcache/textformats_c.h textformats_based.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o textformats_based.c

htslib_based: htslib_based.c
	gcc -DNDEBUG -o $@ -O3 -I${HTSLIBDIR}/include \
		-L${HTSLIBDIR}/lib -l hts.${HTSLIBVERSION} htslib_based.c

INPUT=${PRJDIR}/benchmarks/data/sam/100000.lines.sam

SPEC=${PRJDIR}/bio/spec/sam.yaml
DT=file
run_textformats_based: ${SPEC} ${INPUT} textformats_based
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@time ./textformats_based ${INPUT} ${SPEC} ${DT}

LD_LIBRARY_PATH=${HTSLIBDIR}/lib:${DEFLATEDIR}/lib
run_htslib_based: ${INPUT} htslib_based
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       htslib_based"
	@time env LD_LIBRARY_PATH=${LD_LIBRARY_PATH} ./htslib_based ${INPUT}

compare: ${INPUT} textformats_based htslib_based
	@echo "Input file: ${INPUT}"
	@echo ""
	@echo "Running textformats_based:"
	@time ./textformats_based ${INPUT} ${SPEC} ${DT} > textformats_based.out
	@echo ""
	@echo "Running htslib_based:"
	@time env LD_LIBRARY_PATH=${LD_LIBRARY_PATH} \
		./htslib_based ${INPUT} > htslib_based.out
	@echo ""
	@diff textformats_based.out htslib_based.out
	@echo "The two versions of the program produced the same output"

clean:
	rm -rf nimcache textformats_based.out htslib_based.out

cleanup: clean
	rm -rf textformats_based htslib_based 

