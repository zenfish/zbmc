# Getting Started

Zero to a running virtual BMC. The **`asmb787`** box is turnkey — its firmware ships in the repo — so
start there. The other boxes are reference recipes (you supply their firmware).

## 0. Install dependencies

```bash
# macOS
brew install qemu squashfs-tools u-boot-tools dtc
pipx install jefferson          # or: pip3 install jefferson

# Debian/Ubuntu
sudo apt install qemu-system-arm squashfs-tools u-boot-tools device-tree-compiler python3-pip
pip3 install jefferson
```

Check: `qemu-system-arm --version`, `unsquashfs -version`, `dumpimage -V`, `jefferson --help`.

## 1. Clone

```bash
git clone git@github.com:zenfish/vbmc-lab.git
cd vbmc-lab
```

## 2. Firmware

- **asmb787** — already in the repo (`firmware/encrypted_ASMB-787_20220912.ima_enc`, 67 MB). Nothing to do.
- **Big boxes** (iDRAC, x14) — too large for GitHub, so fetch from the vendors:
  ```bash
  ./firmware/download-fw.sh                 # all, or:  ./firmware/download-fw.sh idrac9
  ```
  iDRAC9 downloads + checksum-verifies automatically from Dell. iDRAC10 / x14 are behind vendor
  JS/EULA pages — the script prints the exact page, filename, and expected SHA-256 to drop in and re-run.

## 3. Build the boot artifacts

Turns the firmware into what QEMU boots (`kernel.Image`, `dtb-a1.dtb`, `rootfs.sqfs`, `mtdflash.bin`).
Artifacts land in `./work/` and are not committed (regenerate anytime).

```bash
./boxes/asmb787/build.sh          # ~35 s
```

## 4. Run it — two ways

### A. Direct (simplest, no privileges)

```bash
WD=./work BG=1 ./boxes/asmb787/boot-asmb787-svc.sh
```

This backgrounds QEMU. The serial console is written to `./work/svc.log`; you drive it by writing to the
fifo `./work/cin`. Wait ~2 minutes for the `login:` prompt:

```bash
tail -f ./work/svc.log            # watch it boot; Ctrl-C when you see 'AMI... login:'
```

Log in over the fifo (console user is **`sysadmin`** / **`superuser`**, uid 0):

```bash
printf 'sysadmin\n' > ./work/cin ; sleep 1
printf 'superuser\n' > ./work/cin ; sleep 1
printf 'id; uname -a\n'  > ./work/cin ; sleep 1
tail -20 ./work/svc.log           # see the output
```

Stop it:

```bash
pkill -f 'work/mtdflash-run'
```

### B. Via the `vbmc` dispatcher (nicer front-end)

`vbmc` wraps start/stop/console/status for every box.

```bash
./tools/vbmc list                 # list the boxes
./tools/vbmc asmb787 start        # build (if needed) + boot, backgrounded
./tools/vbmc asmb787 status       # QEMU up? ports? (asmb787's network is console-only — see below)
./tools/vbmc asmb787 console 'id; uname -r'   # run one command on the console, print result
./tools/vbmc asmb787 console      # live console (tail -f); Ctrl-C to detach
./tools/vbmc asmb787 stop
```

(Put `tools/` on your PATH — `export PATH="$PWD/tools:$PATH"` — to just type `vbmc`.)

## 5. What you get with asmb787

Full MegaRAC SP-X userland: IPMIMain, redis, lighttpd, Redfish, event/task services — all running. Access
is **console only** (root shell via `sysadmin`/`superuser`). External SSH/Redfish/IPMI over host ports do
**not** work on this box — its older AMI kernel can't complete NC-SI link-up under QEMU. The full diagnosis
is in [`docs/from-firmware-to-bare-metal.md`](docs/from-firmware-to-bare-metal.md).

## 6. The other boxes

`boxes/{cray,x14,idrac9,idrac10,gb200,evb-openbmc}/` hold each box's `vbmc.box` + boot/build/restore
recipes + findings docs. They point at the author's build artifacts, so they're **reference recipes**, not
one-command runnable from a clone — use them alongside [`docs/zoo-lessons.md`](docs/zoo-lessons.md), which
explains the per-SoC boot method, network trick, and gotchas for each. `asmb787` is the fully worked,
runnable example.

## Troubleshooting

- **`Could not set up host forwarding rule 'udp:...:6623'`** — a previous QEMU is still holding the port.
  `pkill -f 'work/mtdflash-run'` (or `lsof -tnP -iUDP:6623 | xargs kill -9`), then start again.
- **`firmware not found`** — run from the repo root, and make sure `firmware/…ima_enc` is present
  (`git lfs` is *not* used; the asmb787 image is a normal committed file).
- **`login:` never appears** — give it the full ~2 min under emulation; check `./work/svc.log` for a panic.
- **`jefferson`/`dumpimage` missing** — see step 0; `build.sh` needs them to carve the firmware.
