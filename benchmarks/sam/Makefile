all: run

INPUTDIR=../data/sam
INPUTFN=1000000.lines.sam
INPUT=${INPUTDIR}/${INPUTFN}

${INPUT}:
	cd ${INPUTDIR} && make ${INPUTFN} && make clean

textformats_based htslib_based:
	nimble build

run: ${INPUT} textformats_based htslib_based
	nimble compare

cleanup:
	rm -f htslib_based textformats_based
