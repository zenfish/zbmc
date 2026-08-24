#!/usr/bin/env bash
# ssh-in.sh — root shell into the running virtual iDRAC9. Defaults to the REAL IP + standard port 22
# (zbmc_boot binds $ZBMC_IP:22 directly). OVERRIDE with SSH_HOST/SSH_PORT for a wildcard-hostfwd boot
# (e.g. boot-p6-ckpt.sh's snapshot boot uses 127.0.0.1:2222 to dodge the Mac's own sshd on *:22).
cd "${WD:-$(dirname "$0")}" || exit 1
. ./zbmc.box 2>/dev/null
exec ssh -p "${SSH_PORT:-22}" -i "$PWD/img/vmkey" \
  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 \
  root@"${SSH_HOST:-${ZBMC_IP:-10.0.9.9}}" "$@"
