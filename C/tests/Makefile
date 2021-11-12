default: test
.PHONY: test clean cleanup

NIMLIB:=$(shell ../scripts/find_nimbase.sh)

nimcache/textformats_c.h: ../textformats_c.nim
	nim c --gc:mark_and_sweep --d:danger --noMain \
		    --noLinking --header:textformats_c.h \
	    	--nimcache:nimcache ../textformats_c.nim

nimcache/jsonwrap.h: ../jsonwrap.nim
	nim c --gc:mark_and_sweep -d:danger --noMain \
		    --noLinking --header:jsonwrap.h \
	    	--nimcache:nimcache ../jsonwrap.nim

test_%: nimcache/%.h test_%.c
	gcc -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o $@.c -lm

run_%_test: test_%
	@./test_${*} 2> test_${*}.err > test_${*}.out
	@diff test_${*}.out test_${*}.expected_out
	@if [ $$? -eq 0 ]; then rm test_${*}.out; fi
	@diff test_${*}.err test_${*}.expected_err
	@if [ $$? -eq 0 ]; then rm test_${*}.err; fi
	@echo "${*} module test passed"

test: run_jsonwrap_test run_textformats_c_test

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf test_textformats_c test_jsonwrap
