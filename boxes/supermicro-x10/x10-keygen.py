#!/usr/bin/env python3
"""Supermicro X10 BMC OOB license key generator.

Generates valid Out-of-Band (OOB) and HSDC license keys for Supermicro X10-era
BMCs (AST2400, FW 3.x). These are the /nv/ooblicense keys that gate Redfish,
SNMP, and other OOB management features behind the "Supermicro OOB License".

Two HMAC-SHA1 keys were extracted from libipmi.so (FW 3.93):
  oob_private_key  = 8544e3b47eca58f9583043f8   (12 bytes, VA 0x112230)
  hsdc_private_key = 39cb2a1a3d748ff1dee46b87   (12 bytes, VA 0x112224)

Algorithm (reversed from oob_format_license_create @ 0x66ba0):
  1. Read 6-byte board identifier from persistent storage (offset 0x28E)
     — on real hardware this is the BMC's factory MAC from FRU/EEPROM
     — on QEMU flat-flash instances it's 00:00:00:00:00:00
  2. HMAC-SHA1(private_key, board_id_6bytes)
  3. Take first 12 bytes of the 20-byte HMAC digest
  4. Format as:  XXXX - XXXX - XXXX - XXXX - XXXX - XXXX

Activation path (reversed from oob_format_license_activate @ 0x66950):
  The BMC tries both keys (oob + hsdc) against the entered key.
  Either one matching is sufficient for activation.

Usage:
  x10-keygen.py                         # default: 00:00:00:00:00:00 (QEMU)
  x10-keygen.py AC:1F:6B:12:34:56       # real board's BMC MAC
  x10-keygen.py --raw 001122334455       # raw hex, no colons

Target: Supermicro X10 BMC (ASPEED AST2400, ATEN firmware 3.x)
Related: license_bypass.so (LD_PRELOAD shim), start-x10.py (boot driver)
"""
import hmac
import hashlib
import sys

OOB_KEY  = bytes.fromhex("8544e3b47eca58f9583043f8")
HSDC_KEY = bytes.fromhex("39cb2a1a3d748ff1dee46b87")


def parse_mac(s: str) -> bytes:
    s = s.strip().replace(":", "").replace("-", "").replace(".", "")
    if len(s) != 12:
        raise ValueError(f"MAC must be 6 bytes (12 hex chars), got {len(s)}: {s}")
    return bytes.fromhex(s)


def keygen(board_id: bytes, key: bytes) -> str:
    digest = hmac.new(key, board_id, hashlib.sha1).digest()[:12]
    h = digest.hex()
    return " - ".join(h[i:i+4] for i in range(0, 24, 4))


def main():
    mac_str = "00:00:00:00:00:00"
    raw = False

    args = sys.argv[1:]
    if "--help" in args or "-h" in args:
        print(__doc__.strip())
        sys.exit(0)
    if "--raw" in args:
        raw = True
        args.remove("--raw")
    if args:
        mac_str = args[0]

    board_id = parse_mac(mac_str)

    oob_license  = keygen(board_id, OOB_KEY)
    hsdc_license = keygen(board_id, HSDC_KEY)

    if raw:
        print(oob_license.replace(" - ", ""))
    else:
        print(f"Board ID (MAC):  {':'.join(f'{b:02x}' for b in board_id)}")
        print(f"OOB  license:    {oob_license}")
        print(f"HSDC license:    {hsdc_license}")
        print(f"\nActivation: either key works. Write to /nv/ooblicense and /nv/bios_license.")


if __name__ == "__main__":
    main()
