#!/usr/bin/env python3
"""Assign a guest-owned address through an already-authorized serial shell."""
import socket
import re
import sys
import time


SHELL_PROMPT = re.compile(
    rb"(?:(?:ba)?sh-[0-9.]+|~|/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]*|[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+(?::[^\n ]+)?) ?# ?"
)


def at_shell_prompt(data):
    line = data.replace(b"\r", b"").split(b"\n")[-1]
    return SHELL_PROMPT.fullmatch(line) is not None


def configure(sock_path, address, prefix, gateway, interface, timeout=900):
    deadline = time.monotonic() + timeout
    with socket.socket(socket.AF_UNIX) as sock:
        while True:
            try:
                sock.connect(str(sock_path))
                break
            except (FileNotFoundError, ConnectionRefusedError):
                if time.monotonic() >= deadline:
                    raise TimeoutError("serial socket did not become available")
                time.sleep(0.25)
        sock.settimeout(2)
        sock.sendall(b"\n")
        command = (
            f"ip addr flush dev {interface} scope global; "
            f"ip addr add {address}/{prefix} dev {interface}; "
            f"ip link set {interface} up; "
            f"ip route replace default via {gateway} dev {interface}; "
            f"ip -4 -o addr show dev {interface}; echo ZBMC_TAP_NETWORK_READY\n"
        ).encode()
        challenged_at = 0
        sent = False
        pending = b""
        while time.monotonic() < deadline:
            try:
                data = sock.recv(65536)
            except socket.timeout:
                if not sent:
                    sock.sendall(b"\n")
                continue
            if not data:
                raise ConnectionError("serial socket closed")
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
            pending += data.replace(b"\r", b"")
            lines = [line.strip() for line in pending.splitlines()]
            if not sent and b"ZBMC_TAP_SHELL_READY" in lines:
                sock.sendall(command)
                sent = True
            now = time.monotonic()
            if not sent and at_shell_prompt(pending) and now - challenged_at >= 5:
                sock.sendall(b"echo ZBMC_TAP_SHELL_READY\n")
                challenged_at = now
            if sent and b"ZBMC_TAP_NETWORK_READY" in lines:
                return
            pending = pending[-65536:]
        raise TimeoutError("guest network configuration did not complete")


if __name__ == "__main__":
    if len(sys.argv) not in (6, 7):
        raise SystemExit(f"usage: {sys.argv[0]} SOCKET ADDRESS PREFIX GATEWAY INTERFACE [TIMEOUT]")
    configure(*sys.argv[1:6], timeout=float(sys.argv[6]) if len(sys.argv) == 7 else 900)
