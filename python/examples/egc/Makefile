default: setup run

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

DATADIR=.
INPUT=${DATADIR}/example.egc
SPEC=${DATADIR}/egc.yaml

TIME=time

clean:
	rm -f large.egc large.json egc.tfs converted.egc \
		    *.lines.egc *.out.egc *.json

cleanup: clean
	rm -r -f __pycache__

run_tf_%:
	@if [[ ! -e $*.lines.egc ]]; then echo "run 'make setup' first"; false; fi
	@echo "======================================================"
	@echo
	@echo "EGC test: $* lines, TextFormats-based"
	@echo
	@echo "(1) decode EGC file to JSON file"
	@${TIME} ./egc2json.py $*.lines.egc ${SPEC} > $*.json
	@echo
	@echo "(2) write EGC file from JSON data"
	@${TIME} ./json2egc.py $*.json ${SPEC} > $*.out.egc
	@echo
	@echo "(3) compare output EGC file to input EGC file"
	@echo
	@diff -q $*.lines.egc $*.out.egc && echo "No differences found."
	@echo

run_ah_%:
	@if [[ ! -e $*.lines.egc ]]; then echo "run 'make setup' first"; false; fi
	@echo "======================================================"
	@echo
	@echo "EGC test: $* lines, ad-hoc"
	@echo
	@echo "(1) decode EGC file to JSON file"
	@${TIME} ./egc2json_ad_hoc.py $*.lines.egc > $*.json
	@echo
	@echo "(2) write EGC file from JSON data"
	@${TIME} ./json2egc_ad_hoc.py $*.json > $*.out.egc
	@echo
	@echo "(3) compare output EGC file to input EGC file"
	@echo
	@diff -q $*.lines.egc $*.out.egc && echo "No differences found."
	@echo

run: run_tf_100000 run_tf_500000 run_tf_1000000 \
	   run_ah_100000 run_ah_500000 run_ah_1000000
