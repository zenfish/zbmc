# Getting Started

Go from a fresh clone to a **running virtual server management controller (BMC)** you have a root shell
on. One box — **`advantech-asmb787`** — is fully turnkey (its firmware ships in this repo), so start there.

New to this? See the [Glossary](#glossary) at the bottom for BMC / IPMI / Redfish / MegaRAC / etc.

---

## 0. Install the tools

```bash
# macOS
brew install qemu squashfs-tools u-boot-tools dtc && pipx install jefferson

# Debian / Ubuntu
sudo apt install qemu-system-arm squashfs-tools u-boot-tools device-tree-compiler python3-pip
pip3 install jefferson
```

Then just confirm each one is installed and runs — **any recent version is fine**, you're only checking
they're on your PATH:

```bash
qemu-system-arm --version   # this repo was tested with 11.0
unsquashfs -version         #   "   squashfs-tools 4.7
dumpimage -V                #   "   u-boot-tools 2026.04
dtc --version               #   "   dtc 1.7.2
jefferson --help            #   "   jefferson (any)
```

If a command prints its version/help, you're good. If it says "command not found", re-check step 0.

---

## 1. Clone

```bash
git clone git@github.com:zenfish/zbmc-lab.git
cd zbmc-lab
export PATH="$PWD/tools:$PATH"     # so you can type 'zbmc' instead of './tools/zbmc'
```

## 2. Build the boot image

`build.sh` turns firmware into the files QEMU boots (kernel, device tree, root filesystem, flash image).
It builds every box that's ready to build; right now that's the one whose firmware ships in the repo.

```bash
./build.sh                  # builds advantech-asmb787 into work/advantech-asmb787/  (~35s)
```

Output tells you what built and what didn't:

```
BUILT   ✓ advantech-asmb787   -> work/advantech-asmb787/
ref     – idrac9   (reference recipe — supply firmware + adapt boxes/idrac9/; see docs/zoo-lessons.md)
...
```

## 3. Run it — with `zbmc`

`zbmc` is the one control tool for every box: start, log in, check status, stop. This is the easy path.

```bash
zbmc advantech-asmb787 start
```
Boots the box in the background (builds first if needed). Takes ~2 minutes under emulation.
(Cold boxes take ~2 min to services; warm-snapshot boxes like idrac10 / supermicro-x14 resume in ~15–30 s. A loaded host is slower.)

```bash
zbmc advantech-asmb787 console 'uname -a; id'
```
Runs a command on the box's serial console and prints the output. **It logs you in automatically** the
first time (as `sysadmin` / `superuser`, which is uid 0 — root). Run it again with any command.

```bash
zbmc advantech-asmb787 console
```
With no command, this attaches to the **live console** (a `tail -f`). Press Ctrl-C to detach — the box
keeps running.

```bash
zbmc advantech-asmb787 status      # is QEMU up? which ports?
zbmc advantech-asmb787 stop        # shut it down
zbmc list                          # every box in this repo
```

That's it. `zbmc <box> start` → `zbmc <box> console` is the whole loop.

---

## 4. What you just booted

A complete, running **Advantech ASMB-787** server BMC — the same firmware image that runs on the real
board — inside QEMU. Its full software stack is up (the web server, the IPMI service, the Redfish API,
the event/task daemons), and you have a **root shell** on its console. You can poke at exactly the
software a real BMC exposes to the network, without owning the hardware.

**One limitation for this particular box:** access is **console-only**. Its network services are running,
but they aren't reachable from your host over SSH/Redfish/IPMI, because this firmware's (older) kernel
can't bring its emulated network interface up under QEMU. The full story is in
[docs/from-firmware-to-bare-metal.md](docs/from-firmware-to-bare-metal.md). Other boxes in the zoo *do*
have working network access — see below.

---

## 5. Under the hood (optional)

`zbmc` is a thin wrapper. If you'd rather drive QEMU yourself, the box's own scripts do the same thing:

```bash
WD=./work/advantech-asmb787 BG=1 ./boxes/advantech-asmb787/boot.sh   # boot in background
tail -f ./work/advantech-asmb787/svc.log                            # watch it; Ctrl-C at 'login:'
# the console is a fifo — write commands to it, read output from the log:
printf 'sysadmin\n'  > ./work/advantech-asmb787/cin; sleep 1        # username
printf 'superuser\n' > ./work/advantech-asmb787/cin; sleep 1        # password
printf 'id\n'        > ./work/advantech-asmb787/cin; sleep 1
tail ./work/advantech-asmb787/svc.log
pkill -f 'mtdflash-run'                                              # stop
```

Use `zbmc` unless you're debugging the boot itself.

---

## 6. The other boxes

`boxes/<name>/` holds the recipe + findings for every BMC in the zoo (Dell iDRAC9/10, Supermicro X14,
NVIDIA GB200, HPE Cray, vanilla OpenBMC). These are **reference recipes** — their firmware is too large
for GitHub (fetch it with `./firmware/download-fw.sh`) and their scripts are written against the author's
build tree, so they're not one-command runnable from a clone yet. Read them alongside
[docs/zoo-lessons.md](docs/zoo-lessons.md), which explains each box's SoC, boot method, network trick, and
gotchas. `advantech-asmb787` is the fully worked, runnable example to learn the pattern from.

---

## Glossary

| Term | Plain English |
|------|---------------|
| **BMC** | Baseboard Management Controller — a small always-on computer on a server board that runs its own OS and lets you manage the server (power, console, sensors, firmware) remotely, even while the server is off. |
| **MegaRAC** | AMI's commercial BMC firmware (AMI = American Megatrends Inc.). Many vendors ship a rebadged MegaRAC. **SP-X** is one of AMI's MegaRAC product generations. Advantech ASMB-787 and HPE Cray XD670 both run MegaRAC SP-X. |
| **OpenBMC** | The open-source BMC firmware stack (Linux Foundation / "Phosphor"). Supermicro X14, NVIDIA GB200, and the vanilla baseline box run it. |
| **userland** | The normal programs and services that run on top of the Linux kernel (as opposed to the kernel itself). "Full userland is up" = all the BMC's services started. |
| **IPMI / RMCP+** | The classic remote-management protocol (power control, sensors, users). **RMCP+** is the authenticated IPMI-2.0 network variant; **RAKP** is its login handshake. |
| **Redfish** | The modern REST/JSON management API that's replacing IPMI. |
| **NC-SI** | Network Controller Sideband Interface — lets the BMC share the host server's physical network port. The reason `advantech-asmb787` is console-only under QEMU. |
| **AST2600 / NPCM750** | The actual chips (SoCs) BMCs run on — ASPEED AST2500/2600 and Nuvoton NPCM750/845. QEMU emulates them (`ast2600-evb`, `npcm750-evb`, …). |
| **`zbmc`** | The control tool in this repo — `zbmc <box> start|console|status|stop` for every box. |

## Troubleshooting

- **`Could not set up host forwarding rule 'udp:...:6623'`** — a previous QEMU still holds the port.
  `pkill -f 'mtdflash-run'` (or `lsof -tnP -iUDP:6623 | xargs kill -9`), then start again.
- **`login:` never appears** — give it the full ~2 min under emulation; check the box's `svc.log` for a
  kernel panic. A heavily-loaded host boots slower.
- **`console` prints nothing** — the box was still booting; wait for `login:` in `status`/`svc.log`, then
  re-run. `zbmc` logs in for you once the prompt is up.
- **`firmware not found`** — run from the repo root; `firmware/…ima_enc` must be present (it's a normal
  committed file — this repo does not use git-lfs).
