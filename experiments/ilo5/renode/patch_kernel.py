#!/usr/bin/env python3
# patch_kernel.py — produce an emulation-friendly copy of iLO5 kernel_main.bin by
# neutralizing the low-level CPU-bring-up instructions that an emulator (Renode's
# Cortex-A9) implements incompletely and that otherwise park/trap the boot.
#
# This is a GATE LEDGER: every entry below is one obstacle found while walking the
# boot under Renode, with the VA, the original instruction, the replacement, and why.
# Patches are applied to a COPY (kernel_main.patched.bin); the original is never touched.
#
# Each gate was diagnosed by: run Renode with execution tracing -> find where the trace
# stops/loops -> disassemble that site -> identify the unimplemented/guarding op -> patch.
#
# RUN: python3 patch_kernel.py   (absolute paths; run from anywhere)
import struct, sys
BASE = 0x41000000
NOP  = 0xe320f000        # the image's own NOP encoding (ARM hint nop)

def arm_b(frm, to):
    return 0xea000000 | (((to - (frm + 8)) >> 2) & 0xffffff)

# (va, expected_original_u32, new_u32, reason)
PATCHES = [
    # --- Gate 1: CLIDR cache-topology self-check -> wfi park (0x410bc618) ---
    # mrc p15,1,r5,c0,c0,1 reads CLIDR; firmware validates LoUU/LoC/LoUIS==1 & Ctype1==3
    # and parks at wfi on mismatch. Emulators report LoUIS=0. Branch past the whole guard.
    (0x410bc5d8, 0xe7e20dd5, arm_b(0x410bc5d8, 0x410bc650),
     "Gate 1: CLIDR cache-topology guard -> wfi; branch past to 0x410bc650"),

    # --- Gate 2: undefined CP14 (debug/trace coprocessor) writes -> undef-vector dead-loop ---
    # After enabling VFP via CPACR, the kernel writes CP14 debug regs; Renode's A9 leaves
    # these undefined, trapping to the undef vector (b . at 0x410bc164). NOP them out.
    (0x410bc7a4, 0xeec00e10, NOP, "Gate 2: mcr p14,6,r0,c0,c0,0 (CP14 debug) undefined -> NOP"),
    (0x410bc7b0, 0xeee20e10, NOP, "Gate 2: mcr p14,7,r0,c2,c0,0 (CP14 debug) undefined -> NOP"),
    (0x410bc7b8, 0xeee10e10, NOP, "Gate 2: mcr p14,7,r0,c1,c0,0 (CP14 debug) undefined -> NOP"),

    # --- Gate 3: premature scheduler reschedule -> idle, bootstrap never returns (0x410284d8) ---
    # Scheduler-start 0x4102846c calls the reschedule 0x4100be0c, which context-switches to the
    # (only-ready) idle task and never returns to 0x410284dc. Because the bootstrap context never
    # resumes, the guard 0x4109c170 never reaches `bl KernelMain` (0x4109c1a8) -> the 3 init tasks
    # are never created -> ready table 0x41a04f10 stays empty -> permanent idle. IRQs are disabled
    # (cpsid @0x410bc008) and no timer is modeled, so the parked bootstrap can never be rescheduled
    # back. NOP the reschedule call: scheduler-start then returns, KernelMain runs, the 3 init tasks
    # are created+enqueued, and the kernel boots on to its BSP. VERIFIED: distinct PCs 2842 -> 9111,
    # real console ("Cold Booting", ilomr, "Cortex-A9 r0p0", L2C-310), then ilobsp MMU-fault panic
    # = the next gate. (Likely refinable to a faithful fix once the reschedule's idle-pick condition
    # is understood; for now this is the documented unblock.)
    (0x410284d8, 0xebff8e4b, NOP, "Gate 3: premature reschedule-to-idle 0x4100be0c -> NOP; lets bootstrap reach KernelMain"),

    # --- Gate 4 (SOLVED 2026-06-25): bl1->kernel boot-block-signature dangling-pointer MMU fault ---
    # After Gate 3 the kernel boots to its BSP and panics: "Signed as " then "ilobsp: FatalException
    # - MMU fault on kernel load/store" / INTERRUPT_Panic(NULL,604). FULL pointer-origin chain
    # (every step nailed with live Renode hooks, not static guessing):
    #   1. bl1 `bx 0x41000000` (@0x10000584) hands the kernel r0 = 0x100005FC -- a pointer to the
    #      boot-block SIGNATURE/identity string, which lives in bl1's own transient 0x10000000 region.
    #   2. Kernel entry 0x41000008 `blne 0x410bc000` (early bring-up); 0x410bc018 `mov r4,r0` saves
    #      the handoff r0. 0x410bc0ac `bleq 0x410278e8` (publish fn); 0x410278f4 `str r0,[ip,r9]`
    #      writes 0x100005FC into the boot-args global G = 0x41A24030 (paired with src tag 0xA0008000).
    #   3. BSP boot-banner fn: 0x4102598c `ldr r5,=&G`; 0x41025990 `ldr r2,[r5]` = *G = 0x100005FC;
    #      0x41025998 `cmp r2,#0` -> nonzero picks fmt "Signed as %s\n" (@0x41025b4c); 0x410259a8
    #      `bl 0x41026114` printf(1, "Signed as %s\n", 0x100005FC).
    #   4. printf -> vsnprintf %s-handler 0x410935d4 -> 0x41093ab4 `ldr r1,[r5],#4` (va_arg) -> strlen
    #      0x4108b2a0 `ldrb [0x100005FC]` -> DATA ABORT. DFAR=0x100005FC DFSR=5 (section xlat fault):
    #      the kernel runs on its OWN page tables which do NOT map bl1's transient 0x10000000 region
    #      (proven: PTE[0x100]@0x41A2C400 = 0). The "Signed as " on the console is this printf getting
    #      as far as the literal prefix before the %s strlen faults.
    # *G (0x100005FC) is dereferenced-as-a-string ONLY here; the other G readers (0x41025414,
    #  0x41000b64, 0x41000b98) merely test the pointer for non-NULL, so they are unaffected.
    # FIX: force the banner's local selector/arg r2 to 0, so the fn takes the alternate branch
    # (fmt "Unsigned (downloaded or old boot block)\n" @0x41025b5c, which has NO %s and dereferences
    # nothing). G itself is left untouched for the other readers. One instruction, content-independent,
    # no page-table / relocation / timing dependency.  0x41025990: ldr r2,[r5] -> mov r2,#0.
    # VERIFIED (Renode, both on-disk-patched and handoff-injected): banner fn now calls printf with
    # r1=0x41025b5c (Unsigned fmt) r2=0, returns past the banner; the %s strlen and the data-abort
    # handler 0x410bb1c4 are never reached; 0 FatalException / 0 INTERRUPT_Panic. Boot proceeds to
    # the NEXT wall: a gxp_dev (0xD1000000) poll loop on off 0x30/0x34 (poller refs base literal
    # @0x41021b8c) -- that is Gate 5.
    (0x41025990, 0xe5952000, 0xe3a02000,
     "Gate 4: BSP 'Signed as %s' prints dangling bl1-region sig ptr (0x100005FC, unmapped) -> "
     "force r2=0 so banner takes the no-%s 'Unsigned boot block' branch; kills the ilobsp MMU fault"),

    # --- Gate 6 (2026-06-26): main-init parked forever in the iodion netcfg config-store
    #     validate/repair spin -> never reaches the app-init that leads to ilomain ---
    # ROOT CAUSE (live-proven, not static guessing):
    #   After Gate 4 the BSP boots and the main-init thread (stack 0x4213C3C8) runs, post-KernelMain,
    #   the kernel-init guard 0x4109c170 -> ... -> netcfg-init 0x410247d4 -> config-init 0x410246c8 ->
    #   the iodion ("nics/iodion.ram") config LOAD at 0x410244f0. Its loop head is 0x410244f4:
    #       loop: r2 = config_validate(0x41018d88, base=0x41125e68, 0x800)
    #             r2 in {0,4} -> return (config OK);  r2 in {1,2,3} -> error-log + repair, b 0x410244f4;
    #             else -> b 0x410244f4   (so EVERY non-OK result loops)
    #   The validators are 0x410185a4 (type-3, magic 0x439cd202) and 0x41018600 (type-1, magic
    #   0x439cd203), each = "block magic+type match AND 32-bit word-sum checksum == stored sum".
    #   The persistent config store lives in NVRAM/flash that we do NOT back in emulation, so its
    #   RAM image at 0x41125e68 is all-zero -> magic never matches -> validators return 2 ("mismatch")
    #   -> 0x41018d88 returns 3 -> the loop repairs (no valid source copy, so it stays bad) and retries
    #   FOREVER. LIVE EVIDENCE: a Renode stack-dump hook at 0x410247d4 caught the return chain
    #   0x4109c170 / 0x410a5b3x (the same 0x410Axxxx init neighborhood as ilomain's container 0x410a3908),
    #   and the 0.15s trace showed 0x410244f0's body (0x41024500) executing 645x while the loop's
    #   return point 0x41024504 / the post-config link-check 0x410247e8 NEVER executed. Hot steady state
    #   was checksum 0x41018590 + scheduler ping-pong with the INTEGRITY idle loop 0x4100ee28 dead.
    # FIX (emulation-faithful: "the empty NVRAM config store reads as valid"): short-circuit BOTH leaf
    #   validators to return 0 (=valid). 0x41018cdc/0x41018d88/0x41018868 all funnel through these two,
    #   so every config-init loop in the module converges. Each validator becomes `mov r0,#0; bx lr`
    #   (no stack use, callee-saved regs untouched -> safe to skip the push/pop).
    # VERIFIED (Renode, on-disk patched, RunFor 0.15s): distinct PCs 7432 -> 9751 (>8452); the config
    #   spin + scheduler churn vanish from the hot set; main-init advances past the netcfg link-check
    #   (0x410221b4) into app-init 0x410a4xxx; KernelMain returns (0x4109c1ac) and the INTEGRITY idle
    #   loop 0x4100ee28 now RUNS (842 hits, was 0). 0 CPU faults (data-abort 0x410bb1c4 / undef 0x410bc164
    #   never fire), clean "Machine paused". NEXT wall (Gate 7, distinct issue): with config solved the
    #   boot thread finishes synchronous init and the idle task hits `wfi` @0x410a4564; no timer/tick is
    #   modeled (Gate-3 family) so the CPU sleeps forever and ilomain's task 0x410a3908 is never
    #   scheduled -> needs a periodic timer IRQ source, not a kernel patch.
    (0x410185a4, 0xe92d4020, 0xe3a00000, "Gate 6: iodion config validator(type-3) -> mov r0,#0 (empty NVRAM reads valid)"),
    (0x410185a8, 0xe1a05000, 0xe12fff1e, "Gate 6: iodion config validator(type-3) -> bx lr"),
    (0x41018600, 0xe92d4020, 0xe3a00000, "Gate 6: iodion config validator(type-1) -> mov r0,#0 (empty NVRAM reads valid)"),
    (0x41018604, 0xe1a05000, 0xe12fff1e, "Gate 6: iodion config validator(type-1) -> bx lr"),
]

def main(src, dst):
    data = bytearray(open(src, "rb").read())
    applied = skipped = 0
    for va, expect, new, reason in PATCHES:
        off = va - BASE
        cur = struct.unpack_from("<I", data, off)[0]
        if cur != expect:
            print(f"  SKIP {va:#x}: have {cur:#010x}, expected {expect:#010x} -- {reason}")
            skipped += 1
            continue
        struct.pack_into("<I", data, off, new)
        print(f"  patch {va:#x}: {expect:#010x} -> {new:#010x}  ({reason})")
        applied += 1
    if skipped:
        raise SystemExit(f"refusing partial patch: {skipped} instruction(s) did not match")
    open(dst, "wb").write(data)
    print(f"applied {applied}, skipped {skipped} -> {dst} ({len(data)} bytes)")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} KERNEL_MAIN.BIN OUTPUT.BIN")
    main(sys.argv[1], sys.argv[2])
