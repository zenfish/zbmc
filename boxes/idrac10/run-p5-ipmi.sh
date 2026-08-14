#!/usr/bin/env bash
# run-p5-ipmi.sh — iDRAC10 Phase 5: IPMI/RAKP auth with fleet factory IPMIKey
set -euo pipefail
cd "$(dirname "$0")"

WORK_DIR="${HOME}/phd/tmp/idrac10-virtual"
SOCK="${WORK_DIR}/p5.sock"
SERVE_DIR="${WORK_DIR}/serve"
HTTP_PORT=8080
QEMU_IPMI_PORT=7623
FACTORY_IPMIKEY="915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964"
LOGFILE="${WORK_DIR}/run138.log"

exec > >(tee "$LOGFILE") 2>&1

mkdir -p "$WORK_DIR" "$SERVE_DIR"
[ -S "$SOCK" ] && rm -f "$SOCK"

# Rebuild shim from source (ensures crash-proof: no stale binary)
zig cc -shared -fPIC -o "${SERVE_DIR}/shm-shim.so" shm-shim.c \
    -target aarch64-linux-gnu -ldl -lpthread -O2
cp "${SERVE_DIR}/shm-shim.so" shm-shim.so  # keep project-dir copy in sync
echo "[+] shm-shim.so rebuilt ($(stat -f%z "${SERVE_DIR}/shm-shim.so") bytes)"

cp boot-fullfw-guest.sh fake-journal udp-echo cfgdb-defaults.sql "$SERVE_DIR/"
cp prebind-v2 "${SERVE_DIR}/prebind"
echo "[+] All guest binaries synced to $SERVE_DIR"

pkill -f "http.server ${HTTP_PORT}" 2>/dev/null || true
python3 -m http.server "$HTTP_PORT" --directory "$SERVE_DIR" 2>"${WORK_DIR}/httpd.log" &
PYPID=$!

QPID=0; UDPTESTPID=0
trap "kill $PYPID 2>/dev/null; [ \$QPID -ne 0 ] && kill \$QPID 2>/dev/null; [ \$UDPTESTPID -ne 0 ] && kill \$UDPTESTPID 2>/dev/null" EXIT

qemu-system-aarch64 \
  -M npcm845-evb -m 1G \
  -kernel boot/Image.boot-patched \
  -dtb boot/qemu-gmac.dtb \
  -drive "id=rootsd,if=none,file=img/sd.img,format=raw,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  -nic user,model=npcm-gmac,"hostfwd=udp::${QEMU_IPMI_PORT}-:623" \
  -serial unix:"${SOCK}",server,nowait \
  2>"${WORK_DIR}/qemu.log" &
QPID=$!

until [ -S "$SOCK" ]; do sleep 0.5; done
sleep 1
echo "[+] QEMU started (PID=$QPID)"

# Background: watch for UDP_ECHO_READY → send test packet
(
  until grep -q "UDP_ECHO_READY" "$LOGFILE" 2>/dev/null; do sleep 0.5; done
  echo "[udp-test] sending test packet to 127.0.0.1:$QEMU_IPMI_PORT"
  python3 -c "import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.sendto(b'HELLO_UDP_TEST',('127.0.0.1',$QEMU_IPMI_PORT))" 2>/dev/null || true
  echo "[udp-test] sent"
) &
UDPTESTPID=$!

expect << 'EOEXP'
match_max 2000000
set timeout 60
spawn socat - UNIX-CONNECT:$env(HOME)/phd/tmp/idrac10-virtual/p5.sock

expect { "sh-5.2#" {} timeout { puts "BOOT TIMEOUT"; exit 1 } }
puts "[expect] shell ready"

send "mount -t proc proc /proc; mount -t sysfs sysfs /sys; mount -t devtmpfs devtmpfs /dev; mkdir -p /dev/pts; mount -t devpts devpts /dev/pts; mount -t tmpfs tmpfs /tmp; mount -t tmpfs tmpfs /run; mount -t tmpfs tmpfs /var/volatile; mount -t tmpfs tmpfs /mnt\r"
expect -timeout 15 "sh-5.2#"
puts "[expect] filesystems mounted"

send "ip link set eth0 up; ip addr add 10.0.2.15/24 dev eth0; ip route add default via 10.0.2.2\r"
expect -timeout 210 "sh-5.2#"
puts "[expect] network up"

puts "[expect] starting fw.sh..."
send "wget -q --timeout=15 http://10.0.2.2:8080/boot-fullfw-guest.sh -O /tmp/fw.sh && sh /tmp/fw.sh 2>&1\r"

expect {
    -timeout 600
    "IPMI_READY" { puts "[expect] IPMI_READY matched" }
    timeout { puts "[expect] TIMEOUT waiting for IPMI_READY"; exit 1 }
    eof    { puts "[expect] EOF before IPMI_READY"; exit 1 }
}
after 1000

