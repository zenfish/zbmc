#!/usr/bin/env python3
import importlib.util
import pathlib
import socket
import tempfile
import threading

repo = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("configure_tap", repo / "tools/zbmc-configure-serial-ip.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory() as directory:
    path = pathlib.Path(directory) / "serial.sock"
    server = socket.socket(socket.AF_UNIX)
    server.bind(str(path))
    server.listen(1)

    def guest():
        conn, _ = server.accept()
        with conn:
            conn.recv(1024)
            conn.sendall(b"###+ NCSI WorkAround +###\r\n")
            conn.sendall(b"bash-5.2# ")
            challenge = conn.recv(4096)
            assert challenge == b"echo ZBMC_TAP_SHELL_READY\n"
            conn.sendall(challenge + b"\r\nZBMC_TAP_SHELL_READY\r\nbash-5.2# ")
            command = conn.recv(4096)
            assert b"ip addr add 10.250.0.45/8 dev eth1" in command
            assert b"default via 10.0.0.1 dev eth1" in command
            conn.sendall(command + b"\r\nZBMC_TAP_NETWORK_READY\r\nbash-5.2# ")

    thread = threading.Thread(target=guest)
    thread.start()
    module.configure(path, "10.250.0.45", "8", "10.0.0.1", "eth1", timeout=5)
    thread.join()
    server.close()

print("Lenovo TAP guest configuration: PASS")
