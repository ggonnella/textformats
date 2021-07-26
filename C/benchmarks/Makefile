VERSION=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

default: run

nimcache/textformats_c.h: ../textformats_c.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking \
	    	--header:textformats_c.h \
	    	--nimcache:nimcache ../textformats_c.nim

decode_lines: nimcache/textformats_c.h decode_lines.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o decode_lines.c

DATADIR=../../benchmarks/data
SPEC=${DATADIR}/cigars.yaml
DT=cigar_str
INPUT=${DATADIR}/100k_cigars_len100
OUTPUT=results

run: ${SPEC} ${INPUT} decode_lines
	@>&2 echo "### Running benchmark ###"
	@>&2 echo "# Parameters:"
	@>&2 echo "#   Specification: ${SPEC}"
	@>&2 echo "#   Datatype:      ${DT}"
	@>&2 echo "#   Input file:    ${INPUT}"
	@>&2 echo "#   Output file:   ${OUTPUT}"
	@>&2 echo "# ... parsing cigars ..."
	@time ./decode_lines ${SPEC} ${DT} ${INPUT} decode > ${OUTPUT}

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf results parse_cigars

