# Firmware sources

How to obtain the firmware for every box. The `zbmc` boxes that build from a raw image fetch it
via `firmware/download-fw.sh <box>` — vendor-direct URL first, then the project MIRROR at
`https://git.trouble.org/zbmc-lab/` as fallback — and every image is verified against a pinned
SHA-256 before use.

Most of these vendors **do not provide anonymous direct-download URLs** — their portals are
login/JS-gated — so the boxes are "mirror only" and this doc records the official landing page,
how the file is packaged, and the expected path. The authoritative list of exact files + SHA-256
hashes is [firmware/manifest.txt](firmware/manifest.txt); the boxes also pin their own hash in
`firmware/download-fw.sh`.

> **If a file is missing from the mirror:** grab it from the vendor landing page below, place it at
> the `firmware/` path listed, and re-run `firmware/download-fw.sh <box>` (which verifies the hash).
> If you're hosting the mirror, `firmware/manifest.txt` is the file list + hashes to upload.

## Fully turnkey (firmware fetched by download-fw.sh; build.sh works clone-and-run)

| Box | File (in `firmware/`) | SHA-256 | Source |
|---|---|---|---|
| advantech-asmb787 | `encrypted_ASMB-787_20220912.ima_enc` | `3e9916fd633babe11c208c0982330f8677e4f3b05029653a56ffe4230dea1cbd` | ships in repo / mirror |
| openbmc | `evb-ast2600.static.mtd` | `11b89cbb7a4b129529de26ff0b80030f1f7bdfb0e206a4a5207bd6d55a13c908` | built (github.com/openbmc/openbmc, MACHINE=evb-ast2600) / mirror |
| nvidia-obmc | `obmc-phosphor-image-gb200nvl-obmc.static.mtd` | `a0a866fa6a3fdda49d9beec0a7efe6aadd234866e39bbefde2e05f45d5439495` | bitbake MACHINE=gb200nvl-obmc / mirror |
| megarac-hpe | `XD670_BMC_v1.27_signed.bin.hpm` | `4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76` | HPE Cray XD670 BMC HPM / mirror |
| idrac9 | `iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN` | `752dc96fd01002934c82454e79b80af01593e18e7c6265c91fa72b4a63fafd44` | Dell direct URL (works) / mirror |
| idrac10 | `iDRAC-with-Lifecycle-Controller_Firmware_YP95X_LN64_1.30.10.50_A00.BIN` | `372c49cf8fc167aaff0acc03925a782698937bddba21cbca57146a7c8d722ca9` | Dell page / mirror |
| supermicro-x14 | `x14-flash.img` | `8af1ba767ed0363653537ee6e2fab3fabd66d838e397903cb99e9cd00caaa792` | Supermicro X14 BMC 128 MiB NOR / mirror (see bundle below) |
| supermicro-x10 | `x10-master.flash` | `9bd3fbe8ddb8ee8e0f7d96ee37c810cef99d6c9f9566ddd13dca7ea455204214` | Supermicro X10 AST2400 FW 3.93 / mirror |

## Vendor landing pages

These vendors gate downloads behind a login / JS portal, so the boxes fetch from the mirror.
Vendor landing page + packaging below; the exact file + hash is in
[firmware/manifest.txt](firmware/manifest.txt).

### Supermicro (ATEN AST2600 family)

All at `https://www.supermicro.com/en/support/resources/downloadcenter/firmware`
(login-gated zip; each zip contains the `.bin`). Download the zip, unzip, drop the `.bin` in
`firmware/` under the expected name:

| Box | Expected file | SHA-256 |
|---|---|---|
| supermicro-x12 | `firmware/smc-x12-01.07.20.bin` | `895fcb15c2e7e198db4e9e5310b6619f4ac7aaf2ea76a2e2c3cb2e802d505788` |
| supermicro-x13 | `firmware/smc-x13-01.07.01.bin` | `dc78c07898003d7537b03a593a810e4a329b034a12d3df0503fc574b934e7a87` |
| supermicro-x13d | `firmware/smc-x13d-01.08.08.bin` | `88f6eb5a52d4b8ee2ac5e934ee460426614d3ab725e440dcc00c96c9ed7790f3` |
| supermicro-h13f | `firmware/smc-h13f-01.06.05.bin` | `41d80d11da45b0947b3fd7cf676a944fca3e589b0b581e310d818dd35b973c76` |
| supermicro-h13s | `firmware/smc-h13s-01.09.16.bin` | `afcb4dad50459ba4b1c9b15a52130f9bf486726d04ae6608d0311664f3a5d5d5` |

