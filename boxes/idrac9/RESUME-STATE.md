# Virtual iDRAC9 — STATE & RESUME NOTES

> **Historical investigation record.** The supported package is now cold-only with accepted ICMP, SSH,
> IPMI, and vendor Web-UI. Redfish remains unavailable in this P4 boot. The experiments below are preserved
> as evidence, not current operating instructions. Use the README and `./tools/zbmc idrac9 status -v`.

**Updated:** 2026-07-16. Read this FIRST to pick the project back up cold. Detail lives in the
companion docs cited below; this is the map + how-to-resume.

## ★ 2026-07-16 — ONE-COMMAND Redfish image + the two-image reality (for the zoo)
- **`./redfish-up.sh`** = one command → P6 boot + settle + the full bring-up over the ttyS1 CONSOLE
  (HMC.db seed → fcgiodata@4200 → manual httpd → racadm creds) → **authenticated redfish-LOCAL 200**
  (`no-auth/badpw→401, valid→200`). Codifies the 2026-07-05 recipe; drive the box from inside via
  `./console.sh`. Confirmed live this session.
- **TWO IMAGES (single-core can't do both):** `zbmc idrac9 start` = P4 = **IPMI** (fullfw). `./redfish-up.sh`
  = P6 = **Redfish** (fullfw masked). Pick one per boot. The zoo matrix marks idrac9 cells P4/P6.
- **ipmi-LOCAL works via `racadm`** (getsysinfo → FW 7.20.30.50) — Dell's on-box mgmt tool, NOT ipmitool.
- **redfish-REMOTE (from the Mac / slirp hostfwd) = STILL 400** `Base.1.8.QueryNotSupported`. NOT a
  forwarded-query issue (tested: stripping the query on the `fcgi://…%1/? [P]` proxy did NOT fix it;
  local 200 / remote 400 unchanged). Repros even from INSIDE the box hitting its own external IP
  (127.0.0.1→200, 10.0.9.9→400) — so it's the slirp-forwarded request path (REMOTE_ADDR 10.0.2.2 /
  Host / responder-internal), not Mac-specific. OPEN. redfish is usable LOCALLY only for now.
- Meta-lesson (logged in tasks/lessons.md): READ THIS DOC before re-deriving — a session burned ~2h
  re-hitting the documented httpd-cascade wedge + the `timeout -s KILL` requirement.

## ★ LATEST (2026-07-05) — "HW-data-model floor" DISPROVEN; 200-with-JSON is a 3-step config recipe
**The 2026-07-04 "floor" conclusion below (struck) was WRONG. Re-diagnosed by strace THIS session
(the box has `/usr/bin/strace` — no custom ptrace tool needed). Measured facts:**
1. **fcgiodata does NOT crash-loop, and datamgr is NOT the blocker.** strace of `dsm_sa_datamgrd`
   (pid 2833) while fcgiodata connects: datamgr **accepts the SMIL connection and ANSWERS queries** —
   returned real `lmRootKey` data (32 bytes) over `/var/run/dm/.ipc/dcsmilpipea`. The connection
   close is initiated by **fcgiodata** (datamgr sees `recv()==0`), not datamgr. ~25 populators
   (`dsm_sa_popproc cfgpop/lmpop/thermpop/...`) are up and serving. No data-plane floor.
2. **fcgiodata's real death:** full strace to `exit_group(1)` shows it reads its caches fine, then
   `openat("/var/run/unifieddatabase/HMC.db") = -1 ENOENT` right before exit. **`HMC.db` is a static
   SEED**, not HW-derived: `hmc-client.service` copies it via `ExecCondition= cp -f
   /etc/unifieddatabase/HMC.db /var/run/unifieddatabase/`. I had **masked `hmc-client`** as a
   "HW-less looper" → the seed copy never ran → fcgiodata dies. The earlier `SIGILL` = benign CPU
   feature-probe; the `SIGPIPE`/`exit_group` = self-inflicted teardown after the missing DB.
