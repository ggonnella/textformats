VERSION:=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

default: run

nimcache/c_api.h: ../c_api.nim
	nim c --gc:mark_and_sweep --d:danger --noMain \
		    --noLinking --header:c_api.h \
	    	--nimcache:nimcache ../c_api.nim

small_example: nimcache/c_api.h small_example.c
	gcc -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o small_example.c

run: small_example
	./small_example

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf small_example

