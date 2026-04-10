# Makefile for Dunfield Micro-C 6809 cross-compiler toolchain — Linux port
#
# Targets:
#   make            build mcc09 and asm09
#   make test       compile hello.c end-to-end (no runtime, standalone)
#   make test-rt    compile test_arith.c with the Dunfield lib09 runtime
#   make clean      remove build outputs (keeps sources)
#   make install    install tools to PREFIX (default /usr/local)

PREFIX    ?= /usr/local

CC        = gcc
CFLAGS    = -std=gnu89 \
            -Wno-implicit-int \
            -Wno-implicit-function-declaration \
            -Wno-pointer-sign \
            -Wno-return-type \
            -Wno-unused-function \
            -I.

.PHONY: all test test-rt clean install

all: mcc09 asm09

# ── build ──────────────────────────────────────────────────────────────────

mcc09: compile.c io.c 6809cg.c compile.h tokens.h portab.h
	$(CC) $(CFLAGS) -DCPU=6809 -o $@ compile.c io.c 6809cg.c

asm09: asm09.c xasm.h portab.h
	$(CC) $(CFLAGS) -o $@ asm09.c

# ── smoke tests ────────────────────────────────────────────────────────────

# Minimal hello — no runtime; putstr resolves to a $DEAD stub.
# Good for verifying the compiler and assembler without needing lib09.
test: mcc09 asm09
	@echo "=== Compiling hello.c ==="
	./mcc09 -I./include hello.c hello.asm
	@echo "=== Post-processing (standalone, no runtime) ==="
	./mc09pp hello.asm > hello_pp.asm
	@echo "=== Assembling ==="
	./asm09 hello_pp.asm l=hello.lst c=hello.HEX
	@echo "=== hello.HEX (Motorola S-records) ==="
	@cat hello.HEX

# Full build with lib09 runtime — resolves ?mul, ?div, ?ult, ?ule, etc.
# test_arith.c exercises loops, unsigned comparisons, and function calls.
test-rt: mcc09 asm09
	@echo "=== Compiling test_arith.c ==="
	./mcc09 test_arith.c test_arith.asm
	@echo "=== Post-processing with runtime ==="
	./mc09pp --rt lib09_runtime.asm test_arith.asm > test_arith_pp.asm
	@echo "=== Assembling ==="
	./asm09 test_arith_pp.asm l=test_arith.lst c=test_arith.HEX
	@echo "=== test_arith.HEX (Motorola S-records) ==="
	@cat test_arith.HEX

# ── install ────────────────────────────────────────────────────────────────

install: mcc09 asm09
	install -d $(PREFIX)/bin $(PREFIX)/share/mc09/include
	install -m 755 mcc09 asm09 mc09pp $(PREFIX)/bin/
	install -m 644 include/*.h        $(PREFIX)/share/mc09/include/
	@echo ""
	@echo "Installed to $(PREFIX)/bin:  mcc09  asm09  mc09pp"
	@echo "Headers:     $(PREFIX)/share/mc09/include/"
	@echo "Tip: export MCINCLUDE=$(PREFIX)/share/mc09/include"

# ── clean ──────────────────────────────────────────────────────────────────
# Removes compiler/assembler binaries and generated intermediates.
# Source files (*.c, *.h, mc09pp, lib09_runtime.asm, include/) are kept.

clean:
	rm -f mcc09 asm09
	rm -f hello.asm hello_pp.asm hello.lst hello.HEX
	rm -f test_arith.asm test_arith_pp.asm test_arith.lst test_arith.HEX
	rm -f *.o
