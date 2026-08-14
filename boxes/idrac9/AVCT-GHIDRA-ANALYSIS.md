# Avocent ("avct") Binary RE — iDRAC9 + iDRAC6

Ghidra 12.0_DEV headless (ARM EABI5). Targets, addresses, and string offsets below are
all grounded in disassembly / `.rodata` dumps. Two binaries are stripped (`avct_util`,
`avct_login`, `avcttm`); the iDRAC6 `libavctAuth.so` ships with debug_info (not stripped).

Sources:
- iDRAC9 rootfs: `/Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs`
- iDRAC6 appweb: `/Volumes/yyy/phd/bmc/dell/idrac6-appweb`

Decompiled artifacts saved under the session scratchpad `.../out/` (libnss_avct.so.2.0.0.c,
avct_login.c, login_exec.c). Disassembly via `arm-linux-gnueabi-objdump`.

---

## TL;DR — the two crown findings

1. **`libnss_avct.so.2.0.0` is the SSH restricted-shell mechanism, and the shell is
   FULLY HARDCODED.** `_nss_avct_getpwnam_r` fabricates a passwd entry for *any* username
   with `pw_shell = "/usr/bin/rcdmShell"`. It reads **no** config and **no** AIM variable.
   `racuser` is NOT a special-cased account — it is the literal stamped into the `pw_gecos`
   field of every synthesized entry. The only gate is the **calling program name**: the
   entry is only synthesized when `__progname` is `sshd` or `avct_login`. The username
   `chassis_serial_port_user` is explicitly excluded (returns NOTFOUND).

2. **The iDRAC6 `libavctAuth.so` is NOT the SSH CLP-vs-console selector.** It is the
   **appweb (HTTPS) authentication handler module** (`AVCTAuthHandlerHandler`,
   `DataHandler::doLogin/doSCLogin/doSSOLogin/doTempLogin`, PAM + `AIMClient` + web
   sessions). There is **no `sshuser`/`racuser` string and no shell-exec selector** in it
   or anywhere else in the appweb dir. The `getVar("sshuser")→exec` backdoor mechanism the
   task expected is not in this file. Its only `system()` calls are in TLS-cert upload
   handlers (separate command-injection surface, noted below).

---

## 1. `/usr/bin/avct_util`  (iDRAC9, ARM, **stripped**)

`/usr/local/bin/avct_util` is a symlink to `../../../usr/bin/avct_util` — same binary.

**Purpose (plain English):** a low-level hardware register / memory poke-and-peek debug
CLI for the Nuvoton/Avocent "AESS" SoC. It opens the kernel memory driver `/dev/aess_memdrv`
and reads/writes physical addresses, named register groups, GPIO, I2C, PWM and ADC blocks.
**It has nothing to do with users, passwords, or `avctpasswd`** — the prior assumption that
`avct_util` provisions users or computes hashes is wrong.

**Grounding (strings; binary is stripped so no symbol addresses):**
- Device: `/dev/aess_memdrv`; error paths `fail to {open,request,read,write,release} memory driver`.
- Subcommands: `read`/`write` (`read or write hardwar registers or memories`),
  `reg` (`access hardware registers or memories`, `-g group -n name`), `cal`
  (`calculate or convert`), `debug` (`set debug level`), `time` (`time a simple command or
  show current time, unit is second`), `help`.
- Read/write usage: `-r[b|w|l] [[-a] address [-c count] | -g group [-n name] [-v]]` and the
  matching `-w[b|w|l]` — byte / word / dword access at a physical `--address`.
- Register-group namespace: `i2c0`–`i2c15`, `i2csegctl`, `i2csegsel`, `gpio0`–`gpio7`,
  `pwm0`/`pwm1`, `Analog To Digital Converter` (ADC).
- No `passwd`, `/etc/`, `/mnt/`, `cv/`, `pbkdf`, `crypt`, `hmac`, `salt`, `kuid` strings
  exist in the binary (verified by `strings | grep -i`).

**Limitation:** stripped, so per-subcommand handler addresses aren't recoverable without
manual function carving; the role is nonetheless unambiguous from the string table.

---

## 2. `/usr/lib/libnss_avct.so.2.0.0`  (iDRAC9, ARM, stripped except dynsym) — **KEY**

