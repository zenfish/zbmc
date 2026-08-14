# Live-iterate handoff (from the iDRAC9 session) — kill the rebuild+reboot loop

If you're rebuilding the initramfs and re-booting (~15 min) for every change to iterate, **stop** —
there's a fast loop now. Tool: `/Volumes/yyy/phd/vilo/ilo9/iterate.sh` (also in
`bmc/dell/idrac9-virtual/iterate.sh`).

## What it does
Push a script to the **live, already-booted** BMC and read its output from the **host serial log**
(not ssh) — so results come back even when the single-core guest drops ssh under load. Seconds per
iteration instead of a full rebuild+reboot.

```
iterate.sh -b idrac10 <local-script.sh> <console-log>
```
- `-b idrac10` → uses `vbmc idrac10 ssh` for the push (must work).
- `<console-log>` → the file your run script's `-serial` output is captured to. Make sure your
  launcher does `-serial ... > logs/idrac10-live.log` (nohup redirect) so there's a file to read.
- The script's stdout is bracketed `==ITER-START==`/`==ITER-END==` on the guest console; iterate
  polls the log and prints just that block.

## When it helps (and when it doesn't)
- **Helps**: anything you can re-apply on a *running* box — restart a daemon, reload your shim by
  killing+relaunching the target process with the new `LD_PRELOAD`, re-run a bring-up, poke IPMI.
  Keep the boot inputs FIXED; put the thing you iterate OUTSIDE the boot path (pushed post-boot).
- **Doesn't help by itself**: changes that only take effect at cold boot / in the initramfs. For a
  shim, iterate by `pkill <target>; LD_PRELOAD=/tmp/new-shim.so <relaunch>` on the live box — no reboot.

## The load-bearing finding it produced (may be YOUR bug too)
A bring-up that fails from a **systemd oneshot** but works over ssh = the oneshot's cgroup
(`KillMode=control-group`) reaps the daemon you spawned. Run it via `setsid` **outside** systemd
(which is exactly what iterate.sh does: `setsid nohup sh ...`) and it survives.

## Also here (iDRAC9 session), not yet ready
- `ckpt.py` + `run-p6-restore.sh`: QEMU checkpoint (savevm-to-file) to survive the "dies at 10-15min"
  problem. SAVE works (164M). RESTORE is blocked on `usb-net` being non-migratable + vmstate
  renumbering when you hot-unplug it. Fix direction (untested): never cold-plug usb-net — always
  `device_add` it at runtime, so save and restore have identical device sets. Time/entropy are
  non-issues: `-rtc base=...,clock=vm` pins the clock; entropy is frozen into the state.