The upstream `.bin` filenames inside the zips:
`BMC_X12AST2600-ROT-5201MS_..._STDsph.bin`,
`BMC_X13AST2600-ROT20-2401MS_..._STDsp.bin`,
`BMC_X13AST2600-ROT-C301MS_..._STDsp.bin`,
`BMC_H13AST2600-F401MS_..._STDsp.bin`,
`BMC_H13AST2600-ROT20-E401MS_..._STDsp.bin`.

### H3C HDM3 (OpenBMC phosphor + lighttpd)

- **Landing:** `https://www.h3c.com/en/BizPortal/DownLoadAccessory/en_DownLoadAccessoryFilt.aspx`
  (public listing; download needs an H3C account). File: `HDM3_2.06.02_signed.bin`.
- **Packaging:** the SIGNHEAD container, whose sections are carved into
  `firmware/h3c-hdm3-2.06.02/sections/` (uboot_spl/uboot/overlay_conf/pfr/kernel/rootfs
  `.verify` files). On the mirror this is a single tarball `h3c-hdm3-2.06.02.tar.gz`
  (`sha256 47adacb10c4d50bbb52b46a343d6c4ab52c31014e85a345addbb93ec9db3f633`) that unpacks
  to `firmware/h3c-hdm3-2.06.02/sections/`.

### Fujitsu iRMC S6 (AMI MegaRAC SP-X)

- **Landing:** `https://support.ts.fujitsu.com/IndexDownload.asp` (JS product selector;
  entitlement). File: `RX2540M7_MangtCtr_FW0263S_SDR367` (.scexe self-extractor).
- **Packaging:** the `.scexe` self-extracts (binwalk) to the raw 56 MB NOR image
  `RX2540M7_02.63S_sdr03.67.bin`; the box's build.sh carves it. Expected file:
  `firmware/fujitsu-irmc-s6.bin`
  (`sha256 89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed`).

### NVIDIA BlueField-3 DPU BMC (OpenBMC Moonraker)

- **Landing:** `https://network.nvidia.com/support/firmware/firmware-downloads/` (needs a free
  NVIDIA Developer account). File: `bf-fwbundle-3.4.0-92_26.04-prod.bfb`.
- **Packaging:** the `.bfb` bundle extracts to a FIT + a plaintext root squashfs. The box uses
  the **prebuilt SPL-bypass boot artifacts** (kernel/dtb/initramfs). On the mirror this is
  `bluefield-bmc.tar.gz`
  (`sha256 6099eff853316274c678c251101a70772af12c039103f3dca26640014af1fc54`) unpacking to
  `firmware/bluefield-bmc/{kernel.bin,fdt-boot.dtb,initramfs.cpio}`.

### Opengear OM2200 (x86-64)

- **Landing:** `https://opengear.com/support/download/` (JS portal). File:
  `OM22xx-25.11.7-production-signed.raucb`.
- **Packaging:** the RAUC bundle unpacks to `kernel.img` + `rootfs.squashfs`. On the mirror,
  `opengear-om2200-25.11.7.tar.gz`
  (`sha256 6ec74ab71097985250782220d52b8a25d56c6872ea94c15782c4ed91af28cd92`) unpacks to
  `firmware/opengear-om2200-25.11.7/{kernel.img,rootfs.squashfs}`.

### Lenovo XCC2 (Vertiv Stingray-Z51)

- **Landing:** `https://datacentersupport.lenovo.com/us/en/` → ThinkSystem V3 → Drivers &
  Software → Management Controller Firmware. File: a `.uxz` update package.
- **Packaging:** the `.uxz` (header `deadc0de` + POSIX tar @ 0x9000) yields `zImage-arm` +
  `xcc-rootfs.sqfs`. On the mirror, `lenovo-xcc2-1.10.tar.gz`
  (`sha256 916204703d357c95a7d03c485970f1b08a70977ad05111b5aa65341f3d5b7cad`) unpacks to
  `firmware/lenovo-xcc2-1.10/{zImage-arm,xcc-rootfs.sqfs}`. (EXPERIMENTAL: kernel boots, vendor
  /init is hardware-bound, no login yet.)

## Not-yet-virtualizable (shim tier, not zbmc)

Some targets stay hand-written emulators or qemu-user web-login shims because the firmware is an
RTOS/sealed image with no bootable Linux kernel+rootfs. These are web-login **shims**, not
QEMU-system boxes, so they don't fit the `zbmc` model (which expects a qemu VM). Examples:
advantech-eki (boa under qemu-user), perle-iolan, moxa-nport, eaton, cyberpower, tripplite,
raritan-px3, opengear (container), irmc-megarac (container), and the `web-sim` Go emulator.
Lantronix SLC and Sierra RV50 ship a uImage/zImage but need a per-board machine model + DT
built — future box material, not yet wired.
