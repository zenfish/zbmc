<!-- html2md:auto source=docs/why-multiple-qemu-builds.html source-sha256=c1cedca73ca4aef3c55e07d5a30deb1a8d139b27ae58af27282d71aabdb980ec body-sha256=834c2832726e66b01df5bf23c24ab6b71d95e008c4015cedee34f52c9e29d7d3 -->

## The short answer

Six 32-bit ARM BMCs share one patched QEMU 11 build. Dell iDRAC10 needs a different AArch64 system emulator and a different USB-network patch. Advantech uses an exact stock Debian QEMU 10.0.11 binary because that is the artifact under which its console-only acceptance was reproduced.

Only the architecture split and the two demonstrated patches are technical requirements. Advantech's separately packaged Debian QEMU 10 build is **known-good, not proven necessary**. A clean acceptance run with the packaged QEMU 11 ARM artifact may eliminate the third artifact.

**Terminology matters.** There are three packaged executables, two source architectures, two patch sets, and two QEMU versions. Calling them “three required QEMU versions” overstates the evidence.

## The release artifacts

<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead class="bg-zinc-100 text-zinc-700">
<tr>
<th class="px-4 py-3 font-semibold">Artifact</th>
<th class="px-4 py-3 font-semibold">Consumers</th>
<th class="px-4 py-3 font-semibold">Reason for the split</th>
<th class="px-4 py-3 font-semibold">Evidence status</th>
</tr>
</thead>
<tbody class="divide-y divide-zinc-200 align-top">
<tr>
<td class="px-4 py-4"><strong>QEMU 11 ARM + FTGMAC</strong><br />
<code class="text-xs">qemu-system-arm</code><br />
<code class="text-xs">arm-softmmu</code></td>
<td class="px-4 py-4 text-zinc-700">iDRAC9, MegaRAC-HPE, NVIDIA OpenBMC, upstream OpenBMC, Supermicro X10, Supermicro X14</td>
<td class="px-4 py-4 text-zinc-700">These are 32-bit ARM machines. The shared FTGMAC patch prevents stale receive-descriptor state from corrupting the next packet length.</td>
<td class="px-4 py-4 text-zinc-700"><strong>Required behavior:</strong> verified X10 failure and decoded root cause; the patch is not independently proven necessary for every consumer. <strong>Exact QEMU 11.0.0 version:</strong> reproducibility pin, not the only version that could contain the fix.</td>
</tr>
<tr>
<td class="px-4 py-4"><strong>QEMU 11 AArch64 + USB network</strong><br />
<code class="text-xs">qemu-system-aarch64</code><br />
<code class="text-xs">aarch64-softmmu</code></td>
<td class="px-4 py-4 text-zinc-700">Dell iDRAC10</td>
<td class="px-4 py-4 text-zinc-700">NPCM845 is AArch64 and therefore cannot run under the ARMv7 system emulator. Its current network route also needs QEMU's USB NIC to advertise and handle high-speed endpoints correctly.</td>
<td class="px-4 py-4 text-zinc-700"><strong>Architecture split:</strong> required. <strong>USB behavior:</strong> required by the current iDRAC10 boot path. <strong>Exact QEMU 11.0.0 version:</strong> reproducibility pin.</td>
</tr>
<tr>
<td class="px-4 py-4"><strong>Debian QEMU 10.0.11</strong><br />
<code class="text-xs">qemu-system-arm</code><br />
<code class="text-xs">Debian 13 package</code></td>
<td class="px-4 py-4 text-zinc-700">Advantech ASMB-787</td>
<td class="px-4 py-4 text-zinc-700">This is the unmodified distribution artifact used for the successful 9m38s console-only acceptance run.</td>
<td class="px-4 py-4 text-zinc-700"><strong>Verified known-good.</strong> No preserved comparison proves that Advantech requires QEMU 10 or that it fails on the shared QEMU 11 ARM build.</td>
</tr>
</tbody>
</table>

## Why Advantech currently uses QEMU 10

### What the evidence says

Before packaging, the Advantech descriptor selected an ad hoc QEMU 11 development binary. During packaging, that mutable host-local dependency was replaced by Debian 13's stock QEMU 10.0.11 package. The package supplied a distribution identity, exact version, and executable hash, and the guest then passed its preserved console acceptance.

### What the evidence does not say

The old descriptor path is not proof of an equivalent successful QEMU 11 run. There was no controlled QEMU 10-versus-packaged-QEMU-11 comparison showing that QEMU 11 broke the guest. Advantech's release acceptance was console-only, so choosing the stock package minimized release uncertainty but did not establish a technical version boundary. Commit `1432275` records the switch to the exact Debian QEMU 10.0.11 contract.

