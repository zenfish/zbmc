# X14 virtual BMC — snapshot manifest

QMP warm-restore checkpoints (made by `snapshot-x14.sh`, restored by `restore-svc-x14.sh`).
Each is a full RAM+device state of a running SVC-mode boot. **Restore ~10s, network survives
(-incoming keeps UDP 623 + TCP 443/22 live).** Must restore with matching machine+dtb
(ast2600-evb + x14-noncsi.dtb) — the restore script handles it.

Restore any of them:  `./restore-svc-x14.sh <file>`   then drive: `socat - /tmp/x14.sock`,
`ipmitool -H 10.0.8.14 ...`, `curl -k https://10.0.8.14/...`, `ssh ADMIN@10.0.8.14`.

| snapshot | ~size | what works | notes |
|---|---|---|---|
| **svc-snap-shell.gz** | 93 MB | **IPMI + Redfish + interactive SSH shell** — the full set | ← CANONICAL / newest. smash.conf=0, devpts fixed |
| svc-snap-full-working.gz | 92 MB | IPMI (ipmitool) + Redfish (curl) | after mapperx `--service-namespaces` fix |
| svc-snap-redfish-working.gz | 92 MB | Redfish (curl) only | after bmcweb `/var/log` fix; IPMI still blocked |
| svc-snap2.gz | 92 MB | core daemons only (dbus/mapperx/ipmid/eth0), no Redfish/IPMI | pre-fixes; used as iteration base |
| svc-snap.gz | 91 MB | core daemons only | earliest; poisoned/churned |

## Access on a restored instance
- **Serial console (always):** `sudo socat - UNIX-CONNECT:/tmp/x14.sock` → root `/bin/sh` (PID1, no auth).
- **SSH shell** (shell snapshot): `ssh ADMIN@10.0.8.14` pw `ADMIN` → real Linux `/bin/sh`; `sudo -i` (pw ADMIN) → root. Or `ssh root@10.0.8.14` pw `x14pass` (root unlocked in the shell snapshot).
  - The `SMASH_ENABLE=0` in `/etc/smash.conf` is what makes SSH give a real shell instead of the SMASH-CLP shell (vendor toggle).
- **IPMI:** `ipmitool -I lanplus -H 10.0.8.14 -U ADMIN -P ADMIN user list 1 | channel info 1 | ...`
- **Redfish:** `curl -sk -u ADMIN:ADMIN https://10.0.8.14/redfish/v1/Systems`

## Making a new snapshot
`./snapshot-x14.sh <name>.gz` (pauses the VM — restore to resume). Then add a row here.

## Fixes baked into the SVC bringup (initramfs-x/init) that made each work
- bmcweb exit(255): `mkdir -p /var/volatile/log/redfish` before bmcweb (missing inotify-watch dir).
- IPMI RAKP: `mapperx --service-namespaces="$MAPPER_SERVICES"` (empty whitelist ⇒ mapper indexes nothing ⇒ ipmid wipes users).
- SSH real shell: `/etc/smash.conf` SMASH_ENABLE=0 + `mkdir -p /dev/pts` before devpts mount (ptys) + sshd -D on :22.
