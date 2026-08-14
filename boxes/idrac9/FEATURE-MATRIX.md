<!--
Operational feature matrix for the virtual iDRAC9 — destined for the public
writeup (README.md + index.html). Convert to Tailwind HTML at publish time.
Status legend: full = works end-to-end | live = proven on the wire |
partial/⚠ = works with caveat | ❌ = not present.
-->
# Virtual iDRAC9 — Operational Feature Matrix

One-liner: *A software iDRAC9 that boots the real firmware and answers racadm,
IPMI, and Redfish — a protocol / management-plane emulator, not a hardware
simulator. No live sensors, no KVM, no secure enclave.*

Firmware: `firmimgFIT.d9` **7.20.30.50** (binary patch offsets are pinned to
this exact build). SoC: Nuvoton NPCM750 (Poleg, ARMv7 dual Cortex-A9) under
`qemu-system-arm -M npcm750-evb`.

| Capability | Status |
|---|---|
| Boot real Dell kernel + 177MiB rootfs (QEMU npcm750-evb) | ✅ full |
| SSH root shell (uid=0) | ✅ full |
| `racadm` get/set — real FQDD resolution, cfgdb-backed | ✅ full |
| IPMI 2.0 RMCP+ / RAKP on udp/623 | ✅ live |
| Redfish HTTPS — ServiceRoot, Managers, Systems, Chassis, Session/Account | ✅ 200s |
| Pre-auth root SSH exploit chain (OAuth `/ssh_cert`) | ✅ proven |
| Authenticated Redfish — real PAM credential gate (bad/no creds→401, valid→passes) | ✅ Tier D auth PROVEN (2026-07-04) |
| Redfish odata pipe alive to real JSON (httpd→fcgi-auth→fcgiodata) | ✅ PROVEN 2026-07-05 — real Redfish JSON on the wire (`401 application/json Base.1.8.AccessDenied` when user unprovisioned) |
| Authenticated Redfish returns 200 with real JSON | ✅ PROVEN 2026-07-05 (⚠️ load-fragile). From a clean cold boot: `GET /redfish/v1/Managers` (root:Calvin123#) → **`200` + real ManagerCollection JSON** (`@odata.type #ManagerCollection.ManagerCollection`, Members→iDRAC.Embedded.1). Prior "HW-data-model floor / 504" claim DISPROVEN — datamgr serves SMIL data (strace-confirmed). Fix was 3 config gaps: (1) seed `/var/run/unifieddatabase/HMC.db` — masking `hmc-client` skipped its `cp` ExecCondition; now baked into init.p6 authd.sh → fcgiodata reaches `active`. (2) httpd via `httpd -d /` (ServerRoot=`/`). (3) provision `idrac.users.2` root. CAVEAT: single emulated core → socket-activated fcgiodata@4200 is unstable under repeated traffic (serves ~1–2 requests then intermittent Apache `500` on re-activation). The `200` is real; sustained load needs a calmer box / fcgiodata hardening. ServiceRoot `/redfish/v1/` also intermittently 500s under load. |
| Redfish session tokens (X-Auth-Token / OAuth Bearer) | ❌ needs oauthd chain (Bearer path only) |
| Live-iterate dev harness (iterate.sh — push script to live box, read serial log; box-agnostic) | ✅ built, shared to iDRAC10 |
| QEMU checkpoint/restore (ckpt.py — skip 15min reboots / survive death) | ✅ USABLE (2026-07-06): golden `img/ckpt/golden-200-ready.gz` restores a **200-ready** box in ~15s (vs ~15min boot) with the **patched qemu** (`qemu-system-arm-patched`, migratable usb-net — see qemu-patch/). Box resumes from the exact frozen point (uptime continues; httpd+fcgiodata+creds+HMC.db all intact). **Drive it via the ttyS1 root shell** (`./console.sh`): PROVEN `curl localhost/redfish/v1/Managers = 200` from inside the restored box. CAVEAT: **host-side** network (ssh:2222/redfish:6443 from the Mac) does NOT survive restore — usb-net live-migration is solved through 3 layers (unmigratable→config→altsetting; RX-inject works) but the guest's in-flight EHCI async URBs don't resume, so end-to-end host net stalls. So: restored box is fully usable *from inside* (serial shell), not *from the host over the wire*. Bundle backed up to puffer. |
| Sensor *data plane* (live PECI/I2C/ADC/PWM reads) | ❌ static SDR from config, no live values |
| TPM, eMMC-RPMB secure store | ❌ not modeled by QEMU |
| On-chip GMAC/EMC networking | ⚠️ crashes; uses usb-net workaround |
| Video / KVM / vMedia | ❌ unmodeled |
| Multi-user.target (full 182-service boot) | ❌ dead-end; mini.target only |
| Boot time | ⚠️ 7–9 min under emu |
