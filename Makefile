AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame
ROMDIR=/home/moffitt/.mame/roms/metalbj

ASFLAGS=-i . -n -U

.PHONY: metalbj

all: prg.bin

prg.orig: d12-12.8 d12-11.7 d12-07.9 d12-06.6
	$(BSPLIT) c orig/d12-12.8 orig/d12-11.7 prg1
	$(BSPLIT) c orig/d12-07.9 orig/d12-06.6 prg2
	cat prg1 prg2 > prg.orig
	rm prg1 prg2

prg.o: prg.orig
	$(AS) $(SRC) $(ASFLAGS) -o prg.o

prg.bin: prg.o
	$(P2BIN) $< $@ -r \$$-0xBFFFF
	split prg.bin -b 262144
	cat xaa xab > prg1
	mv xac prg2
	$(BSPLIT) s prg1 d12-12.8 d12-11.7
	$(BSPLIT) s prg2 d12-07.9 d12-06.6
	rm prg1 prg2 prg.o

test: prg.bin
	$(MAME) -debug metalbj

clean:
	@-rm prg.bin
	@-rm prg.o
	@-rm prg.orig
	@-cp orig/* .
