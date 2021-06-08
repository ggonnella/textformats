NIMLIB:=${HOME}/.choosenim/toolchains/nim-1.2.6/lib

default: test

nimcache/jsonwrap.h: ../jsonwrap.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking --header:jsonwrap.h \
	    	--nimcache:nimcache ../jsonwrap.nim

jsonwrap_test: nimcache/jsonwrap.h jsonwrap_test.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o jsonwrap_test.c

.PHONY: test clean cleanup

test: jsonwrap_test expected.out
	./jsonwrap_test | diff - expected.out
	@echo "test passed"

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf jsonwrap_test