## What actually failed

FTGMAC receive descriptors

### A browser request could panic Supermicro X10

QEMU reused a receive descriptor without clearing its old status and length bits. It then ORed the new packet length into that stale value. The guest trusted the resulting false 2047-byte descriptor length, attempted to append 2043 payload bytes, and panicked in `skb_over_panic`. The emulated watchdog subsequently reset the guest while the QEMU process remained alive.

The correction clears stale status while preserving the end-of-ring bit, then writes the new valid-byte count. Because FTGMAC is shared emulated hardware, the fix belongs in the common ARM build rather than an X10-only executable.

Source: [FTGMAC patch](../qemu/patches/ftgmac100-rx-descriptor-reuse.patch). Evidence: `work/zbmc-reliability/x10-post-ready-drop-20260826.txt` in the Limbo research workspace.

NPCM845 USB networking

### iDRAC10 needs a different target and device behavior

iDRAC10's NPCM845 guest is 64-bit AArch64, unlike the ARMv7 BMCs. That alone requires `qemu-system-aarch64`. Its selected USB-network route also attaches to a high-speed USB controller, while QEMU's stock USB NIC exposed only full-speed device descriptors and used hard-coded 64-byte packet-boundary tests.

The patch adds high-speed CDC/RNDIS descriptors, uses each endpoint's actual maximum packet size, and installs the descriptor attach handler. It remains isolated because it changes shared USB NIC behavior also used by iDRAC9; applying both patch sets to one source tree has not been validated across the fleet.

Source: [iDRAC10 USB-net patch](../boxes/idrac10/qemu-usb-net-high-speed.patch).

## Why exact binaries are pinned

### Machine availability

A version string does not prove that a build contains `gb200nvl-bmc`, `npcm845-evb`, or the required boot ROM data.

### Patched behavior

Two binaries can both report QEMU 11.0.0 while only one contains the FTGMAC or USB-network correction.

### Migration state

Warm snapshots serialize device state. A different device layout can reject a stream or restore a guest with broken services.

For that reason each box declares an executable, expected version, machine model, and SHA-256. Before firmware launch, `zbmc` also starts the declared machine paused, checks its QMP state, and quits it. Validation is about executable behavior, not merely a pathname existing on the host.

## How the layout became smaller

1.  **Initial state:** ordinary ARM boxes used one QEMU 11 binary, while X10 used a separate QEMU 11 build carrying the FTGMAC correction.
2.  **Root-cause review:** the correction was found to repair generic FTGMAC descriptor handling, not a Supermicro machine-specific feature.
3.  **Consolidation:** the patch moved into the shared ARM recipe and X10 joined the other five consumers. The separate X10 release artifact was removed.
4.  **Current package:** one ARM artifact, one AArch64 artifact, and the independently pinned Advantech distribution artifact are delivered in one Docker image.

## When a variant may be removed or added

### Remove the Advantech QEMU 10 artifact when

1.  The shared QEMU 11 ARM binary passes machine and QMP validation for `ast2600-evb`.
2.  A fresh Advantech cold boot reaches the serial login prompt.
3.  The console remains functional through login and command execution.
4.  The result and timing are preserved under the run evidence directory.

Network services are not part of this comparison because Advantech's current acceptance contract is console-only.

### Add another QEMU artifact only when

- The guest requires a target architecture absent from existing executables.
- A required machine or ROM is absent from the existing build.
- A demonstrated emulator defect needs a patch that would alter already-validated consumers.
- A required warm snapshot is incompatible with the existing device-state layout.

A new vendor, a different firmware image, or a convenient local QEMU path is not by itself sufficient reason.

## Canonical implementation records

- [QEMU 11 ARM recipe](../qemu/recipes/qemu-11-arm.sh): source commit, target, machines, consumers, ROM, and FTGMAC patch.
- [QEMU 11 iDRAC10 recipe](../qemu/recipes/qemu-11-idrac10.sh): AArch64 target, NPCM845 machine, ROM, and USB-network patch.
- [Debian QEMU manifest](../qemu/packages/debian-13-qemu-10.0.11.json): exact Advantech package identity and SHA-256.
- [Zoo engineering lessons](zoo-lessons.md): SoC machine selection, boot paths, network limitations, and snapshot behavior.

Last reconciled against the packaged x86_64 Linux runtime and fleet evidence on 2026-08-27.
