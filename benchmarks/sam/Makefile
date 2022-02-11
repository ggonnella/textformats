all: compare

INPUTDIR=../data/sam
INPUT1FN=100000.lines.sam
INPUT2FN=500000.lines.sam
INPUT2FN=1000000.lines.sam
INPUT1=${INPUTDIR}/${INPUT1FN}
INPUT2=${INPUTDIR}/${INPUT2FN}
INPUT3=${INPUTDIR}/${INPUT3FN}

${INPUT1}:
	cd ${INPUTDIR} && make ${INPUT1FN} && make clean

${INPUT2}:
	cd ${INPUTDIR} && make ${INPUT2FN} && make clean

${INPUT3}:
	cd ${INPUTDIR} && make ${INPUT3FN} && make clean

textformats_based htslib_based:
	nimble build

compare: ${INPUT1} textformats_based htslib_based
	nimble compare

compare_full: ${INPUT1} ${INPUT2} ${INPUT3} textformats_based htslib_based
	nimble compare_full

cleanup:
	rm -f htslib_based textformats_based
