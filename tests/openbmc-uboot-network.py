#!/usr/bin/env python3
import importlib.util
import os
import pathlib

repo = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "start_openbmc", repo / "boxes/openbmc/start-openbmc.py"
)
source = spec.loader.get_source("start_openbmc")
namespace = {}
os.environ["WD"] = "/tmp/zbmc-openbmc-test"
os.environ["OPENBMC_FLASH"] = "/nonexistent/test.mtd"
exec(source[:source.index("for p in (sock, qmp):")], namespace)


class Console:
    def __init__(self):
        self.calls = []

    def expect(self, text, timeout):
        self.calls.append(("expect", text, timeout))

    def send(self, text):
        self.calls.append(("send", text))

    def sendline(self, text):
        self.calls.append(("sendline", text))


console = Console()
namespace["boot_with_static_ip"](console, "10.250.0.10", "52:54:00:fa:00:10")
sent = [call[1] for call in console.calls if call[0] == "sendline"]
expected = [call[1] for call in console.calls if call[0] == "expect"]
assert sent == [
    "setenv bootargs ${bootargs} rdinit=/bin/sh ip=10.250.0.10::10.0.0.1:255.0.0.0::eth0:off",
    "setenv ethaddr 52:54:00:fa:00:10",
    "run bootcmd",
    "ip link set eth0 up; ip addr flush dev eth0 scope global; ip addr add 10.250.0.10/8 dev eth0; ip route replace default via 10.0.0.1 dev eth0; ip -4 -o addr show dev eth0; echo ZBMC_NETWORK_CONFIGURED",
    "exec /init",
    "root",
    "0penBmc",
    "ip link set eth0 up; ip addr flush dev eth0 scope global; ip addr add 10.250.0.10/8 dev eth0; ip route replace default via 10.0.0.1 dev eth0; ip -4 -o addr show dev eth0; echo ZBMC_NETWORK_CONFIGURED",
]
assert expected[-7:] == [
    r"inet 10\.250\.0\.10/8",
    r"[~/] # ",
    r"login:",
    [r"Password:", r"password:"],
    [r"/#", r"# ", r"root@.*:~#"],
    r"inet 10\.250\.0\.10/8",
    [r"/#", r"# ", r"root@.*:~#"],
]
print("OpenBMC U-Boot native address configuration: PASS")
