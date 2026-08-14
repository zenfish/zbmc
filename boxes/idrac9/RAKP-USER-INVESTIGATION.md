# Virtual iDRAC9 — RAKP user-provisioning investigation (resume notes)

**Date:** 2026-06-24. Branch `vilo-ilo5`. HEAD `b61ba62` (the RAKP wip).
**Goal:** clear RAKP completion code `0x0d` ("unauthorized name") so virtual iDRAC9 (QEMU
npcm750-evb) authenticates IPMI 2.0 as `root`. RAKP socket already LIVE (RAKP1→RAKP2 on udp/623).

This file = full context dump so work can resume cold. Pairs with commit `b61ba62` message.

---

## ROOT CAUSE — FOUND (binary-RE confirmed)

**RAKP does NOT read `/etc/avctpasswd`.** The string `"avctpasswd"` appears in ZERO binaries in
the rootfs — fullfw physically cannot open it by name. avctpasswd is the **OS-login/PAM/NSS**
store only (via `/flash/data0/cv/avctpasswd` → `/etc/avctpasswd`, tmpfiles.d/avctpass.conf).
So the factory root entry in avctpasswd (index 2, IPMIKey `915F32…8964`) is IRRELEVANT to RAKP.

**RAKP validates the username against cfgdb.** Evidence (libsess.so.9.9.9, ARMv7):
- RAKP1 username handler: `RSSPOnSMWaitRAKP1StateRecvRAKP1` @ `0x447b6054`
- 0x0d emitted @ `libsess` `0x447b6664` (`mov r1,#13` → `RSSPReplyErrorRespData`), reached after:
  1. `UserInfoSearchByNameAndPriv` @ `0x447ade90` — walks in-memory table `G_aPSUserInfoTable`
     (semaphore-locked MemCmp on names)
  2. `snprintf` builds key `idrac.embedded.1#users.N#<field>` (fmt `"%s%d#%s%c"`)
  3. `CfgGetAttribute(...)` @ `0x447b6568` — live query to cfgdb; non-zero → "Error invalid
     user" (`0x447bba98`) → `mov r1,#13` → 0x0d
- in-memory table populated at boot by `UserInfoLoadUserConfig` @ `0x447af720` →
  `PSMgrReadAttr` @ `0x447af7ac` → cfgdb stack.
- backing DB = **`/var/run/cfgdb/CfgCurrentValues.db`** (SQLite via `libcfgdbwrapper.so.1`);
  metadata = `/var/run/cfgdb/CfgAttributeMetadata.db`.
- `CfgGetAttribute` exported by `libdellcfg.so.9.9.9`. Password/IPMIKey material for the RAKP2
  HMAC is fetched separately via `osi_getUserSHA256` → plugin `osi_function_getuser_sha256pwd`
  (in `libdccfg.so`/`libfnprv.so.9.9.9`), NOT by file path. (Second gate, after the 0x0d.)
- cfgdb is MASTER, CV/avctpasswd is DERIVATIVE: `libcfgdbwrapper` exports
  `CfgDBCopyPasswordFromSPIToCV` / `…FromEMMCToCV` (cfgdb→CV, never reverse). So hand-editing
  avctpasswd cannot help RAKP and can be overwritten from cfgdb.

**Decompiled asm saved (scratchpad):**
`/private/tmp/claude-501/-Volumes-yyy-phd-bmc-dell-idrac9-virtual/617826b1-9fcb-4ac9-b1cc-6e63518e742a/scratchpad/`
- `RSSPOnSMWaitRAKP1StateRecvRAKP1.asm` (the key one), `RSSPValidateRAKP1Msg.asm`,
  `RSSPReplyRAKP2Msg.asm`, `RSSPOnSMRecvRAKPMsg1.asm`, `UserInfoSearchByName.asm`,
  `libsess_full.asm`
- RE subagent id `a551af0e05d7361d4` (SendMessage to continue).

Relevant binaries (rootfs = `/Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs`):
- `usr/lib/ipmi/libsess.so.9.9.9` (RAKP engine)
- `usr/lib/libcfgdbwrapper.so.1.*` (SQLite cfgdb backend)
- `usr/lib/libdellcfg.so.9.9.9` (`CfgGetAttribute`)

