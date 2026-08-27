<!-- html2md:auto source=boxes/supermicro-x10/README.html source-sha256=6464f1f3eb4359f3fbb22f2a5ff758de861e804db39ce9ff411dd18ddb708af6 body-sha256=5c3f7070514b49103f013afd85d22b240fce03f856f20e419fe53f85dc18dfc8 -->

# Virtual Supermicro X10 BMC

ASPEED **AST2400** (ARMv5TEJ), FW 3.93, emulated with `qemu-system-arm -M supermicrox11-bmc`.

Firmware: `BMC_X10AST2400-32M_20210528_03.93_STD.bin` · zoo box `zbmc supermicro-x10` · 2026-08-23

**Historical bring-up record.** The macOS/Docker attempts below explain discarded approaches. The supported 0.1.1 path is x86_64 Linux using `./build.sh supermicro-x10` and `sudo ./tools/zbmc supermicro-x10 start`.

## Why this box

THE WEAK-CIPHER ORACLE. Unlike modern BMCs (iDRAC9/10, X14 offer only cipher suites 3+17), X10-era firmware advertises the **full IPMI 2.0 cipher set 0–14** — including the RC4/MD5 suites 4,5,9–14 that ipmitool never implemented and modern BMCs dropped. This is the authorized local target for verifying zipmi’s MD5-128 (integrity alg 3) and xRC4-128/40 (confidentiality alg 2/3) against real firmware.

## Flash layout

32 MB flat flash image (`x10-master.flash`), booted directly via `-drive file=...,format=raw,if=mtd`.

| Region | Flash offset | Size | Notes |
|----|----|----|----|
| U-Boot + env | `0x000000` | 4 MB | Bootloader |
| Root CramFS | `0x400000` | ~15 MB | Read-only rootfs; symlinks as CramFS inodes |
| Kernel uImage | `0x1400000` | ~3 MB | Linux 2.6.28.9, ARMv5TEJ |
| Web CramFS | `0x1700000` | varies | Mounted on `/web` |
| JFFS2 (`/nv`) | mtdblock1 | varies | Writable persistent storage: dropbear keys, config |

## Boot & networking

The firmware zeroes its MAC on boot (no FRU/EEPROM in a flat image) and fails to bond `eth0 → bond0`, so DHCP never works. `start-x10.py` (pexpect driver) fixes this via serial console after boot:

1.  Sets a valid MAC on `eth0`
2.  Assigns the QEMU user-net static IP `10.0.2.15`
3.  Adds the default route via `10.0.2.2`
4.  Waits for `udhcpc` to give up, then re-asserts the config (race fix)
5.  Patches SSH (see below), then disconnects pexpect

Serial is a UNIX socket (`x10-serial.sock`) so `zbmc console` can attach after bootstrap via `socat`. Cold boot takes ~60s to NET_CONFIGURED.

## Issues & solutions

Issue 1: SSH probe failed (refused / booting)

**Symptom:** `zbmc status` showed SSH as “refused” even when the BMC was up.

**Root cause:** Two problems stacked. (a) `zbmc_ssh()` was undefined in `zbmc.box` — the dispatcher fell through to the default, which tried port 22 with modern key algorithms. (b) This dropbear (ancient build) only supports `ssh-rsa` and `ssh-dss`, which modern OpenSSH rejects by default.

**Fix:** Added `zbmc_ssh()` with `-o HostKeyAlgorithms=+ssh-rsa,ssh-dss -o PubkeyAcceptedAlgorithms=+ssh-rsa,ssh-dss`. Initial probe detected the SMASH-CLP banner; after the SSH patch (Issue 4), the probe pipes `echo up; exit` via stdin.

Issue 2: Console showed n/a

**Symptom:** `zbmc status` showed Console as “n/a”. Original `start-x10.py` used `-nographic`, tying the serial port to the pexpect driver’s stdio — no way for a second process to attach.

**Fix:** Rewrote to use a UNIX socket serial: `-chardev socket,id=ser0,path=$SOCK,server=on,wait=off -serial chardev:ser0`. Pexpect connects via `socat` for bootstrap, then disconnects — freeing the socket for `zbmc console`. The socket is group-accessible with mode `0660`.

Issue 3: Web (port 443) not forwarded

**Symptom:** lighttpd runs on the guest but port 443 wasn’t in the QEMU `hostfwd` list.

**Fix:** Added `hostfwd=tcp:{HOSTIP}:443-:443` to the QEMU net config.

Issue 4: SSH gives SMASH-CLP shell, not root

**Symptom:** SSH login dropped into SMASH-CLP (`/SMASH/msh`, 103 KB Insyde management shell). No `/bin/sh`, no command execution, no filesystem access.

