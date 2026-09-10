#!/usr/bin/env python3
"""Assign the guest-owned direct-L2 address through XCC's serial root shell."""
import socket
import sys
import time


def configure(sock_path, address, prefix, gateway, timeout=300):
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
            "ip addr flush dev eth1 scope global; "
            f"ip addr add {address}/{prefix} dev eth1; "
            "ip link set eth1 up; "
            f"ip route replace default via {gateway} dev eth1; "
            "ip -4 -o addr show dev eth1; echo XCC_TAP_NETWORK_READY\n"
        ).encode()
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
            if not sent and pending.rstrip().endswith(b"#"):
                sock.sendall(command)
                sent = True
            if sent and any(line.strip() == b"XCC_TAP_NETWORK_READY" for line in pending.splitlines()):
                return
            pending = pending[-65536:]
        raise TimeoutError("guest network configuration did not complete")


if __name__ == "__main__":
    configure(*sys.argv[1:])