3. Copying the seed → **fcgiodata reaches `active` and STAYS** (was `activating→failed` in ~10s).
**PROVEN this session:** with (1)+(2) fixed and httpd up, the full pipe returns **real Redfish JSON
on the wire** — `GET /redfish/v1/Managers` → `401 application/json Base.1.8.AccessDenied` (proper
Redfish error envelope, not the old 504/000). The odata responder serves. Auth then failed only
because `idrac.users.2` (root) was **empty/disabled** in cfgdb (20h box lost it) → provision via
racadm.
**LITERAL 200 CONFIRMED (2026-07-05, task B).** Baked the `HMC.db` seed copy into init.p6 `authd.sh`,
rebuilt, cold-booted clean. On the fresh box: `HMC.db` present (hmcclient:udbm-writer), `fcgiodata@4200
= active`, `users.2 = root Enabled`, httpd up → `GET /redfish/v1/Managers` (root:Calvin123#) returned
**`200` + real ManagerCollection JSON** (`{"@odata.type":"#ManagerCollection.ManagerCollection",
"Members":[{"@odata.id":"/redfish/v1/Managers/iDRAC.Embedded.1"}],...}`). The wall is gone.
**CAVEAT — load fragility (emulation-inherent, not a floor):** single emu core + socket-activated
fcgiodata@4200 (Type=notify) = unstable under repeated traffic. Serves ~1–2 requests then intermittent
Apache `500` (fcgiodata instance exits/crashes, re-activation races under load). The `200` reproduces
only when the box is calm + httpd freshly (re)started. ServiceRoot `/redfish/v1/` also 500s under load.
**REMAINING POLISH (not blocking):** authd.sh's httpd bring-up (`httpd -d / -D SSL -k start` retry loop)
did NOT auto-pass the self-test on the timed cold boot (hit the 20min oneshot timeout, all 000) — the
manual livefix pattern (base_httpd.sh + a foreground `-D FOREGROUND` warm-up, THEN `-k start`) is what
bound :443 and yielded 200. Harden authd.sh to that pattern + longer TimeoutStartSec so unattended boot
self-tests green. Also consider a persistent (non-socket-activated) fcgiodata to kill the 500 flakiness.

### RECIPE to a 200 (bake into init.p6 for cold-boot validation — task B)
```sh
# 1. seed HMC.db (the copy masked hmc-client would have done)
cp -f /etc/unifieddatabase/HMC.db /var/run/unifieddatabase/
chown hmcclient:udbm-writer /var/run/unifieddatabase/HMC.db; chmod 744 /var/run/unifieddatabase/HMC.db
# 2. httpd up — MUST be CWD=/ (httpd.conf uses relative module paths lib/apache2/modules/*)
cd / && /etc/sysapps_script/base_httpd.sh && setsid /usr/sbin/apachectl start   # listens :443
# 3. provision root (cfgdb user table empty on this build)
export RACADM_ACCESS=0x1FF USER=root LOGNAME=root; . /etc/profile
racadm set idrac.users.2.UserName root;  racadm set idrac.users.2.Password 'Calvin123#'
racadm set idrac.users.2.Privilege 0x1ff; racadm set idrac.users.2.Enable Enabled
# verify (host-side, run-p6.sh forwards 6443->:443):
curl -sk -u 'root:Calvin123#' https://localhost:6443/redfish/v1/Managers/iDRAC.Embedded.1
```
Note: rootsd drive is `snapshot=on` → nothing persists; cold boot wipes cruft for free (good for B).

### ~~2026-07-04 (SUPERSEDED — kept for history)~~
~~200-with-real-JSON = BLOCKED at the data-plane floor. valid=504: fcgiodata crash-loops in provider
init; datamgr (no HW inventory) closes the SMIL socket (recv==0 + SIGPIPE), exit_group(1). Conclusion:
hardware-data-model boundary.~~ — **WRONG: datamgr serves data; cause was masked `hmc-client` seed +
httpd-down + unprovisioned user (see above).** The httpd-oneshot-cgroup finding and AUTH-proven
results from that day still stand.
**HOW TO RESUME FAST — the harness (big durable win):**
- `run-p6.sh` now boots with `-qmp`, `-rtc base=...,clock=vm`, a settled box (looper masks). `authd`
  is GATED (dormant until `touch /run/authd-go`) so the box settles clean for iteration.
- **`iterate.sh [-b idrac9|idrac10] <script.sh> <console-log>`** = the fast loop: push a script to the
  LIVE box, read its output from the host serial log (immune to the single-core ssh drops). Turns
  15-min rebuild+reboot cycles into seconds. Boot once, iterate. Also shared to iDRAC10 (see
  `bmc/dell/idrac10-virtual/LIVE-ITERATE-HANDOFF.md`).
- To reach `valid=504` (auth working, backend-blocked) on a fresh boot: boot `run-p6.sh`, wait for
  settle (AIM active, load<8), then `iterate.sh bringup-full.sh logs/p6-live.log` (creds + web + test).
- RE tools built this session (in project + vilo/ilo9, reusable): `exitcatch.c/.so` (LD_PRELOAD
  exit-logger), `ptcatch.c` (ptrace syscall tracer), `sccatch.c` (seccomp exit_group trap), `ckpt.py`
  (QEMU checkpoint — SAVE works, restore blocked on usb-net migratability; see below).
**CHECKPOINT — USABLE: 15s restore to a 200-ready box, drivable via serial shell (2026-07-06).**
Golden state: **`img/ckpt/golden-200-ready.gz`** = the box AT Redfish-200-ready (httpd bound,
fcgiodata@4200 active, root provisioned, HMC.db seeded), saved with the **patched qemu**
(`qemu-system-arm-patched`). Restore in ~15s vs ~15min boot:
```
QEMU_BIN=./qemu-system-arm-patched ./run-p6-restore.sh img/ckpt/golden-200-ready.gz   # loads PAUSED (bg it)
QEMU_NO_UNPLUG=1 python3 ckpt.py restore-finish /tmp/zbmc-idrac9-qmp.sock             # cont
./console.sh    # attach to the ttyS1 root shell -> drive the restored box
```
PROVEN on the restored box (via ttyS1 shell): uptime continues from the frozen point; all daemons
intact; `curl -k https://127.0.0.1/redfish/v1/Managers -u root:Calvin123# = 200 + JSON` **from inside**.
**HOW usb-net checkpoint works now (the qemu-patch/):** stock qemu marks usb-net `.unmigratable=1`, so
the old flow unplugged it (and npcm USB hot-plug never re-delivers to the guest -> no net on restore).
The patch (qemu-patch/0001-usb-net-migratable.patch, built by build-qemu-patched.sh) makes usb-net
migratable so it is NEVER unplugged: 3 layers fixed — (1) real VMStateDescription (not unmigratable),
(2) migrate dev.configuration + post_load SET_CONFIGURATION (else dev.config NULL -> usbnet_receive
returns -1), (3) migrate dev.altsetting[] + post_load SET_INTERFACE (CDC data iface uses alt 1 for its
bulk endpoints; SET_CONFIGURATION reset it to alt 0). Result: the `Slirp: Failed to send packet` RX
errors are GONE.
**REMAINING GAP — host-side network does NOT survive restore.** From the Mac, ssh:2222 / redfish:6443
stay dead after restore: the guest's in-flight USB bulk URBs submitted to the **EHCI** before the
checkpoint don't resume after `-incoming` (EHCI async schedule doesn't re-issue them) -> usbnet stalls.
That's a deeper host-controller migration layer below usb-net. NEXT (if pursued): EHCI async-URB
resumption, OR a clean USB device-reset-on-restore to force the guest to drop stale URBs + re-enumerate.
WORKAROUND (works today): the **console-shell.service** puts a root /bin/sh on ttyS1 (2nd -serial ->
`/tmp/zbmc-idrac9-ttyS1.sock`, attach via `./console.sh`), so the restored box is fully drivable from
INSIDE (racadm, curl-localhost redfish=200, IPMI) without host network. `net-selfheal.service` is
present but log-only (config-restore made its link-bounce unnecessary; a bounce also hangs on the EHCI
issue). Time/entropy non-issues (`clock=vm` + frozen state). GOLDEN BUNDLE (gz + boot artifacts +
patched qemu binary + patch, checksummed GOLDEN-NET.sha256) backed up to puffer
`Puffer Fish/toolz/idrac9-virtual/golden-200-ready-net-20260706.tar` (not in git, >100M).
LEGACY: the 2026-07-06 `redfish-200-ready.gz` (stock-qemu, unplug flow, no host net either) is
superseded; kept on puffer.
---

