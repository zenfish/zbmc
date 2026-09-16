# Lenovo XClarity Controller (XCC) under emulation: cold vs warm boot

*How the emulated Lenovo XCC (AST2600 BMC, "Newyork" platform) boots, why a
cold boot cannot reach full service readiness, and why warm restore is the
supported path. Companion to [zoo-lessons](zoo-lessons.md). Last updated
2026-09-16.*

## TL;DR

- **Warm restore is the working path**: full **6/6** services (ICMP, SSH, IPMI,
  Redfish, Web-UI, Console) in **~2m42s**, verified repeatedly.
- **Cold boot cannot reach full 6/6.** It serves ICMP, Console, and the
  *unauthenticated* web/Redfish surface, but every *authenticated* service
  (SSH, IPMI, Redfish, Web-UI login) never comes ready.
- **Root cause**: the vendor application `/bin/bmc_app` blocks forever on
  **host/chassis hardware handshakes that do not exist when the BMC runs with no
  server attached**. It is not a credential problem and not a CPU/speed problem.
- **Making cold work is a multi-day QEMU hardware-modeling project**, not a
  config fix. It is not worth it over warm. Cold is kept as a Web-UI seed; warm
  is production.

## 1. What "cold" and "warm" mean here

- **Cold** (`boxes/lenovo-xcc/boot.sh`, no `ZBMC_WARM`): full vendor firmware
  boot from the provisioned eMMC image (`-drive ... snapshot=on`). The vendor
  stack self-provisions during boot. Slow (tens of minutes) and gated on the
  vendor application finishing init.
- **Warm** (`boot.sh` with `ZBMC_WARM`): QEMU live-migration restore
  (`-incoming` + gzipped `ckpt/state.gz`) of a *paused, already-good* guest,
  captured once from a running box. Skips vendor init entirely. `verify-warm.py`
  hash-checks the checkpoint and requires the TAP management NIC; `restore.py`
  drives `migrate-incoming`. ~2m42s to 6/6.

This mirrors the whole zoo's biggest reliability lever
([zoo-lessons](zoo-lessons.md)): *cold-boot-flaky → warm-snapshot*. Lenovo XCC
is another instance.

## 2. Capability matrix

| Service              | Cold                  | Warm |
|----------------------|-----------------------|------|
| ICMP                 | yes                   | yes  |
| Console (serial)     | yes                   | yes  |
| Web-UI (unauth GET)  | yes (HTTP 200)        | yes  |
| Web-UI (authed login)| no                    | yes  |
| SSH                  | no (banner timeout)   | yes  |
| IPMI (RMCP+)         | no                    | yes  |
| Redfish (authed)     | no (503 -> hang)      | yes  |

## 3. Root cause: the account data plane never fills cold

All four authenticated failures collapse to one gate:

```
authed SSH / IPMI / Redfish / Web-UI login
  -> proc_sync_wait_main_processes_ready        (/etc/sysapps_script/S_COMMON.sh)
  -> proc_sync -p bmc_app -v 10 -t 120 -w       (waits for bmc_app "ready")
  -> /bin/bmc_app  avocent_initializer          (never completes cold)
  -> blocks on absent host/chassis peers:
       retimer proxy  ("retimer proxy waiting for connection...")
       twr_comm       ("twr_comm_trigger is not ready")
```

The shell-level readiness gates all have timeouts and *proceed anyway* after
~120s, so nginx/gunicorn start and the **unauthenticated** surface serves 200.
But the authenticated stack consults the account/security data plane
(`/bin/immdb_server` + `/sbin/samgr`, populated by `bmc_app` via `AB_DMProc`).
Because `bmc_app` never finishes, that data is never loaded, so authenticated
requests are refused (Redfish 503; SSH times out at banner; IPMI cannot
establish an RMCP+ session). `bmc_app` then crash-loops out via its
`lifeguardmode=respawn::<11:300> reboot` policy.

Warm works because its snapshot was taken from a guest where `bmc_app` had
already finished and the account data was resident — the restore brings that
completed state back without re-running init.

## 4. What was ruled out (with evidence)

- **Credentials / PAM** — byte-identical to the working warm guest.
  Authenticated paths return **503 (not ready)**, not 401 (auth failure). It is
  a readiness gate, not an auth problem.
- **CPU / slowness** — tested `-smp 2 -accel tcg,thread=multi` (both AST2600
  cores across idle host cores, multi-threaded TCG). Ran clean, no crash from
  the custom `xcc-fpga` machine model, and produced the **identical 2/6**
  outcome as single-vCPU. So the block is a sequence/hardware gate, not compute.
  The `-smp 2` knob was kept anyway (env-gated `ZBMC_SMP`/`ZBMC_ACCEL` in
  `boot.sh`, defaults `2`/`tcg,thread=multi`) because it is stable, warm-restore
  compatible, and speeds the one-time cold seed; it does **not** fix the gate.