**Purpose:** an `nsswitch` backend (`passwd: ... avct`) whose sole job is to manufacture a
synthetic `struct passwd` so that SSH (and the custom `avct_login`) sees every iDRAC user
as a uid-1000 account whose login shell is the restricted RACADM shell `/usr/bin/rcdmShell`.

**Key function:** `_nss_avct_getpwnam_r @ 0x00010668` (file offset 0x668). It is the only
real function; everything else is PLT/init glue. `FUN_00010598` is its bump-allocator
string-copy helper (copies a C string into the NSS result buffer and stores the field ptr).

**`.rodata` string map (file offsets):**

| addr   | string                       |
|--------|------------------------------|
| 0x0880 | `chassis_serial_port_user`   |
| 0x089c | `sshd`                       |
| 0x08a4 | `avct_login`                 |
| 0x08b0 | `racuser`                    |
| 0x08b8 | `x`                          |
| 0x08bc | `/tmp/`                      |
| 0x08c4 | `/usr/bin/rcdmShell`         |

**Reconstructed logic** (from disassembly 0x668–0x83c; standard
`getpwnam_r(name, pwd, buf, buflen, errnop)` signature):

```c
nss_status _nss_avct_getpwnam_r(name, pwd, buf, buflen, errnop) {
    if (strcmp(name, "chassis_serial_port_user") == 0)   // 0x6a8
        return NSS_STATUS_NOTFOUND;                       // serial-port user handled elsewhere

    // __progname gate (0x6c0–0x838): only act for the SSH daemon or avct_login
    if (strncmp(__progname, "sshd", 4) != 0 &&            // 0x6dc
        strcmp(__progname, "avct_login") != 0) {          // 0x824
        *errnop = ENOENT;                                 // 0x82c (status=2)
        return NSS_STATUS_NOTFOUND;
    }

    if (buflen < 2*strlen(name) + 36) {                   // 0x6f8
        *errnop = ERANGE; return NSS_STATUS_TRYAGAIN;     // (-2)
    }

    pwd->pw_uid    = 1000;                                // 0x714, str [r4,#8]
    pwd->pw_gid    = 500;                                 // 0x718, str [r4,#12]
    pwd->pw_name   = name;                                // 0x734  -> buf copy
    pwd->pw_gecos  = "racuser";                           // 0x74c  (str @0x8b0)
    pwd->pw_passwd = "x";                                 // 0x764  (str @0x8b8)
    pwd->pw_dir    = "/tmp/";                             // 0x77c  (str @0x8bc)
    // stat(pw_dir); if it fails, truncate pw_dir[5]=0 (no-op for "/tmp/")   0x7b4–0x7d0
    pwd->pw_shell  = "/usr/bin/rcdmShell";                // 0x7e0  (str @0x8c4)  <<<<
    *errnop = 0;
    return NSS_STATUS_SUCCESS;                            // 0x7e4 (r0=1)
}
```

**Security-relevant takeaways:**
- The login shell is a **compile-time constant** — `/usr/bin/rcdmShell` — not read from any
  AIM/config var. There is no code path that yields any other shell. This is exactly why an
  SSH login lands in the restricted RACADM shell; bypass requires `authorized_keys
  command=` or an FSD root-shell (consistent with `reference_idrac9_ssh_shell_chain.md`).
- **`racuser` is a red herring as an "account"**: it is only ever written into `pw_gecos`
  (the comment field) of the synthesized record; no branch compares the *username* against
  `racuser`. Every username that arrives via `sshd`/`avct_login` gets uid 1000, gid 500,
  home `/tmp/`, shell `rcdmShell`.
- uid 1000 / gid 500 are hardcoded constants (0x714/0x718).

---

## 3. `/usr/bin/avct_login`  (iDRAC9, ARM, stripped)

**Purpose:** a drop-in `login(1)` replacement (`Usage: login [OPTION] [ username ]`, flags
`-f` auto-login, `-s` service, `-u` user). It runs PAM (`pam_start`/`pam_authenticate`/
`pam_acct_mgmt`/`pam_setcred`/`pam_open_session`), looks the user up with `getpwnam` (which
routes through `libnss_avct` above), sets up the environment, then `execvp`s the user's
`pw_shell`. It is the serial/console counterpart to `sshd` — and it is the second
`__progname` that `libnss_avct` trusts.

