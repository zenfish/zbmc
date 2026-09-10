#!/usr/bin/env python3
import importlib.util
import pathlib
import tempfile

repo = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "patch_init_network", repo / "boxes/supermicro-x14/patch-init-network.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory() as directory:
    init = pathlib.Path(directory) / "init"
    init.write_text("ip addr add 10.0.2.15/24; ip route via 10.0.2.2; grep 10.0.2.15\n")
    module.patch(init, "10.250.0.21", "10.0.0.1")
    assert init.read_text() == (
        "ip addr add 10.250.0.21/8; ip route via 10.0.0.1; grep 10.250.0.21\n"
    )

print("Supermicro X14 native initramfs network patch: PASS")
