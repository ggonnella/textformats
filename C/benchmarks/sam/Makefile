NIMLIB:=$(shell ../../scripts/find_nimbase.sh)

HTSLIBVERSION=1.13
DEFLATEVERSION=1.7

CONDADIR_MAC=/usr/local/anaconda3
HTSLIBHASH_MAC=hc38c3fb_0
DEFLATEHASH_MAC=h35c211d_5

CONDADIR_LINUX=/home/gonnella/tools/miniconda/3
HTSLIBHASH_LINUX=h9093b5e_0
DEFLATEHASH_LINUX=h7f98852_5

CONDADIR=${CONDADIR_LINUX}
HTSLIBHASH=${HTSLIBHASH_LINUX}
DEFLATEHASH=${DEFLATEHASH_LINUX}

# =====> Paths to the HTS and Deflate libraries <=====
HTSLIBDIR=${CONDADIR}/pkgs/htslib-${HTSLIBVERSION}-${HTSLIBHASH}
DEFLATEDIR=${CONDADIR}/pkgs/libdeflate-${DEFLATEVERSION}-${DEFLATEHASH}

LD_LIBRARY_PATH=${HTSLIBDIR}/lib:${DEFLATEDIR}/lib

default: compare

PRJDIR=../../..

nimcache/textformats_c.h: ${PRJDIR}/C/textformats_c.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking \
	    	--header:textformats_c.h \
	    	--nimcache:nimcache $<

textformats_based: nimcache/textformats_c.h textformats_based.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o textformats_based.c -lm

htslib_based: htslib_based.c
	env LD_LIBRARY_PATH=${LD_LIBRARY_PATH} gcc -DNDEBUG -o $@ -O3 \
		-I${HTSLIBDIR}/include \
		-L${HTSLIBDIR}/lib htslib_based.c -lhts -lm

INPUTDIR=${PRJDIR}/benchmarks/data/sam
INPUT=${INPUTDIR}/100000.lines.sam

${INPUT}:
	cd ${INPUTDIR} && make ${INPUT}

SPEC=${PRJDIR}/spec/sam.yaml
DT=file
run_textformats_based: ${SPEC} ${INPUT} textformats_based
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Input file:    ${INPUT}"
	@>&2 echo "# Program:       textformats_based"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@time ./textformats_based ${INPUT} ${SPEC} ${DT}

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

