#!/usr/bin/env bash
# download-fw.sh — fetch the large vendor BMC firmware images that don't ship in this repo.
#
# WHY: GitHub caps files at 100 MB. The small Advantech image is committed (firmware/…ima_enc);
#      the big Dell DUPs (~216–311 MB) and the Supermicro X14 image (~128 MB) are downloaded here from
#      the vendors' own public download sites. Every image is verified against a known SHA-256.
#
# All of this firmware is publicly and anonymously downloadable from the vendors — this script just
# automates it and pins checksums. Dell's dl.dell.com serves direct anonymous GETs; Supermicro's and
# some Dell driver pages are JS/EULA-gated, so those are marked MANUAL (download to the shown path,
# re-run to verify).
#
# USAGE: ./firmware/download-fw.sh [box...]     (no args = all; e.g. ./download-fw.sh idrac9)
# NEEDS: curl, shasum (or sha256sum).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Safari/605.1'

# box | filename | sha256 | direct-URL-or-empty | landing-page (for MANUAL)
FW=(
"idrac9|iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN|752dc96fd01002934c82454e79b80af01593e18e7c6265c91fa72b4a63fafd44|https://dl.dell.com/FOLDER12233673M/1/iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN|https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=92MM7"
"idrac10|iDRAC-with-Lifecycle-Controller_Firmware_YP95X_LN64_1.30.10.50_A00.BIN|372c49cf8fc167aaff0acc03925a782698937bddba21cbca57146a7c8d722ca9||https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=YP95X"
"x14|BMC_X14AST2600-ROT-E601MS_20260306_01.01.06.07_STDsp.bin|TBD||https://www.supermicro.com/en/support/resources/downloadcenter (search board X14SBSC-based system BMC)"
)

sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }
want="${*:-idrac9 idrac10 x14}"

for row in "${FW[@]}"; do
  IFS='|' read -r box file want256 url page <<<"$row"
  case " $want " in *" $box "*) ;; *) continue;; esac
  dst="$HERE/$box"; mkdir -p "$dst"; out="$dst/$file"
  echo "== $box: $file =="
  if [ -f "$out" ]; then
    got=$(sha "$out")
    if [ "$want256" = "TBD" ]; then echo "   present (sha256 $got — no pinned checksum for this one yet)"; continue; fi
    [ "$got" = "$want256" ] && { echo "   ✓ already present + verified"; continue; } || echo "   present but checksum MISMATCH — re-fetching"
  fi
  if [ -n "$url" ]; then
    echo "   downloading: $url"
    curl -L -A "$UA" --fail --retry 2 -o "$out" "$url" || { echo "   download failed — get it manually: $page"; continue; }
    got=$(sha "$out")
    if [ "$want256" != "TBD" ] && [ "$got" != "$want256" ]; then echo "   ✗ SHA-256 mismatch! got $got want $want256"; else echo "   ✓ $got"; fi
  else
    echo "   MANUAL (JS/EULA-gated): download to  $out"
    echo "   from: $page"
    [ "$want256" != "TBD" ] && echo "   expected sha256: $want256"
    echo "   then re-run: $0 $box   (verifies the checksum)"
  fi
done
echo
echo "note: firmware/asmb787's image ships in this repo (fits under GitHub's 100MB limit)."
echo "      unpack any of these with tools/unpack-idrac (Dell) or tools/unpack-ami (AMI MegaRAC)."
