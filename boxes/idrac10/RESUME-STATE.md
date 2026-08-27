# Virtual iDRAC10 — STATE & RESUME NOTES

> **Historical investigation record (2026-06-29).** Phase status below is not current. The supported
> package now cold-boots to accepted ICMP, SSH, retained IPMI, and a static Redfish ServiceRoot in 7m37s
> on the reference host; it has no vendor Web-UI. Use the README and `./tools/zbmc idrac10 status -v`.

**Updated:** 2026-06-29. Read this first.

## What this is
Dell iDRAC10 (NPCM845 / AArch64) running under QEMU on this Mac, booting Dell's real firmware
(`~/phd/bmc/dell/idrac10-yp95x-dup/`, YP95X 1.30.10.50). Companion to the completed iDRAC9
virtual project (`../idrac9-virtual/`).

## CURRENT STATUS
| Phase | Goal | Status |
|---|---|---|
| Phase 1 | Boot to console shell | **DONE** (commit 9b40aa92b) |
| Phase 2 | Apache HTTPS + Redfish surface | **DONE** (2026-06-29) |
| Phase 3 | Redfish /redfish/v1/ HTTP 200 JSON | **DONE** (2026-06-29) |
| Phase 4 | iDRAC10 service mesh / attack surface | not started |
| Phase 5 | IPMI/RAKP auth | not started |

## HOW TO RUN (Phase 3 — Redfish HTTP 200)
```bash
cd ~/phd/bmc/dell/idrac10-virtual
./run-p3-redfish.sh      # ~5-6min; boots + Apache + static Redfish JSON
```
Waits for:
1. stmmac ndo_open() ~60-180s kernel time (varies each run)
2. crng init done (head -c 1 /dev/random blocks)
3. Apache port 443 up

Endpoints once up:
- `https://localhost:8443/`            → 403 Forbidden
- `https://localhost:8443/redfish/v1/` → **200 OK + ServiceRoot JSON**
- `https://localhost:8443/redfish/`    → **200 OK + `{"v1":"/redfish/v1/"}`**

## Phase 1 (run interactively)
```bash
./run-p1-shell.sh          # starts QEMU unix socket + shell
./connect-p1.sh            # socat to /tmp/idrac10.sock
```

## GUEST-SIDE SCRIPTS (served from /tmp/idrac10-serve/ via HTTP)
| Script | Purpose |
|---|---|
| `setup-apache.sh` | Copies Apache config, patches httpd.conf, writes TLS cert/key |
| `boot-apache-guest.sh` | Full bring-up: setup → crng wait → Apache start → port poll |
| `diag-apache.sh` | Diagnostic run: SELinux/entropy/cert/ErrorLog checks |

## KEY TECHNICAL FACTS
- **stmmac delay**: `ip link set eth0 up` blocks 60–180s (ndo_open() MDIO scan in QEMU)
- **crng timing**: `crng init done` fires at ~150–320s kernel time (interrupt jitter-based)
- **entropy fix**: `head -c 1 /dev/random > /dev/null` blocks until CSPRNG ready (Linux 5.6+)
- **python3 absent**: iDRAC10 busybox rootfs has no python3 binary
- **ErrorLog path**: `/var/log/apache2/error_log` → writable via squashfs `/var/log → /var/volatile/log`
- **cgid_module sed**: must be anchored `/^LoadModule cgid_module /d`; unanchored also deletes `<IfModule>` block
- **AVCT_VCONSOLE_PORT**: `Define` must be at httpd.conf LINE 1 (prepend, not append)
- **TLS cert**: self-signed RSA-2048, SAN=IP:127.0.0.1, CN=idrac10-virtual; AH01906/AH01909 warnings harmless
- **Port 443 binding**: tcp6 socket `::0:01BB`; grep BOTH /proc/net/tcp and /proc/net/tcp6
- **Redfish static mock**: `minimal-redfish.conf` uses `AliasMatch` to serve `/tmp/rf_root.json` → skips telemetryservice/fcgirds entirely
- **telemetryservice**: `com.dell.iDRAC.metric-engine` flatpak (22MB AArch64, 9+ Dell-specific `.so` deps including `libdelldbusclients`); can't start without D-Bus and Dell services
- **expect exit**: MUST add `exit 0` inside APACHE_READY match block or expect hangs waiting for socat EOF

## KEY DIFFERENCES FROM iDRAC9
- **Machine**: `qemu-system-aarch64 -M npcm845-evb` (64-bit AArch64 NPCM845)
  vs iDRAC9's `qemu-system-arm -M npcm750-evb` (32-bit ARMv7 NPCM750)
- **Kernel**: Linux 6.12.40 (from md.itb Image 1, gzip AArch64, 9.3MB compressed)
- **Fleet secrets identical**: calvin / 915F32F4…IPMIKey / 00d078…CredVault AES

