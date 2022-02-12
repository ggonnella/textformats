NIMLIB:=$(shell ../../scripts/find_nimbase.sh)

TIME=time
N_TIMES=3

default: run

PRJDIR=../../..

nimcache/textformats_c.h: ${PRJDIR}/C/textformats_c.nim
	nim c -d:danger --noMain --noLinking \
	    	--header:textformats_c.h \
	    	--nimcache:nimcache $<

%: %.c nimcache/textformats_c.h
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o $< -lm

clean:
	rm -f large.egc large.json egc.tfs converted.egc nimcache

cleanup: clean
	rm -r -f json2egc egc2json

DATADIR=${PRJDIR}/python/examples/egc
INPUT=${DATADIR}/example.egc
SPEC=${DATADIR}/egc.yaml

run:
	@echo "Preparing input data"
	@rm -f large.egc
	@touch large.egc
	@for i in {1..910}; do \
	  	cat ${INPUT} >> large.egc; \
	 done
	@echo
	@echo "EGC encoding and decoding test"
	@echo
	@echo "(1) decode EGC file to JSON file"
	@${TIME} ./egc2json large.egc ${SPEC} > large.json
	@echo
	@echo "(2) write EGC file from JSON data"
	@${TIME} ./json2egc large.json ${SPEC} > converted.egc
	@echo
	@echo "(3) compare output EGC file to input EGC file"
	@echo
	@diff -q large.egc converted.egc && echo "No differences found."
	@echo
