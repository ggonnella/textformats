VERSION:=1.4.8
NIMLIB:=${HOME}/.choosenim/toolchains/nim-${VERSION}/lib

default: run

nimcache/textformats_c.h: ../textformats_c.nim
	nim c --gc:mark_and_sweep --d:danger --noMain \
		    --noLinking --header:textformats_c.h \
	    	--nimcache:nimcache ../textformats_c.nim

%_example: nimcache/textformats_c.h %_example.c
	gcc -o $@ -O3 -Inimcache -I${NIMLIB} \
		nimcache/*.o $@.c

run: small_example large_example
	./large_example
	./small_example

clean:
	rm -rf nimcache

cleanup: clean
	rm -rf small_example
	rm -rf large_example