---

## WHY THE CURRENT INJECT FAILS (leading hypothesis — NOT yet verified)

`init.p4.custom` copies our synthesized `cfgdb-defaults.db` into BOTH
`/var/lib/cfgdb/EMMC/CfgCurrentValues.db` and `/var/lib/cfgdb/SPI/CfgCurrentValues.db`.
That DB DOES contain `Users.2 = root / Enable=1 / IpmiLanPrivilege=4 / Privilege=511 /
SolEnable=1 / IPMIKey=915F32…` (set by `build-p4.sh` via UPDATEs on `CfgValueTable`).

But at runtime: `racadm get iDRAC.Users.2.UserName` → EMPTY, RAKP still 0x0d.
Meanwhile CurrentIPv4 (the IP) DOES load.

**The decisive difference:**
- CurrentIPv4 was written as a **metadata DefaultValue** in `AttributeMetaTable` (build-p4 sets
  `DefaultValue` for CurrentIPv4#Address/Netmask/Gateway/Enable AND `IsReadonly=0`).
- Users.2 was injected **only** into the SPI/EMMC `CfgValueTable` (the cfgdb-defaults.db),
  NOT into metadata defaults.

**Hypothesis:** cfgmgr/cfgdbinit builds the runtime `/var/run/cfgdb/CfgCurrentValues.db` from
**metadata DEFAULTS**, largely ignoring our hand-seeded SPI/EMMC `CfgCurrentValues.db` (real SPI
store has format/validation/signing we don't replicate, or cfgdbinit regenerates fresh). The IP
only worked because we ALSO put it in metadata defaults. Users were never put in metadata
defaults → never materialized into runtime → `G_aPSUserInfoTable` has no `root` → 0x0d.

**If hypothesis holds, the fix is symmetric with what worked:** set the Users.2 values as
**metadata DefaultValues** in the patched `cfgmeta.db` (`AttributeMetaTable`), exactly like
CurrentIPv4, and keep Users `IsReadonly=0` (build-p4 already does the readonly flip for Users).

### OPEN QUESTION blocking the fix (was mid-check when stopped)
Is `AttributeMetaTable` for the `Users` group **per-instance** (a row per GroupIndex 1..16) or
**per-group template** (ONE row for `Users.UserName` applying to all instances)?
- Schema (confirmed): `AttributeMetaTable` PK = `(FQDD, GroupName, AttributeName)` — **no
  GroupIndex column**. So metadata is a **per-group template**, indexed by FQDD, not per-instance.
- Implication: setting `DefaultValue='root'` on `Users.UserName` would default the username of
  EVERY user instance to `root` — may be acceptable (we only need instance 2 to auth) or may
  break enumeration / collide. NEEDS a decision + test.
- The FQDD column likely distinguishes instances (e.g. `iDRAC.Embedded.1` vs per-user FQDD).
  Check `SELECT DISTINCT FQDD FROM AttributeMetaTable WHERE GroupName='Users';` — if FQDD
  encodes the user index, per-instance defaults ARE possible via FQDD. **DO THIS FIRST on resume.**

Metadata DB: `/Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs/usr/share/cfgdb/CfgAttributeMetadata.db`
Users metadata attributes include: UserName, Enable, IPMIKey, IpmiLanPrivilege, Privilege,
SolEnable, Password, SHA256Password, SHA256PasswordSalt, … (full list dumped, 36 attrs).

---

## VERIFY-BEFORE-FIX PLAN (systematic-debugging Phase 1→3)

1. **Static (no boot):** `SELECT DISTINCT FQDD FROM AttributeMetaTable WHERE GroupName='Users';`
   — determine if per-instance defaults are addressable. Inspect `build-cfgdb-defaults.py` to see
   how it maps metadata→CfgValueTable rows (does it even emit Users.2 rows for the UPDATE to hit?).
2. **Live boot** `./run-p4.sh` (QEMU; Ctrl-A X to quit; `--serial-log` to tee). Then inspect the
   LIVE runtime DB the daemon actually serves:
   - `sqlite3 /var/run/cfgdb/CfgCurrentValues.db "SELECT * ... Users ..."` — confirm users.2 absent
   - compare against `/var/lib/cfgdb/SPI/CfgCurrentValues.db` (our seed) — proves SPI ignored
   - check `/tmp/cfgdbinject.log`, `/tmp/cfgdbsetup.log`, `/tmp/cfgmgr*` logs
   - This is the Phase-1.4 component-boundary evidence: seed DB (in) vs runtime DB (out).
3. **Test fix (minimal):** put Users.2 = root/Enable/IPMIKey/priv as metadata DefaultValues in
   cfgmeta.db (per-FQDD if possible, else accept all-instances=root for the test). Rebuild
   (`build-p4.sh`), reboot, `racadm get iDRAC.Users.2.UserName` → expect `root`, then RAKP with
   `zipmi -K 915F32…` (or `-P calvin`) → expect != 0x0d.
4. **Second gate:** if 0x0d clears but RAKP2 HMAC fails, chase `osi_getUserSHA256` /
   `osi_function_getuser_sha256pwd` (libdccfg/libfnprv) for where it pulls the IPMIKey/SHA256.

---

## UPDATE 2026-06-25 — static checks done; seed data PERFECT, bug is runtime load

FQDD for Users (and CurrentIPv4) = single `iDRAC.Embedded.1`. `AttributeMetaTable` PK has no
GroupIndex → metadata is a **per-group template, not per-instance addressable**. So the
"set Users.2 as metadata DefaultValue" idea is DEAD (a default would name ALL 16 slots root).

Instance mechanism FOUND: `GroupMetaTable(FQDD,GroupName,GroupType,GroupDisplayName,
GroupDescription,NoOfGroupInstances)`. For Users: `NoOfGroupInstances=16` (GroupType 16388).
So slot 2 materializes — count is NOT the blocker. Per-platform default tables exist (`evb`,
`Logan`, … one table per platform, same per-group-template shape); `evb` has 0 Users rows (normal).

Per-instance user values can ONLY live in the value store `CfgValueTable(FQDD,GroupName,
GroupIndex,AttributeName,AttributeValue,AttributeMemSize)` (PK includes GroupIndex).

Our built `img/cfgdb-defaults.db` VERIFIED CORRECT: all 16 Users GroupIndex rows present;
`Users.2` = UserName=root / Enable=1 / IPMIKey=915F32… / IpmiLanPrivilege=4 / Privilege=511 /
SolEnable=1. Schema matches. **Seed data + schema + instance count are all right.**

=> The bug is NOT the seed. It is that **cfgmgr/cfgdbinit does not load the seeded SPI/EMMC
`CfgCurrentValues.db` into the runtime `/var/run/cfgdb/CfgCurrentValues.db`** that fullfw/libsess
reads. CurrentIPv4 worked only because it was ALSO a metadata default (survives a
fresh-from-metadata build). The SPI-store load path — the only way to get exactly one user=root —
is the unverified/broken link.

### PRIME CANDIDATE FIX (lazy, ~1 line) — TEST THIS FIRST
`init.p4.custom` prep.sh copies defaults into `/var/lib/cfgdb/EMMC/CfgCurrentValues.db` and
`/var/lib/cfgdb/SPI/CfgCurrentValues.db` — but NOT `/var/run/cfgdb/CfgCurrentValues.db`.
And `cfgdb-setup.sh`→`cfgdbinit` already created an EMPTY `/var/run/cfgdb/CfgCurrentValues.db`
from metadata. If cfgmgr never re-merges SPI→runtime, that empty runtime DB is what fullfw reads.
**Fix to try:** add `/var/run/cfgdb/CfgCurrentValues.db` to the copy loop (the
`for d in …EMMC… …SPI…` loop in prep.sh), so the runtime DB carries Users.2 BEFORE cfgmgr/fullfw
start (the in-RAM `G_aPSUserInfoTable` loads once at boot — must be seeded pre-start, a late
overwrite won't refresh it).

### SINGLE LIVE CHECK to confirm (cheap; do before/after the fix)
Boot `./run-p4.sh`, on console:
```
sqlite3 /var/run/cfgdb/CfgCurrentValues.db \
  "SELECT GroupIndex,AttributeName,AttributeValue FROM CfgValueTable WHERE GroupName='Users' AND GroupIndex=2;"
cat /tmp/cfgdbsetup.log /tmp/cfgdbinject.log
ls -la --full-time /var/run/cfgdb/CfgCurrentValues.db /var/lib/cfgdb/SPI/CfgCurrentValues.db
```
- runtime has empty/no Users.2 while SPI has root  => confirms SPI not merged => apply the fix
- if runtime is rebuilt AFTER our copy (newer mtime) => cfgmgr regenerates => seed must move later
  (after cfgmgr) OR also patch wherever cfgmgr writes runtime.
Then: `racadm get iDRAC.Users.2.UserName` → expect `root`; RAKP (`zipmi -K 915F32…` / `-P calvin`)
→ expect != 0x0d.

## UPDATE 2026-06-25 (live boots) — narrowed to ONE attr, then to the CV store

Booted run-p4 three times with measurements. cfgmgr DOES load our injected Users.2 from the
SPI/EMMC store into the runtime — every attr EXCEPT UserName:
- `racadm get iDRAC.Users.2` → `IpmiLanPrivilege=4` (OUR value, loaded ✓), IPMIKey 915F32 in
  runtime ✓. But `Users.2.UserName` → EMPTY. UserName is the lone holdout → still RAKP 0x0d.

Why only UserName: metadata `DBLocation` column splits attrs across stores. Confirmed:
- IPMIKey/IpmiLanPrivilege/Enable/Privilege = **DBLocation 2** → EMMC store → tmpfs (loaded ✓)
- **UserName + Password = DBLocation 3** → the **CV (credential vault) store**, NOT copied to the
  runtime tmpfs at all.
libcfgdbwrapper builds the runtime tmpfs `/var/run/cfgdb/CfgCurrentValues.db` with exactly two
INSERT..SELECT: `FROM SPI_Flash WHERE DBLocation=1` and `FROM EMMC_Flash WHERE DBLocation=2`.
There is NO loc3→tmpfs path. loc3 (UserName/Password) is handled by
`CfgDBCopyPasswordFromEMMCToCV` / `…FromSPIToCV` (DELETE+INSERT loc3 EMMC/SPI→CV); reads resolve
in CV. CV store path = `/var/lib/cfgdb/CV/CfgCurrentValues.db`.

ROOT-OF-ROOT (boot-log smoking gun): `cfgdb-setup.sh: /var/lib/cfgdb/CV is not writable` +
`chmod: cannot operate on dangling symlink '/var/lib/cfgdb/CV'`. Source =
`usr/lib/tmpfiles.d/cfgdb.conf:16  L+ /var/lib/cfgdb/CV 0755 cfgdb cfgdb - /mnt/cv/cfgdb`.
`systemd-tmpfiles --create` (run in prep.sh) force-symlinks CV → `/mnt/cv/cfgdb` (the dm-crypt
vault mount) which DOESN'T EXIST here → dangling → CopyPasswordToCV fails → UserName never lands.
(SPI works because its tmpfiles symlink target `/flash/data1/var/lib/cfgdb/SPI` IS created by us.)

### Fixes applied to init.p4.custom so far
1. seed loop now writes EMMC+SPI+CV `CfgCurrentValues.db` (was EMMC+SPI only; /var/run was moot —
   cfgmgr regenerates it).
2. de-symlink CV before seeding: `rm -f /var/lib/cfgdb/CV; mkdir -p …/CV; chown cfgdb`.
3. **STILL EMPTY after #1+#2** — because prep's `cfgdb-setup.sh`/cfgdbinit runs BEFORE the
   de-symlink (CopyPassword already failed), and cfgmgr's later CfgDBInit apparently does NOT
   re-copy. So the de-symlink must move EARLIER (before cfgdb-setup.sh), OR CopyPassword must be
   re-triggered after CV is writable.
4. added sshd to prep (p3's exact line) → LIVE shell on host:2222 for fast iteration instead of
   ~6-min reboots. `./ssh-in.sh`.

### NEXT (live, in progress)
Over SSH: confirm CV is a real writable dir at runtime; check
`sqlite3 /var/lib/cfgdb/CV/CfgCurrentValues.db 'select * ... UserName'`; determine whether
CfgGetAttribute(UserName) reads CV or only tmpfs; manually run cfgdbinit/CopyPassword after CV is
writable and watch UserName populate; then move the de-symlink before cfgdb-setup.sh in prep and
bake the working sequence. Goal: `racadm get iDRAC.Users.2.UserName -> root`, then RAKP via
`zipmi -K 915F32… -p 6623` != 0x0d.

## ★★★ 2026-06-25 — MILESTONE 1 SOLVED: RAKP 0x0d CLEARED, root authenticates by name ★★★

The whole-session blocker is GONE. Live proof (host → virtual iDRAC9 udp 6623→623):
```
zipmi -H 127.0.0.1 -p 6623 -U root -K 915F32… -I lanplus -C 17 mc info
  → Open Session Request → reply 52B
  → RAKP Message 1       → reply 88B   (was 24B 0x0d error)
  IPMI error: RAKP2: auth code mismatch   (NOT 0x0d anymore)
```
RAKP2 returns a full 88-byte auth-code reply instead of the 24-byte `status 0x0d`. fullfw now
**accepts username root**. Only the HMAC key (milestone 2) remains.

### The two fixes that did it
1. **cfgdb (root cause):** `UserName` is metadata `DBLocation=3` (credential-vault store), which is
   broken in emulation (CV = dangling symlink to absent `/mnt/cv/cfgdb`; `CopyPasswordToCV` moves
   only secret-class attrs, never UserName). FIX in `build-p4.sh`: patch the bind-mounted
   `cfgmeta.db` `AttributeMetaTable SET DBLocation=2 WHERE Users.UserName` → UserName=root now
   rides the proven EMMC→tmpfs→datacache path (same as IPMIKey/IpmiLanPrivilege). Verified:
   `racadm get iDRAC.Users.2.UserName → root`, datacache shm `CfgStrAttribute` carries root.
2. **fullfw timing:** fullfw loads `G_aPSUserInfoTable` ONCE at startup; on a clean boot it raced
   ahead of UserName reaching the datacache → cached empty table → 0x0d despite racadm showing
   root. Proven by: restarting fullfw → 0x0d instantly clears. FIX in `init.p4.custom` dbg.sh:
   gate the fullfw launch on a live `racadm get …UserName == root` loop; also bind
   `0.0.0.0:623` (was `-l 623` = v6, though bindv6only=0 made it work anyway via SLIRP).

### Other facts nailed
- RAKP cipher suite = **17 (RAKP-HMAC-SHA256)**. Cipher 3 (sha1) is silently dropped by fullfw —
  Open Session got no reply. Always use `-C 17`.
- fullfw is socket-activated: `systemd-socket-activate --datagram -l 0.0.0.0:623 /bin/fullfw`
  from `/flash/data0/BMC_Data`, env `USER=root`.
- Right client = `~/phd/src/zipmi-git` (HEAD has `-K/--key` raw-Kuid commit ab8ae82). The
  brew-installed `zipmi` is a different/older checkout — run zipmi-git via
  `PYTHONPATH=~/phd/src/zipmi-git python3 -m zipmi.cli.zipmi …`.

## ★★★ MILESTONE 2 SOLVED — FULL RAKP AUTHENTICATION (2026-06-25) ★★★

Virtual iDRAC9 now completes RMCP+ RAKP and establishes an authenticated session as root.
Reproducible proof (3/3 attempts, scratchpad `RAKP-AUTH-PROOF.txt`):
```
Open Session → 52B → RAKP1 → RAKP2 88B → RAKP3 → RAKP4 40B → encrypted IPMI reply 68B
```
RAKP4 received = BMC validated our HMAC = authenticated. Test it: `./rakp-test.sh`.

**The key (RE-proven, binary chain in scratchpad `RAKP2-KEY-FINDINGS.md`):** fullfw HMACs with a
**hardcoded 20-byte key** = the FIRST 20 BYTES of the hex-decoded per-user IPMIKey. Not the full
32 bytes, not the 64 ASCII chars, not empty — all of which I'd tried and which mismatch on length.
Chain (libsess.so.9.9.9): `RSSPReplyRAKP2Msg`@0x447b5d64 → `RSSPGetRAKPAuthCode`@0x447b5280 (sets
`mov ip,#20` = keylen 20) → `RSSPGetKeyExchangeCode`@0x447b51b4 → `hmac_SHA256` (libipmicrypto
@0x449c2908) `__memcpy_chk(k_ipad,key,20,64)`. Key source: `UserInfoGetUserHashPWD`@0x447ae2a0 →
`osi_getUserSHA256` → hex-decode → memcpy first 20 bytes. For our user (Password empty) that
64-hex value is the IPMIKey.
→ `zipmi -K 915f32f49a97456d0d6d66eee5ed84c894b414af -C 17 -I lanplus -U root`.

RAKP2 msg order = standard `SIDm‖SIDc‖Rm‖Rc‖GUIDc‖ROLEm‖ULENm‖UNAMEm`, no Dell deviation.
Caveat (fleet): this factory IPMIKey only holds at factory/default; setting any real password
regenerates IPMIKey = UPPER(hex(SHA256(pw‖salt))) (matches the iDRAC10 unicorn proof).

Residual: post-auth IPMI commands (`mc info`) reply ~16s late under emulation (slow/mocked
sensor/SMIL backends) — a performance nit, NOT an auth issue. Auth = done.

### Clean-boot reproducibility caveat (measured)
The auth proof (3/3) was on a VM warmed ~39 min. On a FRESH boot, fullfw binds udp/623 (now IPv4,
gate confirms `UserName=root`) but its RMCP receive loop does NOT start for a long time — fullfw
sits polling `/dev/shm/datacache_*` (strace) while the udp/623 rx_queue grows (packets queued,
unread). So Open Session times out for the first ~tens of minutes after boot. This is the
project's pre-existing "fullfw slow to open udp/623" warmup (mocked sensor/SMIL/CPLD backends),
ORTHOGONAL to the RAKP user/key fixes. Once fullfw's IPMI loop is up, `./rakp-test.sh` authenticates
reliably. The user fix + key are NOT blocked by this; they're proven (boot5).

UPDATE (measured): on a fully clean boot (boot6) fullfw did NOT start its RMCP receive loop even
after >1h — Open Session timed out the whole time; a clean SIGKILL+relaunch of fullfw after config
was ready also didn't bring the listener up within minutes. So this is not merely "slow warmup":
fullfw's transition into the RMCP listen loop is nondeterministic / depends on some backend
readiness the clean mini.target boot doesn't reliably reach. boot5 (which DID authenticate) had
heavy manual poking (cfgmgr restart, fullfw kill/relaunch attempts) — one of those side effects
is what nudged fullfw into listening, not yet isolated.
=> RAKP auth (username accept + 20-byte-key HMAC) is PROVEN end-to-end on boot5 and reproducible
ONCE fullfw is listening. The remaining OPEN item is purely "make fullfw's udp/623 RMCP listener
start reliably on a clean boot" — a fullfw-startup/backend-readiness problem, decoupled from the
RAKP user/key fixes. Next: strace the boot5-vs-boot6 fullfw to find the datacache/IPC condition it
waits on before calling recvfrom on the LISTEN_FDS socket (candidates: IPMILan.Enable / LAN channel
ready, sensord SDR shm, a dfserver/datamgr IPC handshake).

### --- (historical) MILESTONE 2 investigation notes below ---
## MILESTONE 2 (remaining) — RAKP2 auth-code mismatch = wrong HMAC key
fullfw computes RAKP2/RAKP4 HMAC with the user's stored key; our `-K` bytes don't match. Tried &
FAILED: raw 32-byte IPMIKey (`915F32…`), the 64-char ASCII hex of it, and empty password. So
fullfw keys with something else. Strong lead from the earlier RE: fullfw fetches the key via
`osi_getUserSHA256` → plugin `osi_function_getuser_sha256pwd` (libdccfg/libfnprv) — i.e. the
**SHA256 password**, not the IPMIKey. Our user has empty Password/SHA256Password.
NEXT: RE `osi_function_getuser_sha256pwd` to learn the exact Kuid fullfw uses for the HMAC (is it
SHA256Password? IPMIKey? a derivation?), and what byte encoding; OR set a known SHA256Password for
Users.2 and pass the matching key. Don't brute-force key encodings blind (already 3 misses).
Useful: strace the live fullfw during a RAKP attempt to see which cfgdb attr it reads for the key.

## ★★★★★ PHASE 5 COMPLETE — full COLD-BOOT RAKP auth (2026-06-26, boot13) ★★★★★

Virtual iDRAC9 now authenticates IPMI 2.0 over RAKP on a **clean cold boot, zero manual steps**,
and runs authenticated commands. Proof (`RAKP-COLDBOOT-PROOF.txt`, reproducible):
```
zipmi -H 127.0.0.1 -p 6623 -U root -K 915f32...14af -I lanplus -C 17 mc info
  Open Session→52B → RAKP1→RAKP2 88B → RAKP3→RAKP4 40B → encrypted session
  -> Manufacturer ID 674 / Dell, IPMI 2.0, FW 3.00   (authenticated mc info)
```

### The complete cold-boot chain (every gate, in order)
1. **Socket family** — fullfw's `UDPCreateInstance` does an unconditional
   `setsockopt(IPV6_RECVPKTINFO)` that returns -1 on an AF_INET socket → fullfw exits. MUST
   socket-activate on `[::]:623` (IPv6 dual-stack, like stock `fullfw.socket BindIPv6Only=both`);
   bindv6only=0 still catches the SLIRP v4 hostfwd. (I had regressed this to `0.0.0.0:623`.)
2. **UserName load** — `Users.2#UserName` is metadata DBLocation=3 (CV store, broken in emu) →
   patch to DBLocation=2 so root flows EMMC→tmpfs→datacache.
3. **RAKP1 inclusion predicate** — THE 0x0d fix. `UserInfoSearchByNameAndPriv` requires root's
   per-channel access byte `record[37+ch]` to have priv-nibble≥4 AND bit `0x10`. That byte is built
   by `User_Access_Handler` from **`IPMIUserInfo.2#UserChannelAccess`** (8-byte per-channel blob),
   which our direct cfgdb seed never populated (factory/racadm create-flow writes it) → 0x00 → 0x0d.
   Seed `UserChannelAccess = 0x14` per channel (nibble 4 | bit 0x10; `0x14 & 0x70 = 0x10` covers the
   src2 term) + `StdPayload=0x10` insurance. (No password needed; IPMIKey stays the HMAC key.)
4. **HMAC key** — RAKP2/4 keyed with the **first 20 bytes** of the hex-decoded IPMIKey, cipher 17.

### RED HERRINGS ruled out (with proof) — don't chase these again
- `defaultusercreated` 60s park — bounded delay, NOT the blocker (kept the seed; harmless).
- NIC-index bail in `UDPCreateInstance` (libtcpi 0x376c) — NIC index is provably 0, bail never
  fires (boot9-unpatched == boot10-patched, identical). Reverted.
- libsess `UserInfoInit` load-path patch — boot12 forced it and still 0x0d; the issue was the
  inclusion predicate (UserChannelAccess), not the load path. Reverted.
- empty Password/SHA256Password — irrelevant to RAKP (IPMIKey is the credential).

### Residual (minor): first ~30s after boot may return 0x0d, then it works reliably (user table
settles shortly after fullfw start). Not a blocker — auth is solid once warm (seconds, not the old
40 min). All fixes are in `build-p4.sh` + `init.p4.custom`; `./rakp-test.sh` to verify.

## CREDENTIAL VAULT (CV) — the store behind DBLocation=3 (full note: `CV-VAULT-NOTES.md`)
The CV is why UserName (DBLocation=3) didn't load: it's iDRAC9's at-rest secret store, a dm-crypt
volume at `/mnt/cv` (← `/flash/data0/cv`), set up by `/etc/init.d/credential-vault.sh`. cfgdb's
secret-class attrs live in `/mnt/cv/cfgdb/CfgCurrentValues.db`.

Enumerated live (factory state). The vault is a single container, one subdir per secret domain,
under ONE hardcoded fleet-shared AES-256 key `00d078…3a6d` (world-readable in credential-vault.sh)
— so the encryption stops nobody who has read iDRAC9 firmware. Contents:
- `avctpasswd` — root + 16 user records (PBKDF2 pw hash, IPMIKey 915F32…, salt). [populated]
- `cfgdb/CfgCurrentValues.db` — all 16 users' Password + SNMPv3 passphrases; plus a key stored IN
  the vault: `SecureDefaultPassword.AESKey=F91BF6F12B09E262DD1A140D6B0446F7` + IV. [populated]
- `sekmkeydir` — **SEKM KMIP client credential** (the iDRAC's TLS cert+key to the external KMS).
  CORRECTION: SEKM keeps the real drive keys on an external KMS; iDRAC fetches them transiently at
  boot, doesn't store them. So CV compromise → that unit's KMIP client identity → impersonate it to
  the KMS to request its drive keys (per-unit, needs KMS reachability) — NOT drive keys in the vault.
- `krb_keytab` — iDRAC AD machine-account keytab (0B until domain-joined → AD foothold).
- `oauth`/`mod_auth_openidc`, `snmpd`, `supportassist`, `BNR`, `rm`, `private`, `power` — per-daemon
  secrets, empty at factory.

Point: the CV is a SEPARATE problem from calvin and from the RAKP CVE-2013-4786 oracle. It's one
fleet key gating a pile of high-value secrets, several NOT BMC-local (drive keys, AD keytab).
Open Q: is `SecureDefaultPassword.AESKey` per-unit or fleet-shared? (ours is a metadata default —
verify on real HW). Details + threat model: `CV-VAULT-NOTES.md`.

## KEY FILES (all in `/Volumes/yyy/phd/bmc/dell/idrac9-virtual/`)
- `build-p4.sh` — repacks initramfs; injects Users.2 into cfgdb-defaults.db; patches cfgmeta.db
  (CurrentIPv4 writable+default, Users IsReadonly=0). IPMIKEY env overridable.
- `init.p4.custom` — boot init; line ~52 copies avctpasswd to CV (RAKP-irrelevant, can ignore);
  prep.sh runs cfgdb-setup.sh + cfgdbinit, then copies cfgdb-defaults.db → SPI/EMMC
  CfgCurrentValues.db; bind-mounts patched cfgmeta over squashfs metadata.
- `run-p4.sh` — QEMU launcher (npcm750-evb, uImage.patched, p4.dtb, sd256.img snapshot=on,
  hostfwd tcp 2222→22 + udp 6623→623).
- `scripts/build-cfgdb-defaults.py` — builds cfgdb-defaults.db CfgValueTable from metadata
  defaults for a curated group subset (CVGROUPS in build-p4 includes `Users`).

## FACTORY avctpasswd root entry (for reference; RAKP-irrelevant but documents the key)
`/Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs/etc/avctpasswd` line 2:
`2:root:yhmydQG7…=:2:1:Administrator:/flash/data0/home/root:/bin/sh:0x1FF:1:946684814:1:0:0:915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964:C7D744A00CD4FD3042413C4B44141696:1`
(field2=user, field9=0x1FF priv, field14=IPMIKey, field15=salt). Matches memory
`reference_idrac9_factory_ipmikey.md`.

## STALE WEB-UI TASKS (housekeeping, not a bug)
The claude.ai web recap showing "55 running tasks" = dead ghosts from the lost dell session
(QEMU/wait jobs). Mac rebooted (uptime 2h10m), `ps` shows zero qemu/fullfw. Web UI never got the
stop signal. Cosmetic. Nothing to kill.

## NEXT ACTION ON RESUME (one line)
Run step 1 (`SELECT DISTINCT FQDD … Users`) → decide per-instance vs all-instance metadata
default → set Users.2 default in cfgmeta.db → rebuild+boot+test RAKP.
