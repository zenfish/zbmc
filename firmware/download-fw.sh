#!/usr/bin/env bash
# download-fw.sh — fetch the BMC firmware images (none are committed to git; all are fetched here).
#
# For each image: try the VENDOR's public download first (stays current, from the source), and if that
# fails or has no direct URL, fall back to the project MIRROR at https://git.trouble.org/zbmc-lab/.
# Every image is verified against a pinned SHA-256 either way. The images are firmware the vendors
# distribute publicly and anonymously; the mirror just makes the big/JS-gated ones fetchable.
#
# USAGE:  ./firmware/download-fw.sh                 # everything the boxes need
#         ./firmware/download-fw.sh openbmc         # one box (by its box name)
# NEEDS:  curl, shasum (or sha256sum).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MIRROR="https://git.trouble.org/zbmc-lab"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Safari/605.1'

# box | filename | sha256 | vendor-direct-URL (empty = mirror only) | vendor landing page (for reference)
FW=(
"advantech-asmb787|encrypted_ASMB-787_20220912.ima_enc|3e9916fd633babe11c208c0982330f8677e4f3b05029653a56ffe4230dea1cbd||https://www.advantech.com/en/support (search ASMB-787 BMC)"
"openbmc|evb-ast2600.static.mtd|11b89cbb7a4b129529de26ff0b80030f1f7bdfb0e206a4a5207bd6d55a13c908||built from github.com/openbmc/openbmc, MACHINE=evb-ast2600 (mirror only)"
"nvidia-obmc|obmc-phosphor-image-gb200nvl-obmc.static.mtd|a0a866fa6a3fdda49d9beec0a7efe6aadd234866e39bbefde2e05f45d5439495||built from bitbake MACHINE=gb200nvl-obmc (mirror only)"
"megarac-hpe|XD670_BMC_v1.27_signed.bin.hpm|4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76||HPE Cray XD670 BMC HPM (mirror only)"
"idrac9|iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN|752dc96fd01002934c82454e79b80af01593e18e7c6265c91fa72b4a63fafd44|https://dl.dell.com/FOLDER12233673M/1/iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN|https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=92MM7"
"idrac10|iDRAC-with-Lifecycle-Controller_Firmware_YP95X_LN64_1.30.10.50_A00.BIN|372c49cf8fc167aaff0acc03925a782698937bddba21cbca57146a7c8d722ca9||https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=YP95X"
"supermicro-x14|x14-flash.img|8af1ba767ed0363653537ee6e2fab3fabd66d838e397903cb99e9cd00caaa792||Supermicro X14 BMC 128 MiB NOR (source of x14-ce0-64m.img, carved by boxes/supermicro-x14/build.sh — mirror only)"
"supermicro-x10|x10-master.flash|9bd3fbe8ddb8ee8e0f7d96ee37c810cef99d6c9f9566ddd13dca7ea455204214||Supermicro X10 BMC flat flash (AST2400, FW 3.93; from BMC_X10AST2400-32M_20210528_03.93_STD.bin — mirror only)"
"supermicro-x12|smc-x12-01.07.20.bin|895fcb15c2e7e198db4e9e5310b6619f4ac7aaf2ea76a2e2c3cb2e802d505788||Supermicro X12SPI BMC (AST2600, FW 01.07.20; BMC_X12AST2600-ROT-5201MS_20260504_01.07.20_STDsph.bin — mirror only)"
"supermicro-x13|smc-x13-01.07.01.bin|dc78c07898003d7537b03a593a810e4a329b034a12d3df0503fc574b934e7a87||Supermicro X13 2401MS BMC (AST2600 ROT20, FW 01.07.01; BMC_X13AST2600-ROT20-2401MS_20251122_01.07.01_STDsp.bin — mirror only)"
"supermicro-x13d|smc-x13d-01.08.08.bin|88f6eb5a52d4b8ee2ac5e934ee460426614d3ab725e440dcc00c96c9ed7790f3||Supermicro X13DAi C301MS BMC (AST2600 ROT2HW2, FW 01.08.08; BMC_X13AST2600-ROT-C301MS_20260319_01.08.08_STDsp.bin — mirror only)"
"supermicro-h13f|smc-h13f-01.06.05.bin|41d80d11da45b0947b3fd7cf676a944fca3e589b0b581e310d818dd35b973c76||Supermicro H13 F401MS BMC (AST2600, FW 01.06.05; BMC_H13AST2600-F401MS_20260116_01.06.05_STDsp.bin — mirror only)"
"supermicro-h13s|smc-h13s-01.09.16.bin|afcb4dad50459ba4b1c9b15a52130f9bf486726d04ae6608d0311664f3a5d5d5||Supermicro H13SSF E401MS BMC (AST2600 ROT20, FW 01.09.16; BMC_H13AST2600-ROT20-E401MS_20260411_01.09.16_STDsp.bin — mirror only)"
"h3c-hdm|h3c-hdm3-2.06.02.tar.gz|47adacb10c4d50bbb52b46a343d6c4ab52c31014e85a345addbb93ec9db3f633||H3C HDM3 BMC (AST2600, FW 2.06.02; tarball unpacks to h3c-hdm3-2.06.02/sections/ — mirror only)"
"fujitsu-irmc|fujitsu-irmc-s6.bin|89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed||Fujitsu iRMC S6 BMC (AST2600, FW 02.63S; RX2540M7_02.63S_sdr03.67.bin — mirror only)"
"bluefield-bmc|bluefield-bmc.tar.gz|6099eff853316274c678c251101a70772af12c039103f3dca26640014af1fc54||NVIDIA BlueField-3 BMC boot artifacts (tarball unpacks to bluefield-bmc/{kernel.bin,fdt-boot.dtb,initramfs.cpio} — mirror only)"
"opengear-om2200|opengear-om2200-25.11.7.tar.gz|6ec74ab71097985250782220d52b8a25d56c6872ea94c15782c4ed91af28cd92||Opengear OM2200 (x86-64, FW 25.11.7; tarball unpacks to opengear-om2200-25.11.7/{kernel.img,rootfs.squashfs} — mirror only)"
"lenovo-xcc2|lenovo-xcc2-1.10.tar.gz|916204703d357c95a7d03c485970f1b08a70977ad05111b5aa65341f3d5b7cad||Lenovo XCC2 (AST2600, FW 1.10; tarball unpacks to lenovo-xcc2-1.10/{zImage-arm,xcc-rootfs.sqfs} — mirror only)"
)

sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }
_get() { curl -fL -A "$UA" --retry 2 --connect-timeout 20 -o "$2" "$1"; }   # url dest
_verify() { [ "$(sha "$1")" = "$2" ]; }
# unpack: a .tar.gz payload extracts into firmware/ (the tarball carries its own subdir).
_unpack() { case "$1" in *.tar.gz) tar -xzf "$1" -C "$HERE" && rm -f "$1";; esac; }
# default = every box. Pass one-or-more box names to fetch just those.
want="${*:-advantech-asmb787 openbmc nvidia-obmc megarac-hpe idrac9 idrac10 supermicro-x14 supermicro-x10 supermicro-x12 supermicro-x13 supermicro-x13d supermicro-h13f supermicro-h13s h3c-hdm fujitsu-irmc bluefield-bmc opengear-om2200 lenovo-xcc2}"

for row in "${FW[@]}"; do
  IFS='|' read -r box file want256 vurl page <<<"$row"
  case " $want " in *" $box "*) ;; *) continue;; esac
  out="$HERE/$file"
  echo "== $box: $file =="
  # already-fetched check: a tarball payload is "present" once it has been unpacked (the
  # .tar.gz is removed), so check for the extracted dir instead of the archive.
  present=0
  case "$file" in
    *.tar.gz) d="${file%.tar.gz}"; [ -d "$HERE/$d" ] && present=1 ;;
    *)        [ -f "$out" ] && _verify "$out" "$want256" && present=1 ;;
  esac
  [ "$present" = 1 ] && { echo "   ✓ already present"; continue; }

  ok=""
  if [ -n "$vurl" ]; then
    echo "   trying vendor: $vurl"
    if _get "$vurl" "$out" 2>/dev/null && _verify "$out" "$want256"; then ok="vendor"; else echo "   vendor failed/mismatch — falling back to mirror"; fi
  fi
  if [ -z "$ok" ]; then
    echo "   mirror: $MIRROR/$file"
    if _get "$MIRROR/$file" "$out" 2>/dev/null && _verify "$out" "$want256"; then ok="mirror"; fi
  fi

  if [ -n "$ok" ]; then
    _unpack "$out"
    echo "   ✓ $(sha "$out" 2>/dev/null || echo unpacked)  (via $ok)"
  else
    rm -f "$out"
    echo "   ✗ could not fetch. Vendor page: $page"
    echo "     or drop it at $out manually, then re-run: $0 $box"
  fi
done
echo
echo "unpack: tools/unpack-idrac (Dell) or tools/unpack-ami (AMI MegaRAC).  build: ./build.sh"