## FIRMWARE FILES
| File | Location |
|---|---|
| Raw DUP | `~/phd/bmc/dell/idrac10-yp95x-dup/iDRAC-with-Lifecycle-Controller_Firmware_YP95X_LN64_1.30.10.50_A00.BIN` |
| Extraction | `...YP95X...A00.unpacked/` |
| md.itb (kernel+DTB) | `fw-fit-blobs/md.itb` |
| rootfs.squashfs | `fw-filesystems/rootfs.squashfs` (LZO, 253MB) |
| Extracted rootfs | `rootfs-extracted/` |

---

# OEM IPMI COMMAND RE — separate track (updated 2026-07-05)

Static + per-command reverse-engineering of Dell OEM IPMI handlers. Distinct from the
boot/virtualization phases above; uses the extracted rootfs `.so` libs, no live box needed.

## WHERE THINGS ARE (was missing — the reason a cold restart got lost)
- **ALL tmp/scratch:** `/Volumes/yyy/phd/tmp/idrac10-virtual/` (NOT `/tmp`, NOT in-repo)
- **OEM per-command output:** `/Volumes/yyy/phd/tmp/idrac10-virtual/oem-re/`
  - `docs/*.json` — 30 per-lib batch files, schema `list[{name,netfn,cmd,subcmd,priv,purpose,request,response,...}]`
  - `decomp/<lib>/` — EMPTY (decompiled .c never persisted; re-run Ghidra if needed)
- **Committed (in repo):** `idrac10-dispatch-tables.md`, `idrac9-vs-idrac10-ipmi-diff.html`,
  `dump_dispatch_tables_idrac10.py`, `tasks/todo-idrac10-cmds.md`
- **Workflow script (resumable):** `~/.claude/projects/-Volumes-yyy-phd-bmc-dell-idrac10-virtual/d815fdeb-.../workflows/scripts/idrac10-oem-cmd-re-wf_d2eb2cf5-5e6.js`

