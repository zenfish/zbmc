#!/usr/bin/env bash
# download-fw.sh — fetch the BMC firmware images (none are committed to git; all are fetched here).
#
# For each image: try the VENDOR's public download first (stays current, from the source), and if that
# fails or has no direct URL, fall back to the project MIRROR at https://git.trouble.org/vbmc-lab/.
# Every image is verified against a pinned SHA-256 either way. The images are firmware the vendors
# distribute publicly and anonymously; the mirror just makes the big/JS-gated ones fetchable.
#
# USAGE:  ./firmware/download-fw.sh                 # everything the boxes need
#         ./firmware/download-fw.sh openbmc         # one box (by its box name)
# NEEDS:  curl, shasum (or sha256sum).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MIRROR="https://git.trouble.org/vbmc-lab"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Safari/605.1'

# box | filename | sha256 | vendor-direct-URL (empty = mirror only) | vendor landing page (for reference)
FW=(
"advantech-asmb787|encrypted_ASMB-787_20220912.ima_enc|3e9916fd633babe11c208c0982330f8677e4f3b05029653a56ffe4230dea1cbd||https://www.advantech.com/en/support (search ASMB-787 BMC)"
"openbmc|evb-ast2600.static.mtd|11b89cbb7a4b129529de26ff0b80030f1f7bdfb0e206a4a5207bd6d55a13c908||built from github.com/openbmc/openbmc, MACHINE=evb-ast2600 (mirror only)"
"nvidia-obmc|obmc-phosphor-image-gb200nvl-obmc.static.mtd|a0a866fa6a3fdda49d9beec0a7efe6aadd234866e39bbefde2e05f45d5439495||built from bitbake MACHINE=gb200nvl-obmc (mirror only)"
"megarac-hpe|XD670_BMC_v1.27_signed.bin.hpm|4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76||HPE Cray XD670 BMC HPM (mirror only)"
"idrac9|iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN|752dc96fd01002934c82454e79b80af01593e18e7c6265c91fa72b4a63fafd44|https://dl.dell.com/FOLDER12233673M/1/iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN|https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=92MM7"
"idrac10|iDRAC-with-Lifecycle-Controller_Firmware_YP95X_LN64_1.30.10.50_A00.BIN|372c49cf8fc167aaff0acc03925a782698937bddba21cbca57146a7c8d722ca9||https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=YP95X"
"x14|x14-flash.img|8af1ba767ed0363653537ee6e2fab3fabd66d838e397903cb99e9cd00caaa792||Supermicro X14 BMC (mirror only)"
)

sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }
_get() { curl -fL -A "$UA" --retry 2 --connect-timeout 20 -o "$2" "$1"; }   # url dest
want="${*:-advantech-asmb787 openbmc nvidia-obmc megarac-hpe idrac9 idrac10 x14}"

for row in "${FW[@]}"; do
  IFS='|' read -r box file want256 vurl page <<<"$row"
  case " $want " in *" $box "*) ;; *) continue;; esac
  out="$HERE/$file"
  echo "== $box: $file =="
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want256" ]; then echo "   ✓ already present + verified"; continue; fi

  ok=""
  if [ -n "$vurl" ]; then
    echo "   trying vendor: $vurl"
    if _get "$vurl" "$out" 2>/dev/null && [ "$(sha "$out")" = "$want256" ]; then ok="vendor"; else echo "   vendor failed/mismatch — falling back to mirror"; fi
  fi
  if [ -z "$ok" ]; then
    echo "   mirror: $MIRROR/$file"
    if _get "$MIRROR/$file" "$out" 2>/dev/null && [ "$(sha "$out")" = "$want256" ]; then ok="mirror"; fi
  fi

  if [ -n "$ok" ]; then echo "   ✓ $(sha "$out")  (via $ok)"
  else
    rm -f "$out"
    echo "   ✗ could not fetch. Vendor page: $page"
    echo "     or drop it at $out manually, then re-run: $0 $box"
  fi
done
echo
echo "unpack: tools/unpack-idrac (Dell) or tools/unpack-ami (AMI MegaRAC).  build: ./build.sh"
