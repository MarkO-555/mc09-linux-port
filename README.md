# Dunfield Micro-C 6809 Toolchain — Linux Port

A Linux port of Dave Dunfield's **Micro-C** cross-compiler toolchain for the
Motorola 6809, originally a DOS-only product.

Original source: [Dunfield Development Services / Dave's Old Computers](https://dunfield.themindfactory.com)  
Released as freeware. See `copy.txt` in the original archives for licence terms.

---

## Tools included

| Tool | Source | Description |
|------|--------|-------------|
| `cc09` | `cc09.c` | **Command coordinator** — runs the full pipeline in one command |
| `mcc09` | `compile.c` + `io.c` + `6809cg.c` | Micro-C 6809 cross-compiler (K&R C subset → 6809 asm) |
| `mco09` | `mco.c` + `6809.mco` | Peephole optimizer (post-processes mcc09 output) |
| `asm09` | `asm09.c` | 6809 cross-assembler (→ Motorola S-records or Intel HEX) |
| `slink` | `slink.c` | Source linker — resolves `$EX:` externals from lib09/ |
| `slib` | `slib.c` | Source library manager (inspect/modify EXTINDEX.LIB) |
| `sindex` | `sindex.c` | Source index builder (generates EXTINDEX.LIB from .ASM files) |
| `sconvert` | `sconvert.c` | Source converter (prepares .ASM files for use as library modules) |
| `mc09pp` | `mc09pp` (Python) | Minimal slink substitute for standalone testing without lib09 |

**Not yet ported** (DOS binaries only, source available):
- `mcp` — full C preprocessor (cc09 uses it with `-P` flag; mcc09 has a basic built-in preprocessor that handles most cases)
- `make` — Dunfield's simple make utility (use GNU make instead)
- `macro` — assembly macro pre-processor (used with cc09's `-M` flag)

**No source, DOS-only:**
- `ddside` — integrated development environment (GUI, not portable)
- `srenum`, `sreg`, `touch` — minor utilities (trivially replaced by standard tools)

---

## Build

```sh
make
```

Requires only `gcc` and `make`. The sources are K&R C compiled with
`-std=gnu89` and `-Wno-*` flags to suppress the expected implicit-declaration
warnings endemic to the Dunfield codebase.

---

## Toolchain pipeline

### Manual (maximum control)

```
  prog.c
     │
     ▼  mcc09 -I./include prog.c prog.asm
  prog.asm          (Dunfield source-linked asm format, contains $EX: directives)
     │
     ▼  [mco09 prog.asm prog_opt.asm]   (optional peephole optimizer)
     │
     ▼  slink prog.asm s=CRT0.ASM l=./lib09 prog_linked.asm
  prog_linked.asm   (runtime prepended, $EX: resolved, ?-labels uniquified)
     │
     ▼  asm09 prog_linked.asm -I l=prog.lst c=prog.HEX
  prog.HEX          (Intel or Motorola HEX)
  prog.lst          (annotated listing)
```

### Via cc09 coordinator (recommended)

```sh
export MCDIR=/path/to/mc09-linux-port   # tools location
export MCINCLUDE=$MCDIR/include          # target headers
export MCLIBDIR=$MCDIR/lib09            # target runtime library

cc09 prog.c               # compile, link, assemble → prog.HEX (Motorola)
cc09 prog.c -Oq           # with optimizer, quiet
cc09 prog.c -Iq S=CRT0.ASM  # Intel hex, custom startup (e.g. usim09 target)
```

`cc09` accepts:
| Flag | Effect |
|------|--------|
| `-O` | Run `mco09` peephole optimizer |
| `-I` | Intel HEX output (default: Motorola S-records) |
| `-q` | Quiet mode |
| `-C` | Include C source as comments in assembly |
| `-S` | Emit symbolic debug information |
| `-K` | Keep temporary files |
| `S=file` | Override startup file (passed to slink as `s=`) |
| `H=path` | Override MCDIR (tool home directory) |
| `T=prefix` | Temp file prefix |

---

## Targets

### Default (`lib09/`)
Code starts at `$2000`, stack at `$8000`, no reset vector.
Matches Dunfield's original RAM-based monitor system.

```sh
MCLIBDIR=./lib09 cc09 prog.c -q
```

### usim09 (`targets/usim09/lib09/`)
Code in ROM at `$E000`, stack at `$7F00`, MC6850 ACIA at `$C000`,
reset vector at `$FFFE`. Matches `usim09` hardcoded memory map.

```sh
MCDIR=. MCINCLUDE=./include MCLIBDIR=./targets/usim09/lib09 \
  cc09 prog.c -Iq S=CRT0.ASM

echo "" | usim09 prog.HEX
```

Run `make test-usim` to see the full pipeline including simulator execution.

### Adding a new target
1. Create `targets/<name>/lib09/` 
2. Write `CRT0.ASM` — override `6809RLP.ASM` (ORG, LDS, startup, runtime)
3. Write `SERIO.ASM` — override serial I/O for your UART
4. Write `6809RLS.ASM` — override suffix (reset vector, heap marker)
5. Copy remaining files from `lib09/` or symlink them
6. Build with `MCLIBDIR=./targets/<name>/lib09 cc09 prog.c -Iq S=CRT0.ASM`

The three files that almost always need customisation per target:
- **CRT0.ASM** — `ORG` (code base), `LDS` (stack top), exit behaviour
- **SERIO.ASM** — UART base address, status/data register layout, ready bits  
- **6809RLS.ASM** — reset vector address and value

---

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `MCDIR` | `./` | Directory containing tools (`cc09` searches here first, then `PATH`) |
| `MCINCLUDE` | — | Include search path for `mcc09` (alternative to `-I` flag) |
| `MCLIBDIR` | `$MCDIR/lib09` | Runtime library directory for `slink` |

---

## make targets

| Target | Description |
|--------|-------------|
| `make` | Build all eight tools |
| `make test` | Manual pipeline: hello.c → slink → asm09 → HEX |
| `make test-usim` | cc09 single-command: hello_clean.c → usim09 simulator |
| `make clean` | Remove binaries and generated files |
| `make install` | Install to `PREFIX` (default `/usr/local`) |

---

## Linux porting notes — all fixes applied

### Compiler (`mcc09`): compile.c, io.c, 6809cg.c

1. **`abort(msg)`** — Dunfield's signature takes a message string; ANSI `abort()` takes none. Routed via `#define abort(msg) die(msg)` macro in `portab.h`.

2. **CRLF stripping** — DOS line endings stripped in `get_lin()` (compiler reads source) and `MC_fgets()` (assembler/linker read source).

3. **`#CPU` stringize** — K&R token-pasting `"foo"#MACRO"bar"` is not valid in modern cpp. Replaced with `STRINGIFY()` double-macro in `io.c` and `mco.c`.

4. **`skip_comment()` 16-bit window** — The `/* */` comment scanner uses a two-character sliding window in `unsigned x`. On DOS `unsigned` is 16 bits; on LP64 it is 32 bits and the `*/` pattern never matches, causing the scanner to consume parent source after `#include` boundaries. Fixed: `unsigned short x`.

5. **Block comments spanning `#include` boundaries** — When `skip_comment()` exhausts an included file, `read_char()` crossed the file boundary and consumed the parent source. Fixed: `in_comment` counter + `*/` sentinel injected on include pop-back.

6. **`-I` include path option** — `f_open()` now strips `<>` and `""` delimiters, searches the `-I` path and `MCINCLUDE` env var in addition to CWD.

### Assembler (`asm09`): asm09.c

7. **`optr` array index** — declared `char`, used as index into `operand[200]`. Values >127 wrap negative. Fixed: `int`.

8. **`itype`/`otype`/`post` opcode fields** — declared `char`, hold values `0x81`–`0x8a` which are >127. Fixed: `unsigned char`.

9. **`isterm()` missing `\n`** — `fgets()` includes the trailing newline; `eval()` saw `\n` as an unknown operator and fired "invalid expression syntax" after every correctly-assembled line. Fixed: added `\n`, `\r`, `\;` to `isterm()`.

10. **`symtab`/`symtop` pointer types** — symbol table declared `char[]` but compared against `unsigned char *` pointers. Fixed: `unsigned char symtab[]`, `unsigned char *symtop`.

### Source linker (`slink`): slink.c, microc.h

11. **`sp_top` initialiser** — `= &string_pool` (pointer-to-array) should be `= string_pool` (array decay).

12. **`DIRSEP` and default library path** — `'\\'` → `'/'`; `"\\MC\\SLIB"` → `"./lib09"`.

13. **`strbeg()`** — Dunfield Micro-C built-in (string prefix test) absent from standard libraries. Added to `microc.h`.

### Library tools (`slib`, `sindex`, `sconvert`): microc.h

14. **`udata[25] = 0`** — invalid array initialiser; fixed to `= ""`.

15. **Multi-char constant option switches** — `case 'q-':` etc. are implementation-defined in GCC. Rewrote as explicit `if`/`else if` chains.

16. **DOS `fopen` modes** — `"rv"`, `"wvq"`, `"rvq"` → `"r"`, `"w"`, `"r"`.

17. **`sindex` directory traversal** — DOS `find_first()`/`find_next()` replaced with POSIX `glob()`.

### Command coordinator (`cc09`): cc09.c

18. **`exec(cmd, args)`** — DOS API; replaced with `mc_exec()` using `fork()`/`execvp()`.

19. **`getenv(name, buf)`** — DOS two-argument form; adapted to POSIX one-argument `getenv()` via inline wrapper.

20. **`link`, `dup` variable names** — clash with POSIX `link()` and `dup()` from `unistd.h`. Renamed to `do_link`, `do_dup`.

21. **Path separators, `.EXE`/`.COM` suffixes** — all updated for Linux.

22. **`MCLIBDIR` env var** — added to decouple the tools directory (`MCDIR`) from the target runtime library (`lib09/`), enabling per-target builds without relocating tools.

### Optimizer (`mco09`): mco.c

23. **`#include "PC86.mco"`** → `#include "6809.mco"` — point at the 6809 optimization table.
