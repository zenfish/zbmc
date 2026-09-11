<!-- html2md:auto source=README.html source-sha256=a0785e03df942e7925b5ecf91b8bc5c003692a7c5c0228b5a22a728907fe75ef body-sha256=2e354e8dbe1cefcd4080f3f6682d0d2dac2d7d153f4c83c69521a4f95ebe7002 -->

# zbmc — a zoo of virtual BMCs under QEMU

Boot real vendor **BMC**s (Baseboard Management Controller) firmware under QEMU, driven by one dispatcher (`zbmc`), for reverse-engineering and security research on the out-of-band management stack (IPMI / RMCP+, Redfish, the web UI, the RAKP auth path) **without owning the physical server**.

Invaluable for testing [zipmi](https://github.com/zenfish/zipmi) on a variety of BMCs.

This is my own working zoo plus the tools, per-box boot recipes, a full field write-up, and an agent skill so others can reproduce it on their own images. C&C very welcome, as are new recipes/methods/improvements on what I have here. This turned out to be a bit more black magic than I'd anticipated beating these into submission (at least... mostly beaten... still a bit to do.)

> TLDR; → clone this repo → `./build.sh` → `sudo ./tools/zbmc list` \# list possibles -\> `sudo ./tools/zbmc openbmc start` \# run one

There's a [GETTING-STARTED.md](GETTING-STARTED.md) doc that walks through the process in more detail.

> **Supported host:** zbmc 0.1.1 runs only on **x86_64 Linux** (Intel or AMD). The pinned QEMU executables, paths, and SHA-256 values were produced for x86_64 Linux. ARM64 hosts such as Raspberry Pi and Apple Silicon, macOS, and other operating systems are not currently supported. `build.sh` downloads and SHA-256-verifies the pinned QEMU Docker runtime, then installs a pinned `zipmi` environment. Docker keeps the exact QEMU binaries identical across Linux releases.

Resource sizing is guidance, not an enforced check. Individual BMCs request 128 MiB to 1 GiB of guest RAM; allow roughly 2 GiB host RAM and 5 GiB free disk for one-at-a-time use. Fleet timings in this README came from a four-core host and will be slower on smaller systems.

> It aggregates vendor and research firmware and documents fleet-shared *default* credentials (calvin, factory IPMIKeys, CredVault keys, etc.). Those aren't repo secrets — they are already present in the source firmware or published research bundles; the value here is *documenting the danger*. The tracked tree contains no live/customer secrets or private keys. Some fetched lab bundles include deliberately shared research identities; see [SECURITY.md](SECURITY.md).

## The denizens/animals

`zbmc list` shows these; run any with `sudo ./tools/zbmc <name> start`. Firmware isn't present in the current tree. `build.sh` fetches SHA-256-pinned vendor images and derived boot artifacts from the source listed in each build recipe; some are vendor downloads and some are project-mirror-only. The table is the current validation matrix from the four-core Debby host, last updated 2026-09-10. Each name links to that animal's box material.

| `zbmc` name | QEMU network | ICMP | SSH | IPMI | Redfish | Web-UI | Console | Boot | Issues |
|----|----|----|----|----|----|----|----|----|----|
| **[openbmc](boxes/openbmc/index.md)** | TAP / direct L2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Cold ✅; Warm ❌ | Cold TAP run 2026-09-10 passed ICMP, SSH, IPMI, Redfish, Web-UI, and console via `zbmc openbmc status -v`; no warm checkpoint is published. |
| **[nvidia-obmc](boxes/nvidia-obmc/)** | TAP / direct L2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Cold ✅; Warm ❌ | Cold TAP run 2026-09-10 passed ICMP, SSH, IPMI, Redfish, Web-UI, and console via `zbmc nvidia-obmc status -v`; no warm checkpoint is published. |
| **[advantech-asmb787](boxes/advantech-asmb787/)** | TAP / direct L2 | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Cold ✅; Warm ❌ | TAP and the Web-UI answer; SSH grants no usable shell, IPMI authentication fails, Redfish is only a service root, and console PAM login fails. |
| **[idrac10](boxes/idrac10/index.md)** | TAP / direct L2 | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | Cold ✅; Warm ✅ | The image exposes Redfish but no vendor Web-UI. |
| **[megarac-hpe](boxes/megarac-hpe/index.md)** | TAP / direct L2 | ✅ | ❌ | ✅ | ⚠️ FLAKY | ⚠️ FLAKY | ✅ | Cold ✅; Warm ❌ | Redfish and Web-UI passed the readiness hold, then became intermittent; the saved warm image is incompatible with current QEMU. |
| **[ieit](boxes/ieit/)** | TAP / direct L2 | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | Cold ✅; Warm ❌ | The SSH endpoint is a management command shell, not a Unix shell, and is not in the current contract. |
| **[irmc-fujitsu](boxes/irmc-fujitsu/index.md)** | TAP / direct L2 | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | Cold ✅; Warm ❌ | The Web-UI passed before TAP; the latest TAP run on 2026-09-10 was captured only while it was still starting. |
| **[lenovo-xcc](boxes/lenovo-xcc/index.md)** | TAP / direct L2 | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | Cold ✅; Warm ❌ | IPMI worked with the old SLiRP checkpoint; the 2026-09-10 TAP run proved only ICMP and console, and the old warm checkpoint no longer restores. |
| **[supermicro-x14](boxes/supermicro-x14/)** | TAP / direct L2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Cold ✅; Warm ❌ | Cold TAP run 2026-09-10 passed ICMP, SSH, IPMI, Redfish, Web-UI, and console via `zbmc supermicro-x14 status -v`; no warm checkpoint is published. |
| **[supermicro-x10](boxes/supermicro-x10/)** | TAP / direct L2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Cold ✅; Warm ❌ | None observed in the completed TAP validation run. |
| **[idrac9](boxes/idrac9/index.md)** | TAP / direct L2 | ✅ | ⚠️ FLAKY | ❌ | ❌ | ✅ | ✅ | Cold ✅; Warm ❌ | SSH is intermittent; IPMI authentication fails; warm restore leaves the network unusable. |

Legend: ✅ passed in the current TAP topology, ❌ did not pass the latest current-topology validation or is unsupported, and ⚠️ FLAKY passed but did not remain stable. “Cold” means a clean boot from installed build artifacts; “Warm” means `start --warm` can restore a verified checkpoint. Cold firmware startup remains load-sensitive. The iDRAC10 checkpoint is downloaded as a hash-pinned matched bundle from `git.trouble.org`; see [the iDRAC10 warm-start runbook](boxes/idrac10/WARM-START.md).

All eleven descriptors now select **TAP / direct L2** for the advertised management address, with no host proxy for management traffic. Network validation requires three consecutive ICMP replies, ARP from the guest MAC, confirmation that the host does not own the guest IP, the corresponding zBMC checks, and no management `hostfwd`. Those are validation details, not separate capabilities in the table.

Full per-box boot method, network trick, and gotchas: [docs/zoo-lessons.md](docs/zoo-lessons.md). The project-wide retrospective is [Why Virtualizing BMC Firmware Was Hard](docs/why-bmc-virtualization-is-hard.md).

## Quickstart

Full walkthrough (with a glossary): **[GETTING-STARTED.md](GETTING-STARTED.md)**. The short version:

    # Debian 13 on x86_64
    sudo apt install docker.io curl git ca-certificates util-linux-extra fakeroot squashfs-tools u-boot-tools \
      device-tree-compiler qemu-utils expect gcc-aarch64-linux-gnu sshpass socat \
      netcat-openbsd iproute2 iputils-ping tcpdump libarchive-tools \
      python3-pexpect python3-venv pipx
    pipx install jefferson
    export PATH="$HOME/.local/bin:$PWD/tools:$PATH"
    ./build.sh                     # install exact QEMU/zipmi + build every ready box
    sudo ./tools/zbmc openbmc start # boot vanilla OpenBMC (about 4m30s on the reference host)
    ./tools/zbmc openbmc ssh 'uname -a'
    ./tools/zbmc openbmc ipmi mc info
    ./tools/zbmc openbmc web

For iDRAC10, the build installs both cold and warm artifacts. Check availability, then choose either path:

    ./tools/zbmc list                     # iDRAC10 should show WARM READY
    sudo ./tools/zbmc idrac10 start --warm
    sudo ./tools/zbmc idrac10 start       # cold remains the default

No firmware is present in the current checkout; `build.sh` fetches what a box needs via the applicable box recipe or `firmware/download-fw.sh`:

    ./firmware/download-fw.sh            # all, or: ./firmware/download-fw.sh openbmc

Every fetched artifact is SHA-256 verified. `firmware/download-fw.sh` reports whether the source is a vendor URL or the project mirror; several derived boot bundles are mirror-only because they contain the documented emulation adaptations. See [SECURITY.md](SECURITY.md) for the trust and provenance boundary.

## Exact QEMU builds and Docker package

Every box descriptor pins a QEMU executable, version, machine, and SHA-256. `zbmc` validates all four before launch and refuses a changed or incompatible binary. These pins are host-architecture-specific: the current 0.1.1 build/package path supports **x86_64 Linux only** and ships two patched QEMU 11 artifacts plus Debian's exact QEMU 10.0.11 package in one pinned Docker image. Normal users receive and verify this package automatically through `build.sh`; these commands reproduce it:

The engineering rationale, observed failures, evidence strength, and criteria for removing a variant are documented in [Why zbmc Ships Multiple QEMU Builds](docs/why-multiple-qemu-builds.md).

    tools/build-qemu --plan qemu-11-arm
    tools/build-qemu qemu-11-arm
    tools/build-qemu qemu-11-idrac10

    tools/package-qemu-docker /absolute/path/zbmc-qemu.docker.tar \
      /absolute/path/debian-13-qemu-10.0.11.json \
      /absolute/path/qemu-11-arm-manifest.json \
      /absolute/path/qemu-11-idrac10-manifest.json

    docker load -i /absolute/path/zbmc-qemu.docker.tar
    tools/validate-qemu-build --deadline 1200 /absolute/path/qemu-manifest.json box-name

The Docker base image and package version are pinned, and the packager verifies executable/data hashes and QMP startup for every declared machine before export. Debian apt dependencies still resolve from the live repository, so this is exact-artifact packaging rather than a byte-for-byte offline source rebuild. The runtime uses host networking and writable work mounts for QEMU; Docker is packaging, not a security boundary. It does not use privileged mode or the host PID namespace.

## Network configuration

Every advertised address is assigned inside the guest on a Linux TAP/direct-L2 management interface. The host bridge routes the packets but does not own the guest address, and zBMC does not proxy management ports. Descriptor fallback addresses retain the historical vendor ranges below; deployments normally override them with a site pool such as Debby's `10.250.0.x`:

| Fallback range | Vendor | Boxes |
|----|----|----|
| 10.0.6.x | Vendor firmware | megarac-hpe (.66), IEIT/Inspur (.67), irmc-fujitsu (.68), lenovo-xcc (.69) |
| 10.0.7.x | OpenBMC | openbmc (.10), nvidia-obmc (.20) |
| 10.0.8.x | Supermicro | supermicro-x10 (.10), supermicro-x14 (.14) |
| 10.0.9.x | Dell iDRAC | idrac9 (.9), idrac10 (.10) |
| configured pool `.50` | Advantech | advantech-asmb787 |

If your network already uses the default 10.0.{6,7,8,9}.x range, copy `zbmc.conf.example` to `zbmc.conf` (gitignored) and set **one** of:

    # Pool mode — relocate every box into any /24 you control (first 3 octets):
    ZBMC_POOL=10.250.0       # still in 10/8 but out of the way
    # ZBMC_POOL=192.168.9    # or a completely different block
    # → openbmc=.10, nvidia-obmc=.11, x10=.20, x14=.21,
    #   idrac9=.30, idrac10=.31, megarac-hpe=.40, ieit=.41,
    #   irmc-fujitsu=.42, lenovo-xcc=.43, asmb787=.50

    # Per-box override — when you only have a few free IPs:
    ZBMC_IP_idrac9=172.16.0.99
    ZBMC_IP_openbmc=192.168.1.100

Priority: per-box `ZBMC_IP_<name>` \> pool \> `ZHOSTS_FILE` \> descriptor default. Full allocation table and examples: **[zbmc.conf.example](zbmc.conf.example)**.

## Layout

    build.sh      build every ready box's boot artifacts into work/<box>/  (./build.sh --list to preview)
    tools/        unpack-ami (MegaRAC), unpack-idrac (Dell), unpack-ilo5 (HPE), zbmc (dispatcher)
    boxes/<name>/ per-box zbmc.box + boot/build/restore/snapshot scripts + findings docs
    experiments/  pre-service targets kept outside the fleet contract (currently HPE iLO 5 / Renode)
    docs/         engineering rationale, per-box deep dives, and cross-box lessons
    skill/        megarac-virtualize/ + virtualize-bmc/ — agent skills reproducing this on new firmware
    firmware/     download-fw.sh — fetches all firmware (vendor first, git.trouble.org mirror fallback)

Every documentation source has both a GitHub-friendly Markdown form and a styled HTML form. Existing Markdown remains authoritative where it existed first; existing hand-authored HTML remains authoritative for the reverse-engineering reports. Markdown-to-HTML uses the vendored `zmd2html`; HTML-to-Markdown uses Pandoc 3.7.0.2 with its GFM writer. Edit the side without an `html2md:auto` or `zmd2html:auto` marker; the marked side is generated and will be overwritten. Regenerate or verify the pairs with:

    tools/install-pandoc-docs
    export PATH="$PWD/work/deps/pandoc-3.7.0.2/bin:$PATH"
    ./tools/sync-docs               # verify pairs and same-format links; default and CI behavior
    ./tools/sync-docs --write       # regenerate marked siblings, then run the same check
    ./tools/sync-docs README.md      # verify one pair; .html paths and shell-expanded globs also work
    ./tools/sync-docs --write README.md  # regenerate only the selected pair

The check shows each document on one updating terminal line, then lists unsynchronized files. If both sides of a pair were edited, it reports the conflict and leaves that pair for manual reconciliation.

The two `*.standalone.html` packaging copies remain HTML-only.

`./tools/zbmc -V` (or `--version`) prints the dispatcher version.

## The docs, the sweat, the tears

- **[docs/why-bmc-virtualization-is-hard.md](docs/why-bmc-virtualization-is-hard.md)** — why was it so difficult, which problems were inherent versus self-inflicted, what failed, what worked, the current limits, and the rules that hopefully will guide future endeavors.
- **[docs/release-readiness-retrospective.md](docs/release-readiness-retrospective.md)** — the repository-wide 2026-08-27 audit, corrected contracts, verification, and remaining release risks.
- **[docs/why-multiple-qemu-builds.md](docs/why-multiple-qemu-builds.md)** — why multiple QEMU executables were stuffed in here, which differences require separate builds, and how to test whether Advantech still needs the separately packaged Debian QEMU 10 build.
- **[docs/from-firmware-to-bare-metal.md](docs/from-firmware-to-bare-metal.md)** — one box end to end: the "encrypted" misnomer, AMI FMH / SquashFS / JFFS2 / FIT unpacking (and the binwalk & jefferson traps), the exact QEMU flags and why, the IPMIMain SIGSEGV fixes, and the NC-SI networking wall in full.
- **[docs/zoo-lessons.md](docs/zoo-lessons.md)** — the cross-box patterns: QEMU machine per SoC, direct-kernel vs FIT vs raw-flash boot, flash sizing traps, cold-boot-flaky → warm-snapshot (QMP migrate), the network last-mile per SoC (usb-net on NPCM vs the AST2600 NC-SI wall), and the OpenBMC / MegaRAC / iDRAC userland fixes.
- **[experiments/ilo5/README.md](experiments/ilo5/README.md)** — the reproducible iLO 5 v2.41 unpack and Renode bootloader-to-INTEGRITY-scheduler experiment, with explicit service limits.

## License / use

Scripts + docs: MIT (`LICENSE`). Firmware images are the respective vendors' and are not covered by it. Use only on hardware/firmware you're authorized to test.
