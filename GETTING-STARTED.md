# Getting Started

This guide takes a fresh x86_64 Linux host from clone to a functional virtual BMC. Start with the
upstream `openbmc` image: it is the clean control in this repository and has accepted SSH, IPMI,
Redfish, and Web-UI paths.

## Host boundary

zbmc 0.1.1 supports **x86_64 Linux only**. The packaged QEMU executables and their SHA-256 contracts do
not run on ARM64, Raspberry Pi, Apple Silicon, macOS, or other operating systems. `build.sh` rejects an
unsupported host before downloading anything.

For one BMC at a time, roughly 2 GiB RAM and 5 GiB free disk is a useful starting point. Those are
operator guidelines, not enforced limits. Cold boot is CPU- and load-sensitive.

## 1. Install host packages

On Debian 13:

```bash
sudo apt update
sudo apt install docker.io curl git ca-certificates \
  squashfs-tools u-boot-tools device-tree-compiler qemu-utils \
  expect gcc-aarch64-linux-gnu sshpass socat netcat-openbsd \
  iproute2 iputils-ping tcpdump libarchive-tools python3-pexpect \
  python3-venv pipx
pipx install jefferson
```

Start Docker if the package did not do so:

```bash
sudo systemctl enable --now docker
sudo docker info
```

`build.sh` can use Docker directly or through `sudo`; membership in the `docker` group is optional.
Docker group membership is effectively root access, so do not add it only to avoid typing `sudo`.

## 2. Clone and select the tools

```bash
git clone https://github.com/zenfish/zbmc.git
cd zbmc
export PATH="$PWD/tools:$HOME/.local/bin:$PATH"
```

The project has one supported branch: `main`.

## 3. Build the first box

```bash
./build.sh openbmc
```

The first build:

1. Downloads and SHA-256-verifies the pinned QEMU Docker archive.
2. Loads and validates the exact QEMU 11 ARM/AArch64 and Debian QEMU 10.0.11 executables.
3. Installs an isolated, pinned `zipmi` environment under `work/deps/`.
4. Downloads and verifies the selected firmware or boot bundle.
5. Builds or stages artifacts under `work/openbmc/`.

Build everything with `./build.sh`. Preview the registry without downloading or building with
`./build.sh --list`.

## 4. Start and follow it

```bash
sudo ./tools/zbmc openbmc start
```

`start` validates the descriptor's QEMU path, SHA-256, exact version, machine, and QMP startup before
launching firmware. It then reports each startup stage and waits for the box's declared functional
services. OpenBMC took 4m32s on the four-core reference host.

To return immediately while the readiness watcher continues:

```bash
sudo ./tools/zbmc openbmc start --no-wait
./tools/zbmc openbmc status --follow
```

Ctrl-C stops following; it does not stop QEMU. The readiness watcher and permanent console capture
continue in the run evidence directory.

## 5. Use the BMC

```bash
./tools/zbmc openbmc status
./tools/zbmc openbmc status -v
./tools/zbmc openbmc ssh 'uname -a'
./tools/zbmc openbmc ipmi mc info
./tools/zbmc openbmc web
./tools/zbmc openbmc console
```

The upstream OpenBMC image uses `root` / `0penBmc`. `status` reports current functional health;
`status -v` adds the exact probe commands, run evidence directory, console log, and follow command.
Redfish (`/redfish/v1/`) and the vendor Web-UI root are separate checks.

Stop it with:

```bash
sudo ./tools/zbmc openbmc stop
```

zbmc refuses to start around, or stop, a QEMU process that is not owned by the selected run evidence.
An externally discovered process is reported as `UP (UNMANAGED)` and must be handled explicitly.

## 6. Addresses

The default addresses are in `zhosts.txt` and shown by `zbmc list`. To relocate them, copy
`zbmc.conf.example` to the gitignored `zbmc.conf` and set a pool or individual address:

```bash
cp zbmc.conf.example zbmc.conf

# Edit zbmc.conf:
ZBMC_POOL=10.250.0
# ZBMC_IP_openbmc=192.168.1.100
```

Address priority is: per-box `ZBMC_IP_<name>`, then `ZBMC_POOL`, then `ZHOSTS_FILE`, then the descriptor
default. Set `ZHOSTS_FILE=/absolute/path/zhosts.txt` in `zbmc.conf` when a deployment needs a complete
site-specific map.

Supermicro X10 defaults to portable QEMU user networking. Its forwarded ports appear in `status -v`.
Set `X10_NET_MODE=direct` only on an isolated lab LAN that routes the selected address and permits the
guest MAC.

## 7. Choose another box

```bash
./tools/zbmc list
./build.sh supermicro-x14
sudo ./tools/zbmc supermicro-x14 start
```

The current measured acceptance boundary is in the README fleet table. Important exceptions:

- `advantech-asmb787` is console-only and took 9m38s on the reference host.
- `idrac10` reaches SSH, retained IPMI, and its static Redfish ServiceRoot, but has no vendor Web-UI.
- `megarac-hpe` accepts retained IPMI only. Cold boot is nondeterministic and automatically rerolls an
  attempt when the vendor `IPMIMain` process hits its known startup race.
- `idrac9` must cold-boot. Its USB network does not survive warm migration.
- `idrac10` is cold-only. Its former packaged checkpoint carried stale shared state and is no longer a
  supported release path.
- `megarac-hpe` and `supermicro-x14` use a compatible bundled snapshot only with `--warm`.
- MegaRAC's injected blank-password SSH/telnet paths are not forwarded unless
  `ZBMC_INSECURE_LAB_ACCESS=1` is explicitly set on an isolated host.

A startup-watch timeout means the readiness deadline ended; it does not mean QEMU died. Run `status`
again for current health and `explain` for the recorded startup outcome:

```bash
./tools/zbmc supermicro-x14 status -v
./tools/zbmc supermicro-x14 explain
./tools/zbmc supermicro-x14 evidence
```

## Evidence and trust boundary

These images contain vendor default credentials and lab-only adaptations. Some boxes reconstruct
missing board state while retaining vendor services; others interpose or replace a narrow endpoint.
A working substitute does not prove the replaced vendor component. Read
[Why Virtualizing BMC Firmware Was Hard](docs/why-bmc-virtualization-is-hard.md) before using a box as
security evidence, and keep patched guests on an isolated research host.
The Docker runtime uses host networking and writable work mounts. It packages exact QEMU builds but is
not a containment boundary. Read [SECURITY.md](SECURITY.md) before exposing any guest beyond the host.

## Glossary

| Term | Meaning |
|---|---|
| BMC | The server's independent management computer. |
| IPMI / RMCP+ | Classic authenticated remote-management protocol. |
| Redfish | REST/JSON management API rooted at `/redfish/v1/`. |
| Web-UI | Vendor browser interface; distinct from Redfish. |
| NC-SI | Sideband protocol used by a BMC to share a host NIC. |
| QMP | QEMU Machine Protocol, used for validation, control, and compatible snapshots. |
| `READY` | Every service declared for that run passed its functional probe. |
