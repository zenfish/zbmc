#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
_zbmc_resolve_ip(){ echo 127.0.0.1; }
. "$repo/boxes/lenovo-xcc/zbmc.box"
zbmc_ssh(){
  [ "$*" = help ] || return 91
  printf '%s\n' "${TEST_HELP:-help  --  Display command list}"
  return "${TEST_RC:-0}"
}
zbmc_ssh_health >/dev/null
TEST_RC=1
! zbmc_ssh_health >/dev/null
TEST_RC=0
TEST_HELP='system> Error: Command not recognized'
! zbmc_ssh_health >/dev/null
echo 'Lenovo native SSH health: PASS'