**Env-setup function (decompiled, avct_login.c ~L1255–1290):** treats `param_4` as the
`struct passwd` (word array): `param_4[0]=pw_name`, `[2]=pw_uid`, `[5]=pw_dir`,
`[6]=pw_shell`. It calls:
- `setenv("USER", pw_name, 1)` / `LOGNAME`               (USER @0x13318)
- `setenv("HOME", pw_dir, 0)`                            (HOME @0x13324)
- `if (pw_uid==0) PATH=/usr/local/sbin:...:/usr/sbin:/usr/bin else PATH=/usr/local/bin:/bin/:/usr/bin`
- `setenv("SHELL", pw_shell, 1)`  ← **SHELL = pw_shell**  (SHELL @0x1339c)

**Exec function (disassembly around `execvp@plt`):**
- `execvp` PLT @ `0x10f5c`; the single call site is `@0x115f4`.
- It branches on `strchr(pw_shell, ' ')` (`@0x1158c`):
  - **No-space (normal) path @0x118b0:** find last `/` in `pw_shell`, build a login-style
    argv0 by prefixing `'-'` to the basename, then
    `execvp(pw_shell, { pw_shell, "-<basename>", NULL })`.
    For the synthesized record this is
    `execvp("/usr/bin/rcdmShell", {"/usr/bin/rcdmShell", "-rcdmShell", NULL})`.
  - **Space path @0x115a0:** wraps the command in a shell —
    `execvp("/bin/sh", {"/bin/sh", "-sh", "-c", "<pw_shell string>", NULL})`
    (`/bin/sh`@0x1360c, `-sh`@0x13614, `-c`@0x13618).
- On exec failure it logs `Fatal: Fail to invoke SHELL %s` (@0x1361e).

**Takeaway:** `avct_login` faithfully execs whatever `pw_shell` the NSS layer returns — it
adds no shell of its own. The restriction is entirely upstream in `libnss_avct`. `/bin/sh`
appears only in the space-wrapper branch (never reached for the plain `/usr/bin/rcdmShell`).

---

## 4. Supporting Avocent binaries (brief)

### `/usr/bin/avcttm`  (ARM, stripped)
Avocent **Time-Management** daemon/test tool. Imports `libtm.so.1` and the `aim_config_*` /
`aim_event_occurred` / `aim_function_execute_DDS` API. Handles NTP config + sync
(`event_tm_ntp_config`, `tm_ntp_sync_req`, `tm_ntp_{suspend,resume,immediate_sync}`,
`tm_ntp_set/get_maxdist`, servers 1–3) and timezone (`tm_tz_set/get`,
`tm_tz_support_cities_get`). Built-in `Usage:` exposes an `event`/`api` test harness. No
auth/passwd role.

### `/usr/lib/libavctUtilLM.so.1.2.3`
Avocent **License Manager** library. Exports `LicenseItem` (`importLicense`,
`exportLicense`, `replaceLicense`, `deleteLicense`, `getStatus/getType/getExpiration/
getEntitlementID/getFEB`, `isLicenseStatusActive`) and `LDSRItemList`. Manages iDRAC feature
licenses ("LM" = License Manager). No auth/passwd/shell role.

### `/usr/lib/libavctv6.so.1.2.3`
Avocent **IPv6 + IPsec/IKE** networking library. Exports `ParseIPV6Addr`,
`INET6_addr_translate`, `add_v6_link_local`, and a large `avct_ike_*` get/set surface
(authentication, encryption, dh_group, hash, pfs_mode, sa_lifetime, policy number/enable,
remote prefix, key-exchange method). Reads/writes `/etc/sysconfig/network_config/ifcfgv6-eth0`,
`ipsec_policy/`, `ipsec/psk.txt`, `racoon_*`, `/proc/net/if_inet6`, `/var/lib/dhcpv6/`.
No auth/passwd role.

---

## 5. iDRAC6 `libavctAuth.so`  (ARM, **not stripped** — has debug_info)

**Purpose:** the **appweb HTTP(S) authentication handler module**, not an SSH shell selector.
It is an MPR/appweb `MaModule`/`MaHandler` (`AVCTAuthHandlerModule`,
`AVCTAuthHandlerHandler::{run,matchRequest,negotiate,doSSOLogin,writeAuthToSession}`) that
authenticates **web-UI / Redfish-era login requests** and writes web sessions.

