default: test
.PHONY: test clean cleanup

VERSION:=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

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
		nimcache/*.o $@.c

run_jsonwrap_test: test_jsonwrap
	@./test_jsonwrap | diff - test_jsonwrap.expected_out
	@echo "jsonwrap module test passed"

run_textformats_c_test: test_textformats_c
	@./test_textformats_c 2>&1 | diff - test_textformats_c.expected_out
	@echo "textformats_c module test passed"

test: run_jsonwrap_test run_textformats_c_test

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf test_textformats_c test_jsonwrap
