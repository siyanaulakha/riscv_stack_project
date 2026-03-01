# RISC-V Stack Guard

A Python-based post-compilation hardening tool that automatically instruments RISC-V assembly (`.s`) files with stack canary protection against stack buffer overflow attacks.

The tool works **without modifying the compiler or source code**. Instead, it rewrites compiler-generated assembly after compilation and injects:

* a randomized global stack canary
* prologue canary storage
* epilogue canary verification
* a fail handler on mismatch

## Motivation

Modern stack-smashing defenses are usually implemented inside the compiler. This project explores a different approach: **post-compilation assembly rewriting** for RISC-V, allowing stack protection to be added even when compiler modification is not practical.

## Features

* Detects stack-allocating functions using:

  * `addi sp, sp, -N`
* Instruments only when:

  * `N >= 16`
* Inserts a randomized global canary
* Updates function prologue to:

  * enlarge the stack frame
  * store the canary at `0(sp)`
* Updates epilogue to:

  * compare the stored canary with the master canary
  * branch to `__stack_chk_fail` on mismatch
* Supports:

  * `ret`
  * `jr ra`
  * `jalr x0, 0(ra)`
* Supports bare-metal fail handler mode with `--baremetal`

## Project Structure

```text
riscv_stack_project/
├── riscv_stack_guard.py
├── README.md
├── LICENSE
├── .gitignore
├── start.s
├── tests/
│   ├── test_vunl.c
│   ├── test_skip.c
│   ├── test_skip2.c
│   ├── test_leaf.c
│   └── test_tamper.c
└── test_outputs/
    ├── test_vunl.s
    ├── test_vunl_hardened.s
    ├── test_vunl_baremetal.s
    ├── test_skip.s
    ├── test_skip_hardened.s
    ├── test_skip2.s
    ├── test_skip2_hardened.s
    ├── test_leaf.s
    ├── test_leaf_hardened.s
    ├── test_tamper.s
    └── test_tamper_hardened.s
```

## How It Works

For a function like:

```asm
addi sp, sp, -80
sw   ra, 76(sp)
sw   s0, 72(sp)
addi s0, sp, 80
...
lw   ra, 76(sp)
lw   s0, 72(sp)
addi sp, sp, 80
jr   ra
```

the tool transforms it into:

```asm
addi sp, sp, -84
la   t6, __stack_chk_guard
lw   t5, 0(t6)
sw   t5, 0(sp)

sw   ra, 80(sp)
sw   s0, 76(sp)
addi s0, sp, 84
...
lw   ra, 80(sp)
lw   s0, 76(sp)
la   t6, __stack_chk_guard
lw   t5, 0(sp)
lw   t4, 0(t6)
bne  t5, t4, __stack_chk_fail
addi sp, sp, 84
jr   ra
```

## Usage

### 1. Compile C to assembly

```bash
riscv64-unknown-elf-gcc -S -O0 -march=rv32i -mabi=ilp32 -ffreestanding -fno-builtin tests/test_vunl.c -o test_outputs/test_vunl.s
```

### 2. Harden the assembly

```bash
python3 riscv_stack_guard.py test_outputs/test_vunl.s test_outputs/test_vunl_hardened.s
```

### 3. Assemble hardened output

```bash
riscv64-unknown-elf-gcc -c -march=rv32i -mabi=ilp32 test_outputs/test_vunl_hardened.s -o test_vunl_hardened.o
```

### 4. Disassemble for verification

```bash
riscv64-unknown-elf-objdump -d -M no-aliases,numeric test_vunl_hardened.o
```

### Bare-metal mode

```bash
python3 riscv_stack_guard.py test_outputs/test_vunl.s test_outputs/test_vunl_baremetal.s --baremetal
```

## Validation Performed

### 1. Standard instrumentation test

* Verified that stack-allocating functions with `N >= 16` are instrumented correctly.
* Confirmed prologue/epilogue rewriting and insertion of canary logic.

### 2. Skip test

* Verified that functions without stack allocation are skipped.
* Example: optimized test with no `addi sp, sp, -N`.

### 3. Bare-metal handler test

* Verified generation of:

  * `ebreak`
  * infinite loop fail handler
* when `--baremetal` is enabled.

### 4. Tamper/fail-path test

* Manually corrupted the stored canary at `0(sp)` before epilogue verification.
* Confirmed branch to `__stack_chk_fail` is emitted and reachable.

### 5. Leaf-style function test

* Verified correct instrumentation on a local-buffer function with frame-pointer-based stack layout.

## Limitations

Current version is designed for simple GCC-style RISC-V assembly and does **not** fully support:

* dynamic stack allocation
* highly optimized nonstandard epilogues
* arbitrary hand-written assembly
* complex stack pointer updates within a function
* full runtime execution framework or simulator-backed attack validation

## Future Improvements

* use `secrets.randbits(32)` instead of the standard `random` module
* append runtime only when at least one function is instrumented
* improve detection of `.text.startup` and similar text sections
* add automated regression tests
* add runtime validation in a simulator or bare-metal environment
* support more optimized compiler output patterns

## Author

Developed as a post-compilation RISC-V security hardening project focused on stack buffer overflow mitigation using assembly rewriting.

