VERSION:=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

default: run_test

nimcache/c_api.h: ../c_api.nim
	nim c --gc:mark_and_sweep --d:danger --noMain \
		    --noLinking --header:c_api.h \
	    	--nimcache:nimcache ../c_api.nim

%: nimcache/c_api.h %.c
	gcc -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o $@.c

run_test: test_c_api
	./test_c_api

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf test_c_api

