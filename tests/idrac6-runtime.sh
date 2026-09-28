#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/idrac6"

bash -n "$box/build.sh" "$box/boot.sh" "$box/init"
grep -Fxq 'ZBMC_NETWORK_MODE=tap' "$box/zbmc.box"
grep -Fxq 'ZBMC_TAP=ztap-idrac6' "$box/zbmc.box"
grep -Fxq 'ZBMC_MAC=52:54:00:fa:00:29' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=versatilepb' "$box/zbmc.box"
grep -Fq '"-audio", "none"' "$repo/tools/zbmc"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="console"' "$box/zbmc.box"
grep -Fxq 'IPMI_USER=root' "$box/zbmc.box"
grep -Fxq 'IPMI_PW=calvin' "$box/zbmc.box"
grep -Fq 'FULLFW_SHA256=67f17aa14eda9e5d96b96825b93536a228db031acda90122eb353fba56dd3465' "$box/build.sh"
grep -Fq 'KERNEL_SHA256=478d458edc67f8f38ed53ac44e706908daa59ccf85031933bfa838678fc2bd70' "$box/build.sh"
grep -Fq 'INITRD_SHA256=c9bb9a51734b95ce9ea231373a06c624a922f20e8823c7fa413bdd30d289a21b' "$box/build.sh"
grep -Fq 'PRIVATE_STORAGE_SHA256=fd349b3672122d5d8e89564ad8be6e03234199e95d8af602de046b36c20798ab' "$box/build.sh"
grep -Fq '[ -L "$link" ] && cp -a "$link" "$GUEST/bin/"' "$box/build.sh"
grep -Fq 'ln -s busybox "$GUEST/bin/sh"' "$box/build.sh"
grep -Fq -- '--hash-style=sysv' "$box/build.sh"
grep -Fq -- '--version-script="$HERE/ioctl-shim.map"' "$box/build.sh"
grep -Fq 'request == 0xc004b900 || request == 0xc004b901' "$box/ioctl-shim.c"
grep -Fq 'LD_PRELOAD=/lib/libidrac6-ioctl-shim.so /bin/fullfw &' "$box/init"
grep -Fq 'busybox mknod /dev/null c 1 3' "$box/init"
grep -Fq "ZBMC_READY_GREP='BMC_RDY ASSERTED'" "$box/zbmc.box"
! grep -q 'ipmiextd\|racadm' "$box/init"
grep -Fq -- '-netdev "tap,id=bmcnet,ifname=$TAP,script=no,downscript=no"' "$box/boot.sh"
! grep -Rq 'hostfwd' "$box"

echo 'idrac6 runtime contract: PASS'
