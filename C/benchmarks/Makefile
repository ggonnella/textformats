VERSION=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

default: run

nimcache/c_api.h: ../c_api.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking --header:c_api.h \
	    	--nimcache:nimcache ../c_api.nim

parse_cigars: nimcache/c_api.h parse_cigars.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o parse_cigars.c

run: parse_cigars parse_cigars.sh
	./parse_cigars.sh

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf results parse_cigars

