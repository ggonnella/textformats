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
	rm -rf large.egc egc.tfs converted.egc nimcache \
		    *.lines.egc *.json *.out.egc

cleanup: clean
	rm -f json2egc egc2json

DATADIR=${PRJDIR}/python/examples/egc
INPUT=${DATADIR}/example.egc
SPEC=${DATADIR}/egc.yaml

setup:
	@echo "Preparing input data"
	@rm -f large.egc
	@touch large.egc
	@for i in {1..18200}; do \
	  	cat ${INPUT} >> large.egc; \
	 done
	@head -n 100000 large.egc > 100000.lines.egc
	@head -n 500000 large.egc > 500000.lines.egc
	@head -n 1000000 large.egc > 1000000.lines.egc
	@echo

run_%:
	@if [[ ! -e $*.lines.egc ]]; then echo "run 'make setup' first"; false; fi
	@echo "======================================================"
	@echo
	@echo "EGC test: $* lines"
	@echo
	@echo "(1) decode EGC file to JSON file"
	@${TIME} ./egc2json $*.lines.egc ${SPEC} > $*.json
	@echo
	@echo "(2) write EGC file from JSON data"
	@${TIME} ./json2egc $*.json ${SPEC} > $*.out.egc
	@echo
	@echo "(3) compare output EGC file to input EGC file"
	@echo
	@diff -q $*.lines.egc $*.out.egc && echo "No differences found."
	@echo

run: egc2json json2egc run_100000 run_500000 run_1000000
