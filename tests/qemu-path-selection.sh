#!/usr/bin/env bash
set -euo pipefail
trap 'echo "qemu path fixture failed at line $LINENO" >&2' ERR

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
export TEST_ROOT="$fixture/work/fake"
mkdir -p "$fixture/tools" "$fixture/boxes/fake" "$TEST_ROOT"
cp "$repo/tools/zbmc" "$repo/tools/zbmc-runlib" "$fixture/tools/"
printf 'fake 127.0.0.1\n' > "$fixture/zhosts.txt"

make_qemu(){
  local path="$1" version="$2" machine="$3" behavior="${4:-works}"
  cat >"$path" <<EOF
#!/usr/bin/env bash
case "\$1" in
  --version) echo "QEMU emulator version $version"; exit 0 ;;
  -machine) echo "$machine board"; exit 0 ;;
esac
[ "$behavior" = broken ] && exit 1
printf '%s\\n' '{"QMP":{"version":{},"capabilities":[]}}'
while IFS= read -r request; do
  case "\$request" in
    *qmp_capabilities*|*cont*|*stop*|*quit*) printf '%s\\n' '{"return":{}}' ;;
    *query-status*) printf '%s\\n' '{"return":{"status":"running"}}' ;;
  esac
  case "\$request" in *quit*) exit 0 ;; esac
done
EOF
  chmod +x "$path"
}
good="$fixture/qemu-11"; bad_version="$fixture/qemu-10"; bad_machine="$fixture/qemu-no-aspeed"; bad_start="$fixture/qemu-start-fails"
make_qemu "$good" 11.0.0 ast2600-evb
make_qemu "$bad_version" 10.2.0 ast2600-evb
make_qemu "$bad_machine" 11.0.0 virt
make_qemu "$bad_start" 11.0.0 ast2600-evb broken

cat > "$fixture/boxes/fake/zbmc.box" <<EOF
ZBMC_NAME=fake
ZBMC_DESC="QEMU fixture"
ZBMC_DIR="$TEST_ROOT"
ZBMC_IP=127.0.0.1
ZBMC_HOST=fake
ZBMC_QEMU=$bad_version
ZBMC_QEMU_MAJOR=11
ZBMC_QEMU_MACHINE=ast2600-evb
PIDF="\$ZBMC_DIR/zbmc.pid"
LOG="\$ZBMC_DIR/console.log"
CONSOLE_LOG="\$LOG"
ZBMC_REQUIRED_SERVICES=""
zbmc_ready(){ echo ready; }
zbmc_boot(){ printf '%s\n' "\${ZBMC_QEMU:-}" >"\$TEST_ROOT/booted"; sleep 30 >/dev/null 2>&1 & echo "\$!"; }
zbmc_snapshot(){ printf '%s\n' "\${ZBMC_QEMU:-}" >"\$TEST_ROOT/snapshotted"; }
zbmc_restore(){ printf '%s\n' "\${ZBMC_QEMU:-}" >"\$TEST_ROOT/restored"; }
EOF

run(){ ZHOSTS_FILE="$fixture/zhosts.txt" TEST_ROOT="$TEST_ROOT" "$fixture/tools/zbmc" fake "$@"; }
wait_for_boot(){
  local n=0
  until [ -e "$TEST_ROOT/booted" ]; do
    [ "$n" -lt 20 ] || return 1
    sleep 0.1; n=$((n + 1))
  done
}
stop_fake(){
  local pid n=0; pid=$(cat "$TEST_ROOT/zbmc.pid" 2>/dev/null || true)
  [ -z "$pid" ] || kill "$pid" 2>/dev/null || true
  while [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && [ "$n" -lt 20 ]; do
    sleep 0.1; n=$((n + 1))
  done
  rm -f "$TEST_ROOT/zbmc.pid"
}
cleanup(){
  local watcher
  for watcher in "$TEST_ROOT"/runs/*/watcher.pid; do
    [ -f "$watcher" ] || continue
    kill "$(cat "$watcher")" 2>/dev/null || true
  done
  stop_fake
  rm -rf "$fixture"
}
trap cleanup EXIT
if run start --run-as-me --no-wait >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/booted" ]
run start --run-as-me --no-wait -q "$good" >/dev/null
wait_for_boot
grep -Fx "ZBMC_QEMU=$good" "$fixture/boxes/fake/zbmc.box" >/dev/null
grep -Fx "$good" "$TEST_ROOT/booted" >/dev/null
stop_fake; rm -f "$TEST_ROOT/booted"
run start --run-as-me --no-wait >/dev/null
wait_for_boot
grep -Fx "$good" "$TEST_ROOT/booted" >/dev/null
stop_fake
run snapshot --run-as-me
grep -Fx "$good" "$TEST_ROOT/snapshotted" >/dev/null
run restore --run-as-me
grep -Fx "$good" "$TEST_ROOT/restored" >/dev/null
if run start --run-as-me --no-wait -q "$bad_machine" >/dev/null 2>&1; then exit 1; fi
grep -Fx "ZBMC_QEMU=$good" "$fixture/boxes/fake/zbmc.box" >/dev/null
if run start --run-as-me --no-wait -q "$bad_start" >/dev/null 2>&1; then exit 1; fi
grep -Fx "ZBMC_QEMU=$good" "$fixture/boxes/fake/zbmc.box" >/dev/null
sed -i.bak "s|^ZBMC_QEMU=$good\$|ZBMC_QEMU=$bad_version|" "$fixture/boxes/fake/zbmc.box"
rm -f "$TEST_ROOT/snapshotted"
if run snapshot --run-as-me >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/snapshotted" ]
rm -f "$TEST_ROOT/restored"
if run restore --run-as-me >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/restored" ]
run restore --run-as-me -q "$good" >/dev/null
grep -Fx "$good" "$TEST_ROOT/restored" >/dev/null
sed -i.bak "s|^ZBMC_QEMU=$good$|ZBMC_QEMU=$bad_version|" "$fixture/boxes/fake/zbmc.box"
run snapshot --run-as-me -q "$good" >/dev/null
grep -Fx "$good" "$TEST_ROOT/snapshotted" >/dev/null
run restore --run-as-me >/dev/null
grep -Fx "$good" "$TEST_ROOT/restored" >/dev/null
python3 - "$fixture/boxes/fake/zbmc.box" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
path.write_text("\n".join(line for line in path.read_text().splitlines()
                           if not line.startswith("ZBMC_QEMU")) + "\n")
PY
rm -f "$TEST_ROOT/booted"
run start --run-as-me --no-wait >/dev/null
wait_for_boot
stop_fake