**Key functions (symbol addrs):**
- `DataHandler::doLogin(MaRequest*,char*) @0x20400`
- `DataHandler::doSCLogin(MaRequest*,char*) @0x21494`  (smart-card login)
- `DataHandler::doSSOLogin(MaRequest*,char*) @0x22660`  / `AVCTAuthHandlerHandler::doSSOLogin @0x1a384`
- `DataHandler::doTempLogin(MaRequest*,char*) @0x23554`
- `DataHandler::writeAuthToSession(...PAMHelper&) @0x24764`
- `AVCTAuthHandlerHandler::run(MaRequest*) @0x19010`, `matchRequest @0x18f64`, `negotiate @0x1b278`
- `AIMClient::{initialize@0x3d7fc, getProperty@0x3db9c/0x3dd18, setProperty, callFunction@0x3e0b8, notifyEvent@0x3e2d8}`
- `PAMHelper::{converse, getAIMSessionId@0x46998, instanceForAIMId@0x46e64}`
- Globals `GUISESSIONTYPE @0x5afb4`, `VMCLISESSIONTYPE @0x5afb8` — it distinguishes
  **web GUI** vs **VM-CLI** *web* session types (this is the "console vs CLI" distinction,
  but at the appweb session layer — not a shell exec).

**Auth flow (grounded by imports/strings):** request vars via `MaRequest::getVar/setVar/
compareVar` → credentials checked through `PAMHelper::converse` (`pam_message`/`pam_response`/
`pam_close_session`/`pam_end`) and `AIMClient::getProperty/callFunction` against the AIM
object model → result written to the web session (`writeAuthToSession` /
`writeAuthResponseXML`). No `getpwnam`, no `pw_shell`, no `execvp`.

**No SSH backdoor here:** `strings`/`nm` over `libavctAuth.so` **and every other lib in the
appweb dir** (`libDataHandler.so`, `libWSManModule.so`, `appweb`, …) return **zero** matches
for `sshuser`, `racuser`, `smclp`, `clpload`, or a `/bin/sh` shell-selector. Whatever does
the iDRAC6 SSH CLP-vs-console decision lives in a different component (the SSH/SMASH-CLP
launcher binary), not in this appweb extract.

**Tangential finding — cert-upload `system()` shell-outs (command-injection surface):**
`system@plt @0x16460` is called only from TLS/credential upload handlers:
`uploadUserCert @0x2d304`, `uploadKrbKeytab @0x2da98` (×2), `uploadADCert @0x2e60c`,
`uploadKMSCert @0x2eb54`, `uploadKMCPKCSCert @0x2f2fc` (×2), `removeidrac_fw @0x2f934`,
`FirmwareStartHandler::run @0x3993c`. These build shell command lines (cert post-processing)
and are an injection-audit target — separate concern from the shell-selector task.

---

## 6. Where `avctpasswd` actually lives (neither avct_util nor libnss_avct touch it)

Confirmed by scanning the rootfs: **no binary under `usr/{bin,lib,sbin}` computes or verifies
`avctpasswd`** — only config does:
- `usr/lib/tmpfiles.d/avctpass.conf`: `C /flash/data0/cv/avctpasswd - - - - /etc/avctpasswd`
  → `/etc/avctpasswd` is a copy of the credential-vault file `/flash/data0/cv/avctpasswd`.
- `etc/init.d/credential-vault.sh:128–129`: moves `…/etc/avctpasswd` into the dm-crypt CV
  mountpoint, `chmod 640`.

So the PBKDF2-SHA384/1000 (field 2) + universal Kuid/IPMIKey (field 14) parsing is done by
the CIAM / `pam_iiam_manager` stack against the CV-mounted file, exactly as documented in
`reference_bmc_auth_architecture.md` / `reference_idrac9_factory_ipmikey.md` — **not** by any
`avct_*` utility analyzed here.

---

## Tooling notes / limitations
- `avct_util`, `avct_login`, `avcttm` are stripped; function addresses for those are derived
  by carving (objdump) rather than symbol names. `libavctAuth.so` retains symbols.
- All string offsets for the stripped iDRAC9 ELFs are **file** offsets (Ghidra rebases the
  shared objects to 0x10000; subtract 0x10000 to match the objdump column).