# Helper: send command, wait for prompt, print full buffer
proc run_and_print {cmd label {tmo 20}} {
    send "$cmd\r"
    expect {
        -timeout $tmo
        "sh-5.2#" { puts "$label OUTPUT:\n$expect_out(buffer)" }
        timeout   { puts "$label TIMEOUT" }
        eof       { puts "$label EOF"; return }
    }
}

# Drain buffered prompt from fw.sh exit before running commands
run_and_print "echo SYNC_OK" "SYNC" 10

# === POLLING (first — before any heavy diagnostics) ===
puts "[expect] === POLLING ==="
set ipmi_up 0
for {set i 1} {$i <= 24} {incr i} {
    set out [exec sh -c {zipmi -H localhost -p 7623 -U root -K 915F32F49A97456D0D6D66EEE5ED84C894B414AF -t 20 chassis status 2>&1 || true}]
    puts " poll $i/24: [string trim $out]"
    if {![string match "*timed out*" $out] && ![string match "*error*" [string tolower $out]] && ![string match "*RAKP*" $out]} {
        puts " IPMI RESPONDING at poll $i"
        set ipmi_up 1
        break
    }
    # Every 4th poll: check UDP 623 socket state
    if {$i % 4 == 0} {
        run_and_print "grep ':026F' /proc/net/udp" "UDP-RXQUEUE-$i" 5
    }
    after 3000
}
puts " IPMI_UP=$ipmi_up"

# Verbose single-shot to capture the full RAKP1-4 exchange (wire trace)
puts "[expect] === VERBOSE RAKP ==="
set vout [exec sh -c {zipmi -d -H localhost -p 7623 -U root -K 915F32F49A97456D0D6D66EEE5ED84C894B414AF -t 25 chassis status 2>&1 || true}]
puts "VERBOSE-RAKP:\n$vout"

# === DIAGNOSTICS (after polls — crash here doesn't lose results) ===
puts "[expect] === DIAGNOSTICS ==="
run_and_print "ls -la /proc/*/fd/3 2>/dev/null | grep -v ' -> /proc' | head -20" "fd3"
run_and_print "grep ':026F' /proc/net/udp" "PROC-NET-UDP"
run_and_print "wc -l /tmp/shim-calls.log 2>/dev/null || echo NO-SHIM-LOG; grep -cE 'PSMgrReadAttr|CfgGetAttr|UserInfo|injected' /tmp/shim-calls.log 2>/dev/null || echo 0" "SHIM-LINECOUNT" 5
run_and_print {grep -E 'Users\.|sz=1\)|sz=8\)|sz=16\)|Enable|PrivLimit|Privilege|injected' /tmp/shim-calls.log 2>/dev/null | head -60 || echo no-user-table-calls} "SHIM-USERTABLE" 15
run_and_print "grep -E 'PSMgrReadAttr|CfgGetAttr|UserInfo|injected' /tmp/shim-calls.log 2>/dev/null | head -200 || echo no-relevant-shim-calls" "SHIM-RELEVANT" 30
run_and_print {grep -E 'UserName|UserInfoGetUser|injected.*root|injected.*username' /tmp/shim-calls.log 2>/dev/null | head -40 || echo no-username-calls} "SHIM-USERNAME" 10
run_and_print "grep 'PSMgr uid=2' /tmp/shim-calls.log 2>/dev/null | sort | uniq -c | head -30 || echo no-diag-lines" "DIAG-PSMGR-UID2" 15
run_and_print "grep dump /tmp/shim-calls.log 2>/dev/null | tail -40 || echo no-dump" "USERTABLE-DUMP" 20
run_and_print "grep inject /tmp/shim-calls.log 2>/dev/null | grep -v injected= | head -3 || echo no-inject" "INJECT-DETAIL" 10
run_and_print "cat /tmp/crash.log 2>/dev/null | tail -8 || echo no-crashlog" "CRASH-PC" 10
run_and_print "cat /tmp/fullfw.log 2>/dev/null | tail -20 || echo no-fullfw-log" "FULLFW-LOG" 10
run_and_print {FP=$(pgrep SoftTimer 2>/dev/null | head -1); echo "FWPID=$FP"; [ -n "$FP" ] && for t in /proc/$FP/task/*/wchan; do tid=${t%/wchan}; tid=${tid##*/}; printf 'tid=%s wchan=%s\n' $tid "$(cat $t 2>/dev/null)"; done} "FULLFW-THREADS" 30
run_and_print {for name in SoftTimer aim dbus-broker; do pgrep "$name" 2>/dev/null | while read p; do printf 'pid=%s comm=%s wchan=%s\n' "$p" "$name" "$(cat /proc/$p/wchan 2>/dev/null)"; done; done} "PROC-WCHAN" 15
run_and_print "tail -30 /tmp/console-full.log 2>/dev/null" "CONSOLE-LOG" 10

puts " done"
exit 0
EOEXP

echo "[+] Phase 5 run138 complete."