## What this is
A Dell iDRAC9 (server BMC) running entirely in software on this Mac under QEMU (`-M npcm750-evb`,
ARMv7 dual-Cortex-A9 = the real iDRAC9 Nuvoton NPCM750 SoC), booting Dell's **real** firmware
(`~/phd/bmc/idrac9-firmware/`). No PowerEdge hardware. Project dir:
`/Volumes/yyy/phd/bmc/dell/idrac9-virtual/`.

## CURRENT CAPABILITIES (all live-proven)
| Capability | How | Proof |
|---|---|---|
| **Boot to shell + real ARM binaries** | `./run.sh` (Phase 1) | done |
| **Full systemd daemon mesh** | `./run-p2.sh` (Phase 2) | done |
| **SSH root login** | `./run-p4.sh` then `./ssh-in.sh` | done |
| **Live racadm** (cfgdb object-model mesh) | p4 mesh | done |
| **Authenticated IPMI 2.0 (RAKP) as root** | `./rakp-test.sh` (cipher 17, IPMIKey HMAC) | `RAKP-COLDBOOT-PROOF.txt` |
| **Redfish REST over HTTPS** | `./start-web.sh` | `REDFISH-PROOF.txt` |

So the virtual iDRAC9 does **SSH + authenticated IPMI/RAKP + Redfish HTTPS** — a real management
plane to attack/study.

## THE CONTROL TOOL — `zbmc` (use this)
`zbmc` (in `~/phd/bin`, init.d-style) is the single entry point for every virtual BMC.
```
zbmc                       # help: lists boxes + verbs
zbmc idrac9 status         # qemu / ports / ssh / rakp / redfish health
zbmc idrac9 start [--build]   # boot detached (+ auto-bring-up web once SSH is up). --no-web to skip
zbmc idrac9 stop | restart
zbmc idrac9 ssh [cmd]      # root shell (high port; use THIS not `ssh root@drac9` if macOS Remote Login is on)
zbmc idrac9 ipmi mc info   # authenticated zipmi — key/cipher/port baked in (no flags to remember)
zbmc idrac9 web            # bring up httpd + Redfish
zbmc idrac9 console        # tail serial log
zbmc idrac9 build          # repack the Phase-4 initramfs (init.p4 + cfgdb seeds) — see build-p4.sh
zbmc idrac9 net up|down    # map standard ports 623/443/22 -> loopback 10.0.9.9 + /etc/hosts (sudo)
```
Per-box descriptor = `zbmc.box` (ports, IPMIKey, `zbmc_boot`); add a box by dropping a `zbmc.box`
in its dir + registering its path in `~/phd/bin/zbmc` REGISTRY. The `net up` verb (zbmc-net.sh,
self-sudo) gives `zipmi -H drac9 …`, `curl -k https://drac9/redfish/`, and `ssh root@drac9`
(verified to reach the BMC even with macOS Remote Login ON — socat's specific reuseaddr bind on
10.0.9.9:22 wins over the wildcard sshd via most-specific match).

## HOW TO RESUME (cold start — the raw scripts under zbmc)
1. **Build + boot** the Phase-4 box:
   ```
   cd /Volumes/yyy/phd/bmc/dell/idrac9-virtual
   IPMIKEY=915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964 ./build-p4.sh
   ./run-p4.sh        # add hostfwd=tcp::6443-:443 to run-p4.sh first if you want web from host
   ```
   Boot to the mesh + fullfw takes ~6–15 min under emulation (host-load dependent). `./ssh-in.sh`
   for a root shell once up (host port 2222).
2. **IPMI/RAKP** (udp 6623→623): `./rakp-test.sh`  → authenticated `mc info` (Manufacturer 674/Dell).
   - Client = `~/phd/src/zipmi-git` (has `-K` raw-Kuid). Run via
     `PYTHONPATH=~/phd/src/zipmi-git python3 -m zipmi.cli.zipmi -H 127.0.0.1 -p 6623 -U root -K 915f32f49a97456d0d6d66eee5ed84c894b414af -I lanplus -C 17 <cmd>`
     (the `-K` is the **first 20 bytes** of the hex IPMIKey; cipher **17** required).
3. **Web/Redfish** (tcp 6443→443): `./start-web.sh` (drives the guest over ssh). Then
   `curl -k https://localhost:6443/redfish/`.

## PHASE STATUS (roadmap = index.html)
- Phase 1 boot→shell — **done**
- Phase 2 systemd mesh — **done**
- Phase 3 SSH root — **done**
- Phase 4 live racadm mesh — **done**
- Phase 5 **RAKP / IPMI auth — DONE** (full chain below; `RAKP-USER-INVESTIGATION.md`)
- Phase 6 **Web/Redfish — Tier A+B DONE** (HTTPS service root + /redfish/v1/ HTTP 200 ServiceRoot);
  Tier C (real auth/GUI) remains. `start-web.sh`, `REDFISH-PROOF.txt`.

## THE RAKP COLD-BOOT CHAIN (Phase 5 — the hard-won 5 gates)
All baked into `build-p4.sh` + `init.p4.custom`. Full story + red-herrings in
`RAKP-USER-INVESTIGATION.md`. Summary:
1. **Socket**: fullfw must socket-activate on `[::]:623` (IPv6 dual-stack). It does an
   unconditional `setsockopt(IPV6_RECVPKTINFO)` that fails on an AF_INET socket → fullfw exits.
   (0.0.0.0:623 was a self-inflicted regression.) bindv6only=0 catches the v4 hostfwd.
2. **UserName load**: `Users.2#UserName` is metadata DBLocation=3 (CV store, broken in emu) →
   patched to DBLocation=2 so root flows EMMC→tmpfs→datacache.
3. **RAKP1 inclusion predicate (the 0x0d closer)**: `UserInfoSearchByNameAndPriv` needs root's
   per-channel access byte (record[37+ch]) to have priv-nibble≥4 AND bit 0x10. Built from
   `IPMIUserInfo.2#UserChannelAccess` — our direct seed never wrote it → 0x00 → 0x0d. Seed
   `UserChannelAccess=0x14` per channel.
