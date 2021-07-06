VERSION=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

default: run

nimcache/textformats_c.h: ../textformats_c.nim
	nim c -d:danger --gc:mark_and_sweep --noMain --noLinking --header:textformats_c.h \
	    	--nimcache:nimcache ../textformats_c.nim

parse_cigars: nimcache/textformats_c.h parse_cigars.c
	gcc -DNDEBUG -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o parse_cigars.c

run: parse_cigars parse_cigars.sh
	./parse_cigars.sh

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf results parse_cigars

