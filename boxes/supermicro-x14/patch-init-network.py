#!/usr/bin/env python3
"""Replace the historical SLiRP address in X14's derived init script."""
import pathlib
import sys


def patch(path, address, gateway):
    path = pathlib.Path(path)
    text = path.read_text()
    if "10.0.2.15" not in text or "10.0.2.2" not in text:
        raise ValueError("X14 init does not contain the expected SLiRP network template")
    text = text.replace("10.0.2.15/24", f"{address}/8")
    text = text.replace("10.0.2.15", address).replace("10.0.2.2", gateway)
    keepalive = (
        f"ip addr show eth0 2>/dev/null | grep -q {address} || "
        f"{{ ip addr add {address}/8 dev eth0 2>/dev/null; ip link set eth0 up; }}; sleep 2"
    )
    recovery = (
        f"ip addr show eth0 2>/dev/null | grep -q {address} || "
        f"ip addr add {address}/8 dev eth0 2>/dev/null; "
        f"ping -c 1 -W 1 {gateway} >/dev/null 2>&1 || "
        "{ ip link set eth0 down; sleep 1; ip link set eth0 up; }; sleep 2"
    )
    if keepalive not in text:
        raise ValueError("X14 init does not contain the expected network keepalive")
    text = text.replace(keepalive, recovery)
    text = text.replace(
        "re-assert the hostfwd IP.",
        "re-assert the direct TAP address and recover a stalled emulated link.",
    )
    path.write_text(text)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(f"usage: {sys.argv[0]} INIT ADDRESS GATEWAY")
    patch(*sys.argv[1:])