4. **HMAC key**: RAKP2/4 keyed with the **first 20 bytes** of the hex-decoded IPMIKey, cipher 17.
5. (defaultusercreated seed kept — removes a bounded 60s park; orthogonal.)
RED HERRINGS (don't rechase): NIC-index bail (index is 0), libsess load-path patch, empty password.

## THE WEB/REDFISH RECIPE (Phase 6 — in start-web.sh)
Built on the running p4 box (drives guest over ssh):
1. seed self-signed cert at `/flash/data0/etc/certs/CA/certs/host.crt` + `/flash/data0/cv/private/host.key`
2. **bypass fcgi-auth for /redfish** (`Require all granted`) — the CIAM/PAM authorizer isn't wired
   in mini.target; this is the "always-allow" for the unauthenticated Redfish surface.
3. odatalite (Redfish responder) = `/usr/bin/fcgiodata`, `LD_LIBRARY_PATH=/usr/libexec/odatalite`,
   `FCGI_ODATA_RESPONDER_PORT=4200`, socket-activate 127.0.0.1:4200.
4. httpd: `httpd -d /` (ServerRoot — modules at /lib/apache2/modules) `-D SSL`, `RF_RESPONDER=4200`
   in its env (the Redfish rewrite targets `fcgi://127.0.0.1:$RF_RESPONDER`).
KNOWN ISSUES: a systemd-managed httpd.service (Requires= by fcgi-auth) keeps taking over WITHOUT
RF_RESPONDER → `fcgi://127.0.0.1:/` → "DNS lookup failure". Workaround: pkill+restart httpd with
the env; proper fix = mask httpd.service or `SetEnv RF_RESPONDER 4200`. odatalite returns
`ServiceTemporarilyUnavailable` until `unified-database-model` (UDB) is up.

## KEY FILES
- `build-p4.sh` / `init.p4.custom` — build + boot the Phase-4 box (all RAKP fixes baked in).
- `run-p4.sh` — QEMU launcher (hostfwd 2222→22, 6623→623; add 6443→443 for web).
- `rakp-test.sh` — one-command RAKP auth test.
- `start-web.sh` — web/Redfish bring-up (Tier A+B).
- `ssh-in.sh` — root shell into the running box.
- Docs: `RAKP-USER-INVESTIGATION.md` (RAKP, exhaustive), `CV-VAULT-NOTES.md` (credential vault +
  SEKM), `RAKP-COLDBOOT-PROOF.txt`, `REDFISH-PROOF.txt`, `index.html` (roadmap/landing).
- Firmware: `~/phd/bmc/idrac9-firmware/extracted/rootfs` (the squashfs unpacked, for RE).

## PHASE 6 TIER-B DONE (2026-06-28)
`/redfish/v1/` now returns HTTP 200 with ServiceRoot.json (724 bytes, real Links tree).

**Root cause of 400**: `librootprovider.so` GET handler only compared URI sub-path with "odata" and
"$metadata". Anything else (including "v1" = GET /redfish/v1/) hit the error path at 0xa30.

**Fix**: 4-byte binary patch at offset 0xa30 in `/usr/libexec/odatalite/librootprovider.so`:
- Before: `ldr r3, [pc, #136]` (error path entry)
- After:  `b 0x870` (8E FF FF EA) — jump to existing ServiceRoot.json reader
- 0x870 already reads `/etc/phit/ServiceRoot.json` → File2String → response body

**Persistence**: `init.p6.custom` now copies librootprovider.so to tmpfs, applies the 4-byte
patch, bind-mounts it over the squashfs original — survives cold boot.

**LD_PRELOAD hook retired**: `idrac9_combined_v28.so` no longer needed.
UDB (`unified-database-model.service`) creates HMC.db on its own. ZMQ stubs not required —
UDB provides the ZMQ infrastructure that fcgiodata's AttributeListener needs.

## PHASE 6 TIER-B+ DONE (2026-06-28)
All major Redfish collections 200: /Managers, /Systems, /Chassis + Managers/iDRAC.Embedded.1.

**Root cause of SYS403 on /Managers (and /Systems, /Chassis)**: `libserver-provider.so` (62 DT_NEEDED
entries) failed dlopen because `libjob-utils.so` was absent from the odatalite tmpfs. Without
libserver-provider.so loaded, all server-provider routes returned SYS403 "resource not found".
Secondary: even when loaded, `GetCurrentUserRedfishPrivilege` returns 0 (no priv) for unauthenticated
requests → every handler returns "insufficient privileges" (RAC0506).

**Fix 1 — missing library**: copy `libjob-utils.so` from squashfs to the odatalite tmpfs.
  - init.p6.custom stages it to `/tmp/libjob-utils.so` before switch_root
  - start-web.sh copies to `/usr/libexec/odatalite/` if not present

**Fix 2 — privilege bypass**: patch `GetCurrentUserRedfishPrivilege` at vaddr 0x227c in
`libauthorization-utils.so` to `mov r0, #0x0f; bx lr` (returns admin priv unconditionally).
  - Bytes: `0f 00 a0 e3 1e ff 2f e1`
  - init.p6.custom bind-mounts patched copy; survives cold boot.

Full sweep (2026-06-28, no auth, no LD_PRELOAD):
  /redfish/v1/ → 200, /odata → 200, /$metadata → 200
  /SessionService, /AccountService, /Registries, /JsonSchemas → 200
  /Managers → 200 (iDRAC.Embedded.1), /Managers/iDRAC.Embedded.1 → 200
  /Systems → 200 (System.Embedded.1), /Chassis → 200 (System.Embedded.1)

GUI (Tier C) — login UI renders but is non-functional: AngularJS init XHRs need the DM object
model (`/sysmgmt/2015/bmc/info`, ManagerAttributeRegistry). Same ceiling as live sensor data.

## PHASE 6 TIER-D — REAL SESSION AUTH (in progress 2026-07-02)
Goal: replace the `Require all granted` + `GetCurrentUserRedfishPrivilege→0x0f` bypass with the
REAL credential-validated path: `POST /redfish/v1/SessionService/Sessions {UserName,Password}` →
`X-Auth-Token`; bad creds → 401.

**"CIAM" = AIM.** No service literally named CIAM. The session daemon is **AIM**
(`/usr/bin/aim`, dbus `com.dell.idrac.aim`, lib `libaim.so.1.2.3`). It mints + validates session
tokens; PAM modules call it.

Real chain (RE'd from firmware 7.20.30.50, Explore subagent 2026-07-02):
```
apache httpd  (LocationMatch ^/redfish  in /usr/share/factory/etc/apache2/conf.d/fcgi-auth.conf:104)
  → AuthnzFcgiCheckAuthnProvider fcgi-auth → fcgi://127.0.0.1:4300/   (fcgi-auth.conf:13)
  → /usr/bin/fcgi-auth (user=authzr, StandardInput=socket via fcgi-auth.socket 127.0.0.1:4300)
      LD_PRELOAD = pam_local_manager.so pam_ldap_manager.so pam_session_manager.so pam_auth_status.so
  → PAM service /etc/pam.d/redfish :
        auth  sufficient pam_ldap_manager   (LDAP; fails-through in emu)
        auth  sufficient pam_local_manager  → aim_function_execute_DDS(user,pass) → AIM validates
        auth  required   pam_auth_status
        session required pam_session_manager → aim_session_started() → mints session id
  → 200 + X-Auth-Token: <sessid>
  → apache proxies Sessions POST to fcgiodata@4200 → libserver-provider.so ("Identified as Sessions Post")
       → 201 Created + X-Auth-Token
  subsequent req w/ X-Auth-Token → fcgi-auth again → pam_acct_mgmt → aim_session_get_info(id) → user+priv
```
Bring-up order (mini.target, deps dfserver/cfgmgr/httpd/UDB already up in p6):
`aim.service` → `aim-post.service` → `fcgi-auth.socket` + `fcgi-auth.service`, then swap apache
`/redfish` block from `Require all granted` to the AuthnzFcgi provider + `Require valid-user`.
- aim.service: ExecStart=/usr/bin/aim, After/Wants=dfserver; writes state to
  `/mnt/persistent_data/data0/aim/persistent/` (tmpfs in emu — ensure dir exists + writable).
- Credential backend = pam_local_manager → AIM local user store = cfgdb Users. **Need root's
  password attr seeded** (Users.2#Password) for local login; IPMI side used IPMIKey, not this.
EMU RISK FLAGS: pam_ldap (sufficient→harmless fail-through); oauthd optional; UDB already up;
aim persistent dir on tmpfs. Key files: /usr/bin/{aim,fcgi-auth,fcgiodata},
/lib/security/pam_*_manager.so, /etc/pam.d/redfish, /lib/systemd/system/{aim,fcgi-auth}.*,
/usr/libexec/odatalite/libserver-provider.so.

### TIER-D PROGRESS 2026-07-02 (session) — reached authorizer, blocked on oauthd chain
State reached this session (box booted, AIM already up from mesh boot):
- Restored the REAL `<LocationMatch ^/redfish>` block by copying the pristine factory config
  `/usr/share/factory/etc/apache2/conf.d/fcgi-auth.conf` over the volatile
  `/etc/apache2/conf.d/fcgi-auth.conf` (undoes start-web.sh's `Require all granted` bypass).
- fcgiodata (:4200) + fcgi-auth (:4300) must run as **systemd-run transient units** (survive
  ssh disconnect; over-ssh backgrounded daemons die on session close — the ControlMaster issue).
  `systemd-run --unit=tierd-fcgiodata --collect --setenv=LD_LIBRARY_PATH=/usr/libexec/odatalite
   --setenv=FCGI_ODATA_RESPONDER_PORT=4200 /usr/bin/systemd-socket-activate -l 127.0.0.1:4200 /usr/bin/fcgiodata`
- **fd-0 BREAKTHROUGH**: fcgi-auth is raw libfcgi — expects the listening socket on **fd 0**
  (FCGI_LISTENSOCK_FILENO). The real unit uses `StandardInput=socket` (fd 0). `systemd-socket-activate`
  hands the socket on **fd 3**, so fcgi-auth spun in oauth-init and never accepted (apache hung,
  Recv-Q piled up). FIX = dup fd3→fd0 in a wrapper:
  `systemd-run --unit=tierd-fcgiauth --collect -p User=authzr -p Group=authzr /bin/sh -c
   '. /etc/global.env; export LD_PRELOAD="/lib/security/pam_local_manager.so /lib/security/pam_ldap_manager.so /lib/security/pam_session_manager.so /lib/security/pam_auth_status.so";
    exec systemd-socket-activate -l 127.0.0.1:4300 /bin/sh -c "exec /usr/bin/fcgi-auth 0<&3"'`
  After this, apache REACHES the authorizer — hang turned into HTTP 500 (progress).
- **REMAINING WALL = oauthd.** fcgi-auth accepts one request, can't emit a full FastCGI response
  header, exits (apache `AH02497 Couldn't read from backend` → 500 → next req `Connection refused`).
  Its log shows heavy `OAuth-lib ddsc` activity → fcgi-auth needs **oauthd**. oauthd
  `Requires=httpd.service` + `After=oauthinit,sailfish` and pulls the deep multi-user chain
  (personality_module, dm-stage2/core...). httpd.service can't run here (apachectl exits 1; needs
  manual `httpd -d /`); a no-op oneshot override for httpd.service completes→inactive so it doesn't
  satisfy oauthd's Requires. This is the mini.target-vs-multi-user boundary (the 182-svc thrash).
- httpd MUST stay manual (`env RF_RESPONDER=4200 httpd -d / -D SSL -k start`); **mask httpd.service
  `--runtime`** or it respawns `/usr/sbin/httpd` WITHOUT `-d /`/RF_RESPONDER and steals :443.
- Cert `/flash/data0/etc/certs/CA/certs/host.crt` (+ cv/private/host.key) must exist or httpd
  aborts at 03-vhosts.conf:157; re-seed with openssl if `/flash/data0` was cleared.
NEXT DECISION (Tier D scope): (A) bring up oauthd's full tree under a broader target — risks
182-svc thrash; (B) scoped-faithful: satisfy/stub the oauth-lib dep so fcgi-auth does PAM Basic
validation only (401/200 gating) — proves credential-gated Redfish w/o OAuth token mint; (C) ship
release with the working privilege-bypass Redfish + this documented real-auth progress.

### TIER-D APPROACH B — REAL PAM AUTH PROVEN 2026-07-02/03 (user chose B)
**RESULT: credential-gated Redfish works.** no-auth/bad-pw on protected resources → 401 (real PAM
`redfish-basic` reject); valid pw → PASSES auth (401→503 transition = auth gate cleared, reaches
backend). fcgi-auth runs the genuine PAM stack against the iDRAC user store. NOT the priv-bypass.

Two RE facts that unblocked it (fcgi-auth binary, general-purpose subagent):
- **oauthd is a RED HERRING** — Basic auth never calls it; `oauthd_connection_init` failure is
  non-fatal (branch @vaddr 0x32a24 falls through to the FCGX accept loop). The
  `**** INTERRUPTED! EXITING ****` line is just `FCGX_Accept_r`<0 (normal teardown when apache
  closes the socket), NOT a crash. No binary patch needed. Basic path = PAM service **`redfish-basic`**
  (NOT `redfish`), functions @0x44d5c/0x4538c → `PAMHelper::authenticate`. oauthd only on Bearer path.
- fcgi-auth is raw libfcgi: wants the listen socket on **fd 0**. Real `fcgi-auth.service` uses
  `StandardInput=socket` (fd0). Use the REAL systemd socket unit — NOT `systemd-socket-activate`
  (that hands fd3; a `0<&3` dup works too but the native unit is cleaner).

WORKING RECIPE (on the booted p4/p6 box; AIM comes up with the mesh):
1. Restore real authorizer: `cp /usr/share/factory/etc/apache2/conf.d/fcgi-auth.conf
   /etc/apache2/conf.d/fcgi-auth.conf` (undoes start-web's `Require all granted`).
2. Satisfy fcgi-auth.service `Requires=httpd.service` WITHOUT running apache under systemd (apachectl
   exits 1; apache must be manual `httpd -d /`). Drop-in makes httpd.service a no-op long-runner:
   `/run/systemd/system/httpd.service.d/tierd.conf` = `[Service]\nType=simple\nExecStartPre=\nExecStart=\nExecStop=\nExecStartPost=\nExecStart=/bin/sleep infinity` ; `daemon-reload; systemctl restart httpd.service` → active.
   (Empty `Requires=` drop-in reset does NOT work on this systemd — that's why the sleep trick.)
3. `systemctl start fcgi-auth.socket` (systemd owns :4300, hands fd0 to fcgi-auth.service on connect).
4. Manual apache: `env RF_RESPONDER=4200 httpd -d / -D SSL -k start`. Cert must exist at
   /flash/data0/etc/certs/CA/certs/host.crt (+cv/private/host.key) — reseed if missing.
5. Set a POLICY-COMPLIANT root password (plain "calvin" is REJECTED by password policy → SHA256Password
   stays empty → every login fails): `racadm set iDRAC.Users.2.Password 'Calvin123#'` → populates
   SHA256Password. Then Basic `root:Calvin123#` passes PAM.
6. fcgiodata(:4200 systemd-run) + UDB(`systemctl start unified-database-model.service`) for the backend.
PROOF: `curl -sk -u root:badpw   https://127.0.0.1:443/redfish/v1/Managers` → 401;
       `curl -sk -u root:Calvin123# https://…/redfish/v1/Managers` → passes auth (503 backend).
GOTCHA: authzr(uid 1050) gets dbus `Permission denied` reading `BootstrapUsers.N#UserName` from
cfgmgr — harmless (pam_bootstrap_manager is `sufficient`, falls through to pam_local_manager).

ACCOUNT-ADD IS REAL, NOT HARDCODED (verified 2026-07-03). `racadm set iDRAC.Users.3.UserName
testuser` + `.Password Test123#` + `.Enable Enabled` + `.Privilege 0x1ff` → stored real
SHA256Password → new user authenticates to Redfish: `testuser:Test123#`→passes(503 backend),
`testuser:WRONGpw`→401. So the write path (racadm→cfgdb) + read path (Redfish PAM→cfgdb) work for
ARBITRARY new accounts. Redfish AccountService POST = same store (works once 200 works). Native
IPMI set-user writes via fullfw to the same (real, RAKP-proven) user table — likely works, untested.
Password POLICY enforced (weak pw rejected). IPMI/RAKP uses IPMIKey (HMAC, derived from pw at set).

503→200 ROOT CAUSE NAILED (RE subagent + live diag 2026-07-03): the 503 is **NOT from
fcgiodata/odata/UDB**. It is **Apache's `ErrorDocument 503`** (`httpd_redfish.conf:187` →
`/usr/local/www/rfservice/Error_Docs/redfish_error_503.json`), fired when **mod_proxy_fcgi can't
reach the backend responder**. Flow: `<LocationMatch ^/redfish>` → fcgi-auth(:4300) authorizes AND
emits `Variable-RF_RESPONDER:<port>` looked up per-URI from `/usr/share/redfish/rf_resource_info.db`
(table RedfishUris; ServiceRoot→4200) → apache rewrites to `fcgi://127.0.0.1:<port>`. So 503 =
responder on that port not accepting. HMC.db = RED HERRING (only hmc-client uses it; its
ExecCondition fails on rack/emu; not needed for ServiceRoot). Live diag: `AH00957 attempt to
connect to 127.0.0.1:4200 failed (Connection refused)` → **fcgiodata@4200 was down**, then when
started via the REAL unit (`systemctl start fcgiodata@4200.socket fcgiodata@4200.service`;
Type=notify, After=unified-database-model) it **crash-loops exit-code 1** during provider init
(pids respawn ~11s; never reaches sd_notify READY) → requests time out.
WHY crash-loop: **this box booted `mini.target` (p4-style), NOT p6.** The `init.p6.custom`
odatalite bind-mount patches (librootprovider.so `b 0x870`@0xa30 for the v1 URI; libauthorization
priv 0x0f@0x227c) are ABSENT (`mount|grep odatalite`=0). Tier B+ served 200 *because* it booted
p6 with those patches. So the clean 200 recipe = **boot `run-p6.sh`** (applies init.p6 odatalite
patches) THEN the Tier-D auth bring-up above (restore factory fcgi-auth.conf, httpd.service=sleep
trick, `fcgi-auth.socket`, real `fcgiodata@4200` units, manual `httpd -d / RF_RESPONDER=4200`,
racadm password) → authenticated 200 with real JSON. NOT achievable by more poking on the p4 box.
TODO: (1) script all of it as start-web-authd.sh on a p6 boot; (2) verify testuser can do IPMI RAKP.

P6 LIVE-200 ATTEMPT 2026-07-03 — every component works, blocked by cascade-thrash:
Booted `run-p6.sh` (initramfs.p6.xz). CONFIRMED on p6: odatalite patches bind-mounted
(`mount|grep odatalite`=2: librootprovider.so + libauthorization-utils.so); real authorizer config
ships by default (no bypass to restore); UDB → **active**; **fcgiodata@4200 → active/READY (the p4
crash-loop is GONE** once the odatalite patches are present + UDB up); manual httpd on 443; fcgi-auth
authorizer up. So the full authenticated-200 pipeline is present. ONLY remaining step = set root
creds via racadm — and that's where it died.
**THE WALL: `systemctl start {unified-database-model,httpd,fcgiodata@4200}` PULLS A DEPENDENCY
CASCADE** (55 queued jobs: oauthd, redfish-eventservice, cmcServer, xmlconfig, dsm-sa-eventmgr…
behind fullfw) that drives the emulated npcm750 to **load 15+**, then sshd drops all connections
(10 min continuous ssh-drop) — the documented multi-user-thrash dead-end. racadm can't complete
(4 sets time out >55s under load). Fresh p6 snapshot also has `Users.2.UserName` BLANK → must
`racadm set iDRAC.Users.2.UserName root` BEFORE `.Password` (else SWC0296 "user name or password
is blank").
**CORRECTED RECIPE for start-web-authd.sh (creds-first, NO cascade):** on a p6 boot, right after
mesh-ready (AIM active, ~160s) and BEFORE any web start: (1) `racadm set iDRAC.Users.2.UserName
root; .Password Calvin123#; .Enable Enabled; .Privilege 0x1ff` while box is IDLE. (2) Bring up
responders WITHOUT `systemctl start` (which pulls the cascade): use socket-activation / `systemd-run`
for fcgiodata@4200 + fcgi-auth, `systemctl start` UDB only (needed backend), manual `httpd -d /
RF_RESPONDER=4200`. Mask the cascade pull-ins (oauthd, redfish-eventservice, cmcServer, xmlconfig,
dsm-sa-*) first if they still get dragged in. (3) THEN test → expect authenticated 200.
TOOLING NOTE: zbmc ssh wedges for 1hr under high load; the shell `timeout N` (SIGTERM) does NOT
kill it — MUST use `timeout -s KILL N` + a short Bash-tool timeout to bound each call.
STATUS: authenticated-200 not yet demonstrated live (box thrashed before the racadm step); every
prerequisite proven present on p6.

P6 200 — THREE boot attempts, THE REAL CONSTRAINT (2026-07-03): the authenticated-200 could NOT be
landed via ssh orchestration. ROOT CAUSE: the guest is **SINGLE-CORE** (p4/p6 DTB = 1 CPU) and the
p6 mini.target boot queues **~68 jobs** (full mesh + web). On one emulated Cortex-A9 that saturates
the core for 10-15 min and **sshd drops ALL connections** during the storm. Adding racadm/web
bring-up over ssh mid-storm piles onto the pegged core → permanent wedge (10-15 min continuous
ssh-drop, observed 3×). CPU contention with the concurrent iDRAC10 emulator (186% vs 98%) made it
worse; pausing iDRAC10 helped but the single-core storm alone still wedges it.
MISTAKE each time: intervened WHILE the boot storm was still draining (jobs>0, load 7-14). 
TWO REAL PATHS to the live 200 (do NOT ssh-orchestrate mid-boot):
  (A) LET IT FULLY SETTLE: boot run-p6.sh, wait UNTOUCHED until jobs→0 AND load<3 (single core may
      need 15-25 min), THEN run `start-web-authd.sh`-style bring-up on the calm box. No racadm/web
      until the boot storm is completely done.
  (B) BAKE INTO init.p6 (robust, recommended for release): inject the bring-up (creds + web start +
      self-test → /tmp/result) as a boot-time step in init.p6.custom so the box self-configures
      WITHOUT interactive ssh; read /tmp/result once after settle. Rebuild via build-p6.sh.
ARTIFACT: `start-web-authd.sh` (in project + vilo/ilo9) = the full cascade-free bring-up + guest-side
self-test (creds→httpd.service sleep→UDB/fcgiodata@4200/fcgi-auth via --job-mode=ignore-dependencies
→manual httpd→curl 401/401/200 checks→/tmp/result). Ready to run on a SETTLED box or adapt into init.p6.
Also consider a **2-CPU DTB** for p6 (p4.dts forced 1 CPU for the dm_bufio/workqueue fix; if a 2nd
core is stable under p6 it would halve the boot-storm wedge) — untested, note in [[project_idrac9_virtual_qemu]].

PATH-2 BAKED INTO init.p6 — 2026-07-04, ~9 boots. tierd-authd.service now self-configures at boot
(writes result to /dev/console → host boot log, NO ssh). SIX boot bugs found+fixed, each real:
  1. Trigger: was After=multi-user.target which NEVER completes on this HW-less emu (usbmap loops
     1000s×) → After=basic.target (IS reached) + internal readiness wait.
  2. Thrash: ~68-job boot storm + HW-less restart-loopers peg the single core. MASKED the loopers
     in init.p6 (usbmap/sensord/vnc/cpld_updated/hmc-client/thermald/oauthd/vmedia/fullfw/
     gpubaseboard/dpumgr/hba-km/rsyslog) → load dropped 12→3.8. (fullfw/sensord=IPMI, oauthd=Bearer;
     none needed for Redfish Basic. Un-mask fullfw+sensord for IPMI on a non-Redfish boot.)
  3. Enable-symlink: my block ran before slirp-net created basic.target.wants → `mkdir -p` it first.
  4. racadm env: bare systemd script → every `racadm set` fails "current user privilege is not
     valid". FIX: `. /etc/profile` + `export RACADM_ACCESS=0x1FF USER=root LC_USERNAME/REMOTE_USERNAME/
     LOGNAME=root`. CONFIRMED works ("racadm set UserName -> Object value modified successfully").
  5. Password timeout: single core → racadm Password set times out. FIX: retry until SHA256
     populates. CONFIRMED ("password set OK SHA256=BAF9C7… after 2 try").
  6. Cert under load: openssl RSA-2048 heavy → move cert-gen EARLY + retry. CONFIRMED (cert OK).
PROVEN COMPONENTS (across the ~9 boots, each individually green): auth GATE (no-auth/badpw→401);
fcgiodata@4200 active/READY on p6; cert OK; racadm creds set (SHA256 populated). 
**NOT YET aligned in ONE boot: httpd-serving-:443 AND creds-set simultaneously.** httpd served
(401 gate) in boot authd3 but returned 000 in authd5/6 (creds-green boots) — the manual `httpd -d /`
vs the boot's own httpd.service ordering + single-core timing is NON-DETERMINISTIC. The backend poll
only restarts httpd if pgrep=0, so a running-but-not-serving httpd (443 not bound, likely a
boot-httpd.service-vs-manual-httpd :443 conflict) is never fixed → 000. 
NEXT (to close the last mile): (a) in authd backend-poll, if code=000 AND httpd running, pkill+restart
anyway (handle running-but-broken); mask httpd.service from boot auto-start OR ensure the manual
httpd owns :443 (check apache error_log on a calm box for the bind failure). (b) OR 2-CPU DTB to kill
the single-core non-determinism. All fixes are in init.p6.custom (committed); start-web-authd.sh is the
standalone equivalent. ROOT PATTERN: single-core emu can't deterministically orchestrate the full
multi-step web bring-up; more cores or a running-but-broken-httpd guard is the fix.

UPDATE 2026-07-04 (~12 boots) — CREDS FULLY SOLVED, httpd-from-boot is the last wall:
CONFIRMED reliably green every boot now: settle (load ~3-7 via masks), cert OK, **password set
(SHA256 populates, retry ×2)**, racadm-env fix. The ONLY remaining failure = **manual `httpd -d /
-D SSL` does not start/serve :443 when launched from the tierd-authd systemd-oneshot** (curl 000,
apache error_log EMPTY = apache never starts/logs). Yet the SAME `httpd -d /` command WORKS over
interactive ssh (start-web.sh) and worked in one early boot (authd3, got 401 gate). Diagnosis so far:
 - httpd.service takeover FIXED: baked `httpd.service.d/sleep.conf` in init.p6 (KEEP ExecStartPre=
   base_httpd.sh, replace only ExecStart with /bin/sleep) so real /usr/sbin/httpd never grabs :443.
   Also run base_httpd.sh in authd before manual httpd. Neither made manual httpd serve.
 - err EMPTY (not a cert/config error apache would log) → apache isn't even reaching startup. Suspect
   a systemd-oneshot ENV/cwd/fd difference vs the interactive shell, OR apache binds a non-127.0.0.1
   IP (the SSL vhost may bind the configured iDRAC IP, so curl 127.0.0.1:443 = 000 while the real
   bound IP would answer — UNVERIFIED; test curl to 10.0.2.15:443 and to the CurrentIPv4).
NEXT (do on a CALM box via ssh, not more blind boots): (1) run `env RF_RESPONDER=4200 httpd -d /
-D SSL -k start` by hand and read /var/log/apache2/error_log + `ss -tlnp|grep 443` to see IF/WHERE it
binds. (2) If it binds a non-loopback IP, point authd's self-test curl there. (3) ALTERNATIVELY the
cleaner fix per start-web notes: DON'T neutralize httpd.service — give it a drop-in
`Environment=RF_RESPONDER=4200` and let the REAL apache serve (it was already binding in the takeover),
dropping the manual-httpd approach entirely. (4) OR 2-CPU DTB. Interactive path already demo'd
401/401/503 this session; the p6 self-landing 200 is one httpd-bind detail away. All fixes committed
to init.p6.custom + start-web-authd.sh.
FINAL DIAGNOSIS (host+guest checked): `pgrep httpd`=0, nothing on :443 → httpd is NOT running at all
(NOT a bind-address issue). `httpd -d / -D SSL -k start` forks a daemon that DIES IMMEDIATELY when
launched from the tierd-authd **systemd oneshot** — almost certainly systemd reaping it via the
service cgroup (default KillMode=control-group kills the forked daemon when/as the oneshot manages its
cgroup). Same command persists fine over ssh (no oneshot cgroup). THE FIX (next session, high
confidence): either (a) run apache as a PROPER unit — give httpd.service a drop-in
`Environment=RF_RESPONDER=4200` and let the REAL apache serve (drop sleep-override + manual httpd
entirely; this is the start-web.sh "proper fix"), OR (b) launch manual httpd with `setsid` + set the
tierd-authd unit `KillMode=process` (or Type=forking with PIDFile) so systemd doesn't reap the apache
daemon. This is the last blocker; creds + gate + backend all proven. ~13 boots spent; stopping to
avoid further blind iteration.
TRIED + FAILED for the httpd-from-boot start (all left err EMPTY, pgrep httpd=0): (1) httpd.service
sleep-override to stop takeover; (2) keep ExecStartPre=base_httpd.sh + run it in authd; (3)
KillMode=process + RemainAfterExit on tierd-authd; (4) setsid the httpd launch. None made apache
start from the oneshot. err EMPTY = apache dies/fails BEFORE writing error_log — so it's not cert/
config (those log). MUST diagnose interactively on a CALM box (idrac10 paused, single ssh): run
`env RF_RESPONDER=4200 httpd -d / -D SSL -k start; echo $?; cat /var/log/apache2/error_log; ss -tlnp|grep 443`
by hand — that one command's exit code + error will reveal it (missing ServerRoot dir? apachectl -k
needs pidfile? a masked service removed a lib/dir apache opens? apache logs to a path that doesn't
exist under our tmpfs?). STRONGEST UNTRIED FIX: don't fight it — give httpd.service a drop-in
`Environment=RF_RESPONDER=4200` and let the REAL systemd-managed apache serve (it's a proper service,
no oneshot-cgroup issue); drop the manual-httpd entirely. That's the start-web.sh "proper fix" and
avoids the whole boot-oneshot-daemon problem.

## NEXT WORK (priority order)
1. Phase 6 Tier D: wire real fcgi-auth/AIM for authenticated Redfish/GUI/WS-Man (SEE ABOVE).
2. Explore Redfish attack surface — enumerate /redfish/v1/ tree, OEM Dell extensions.
3. Security research: Redfish + RAKP + CV-vault surfaces all live to attack locally.
4. Stability: bake full web bring-up into init.p6 for zero-step cold boot.

## QUICK FACTS
- Fleet secrets carried: root IPMIKey `915F32…8964`, CV AES key `00d078…`, root pw `calvin`
  (see `reference_idrac9_*` memories). The factory IPMIKey only holds at default state.
- zipmi client: `~/phd/src/zipmi-git` (NOT the brew `zipmi` or `~/phd/src/zipmi`).