## 5. What was tested and rejected: the L1 shell shim

Rather than rebuild the shell kernel blind, the cheap-shim hypothesis was tested
*live* on a stalled cold guest over the serial root shell: set
`aim_var_int_platform_id=0`, touched the ready-flags
(`manifest_ready`, `AB_DMProc_ready`), and forced
`proc_sync -p {bmc_app,sm,tm,osinet,pm,seclvd,adam} -v 10 -s`.

Result: authenticated Redfish went **503 -> 000** (fast-reject -> *hang*), never
200. Opening the gate makes Redfish actually attempt the account lookup, which
then hangs because the account data plane is genuinely empty. Confirmed on the
live guest: `aim platform_id` already `0`, all ready-flags already present, yet
`/bin/bmc_app` not running.

**No shell/flag shim can fix cold.** `bmc_app` must actually run to completion.

## 6. The real fix (L2), and why it is expensive

To let `bmc_app` finish, its two blocking peers must be provided. They were
classified by offline analysis of the platform libraries
(`libhal.so`, `libdevices.so`, `liblegoland_hv.so`, `pl_newyork`):

| Peer          | Interface | Evidence | Cost |
|---------------|-----------|----------|------|
| retimer proxy | **SOCKET** | `retimer proxy server is started.` then blocks in `accept()`; PLDM-over-MCTP IPC (`pldm_srv`, `Mctpd` daemons via `S_MCTPD.sh`) | cheap stub daemon — **but** the socket path/protocol lives inside `bmc_app` + `libpldm_proxy.so`, which must be extracted from the eMMC first |
| twr_comm      | **REGISTER** | `/dev/xcc_twr` char device; `libhal.so` `hal_*_twr` use only open/ioctl/mmap (no sockets); `twr_comm_trigger` is a field of the host<->BMC "Elx Shared TWR Control Register", set by the host/UEFI | **expensive** — QEMU-C register/char-device modeling; separate from the modeled `xcc-fpga` |

Both must complete, and both are **host/chassis-presence handshakes** that
simply do not occur when a BMC is emulated with no server powered on — the
classic "BMC without a host" wall.

**L2 therefore requires:** (a) extract `bmc_app` from the eMMC and recover the
`rtcfg` socket protocol, write a stub client daemon; **and** (b) model
`/dev/xcc_twr` in QEMU C to assert the host-handshake bits ready; **plus** an
unknown further peer chain revealed only as each is satisfied. Multi-day,
uncertain, and marginal over the working warm path.

**Cheaper alternative to check first if L2 is ever funded:** look for a vendor
"no host present / standalone" code path or config that lets
`avocent_initializer` skip the retimer/twr host handshakes, instead of emulating
them. More RE, but avoids both the socket daemon and the QEMU-C device.

## 7. Recommendation

- **Ship warm for 6/6.** It is the supported, verified path.
- **Keep cold as a Web-UI seed only.** Do **not** require SSH/IPMI/Redfish/Web
  at cold in the service contract — cold cannot hit that, and requiring it
  reports a healthy box as failed.
- **Only pursue L2** if unattended cold-to-6/6 becomes a hard requirement, and
  gate it behind the "standalone path" check above.

## 8. Reproduce the warm 6/6

Assemble a work dir with the base artifacts plus
`ckpt/{state.gz,emmc.qcow2,manifest.json,source-argv.json}` (note:
`verify-warm.py` maps the installed `kernel-shell.zImage` to the captured
*runtime* kernel hash), then:

```
sudo env ZBMC_DIR="$WARM" zbmc lenovo-xcc start --warm -v
zbmc lenovo-xcc status --all-services      # -> Health: READY [6/6]
```

## Appendix: how this was diagnosed (tooling)

- **Serial root shell** into a running guest: the diagnostic getty on ttyS4 is
  `getty -n -l /bin/bash` (no login). Send Ctrl-C first to clear a stuck `>`
  continuation prompt, then commands. A file-fed injector avoids
  ssh -> python -> serial quoting problems.
- **Test shim logic live** over serial before any kernel rebuild: one cold boot
  (~45-60 min to the stall) then iterate in seconds, instead of ~1 h per shell-
  kernel rebuild.
- **Classify hardware peers offline**: the platform libraries under a rootfs
  extract give a definitive socket-vs-register read via `strings`/`nm`/`objdump`
  without booting.
