<!-- html2md:auto source=boxes/idrac6/index.html source-sha256=93683dfafc1bb9aba0b56aabaa3795a0f676b8ca2bdd8d9399235aeae66d3779 body-sha256=a95ce0cf95f69ef997f2550738f0fe50d87c593c24b5166d66e7579257c177b4 -->

# Dell iDRAC6 1.70

This box runs Dell's original ARM `fullfw`, AIM, IPMI system-call agent, IPMI gateway, shared libraries, configuration, and captured persistent state on QEMU's ARM926 `versatilepb` machine. It is firmware-userspace emulation, not an emulation of the Winbond WPCM450 SoC or Dell's vendor kernel.

## Current fidelity

| Surface | State | Evidence |
|----|----|----|
| Console | Working | Dell userspace reaches `BMC_RDY ASSERTED`; all 19 expected `fullfw` tasks run. |
| RMCP presence | Working | UDP/623 returns an IPMI-supported presence reply with Dell IANA 4542. |
| RMCP+ authentication | Partial | `root/calvin` completes the RAKP exchange at User privilege. |
| Application IPMI commands | Blocked | Requests reach the authenticated session but do not return command responses. The WPCM450 dynamic-IRQ device that delivers work into the firmware is not modeled. |
| Web, SSH, Redfish, host hardware | Not included | These are outside this minimal IPMI-oriented userspace slice. |

## Build and run

The proprietary firmware is not committed. Point the builder at the extracted iDRAC6 1.70 WPCM450 root filesystem. The builder rejects any other `fullfw` or private-storage image, downloads SHA-256-pinned Debian Lenny VersatilePB boot artifacts, compiles the two-command ioctl compatibility shim, and packs the minimal proven userspace.

    IDRAC6_ROOTFS=/path/to/WPCM450 ./tools/zbmc idrac6 build
    sudo ./tools/zbmc idrac6 start
    sudo ./tools/zbmc idrac6 status -v
    sudo ./tools/zbmc idrac6 console

## Extracting the filesystem

The source expected by `build.sh` is an already extracted iDRAC6 1.70 root filesystem containing `bin/fullfw`, `sbin/aim`, `lib/`, `etc/`, and `flash/`. The pinned `fullfw` SHA-256 is `67f17aa14eda9e5d96b96825b93536a228db031acda90122eb353fba56dd3465`. The original WPCM450 firmware image is not redistributed by zBMC.

## Why the shim exists

Dell's `fullfw` requires two ioctl calls from `aess_dynairqdrv.ko` during startup: reset the dynamic-IRQ registration list and register an IRQ. QEMU has no WPCM450 interrupt controller, so the preload library acknowledges only those exact requests and forwards every other ioctl unchanged. This is enough for full initialization and network-session handling, but it does not synthesize the missing interrupt-driven application-command delivery.

## Command documentation

The compact operator inventory is in zipmi's [iDRAC6 command table](../../../zipmi/docs/idrac6-command-table.md). A normalized command-reference page has not yet been produced; zBMC does not claim otherwise.