**Investigation (Ghidra + radare2):**

- Extracted `/usr/local/dropbear/sbin/dropbear` (ARM32 PIE, stripped, 223640 bytes) from the CramFS rootfs
- Found `/SMASH/msh` string at `.rodata` offset `0x2f2c8`, adjacent to `/` (home dir) at `0x2f2c4`
- Single xref from function at `0xc7e8` (session setup): loads `obj.ses` via GOT, stores:
  - `ses+0xe4` ← `m_strdup(username)`
  - `ses+0xdc` ← `m_strdup("/")` (home directory)
  - `ses+0xe0` ← `m_strdup("/SMASH/msh")` (login shell)
- Caller at `0x161b0` (dropbear’s `fill_passwd()` equivalent): checks `ses+0xb0` (pw_name) — if NULL, unconditionally jumps to the SMASH setup path. Since `/etc/passwd` has only `root` and the SSH user is `ADMIN`, `getpwnam("ADMIN")` returns NULL → always hardcodes SMASH.

**Invocation quirk:** This custom dropbear does NOT use the standard `shell -c "command"` pattern. Instead it invokes `/SMASH/msh <username> <password> <privilege-level>` (e.g. `/SMASH/msh ADMIN ADMIN 4`). SSH exec requests are silently dropped — commands must be piped via stdin.

**Failed approaches:**

- **Binary patch + CramFS rebuild:** Patched `/SMASH/msh` → `/bin/sh\x00\x00\x00\x00` in the dropbear binary, rebuilt CramFS with `mkcramfs`. Failed: binwalk extracts CramFS symlinks as text files (e.g. `linuxrc` becomes an 11-byte file containing “bin/busybox”). `mkcramfs` treats them as regular files → kernel can’t find init → panic. Restored from backup.
- **Docker CramFS mount:** Tried `mount -t cramfs` inside Docker to properly extract. Failed: Docker on macOS shares the linuxkit kernel, which lacks the cramfs module.
- **telnetd:** Attempted to start a BusyBox telnetd for root access. Failed: this BusyBox build doesn’t include the telnetd applet.
- **Naive wrapper (`$1` = username):** First wrapper assumed dropbear passes `username [-c cmd]`. Actual invocation is `username password privilege`. `/bin/ash ADMIN` tries to open “ADMIN” as a script file → “can’t open ‘ADMIN’”.
- **tmpfs mount instead of bind mount:** Early `mount` attempt created a tmpfs directory at `/SMASH/msh` instead of a file bind mount. Content was readable via `cat` but `execve()` saw a directory.

**Working solution — runtime bind mount at boot:**

1.  Write a 3-line wrapper to `/tmp/msh`:

        #!/bin/ash
        exec /bin/ash -l

2.  `mount --bind /tmp/msh /SMASH/msh` — overlays the wrapper on the CramFS binary

3.  Kill dropbear, restart with explicit key paths: `dropbear -p 22 -r /nv/dropbear/dropbear_rsa_host_key -d /nv/dropbear/dropbear_dss_host_key` (default paths are `/etc/dropbear/` which doesn’t exist; keys live on the JFFS2 `/nv` partition)

All three steps are automated in `start-x10.py` after networking. Every `zbmc supermicro-x10 start` produces a root SSH shell from cold boot.

## Access

| Method | Command | Notes |
|----|----|----|
| IPMI | `zipmi -H 10.0.8.10 -U ADMIN -P ADMIN mc info` | RMCP+; cipher suites 0–14 |
| SSH | `zbmc supermicro-x10 ssh` | Root shell (patched at boot); commands via stdin only |
| Serial | `zbmc supermicro-x10 shell` | Root shell via UNIX socket; Ctrl-\] to detach |
| Web | `curl -sk https://x10bmc:443/` | lighttpd + stunnel |

Credentials: **ADMIN / ADMIN** (Supermicro factory default, password auth).

## Key processes

| Process                      | Role                                   |
|------------------------------|----------------------------------------|
| `ipmi_kcs 15`, `ipmi_kcs 13` | KCS IPMI channel handlers              |
| `ipmi_lan 1`                 | RMCP+ network IPMI                     |
| `ipmi_ipmb 0`, `ipmi_ipmb 5` | IPMB bus handlers                      |
| `ipmi_uart 3`                | Serial IPMI channel                    |
| `lighttpd` + `index.fcgi`    | Web interface (behind stunnel for TLS) |
| `sfcbd`                      | CIM/WBEM broker (SFCB)                 |
| `dropbear`                   | SSH (patched to root shell at boot)    |
| `ikvmserver`                 | KVM-over-IP server                     |

