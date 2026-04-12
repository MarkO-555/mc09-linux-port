# Dunfield Micro-C 6809 Toolchain — Linux Port

A Linux port of Dave Dunfield's **Micro-C** cross-compiler toolchain for the
Motorola 6809, originally a DOS-only product.

Original source: [Dunfield Development Services / Dave's Old Computers](https://dunfield.themindfactory.com)  
Released as freeware. See `COPY.TXT` in the original archives for licence terms.

---

### Why?

Micro‑C is one of those things that’s really relevant to telling the story of Dave. Since I like telling a story, I figured the best way to do that was to make it easier for more people to actually experience it.  I do know that Dave even built a VM called the DVM (Dunfield Virtual Machine), and it can compile and run most of his software when you need it.  I do think even though that is the case this is still worthwile, simply in a "Because it was there" capacity.  This is simply just my attempt to get a good thing into the hands of people looking for it, and I hope I've done that here.

Micro‑C is very intentional in how it’s built. It’s bootstrapped, properly structured, and written in its own syntax. Whoever wrote it clearly cared about doing it right, and if you’ve ever read anything Dave has written, you know he cares a lot about doing things well. The C compiler that builds the 6809 kit runs on DOS and doesn’t assume anything about its environment. All the passes and tools are modular, single‑file pieces, most of them tiny .COM programs. That means you can set up a Micro‑C compiler on just about any memory footprint. Each stage writes to standard out, so you can pipe one pass into the next or dump to disk if you’re crawling along on a 256K machine. It’s a bygone way of building a compiler, and that alone makes it interesting.

Micro‑C is also a C compiler for microcomputers first. That sounds strange until you look at what it was trying to solve. C was a pretty rough language to run on embedded microcontrollers, I/O controllers, and single‑board computers. These machines didn’t have the big register sets, memory, or instruction sets you’d find on a minicomputer or timesharing system. And that minicomputer environment is exactly where C came from. It was written to make programs more efficient and portable, and of course to build UNIX.

Micro‑C flips the question around and asks: what can I do with what I have? It’s a small language that’s configurable, scalable, and useful. It lets you write a C program for that custom industrial controller you built for a client 13 years ago, the one that now needs an update because the automation uses a new relay. Micro‑C was written to do Dave’s work, consulting work, and honestly because Dave likes writing his own software. And it shows.

Tools like this fascinate me. They’re worth preserving or at least getting running cleanly on a modern OS. 

## Tools included

| Tool | Source | Description |
|------|--------|-------------|
| `cc09` | `cc09.c` | **Command coordinator** — runs the full pipeline in one command |
| `mcc09` | `compile.c` + `io.c` + `6809cg.c` | Micro-C 6809 cross-compiler (K&R C subset → 6809 asm) |
| `mco09` | `mco.c` + `6809.mco` | Peephole optimizer (post-processes mcc09 output) |
| `mcp` | `mcp.c` | Full C preprocessor — parameterised macros, `##`, `#if` expressions |
| `macro` | `macro.c` | Assembly source macro processor — `SET`, `MACRO`/`ENDMAC`, `IFEQ`/`IFNE` |
| `asm09` | `asm09.c` | 6809 cross-assembler (→ Motorola S-records or Intel HEX) |
| `slink` | `slink.c` | Source linker — resolves `$EX:` externals from lib09/ |
| `slib` | `slib.c` | Source library manager (inspect/modify EXTINDEX.LIB) |
| `sindex` | `sindex.c` | Source index builder (generates EXTINDEX.LIB from .ASM files) |
| `sconvert` | `sconvert.c` | Source converter (prepares .ASM files for use as library modules) |
| `mc09pp` | `mc09pp` (Python) | Minimal slink substitute for standalone testing without lib09 |

**Not yet ported** (DOS binaries only, source available):
- `make` — Dunfield's simple make utility (use GNU make instead — the makefile format is incompatible and the timestamp API is DOS-specific)
**No source, DOS-only:**
- `ddside` — integrated development environment (GUI, not portable)
- `srenum`, `sreg`, `touch` — minor utilities with trivial Linux equivalents

---

## Build

```sh
make
```

Requires only `gcc` and `make`. The sources are K&R C compiled with
`-std=gnu89` and a handful of `-Wno-*` flags to suppress the implicit-declaration
warnings endemic to the Dunfield codebase.

There are still warnings; bad looking ones.  However, these warnings don't cause any issues, 
and don't seem to cause issue with any existing code. Keep in mind thats something
that we will still need to tackle.  The goal here was to get it to compile, we will still
have to work out the warnings at some point but for the most part its done.  
I feel like this is mostly good enough for production.  The warnings dont translate into 
the toolchain and are mostly just things that are gotchas you have to be careful about 
in K&R as you are very much the 'captan' there and not the other way around.

---

## Toolchain pipeline

### With preprocessor (recommended for larger projects)

```
  prog.c
     │
     ▼  mcp -I./include prog.c prog_pp.c        (optional full preprocessor)
  prog_pp.c         (macros expanded, #if resolved, ## paste applied)
     │
     ▼  mcc09 prog_pp.c prog.asm
  prog.asm          (Dunfield source-linked asm, contains $EX: directives)
     │
     ▼  [mco09 prog.asm prog_opt.asm]            (optional peephole optimizer)
     │
     ▼  slink prog.asm s=CRT0.ASM l=./lib09 prog_linked.asm
  prog_linked.asm   (runtime prepended, $EX: resolved, ?-labels uniquified)
     │
     ▼  asm09 prog_linked.asm -I l=prog.lst c=prog.HEX
  prog.HEX          (Intel or Motorola HEX)
  prog.lst          (annotated listing)
```

### Via cc09 coordinator (one command)

```sh
export MCDIR=/path/to/mc09-linux-port   # tools location
export MCINCLUDE=$MCDIR/include          # target headers
export MCLIBDIR=$MCDIR/lib09            # target runtime library

cc09 prog.c               # compile → prog.HEX (Motorola S-records)
cc09 prog.c -POq          # preprocess + optimize, quiet
cc09 prog.c -PIq S=CRT0.ASM  # Intel hex, usim09 startup, quiet
```

`cc09` flags:

| Flag | Effect |
|------|--------|
| `-P` | Run `mcp` full preprocessor before compiling |
| `-O` | Run `mco09` peephole optimizer after compiling |
| `-I` | Intel HEX output (default: Motorola S-records) |
| `-C` | Include C source as comments in assembly output |
| `-S` | Emit symbolic debug information |
| `-K` | Keep temporary files |
| `-q` | Quiet mode (suppress step banners) |
| `S=file` | Override startup file passed to slink as `s=` |
| `H=path` | Override MCDIR (tool home directory) |
| `T=prefix` | Temp file prefix |

---

## Preprocessor (`mcp`)

`mcp` is the full C preprocessor, invoked by `cc09 -P`. Use it when you need
features beyond `mcc09`'s built-in preprocessor:

| Feature | Example |
|---------|---------|
| Parameterised macros | `#define MAX(a,b) ((a)>(b)?(a):(b))` |
| `##` token-paste | `#define REG(b,o) b##o` → `0xC001` |
| `#if` with expressions | `#if VERSION >= 3`, `#elif`, `&&`, `\|\|`, `<<`, `>>` |
| `#undef` / `#forget` | Undefine a single macro or a whole block |
| `#error` / `#message` | Compile-time diagnostics |
| Predefined symbols | `__LINE__`, `__FILE__`, `__TIME__`, `__DATE__`, `__INDEX__` |
| Multi-line macros | `\` continuation |

`mcc09`'s built-in preprocessor handles `#define NAME value`, `#ifdef`/`#ifndef`/
`#endif`, and `#include`. Use `mcp` (via `cc09 -P` or manually) for anything
beyond that — in particular for firmware code that uses parameterised macros for
bit manipulation and register access.

`mcp` options:

| Option | Effect |
|--------|--------|
| `-I<path>` | Include search path (also: `l=<path>`) |
| `-c` | Keep comments in output |
| `-d` | Warn on duplicate macro definitions |
| `-l` | Emit line number directives for error tracking |
| `-q` | Quiet |
| `NAME=value` | Command-line macro definition |

`MCINCLUDE` env var sets the default include path.

---

## Assembly macro processor (`macro`)

`macro` is a source-level macro processor for assembly files — it runs on
`.asm` source before `asm09`, expanding `MACRO`/`ENDMAC` blocks and resolving
`SET` symbol substitutions. It is invoked by `cc09 -M`.

This is distinct from `mcp` (which preprocesses C source). `macro` is needed
for assembly files that use Dunfield's macro conventions — most notably the
monitor sources (`mon09.mac`, `hdm09.mac`) which **require** `macro` before
assembling.

```sh
# Process a .mac file and assemble it
macro mon09.mac > mon09.asm
asm09 mon09.asm l=mon09.lst c=mon09.HEX

# Or via cc09 coordinator (for C code that generates macro-using asm)
cc09 prog.c -M
```

`macro` directives:

| Directive | Effect |
|-----------|--------|
| `label SET value` | Define/redefine a substitutable symbol |
| `label ESET expr` | Define symbol from evaluated expression |
| `label MACRO` / `ENDMAC` | Define a macro (body follows until ENDMAC) |
| `IFEQ sym,val` | Conditional: assemble if sym == val |
| `IFNE sym,val` | Conditional: assemble if sym != val |
| `IF expr` | Conditional: assemble if expression is non-zero |
| `ELSE` / `ENDIF` | Conditional branches |
| `INCLUDE file` | Include another file |
| `ABORT message` | Terminate with error |
| `PREFIX char` | Set directive prefix character |

Within macro bodies, parameter substitution uses `\1`, `\2`, etc. for
positional arguments, `\0` for the label, `\$` for a unique call-site
number (for generating unique local labels), and `\#` for the argument count.

`macro` options:

| Option | Effect |
|--------|--------|
| `-L` | Emit `line N` directives for assembler error tracking |
| `-Pchar` | Set directive prefix character |
| `NAME=value` | Command-line symbol definition |
| `>file` | Write output to file (alternative to shell redirect) |

---

## Targets

### Default (`lib09/`)
Code starts at `$2000`, stack at `$8000`, no reset vector.
Matches Dunfield's original RAM-based monitor system.

```sh
MCDIR=. MCINCLUDE=./include cc09 prog.c -q
```

### usim09 (`targets/usim09/lib09/`)
Code in ROM at `$E000`, stack at `$7F00`, MC6850 ACIA at `$C000`,
reset vector at `$FFFE`. Matches the `usim09` simulator's hardcoded memory map.

```sh
MCDIR=. MCINCLUDE=./include MCLIBDIR=./targets/usim09/lib09 \
  cc09 prog.c -Iq S=CRT0.ASM

echo "" | usim09 prog.HEX
```

Run `make test-usim` to see the full pipeline including simulator execution.

### Adding a new target
1. Create `targets/<name>/lib09/`
2. Copy `EXTINDEX.LIB` from `lib09/` and all `.ASM` files except the three below
3. Write **`CRT0.ASM`** — overrides `6809RLP.ASM` via `slink s=CRT0.ASM`:
   sets `ORG` (code base), `LDS` (stack top), startup sequence, exit behaviour.
   Copy the runtime arithmetic/comparison routines from `6809RLP.ASM`.
4. Write **`SERIO.ASM`** — overrides `lib09/SERIO.ASM`:
   set `?uart EQU <base>`, status register offsets, TX/RX ready bits.
5. Write **`6809RLS.ASM`** — overrides the suffix: `?heap EQU *`, reset vector
   at `$FFFE`, any other interrupt vectors.
6. Compile: `MCLIBDIR=./targets/<name>/lib09 cc09 prog.c -Iq S=CRT0.ASM`

---

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `MCDIR` | `./` | Tools directory (`cc09` searches here first, then `PATH`) |
| `MCINCLUDE` | — | Include search path for `mcc09` and `mcp` |
| `MCLIBDIR` | `$MCDIR/lib09` | Runtime library directory for `slink` |

---

## make targets

| Target | Description |
|--------|-------------|
| `make` | Build all eleven tools |
| `make test` | Manual pipeline: `hello.c` → slink → asm09 → Motorola HEX |
| `make test-usim` | `cc09` single command → `hello_clean.HEX` → run in usim09 |
| `make clean` | Remove binaries and generated files |
| `make install` | Install to `PREFIX` (default `/usr/local`) |

---

## Linux porting notes

### Compiler (`mcc09`): `compile.c`, `io.c`, `6809cg.c`

1. **`abort(msg)`** — Dunfield's signature takes a message string; ANSI `abort()` takes none. Routed via `#define abort(msg) die(msg)` macro in `portab.h`.

2. **CRLF stripping** — DOS line endings stripped in `get_lin()` and `MC_fgets()`.

3. **`#CPU` stringize** — K&R token-pasting `"foo"#MACRO"bar"` is invalid in modern cpp. Replaced with a `STRINGIFY()` double-macro in `io.c` and `mco.c`.

4. **`skip_comment()` 16-bit window** — The `/* */` scanner uses a 2-char sliding window in `unsigned x`. On DOS `unsigned` is 16 bits; on LP64 it is 32 bits and the `*/` pattern never matches. Fixed: `unsigned short x`.

5. **Block comments spanning `#include` boundaries** — `read_char()` crossed file boundaries mid-comment, consuming the parent source. Fixed: `in_comment` counter + `*/` sentinel on include pop-back.

6. **`-I` include path and `MCINCLUDE`** — `f_open()` now strips `<>`/`""` delimiters and searches `-I` path and `MCINCLUDE` env var.

### Assembler (`asm09`): `asm09.c`

7. **`optr` array index** — `char` used as index into `operand[200]`; wraps negative above 127. Fixed: `int`.

8. **`itype`/`otype`/`post` opcode fields** — `char` holds values `0x81`–`0x8a` (>127). Fixed: `unsigned char`.

9. **`isterm()` missing `\n`** — `fgets()` includes the trailing newline; `eval()` saw it as an unknown operator and fired "invalid expression syntax" after every correctly-assembled line. Fixed: `\n`, `\r`, `;` added to `isterm()`.

10. **`symtab`/`symtop` pointer types** — `char[]` vs `unsigned char *` mismatch. Fixed throughout.

### Source linker (`slink`): `slink.c`, `microc.h`

11. **`sp_top` initialiser** — `= &string_pool` (pointer-to-array) → `= string_pool` (array decay).

12. **`DIRSEP` and default library path** — `'\\'` → `'/'`; `"\\MC\\SLIB"` → `"./lib09"`.

13. **`strbeg()`** — Dunfield Micro-C built-in absent from standard libraries. Added to `microc.h`.

### Library tools (`slib`, `sindex`, `sconvert`)

14. **`udata[25] = 0`** — invalid array initialiser; fixed to `= ""`.

15. **Multi-char constant option switches** — `case 'q-':` is implementation-defined in GCC. Rewrote as `if`/`else if` chains.

16. **DOS `fopen` modes** — `"rv"`, `"wvq"`, `"rvq"` → `"r"`, `"w"`, `"r"`.

17. **`sindex` directory traversal** — DOS `find_first()`/`find_next()` replaced with POSIX `glob()`.

### Command coordinator (`cc09`): `cc09.c`

18. **`exec(cmd, args)`** — DOS API; replaced with `mc_exec()` using `fork()`/`execvp()`.

19. **`getenv(name, buf)`** — DOS two-argument form; wrapped as `mc_getenv()` adapter over POSIX `getenv()`.

20. **`link`, `dup` variable names** — clash with POSIX `link()`/`dup()` from `unistd.h`. Renamed to `do_link`, `do_dup`.

21. **Path separators and `.EXE`/`.COM` suffixes** — all updated for Linux.

22. **`MCLIBDIR` env var** — added to separate the tools directory from the target runtime library, enabling per-target builds.

### Optimizer (`mco09`): `mco.c`

23. **`#include "PC86.mco"`** → `#include "6809.mco"` — point at the 6809 optimization table.

### Preprocessor (`mcp`): `mcp.c`

24. **`<dos.h>` / `int86()` / `union REGS`** — used only to read the system clock for `__TIME__`/`__DATE__`. Replaced with POSIX `time()` + `localtime()`.

25. **`fprint()` with `nargs()`** — Dunfield's Micro-C exposes a non-standard `nargs()` intrinsic that lets functions count their arguments by walking the call stack. Both implementations of `fprint()` relied on this. Replaced with a standard ANSI `va_list` variadic function.

26. **`##` token-paste operator** — mcp stored `##` literally in macro definitions but had no expansion handler. Added to `resolve_macro()`: strip trailing whitespace from output, skip `##`, skip leading whitespace, then continue — causing adjacent tokens to concatenate directly.

27. **`-I<path>` flag** — mcp used `l=path` for include directories. Added `-I` matching the convention used by `mcc09` and standard C compilers. Added `MCINCLUDE` env var fallback.

### Porting notes (`macro.c`)

28. **`macsub[NUMSMACS]` declaration** — declared as `unsigned char` (flat
    byte array) but used throughout as an array of pointers (`macsub[i] = freptr`,
    `strcmp(macsub[i], ...)`, pointer arithmetic). On 16-bit DOS the array was
    storing 2-byte pointers into what was effectively a contiguous pool; on
    64-bit Linux this silently truncates 8-byte pointers to 1 byte. Fixed:
    `unsigned char *macsub[NUMSMACS]`.

29. **`input_ptr` type** — declared in the `unsigned` global block as
    `*input_ptr` (i.e. `unsigned *`), but used as a character pointer throughout
    the expression evaluator. On 64-bit Linux, assignments from `unsigned char *`
    functions truncated the pointer to 32 bits. Fixed: moved to its own
    `unsigned char *input_ptr` declaration.

30. **Pointer-returning functions with implicit `int` return** — `skip_blank()`,
    `skip_parm()`, `extract_parm()`, and `process_line()` all return
    `unsigned char *` but had no explicit return type (K&R implicit `int`).
    On 64-bit Linux, GCC generates code that sign-extends or zero-fills
    the 32-bit `int` return to 64 bits, mangling the upper half of every
    returned pointer. Fixed: explicit return types added to all definitions,
    plus matching forward declarations before `main()` so call sites see the
    correct type from the start.

31. **`isend()` missing `\n` and `\r`** — the label/instruction scanner loop
    `for(linptr = linebuf; !isend(chr=*linptr); ++linptr)` treated newlines as
    non-terminating, so on Linux where `fgets()` includes `\n` in the buffer
    it ran off the end of every line into unmapped memory. Fixed: `\n` and `\r`
    added to `isend()` — same class of fix as `isterm()` in `asm09.c`.

32. **`get_date()`/`get_time()`** — DOS-specific Micro-C built-ins for reading
    the system clock. Replaced with POSIX `time()` + `localtime()`.

33. **`freptr = &buffer`** — same array-vs-pointer-to-array initialiser issue
    as `slink`'s `sp_top`. Fixed: `freptr = buffer`.
