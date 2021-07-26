default: run

DATADIR=../../benchmarks/data
SPEC=${DATADIR}/cigar.datatypes.yaml
DT=cigar
INPUT=${DATADIR}/100k_cigars_len100
OUTPUT=results

run: ${SPEC} ${INPUT} decode_lines.py
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@>&2 echo "#   Input file:    ${INPUT}"
	@>&2 echo "#   Output file:   ${OUTPUT}"
	@>&2 echo "# ... parsing cigars ..."
	@time ./decode_lines.py ${SPEC} ${DT} ${INPUT} decode > ${OUTPUT}

clean:
	@echo ""

cleanup:
	rm -rf results