## Redfish (license-bypassed)

Supermicro FW 3.93 gates all Redfish endpoints behind an **OOB license check** (`license_check()` in `libipmi.so`). Without a valid license key in `/nv/ooblicense`, every endpoint past `/redfish/v1/` returns 403. The boot driver bypasses this via `LD_PRELOAD` of a 5 KB ARM .so that overrides `license_check() → return 1`, then restarts lighttpd with a wrapper script.

After bypass, 13 Supermicro OEM extensions are exposed at `/redfish/v1/Managers/1/<ext>`:

`SMCRAKP` `IPAccessControl` `NTP` `LDAP` `ActiveDirectory` `RADIUS` `SMTP` `SNMP` `Syslog` `Snooping` `FanMode` `IKVM` `MouseMode`

Auth: `curl -sk -u ADMIN:ADMIN https://10.0.8.10/redfish/v1/Managers/1`

## OOB license system (reversed)

`license_check()` in `libipmi.so` (0x666cc) gates Redfish/SNMP/OOB features. Two independent validation paths, selected by bitmask:

### Path 1 — HMAC (bit 0 / bit 1)

Factory license files `/nv/ooblicense` and `/nv/bios_license` are HMAC-SHA1 digests. Two 12-byte keys extracted from `libipmi.so` `.data` section:

| Key                | VA         | Value (hex)              | License type |
|--------------------|------------|--------------------------|--------------|
| `oob_private_key`  | `0x112230` | 8544e3b47eca58f9583043f8 | OOB (bit 0)  |
| `hsdc_private_key` | `0x112224` | 39cb2a1a3d748ff1dee46b87 | HSDC (bit 1) |

**Algorithm** (`oob_format_license_create` @ 0x66ba0):

1.  Read 6-byte board identifier from persistent storage (`at_p_St_PS + 0x28E`) — factory MAC from FRU/EEPROM on real hardware; all-zeros on QEMU flat-flash
2.  `HMAC-SHA1(private_key, board_id_6bytes)`
3.  Take first 12 bytes of the 20-byte digest
4.  Format as `XXXX - XXXX - XXXX - XXXX - XXXX - XXXX`

**Activation** (`oob_format_license_activate` @ 0x66950): tries both keys against the entered key. Either match activates the license and writes to both files.

**Keygen:** `x10-keygen.py [MAC]` generates valid OOB + HSDC keys for any board ID. Verified against the running QEMU BMC.

### Path 2 — AES (bit 3)

FRU-stored license data validated via AES-128-CBC decrypt + `verify_productkey_content`. Key derivation (`Generate_KeyIV` @ 0x4cd18):

1.  Passphrase = `UPPERCASE(MAC_no_colons)` + `"ejmb"`
2.  `MD5(passphrase)` → 16-byte digest
3.  KEY = hex-per-nibble of `digest[8:16]` → 16 ASCII bytes (each nibble → one `%x` char)
4.  IV = hex-per-nibble of `digest[0:8]` → 16 ASCII bytes

ASCII hex strings used directly as raw AES key/IV bytes (effective entropy ~64 bits). The plaintext format is complex (product info + checksum via `verify_productkey_content` @ 0x65e60); the HMAC path is sufficient for activation.

### Key functions in libipmi.so

| Function | VA | Size | Role |
|----|----|----|----|
| `license_check` | `0x666cc` | 592 | Orchestrator: bit 3 → AES/FRU, bit 0 → HMAC |
| `oob_format_license_create` | `0x66ba0` | 304 | HMAC factory license generation |
| `oob_format_license_activate` | `0x66950` | 548 | HMAC key validation (tries both keys) |
| `oob_format_license_create_file` | `0x658c8` | 532 | Write hex-dash format to /nv files |
| `check_sw_product_license` | `0x663c4` | 748 | AES/FRU decrypt + verify |
| `Generate_KeyIV` | `0x4cd18` | 308 | MAC → MD5 → hex-nibble AES key+IV |
| `verify_productkey_content` | `0x65e60` | 1344 | AES plaintext validation |

## RE artifacts

- `~/phd/tmp/x10-dropbear-re/dropbear` — extracted binary (ARM32 PIE, stripped, 223640 bytes)
- `~/phd/tmp/x10-dropbear-re/rootfs.cramfs` — extracted root CramFS (15278080 bytes)
- `/SMASH/msh` string at `.rodata` offset `0x2f2c8`; session setup at `fcn.0000c7e8`; fill_passwd equivalent at `0x161b0`

Supermicro X10 BMC · ASPEED AST2400 · FW 3.93 · qemu supermicrox11-bmc · part of the zbmc zoo · 2026-08-23.