## STATUS
Committed (5fd37640b, 528bd6f8b): static map **429 tuples** (>iDRAC9's 293);
zipmi `load_vendor("idrac10")` 383 entries; iDRAC9↔10 diff HTML.
Live dynamic sweep DONE 2026-07-08 (commit 1a062b802) — earlier "BLOCKED on D-Bus"
verdict was WRONG (asserted, not measured). Fix: probe each cmd with EMPTY data — the
handler rejects at request-length validation (CC 0xc7) BEFORE it ever calls the D-Bus
backend, so dispatch is confirmed without the hang. `re-tools/live_oem_sweep.py` probes
all determined netfn/cmd (skips destructive names), classifies CC, appends resumable
JSONL; `merge_live.py` folds a SEPARATE `live` axis into the catalog (never overwrites
static `confidence`). RESULT idrac10: **342/383 (89%) confirmed real** (238 dispatched +
64 Dell-CC + 40 data), 17 gated, 24 absent, ZERO timeouts. idrac9 (10.0.9.9): **214/223
(95%)** (commit 1132a5555). Raw evidence: idrac{9,10}-live-sweep-results.jsonl. Live
badges in idrac{9,10}-oem-reference.html (gen_reference.py). DESTRUCTIVE PASS also DONE
(commit f038a7f9e): all 60 idrac10 + 53 idrac9 destructive-named cmds probed with empty
data + per-cmd liveness check (DESTRUCTIVE=1 env) — box NEVER died, 0 executed-fatal, every
one rejects empty data at request-validation. FULL COVERAGE: idrac10 402/443 real (91%),
idrac9 267/276 (97%). Nothing left live-unverified except 3 undetermined-netfn stubs.

Deep per-command workflow wf_d2eb2cf5-5e6 produced 30 `docs/*.json` batches
(**358 entries, 9 libs**: liboemcmds 106, libmisccmd 89, libmaser 66, libdcmi 60,
libmodular 22, libosa 11, + backplane/kcspassthru/serialcmds) but DIED before Synthesize.
→ Being closed 2026-07-05: merge → `idrac10-commands.json` + `idrac10-ipmi-commands.html`, move to repo, commit.

## 4-PHASE PROGRAM IN FLIGHT (2026-07-05, user-directed, workflow-driven)
1. **Close idrac10 OEM gap** — workflow `wv61kf1ph` DONE (decompile all 4 libs ok). Gap docs at
   `docs/<lib>.so.9.9.9-gap.json`: libmisccmd 9, libmodular 30, liboemcmds 19 (all verified);
   **libmaser 65** (5 dispatcher trees expanded — DellFactory/vFlash/BackupRestore/SupportAssist/
   RemoteEnablement) documented, verify was cut by session-limit → RE-VERIFY running as standalone
   agent `a9780c925a3fa54eb`. NOTE: gap files are `{lib,commands:[...]}` wrappers (not bare lists);
   `synthesize.py` patched to normalize both + sanitize polluted subcmd. Verify caught many
   inBandOnly mislabels + fabricated byte layouts (adversarial pass earned its keep).
   ON libmaser-verify DONE: re-run `synthesize.py` → regen idrac10-commands.json (~481 cmds) + HTML → commit.
   Phase-3 idrac9 workflow already authored: `tmp/idrac9-firmware/oem-re/idrac9-oem-re-wf.js`.
   → PHASE 1 COMMITTED 2026-07-05 (commit 46aedd90e): idrac10-commands.json = **447 cmds**, HTML regenerated.
2. **zipmi oem idrac10 + dox** — RUNNING: background agent `a4648c87ceb61bb4c`. Generates
   `zipmi/scapy_ipmi/oem/idrac10_commands_generated.py` (447-cmd catalog) + parser
   `parsers/idrac10_commands_json.py` + CLI `oem idrac10` doc-lookup + test; commits in zipmi repo
   (/Volumes/xxx/src/me/git/zipmi). Mirrors idrac9_generated.py pattern.
3. **idrac9 fine-tooth deep RE** — workflow `wipe69gxv` DONE (2 casualties: decompile:liboemcmds
   API-policy false-positive, document:liboemcmds-1 timeout — neither lost output). Synthesized:
   **idrac9-commands.json = 249 cmds** (liboemcmds 243, libmaser 1, libipmicmdtableapi 5), 0 dups,
   162 inBandOnly. liboemcmds-1 batch (49: vFlash/SupportAssist/ToolSet/POSTMASER) skipped verify
   → RE-VERIFY running as agent `a9589b0d1f94ada0c`. ON verify DONE: re-run idrac9 synthesize.py →
   commit idrac9-commands.json + idrac9-ipmi-commands.html. (2a/4a: wire into zipmi = task #5.)
   → idrac9 COMMITTED honest 2026-07-05 (a8c2880ca): 249 cmds, but 48 (batch liboemcmds-1)
   were FABRICATED by the timed-out agent (bodies live in libvfl/libvflash/libsupportassist,
   never imported) → verify reset them to undetermined. FIX RUNNING: workflow `w15lm97jr` /
   run `wf_5fed5dd7-0bc`, script `tmp/idrac9-firmware/oem-re/fix-batch1-wf.js` — imports the
   delegate libs, re-decompiles 9 dispatchers, re-documents to `docs-fix/{A,B}.json`, verifies.
   ON FIX DONE: merge docs-fix/A+B (+ keep body-verified CmdOEMSetMASERAccessState) into
   docs/liboemcmds.so.9.9.9-1.json → re-run idrac9 synthesize.py → commit upgrade → then Phase 4.
4. **9↔10 diff** — generator authored+syntax-clean: `tmp/idrac9-firmware/oem-re/gen_diff.py`
   (matches by handler name; buckets changed/added/removed; OEM-namespace filter on added).
   Run AFTER the fix so the 48 carry real inBandOnly/req/resp. Output idrac9-vs-idrac10-oem-diff.html.
   PREP facts: 211 entries in
   `idrac9-firmware/idrac9_runtime_dispatch.json` (netfn,cmd→symbol/priv/lib); 58 top-level
   Dell/OEM (liboemcmds 53) + dispatcher expansion; libs `idrac9-firmware/extracted/rootfs/usr/lib/ipmi/`
   (.so.9.9.9, SAME names as idrac10 → idrac10 docs are the template); `arm-linux-gnueabi-objdump`
   present (32-bit). Clone gap-close-wf.js pattern, 32-bit ARM, output idrac9-commands.json + HTML.
4. **9↔10 per-command diff** — after (1)+(3). Supersedes dispatch-tuple-only diff.

## ★ ANTI-FABRICATION (2026-07-05) — the LLM RE pipeline fabricated 3×, all caught
The multi-agent document+verify pipeline invented byte layouts when decompile
failed/timed out (48-entry liboemcmds-1 batch; DellCmdRIPSControl — LLM verifier
MISSED that one). Guard now permanent: `bmc/dell/re-tools/provenance_check.py`
grounds every cited symbol against the decomp .c corpus AND every .so's dynsym;
a symbol in neither = fabrication. Wired as a HARD GATE at the end of both
synthesize scripts (exit 1 blocks build). `--selftest` proves teeth. All 4 gens'
catalogs pass; `undetermined` beats invented. Committed 1f26007a4, 69fe30c94.
NEXT (task #6): per-entry `source` field (exact .c file+line) → exact provenance,
click-to-verify. Needs re-running document agents (cost) — user-scheduled.

## STILL TODO (beyond the 4 phases)
- Task #6: per-entry source-provenance field (bulletproof the gate; heavy re-RE)
- Unified 6↔9↔10 cross-gen doc; link from bmc/dell index

## SECURITY-NOTABLE OEM commands
- `DellCmdGetBootstrapCredentials` / `DellCmdGetMgrCertFingerprint` (netfn 0x2c) — bootstrap creds + cert fp over KCS
- `DellCPLDAccessStatus` (0x30/0xbc) — arb CPLD reg read; op=3 leaks uninitialized buffer
- `DellRollbackFW` (0x30/0xbe) — no-validation FW downgrade
- `libkcspassthru` — KCS→racadm shell bridge (RACADM_ACCESS=kcspt)
