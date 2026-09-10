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
    path.write_text(text)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(f"usage: {sys.argv[0]} INIT ADDRESS GATEWAY")
    patch(*sys.argv[1:])
