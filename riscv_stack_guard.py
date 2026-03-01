import re
import sys
import random
from pathlib import Path

GLOBAL_GUARD_NAME = "__stack_chk_guard"
FAIL_HANDLER_NAME = "__stack_chk_fail"

FUNC_LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$]*)\s*:\s*(?:#.*)?$')
STACK_ALLOC_RE = re.compile(r'^\s*addi\s+sp\s*,\s*sp\s*,\s*(-\d+)\s*(?:#.*)?$')
STACK_FREE_RE = re.compile(r'^\s*addi\s+sp\s*,\s*sp\s*,\s*(\d+)\s*(?:#.*)?$')
RET_RE = re.compile(r'^\s*ret\s*(?:#.*)?$')
JR_RA_RE = re.compile(r'^\s*jr\s+ra\s*(?:#.*)?$')
JALR_RA_RE = re.compile(r'^\s*jalr\s+x0\s*,\s*0\(ra\)\s*(?:#.*)?$')
S0_SETUP_RE = re.compile(r'^\s*addi\s+s0\s*,\s*sp\s*,\s*(\d+)\s*(?:#.*)?$')

SP_ACCESS_RE = re.compile(
    r'^(?P<indent>\s*)'
    r'(?P<op>lb|lh|lw|lbu|lhu|sb|sh|sw)\s+'
    r'(?P<arg1>[^,]+)\s*,\s*'
    r'(?P<off>-?\d+)\(sp\)'
    r'(?P<trail>\s*(?:#.*)?)$'
)

SECTION_TEXT_RE = re.compile(r'^\s*\.text\b')
SECTION_RE = re.compile(r'^\s*\.section\b')


def is_nonlocal_label(line: str) -> bool:
    m = FUNC_LABEL_RE.match(line)
    if not m:
        return False
    label = m.group(1)
    return not label.startswith(".L")


def split_top_level(lines):
    parts = []
    current_kind = "preamble"
    current_name = None
    current_lines = []
    in_text = False

    def flush():
        nonlocal current_kind, current_name, current_lines
        if current_lines:
            parts.append((current_kind, current_name, current_lines))
        current_kind = None
        current_name = None
        current_lines = []

    for line in lines:
        if SECTION_TEXT_RE.match(line):
            in_text = True
        elif SECTION_RE.match(line) and not SECTION_TEXT_RE.match(line):
            in_text = False

        if in_text and is_nonlocal_label(line):
            flush()
            current_kind = "function"
            current_name = FUNC_LABEL_RE.match(line).group(1)
            current_lines = [line]
        else:
            if current_kind is None:
                current_kind = "preamble"
                current_name = None
                current_lines = []
            current_lines.append(line)

    flush()
    return parts


def has_existing_symbols(text: str) -> bool:
    return GLOBAL_GUARD_NAME in text or FAIL_HANDLER_NAME in text


def analyze_stack_behavior(lines):
    alloc_idx = None
    frame_size = None

    for i, line in enumerate(lines):
        if alloc_idx is None:
            m = STACK_ALLOC_RE.match(line)
            if m:
                n = -int(m.group(1))
                if n >= 16:
                    alloc_idx = i
                    frame_size = n
                else:
                    return None, None, "skipped (stack frame < 16 bytes)"
                break

    if alloc_idx is None:
        return None, None, "skipped (no eligible stack allocation)"

    for i, line in enumerate(lines):
        if i == alloc_idx:
            continue
        if re.search(r'\baddi\s+sp\s*,\s*sp\s*,', line):
            m_free = STACK_FREE_RE.match(line)
            if m_free and int(m_free.group(1)) == frame_size:
                continue
            return None, None, "skipped (complex stack pointer updates)"

    return alloc_idx, frame_size, None


def rewrite_sp_access(line, delta):
    m = SP_ACCESS_RE.match(line)
    if not m:
        return line

    old_off = int(m.group("off"))
    new_off = old_off + delta

    return (
        f"{m.group('indent')}{m.group('op')} {m.group('arg1')}, "
        f"{new_off}(sp){m.group('trail')}\n"
    )


def rewrite_function(name, lines):
    alloc_idx, frame_size, reason = analyze_stack_behavior(lines)
    if reason is not None:
        return lines, False, f"{name}: {reason}"

    new_frame_size = frame_size + 4
    out = []
    i = 0

    while i < len(lines):
        line = lines[i]

        if i == alloc_idx:
            out.append(
                re.sub(
                    r'addi\s+sp\s*,\s*sp\s*,\s*-\d+',
                    f'addi sp, sp, -{new_frame_size}',
                    line
                )
            )
            out.append(f'    la t6, {GLOBAL_GUARD_NAME}\n')
            out.append(f'    lw t5, 0(t6)\n')
            out.append(f'    sw t5, 0(sp)\n')
            i += 1
            continue

        m_s0 = S0_SETUP_RE.match(line)
        if m_s0 and int(m_s0.group(1)) == frame_size:
            out.append(
                re.sub(
                    r'addi\s+s0\s*,\s*sp\s*,\s*\d+',
                    f'addi s0, sp, {new_frame_size}',
                    line
                )
            )
            i += 1
            continue

        # Detect epilogue pair:
        #   addi sp, sp, frame_size
        #   jr ra / ret / jalr x0,0(ra)
        m_free = STACK_FREE_RE.match(line)
        if m_free and int(m_free.group(1)) == frame_size and i + 1 < len(lines):
            next_line = lines[i + 1]
            if RET_RE.match(next_line) or JR_RA_RE.match(next_line) or JALR_RA_RE.match(next_line):
                out.append(f'    la t6, {GLOBAL_GUARD_NAME}\n')
                out.append(f'    lw t5, 0(sp)\n')
                out.append(f'    lw t4, 0(t6)\n')
                out.append(f'    bne t5, t4, {FAIL_HANDLER_NAME}\n')
                out.append(
                    re.sub(
                        r'addi\s+sp\s*,\s*sp\s*,\s*\d+',
                        f'addi sp, sp, {new_frame_size}',
                        line
                    )
                )
                out.append(next_line)
                i += 2
                continue

        # Non-returning plain stack restore
        if m_free and int(m_free.group(1)) == frame_size:
            out.append(
                re.sub(
                    r'addi\s+sp\s*,\s*sp\s*,\s*\d+',
                    f'addi sp, sp, {new_frame_size}',
                    line
                )
            )
            i += 1
            continue

        # Standalone return without visible stack restore before it
        if RET_RE.match(line) or JR_RA_RE.match(line) or JALR_RA_RE.match(line):
            out.append(f'    la t6, {GLOBAL_GUARD_NAME}\n')
            out.append(f'    lw t5, 0(sp)\n')
            out.append(f'    lw t4, 0(t6)\n')
            out.append(f'    bne t5, t4, {FAIL_HANDLER_NAME}\n')
            out.append(line)
            i += 1
            continue

        out.append(rewrite_sp_access(line, 4))
        i += 1

    return out, True, f"{name}: instrumented (frame {frame_size} -> {new_frame_size})"

def append_runtime(text_lines, canary_value, baremetal=False):
    rt = []
    rt.append("\n")
    rt.append("    .section .data\n")
    rt.append("    .align 2\n")
    rt.append(f"    .globl {GLOBAL_GUARD_NAME}\n")
    rt.append(f"{GLOBAL_GUARD_NAME}:\n")
    rt.append(f"    .word 0x{canary_value:08x}\n")
    rt.append("\n")
    rt.append("    .section .text\n")
    rt.append("    .align 2\n")
    rt.append(f"    .globl {FAIL_HANDLER_NAME}\n")
    rt.append(f"{FAIL_HANDLER_NAME}:\n")

    if baremetal:
        rt.append("    ebreak\n")
        rt.append(".L__stack_chk_fail_hang:\n")
        rt.append("    j .L__stack_chk_fail_hang\n")
    else:
        rt.append("    li a0, 1\n")
        rt.append("    li a7, 93\n")
        rt.append("    ecall\n")
        rt.append(".L__stack_chk_fail_hang:\n")
        rt.append("    j .L__stack_chk_fail_hang\n")

    return text_lines + rt


def harden_asm(src_text, baremetal=False):
    if has_existing_symbols(src_text):
        raise RuntimeError("input already contains stack guard symbols")

    lines = src_text.splitlines(keepends=True)
    parts = split_top_level(lines)

    out = []
    reports = []
    instrumented = 0

    for kind, name, chunk in parts:
        if kind == "function":
            new_chunk, changed, report = rewrite_function(name, chunk)
            out.extend(new_chunk)
            reports.append(report)
            if changed:
                instrumented += 1
        else:
            out.extend(chunk)

    canary_value = random.getrandbits(32)
    out = append_runtime(out, canary_value, baremetal=baremetal)

    return "".join(out), reports, instrumented, canary_value


def main():
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print(f"Usage: {sys.argv[0]} input.s [output.s] [--baremetal]")
        sys.exit(1)

    args = sys.argv[1:]
    baremetal = False

    if "--baremetal" in args:
        baremetal = True
        args.remove("--baremetal")

    in_path = Path(args[0])
    if len(args) >= 2:
        out_path = Path(args[1])
    else:
        out_path = in_path.with_name(in_path.stem + "_hardened.s")

    src = in_path.read_text()
    hardened, reports, instrumented, canary = harden_asm(src, baremetal=baremetal)
    out_path.write_text(hardened)

    print(f"Input file            : {in_path}")
    print(f"Output file           : {out_path}")
    print(f"Random canary         : 0x{canary:08x}")
    print(f"Instrumented functions: {instrumented}")
    print()

    for r in reports:
        print(r)


if __name__ == "__main__":
    main()
