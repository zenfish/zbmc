#!/bin/bash
# Boot-test the freshly-built vanilla evb-ast2600 OpenBMC flash image in qemu.
# WHAT: qemu ast2600-evb, flash via -drive if=mtd, user-net hostfwd 2210->22 / 2243->443 / 2262->623.
# Console: AST2600 evb UART is serial0; -nographic wires it to stdio. Do NOT prepend -serial null.
cd "$(dirname "$0")"
exec qemu-system-arm -M ast2600-evb -m 1G -nographic \
  -drive file=evb-ast2600.static.mtd,format=raw,if=mtd \
  -nic user,hostfwd=tcp::2210-:22,hostfwd=tcp::2243-:443,hostfwd=udp::2262-:623 2>&1
