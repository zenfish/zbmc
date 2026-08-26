#!/bin/sh
# boot-fullfw-guest.sh — iDRAC10 Phase 5: start fullfw IPMI daemon in QEMU guest
#
# WHAT:   Runs inside QEMU npcm845-evb guest (init=/usr/bin/sh).
#         Boots dbus-broker via systemd-socket-activate (creates socket on bind,
#         spawns broker on first client connect), then aim → fullfw → wait UDP 623.
# OUTPUT: IPMI_READY (UDP 623 up) or IPMI_FAILED

set -e

# Mounts (tolerate already-done)
mkdir -p /var/volatile /run /tmp /flash /mnt
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts 2>/dev/null || true
mount -t tmpfs tmpfs /tmp 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
mount -t tmpfs tmpfs /var/volatile 2>/dev/null || true
mount -t tmpfs tmpfs /mnt 2>/dev/null || true

# /flash/data0 → symlink to /mnt/persistent_data/data0 (dangling until we create the target)
# Create target through /mnt FIRST, then symlink becomes valid
# /flash/data0 → symlink to /mnt/persistent_data/data0 (dangling until target created)
# /var/log    → symlink to /var/volatile/log (dangling until volatile mounted + dir created)
# /var/run    → symlink to /run (ok, /run is tmpfs)
# All: use concrete paths to avoid mkdir EEXIST on dangling symlinks
mkdir -p /mnt/persistent_data/data0/BMC_Data
mkdir -p /mnt/persistent_data/data0/etc/ssl/certs
mkdir -p /mnt/persistent_data/data0/aim/persistent
mkdir -p /var/volatile/log/fullfw /var/volatile/log/avct
mkdir -p /run/aim /run/fullfw

echo "=== FAKE JOURNAL SOCKET ==="
# dbus-broker-launch calls sd_journal_stream_fd() which needs /run/systemd/journal/stdout.
# Without systemd-journald, it crashes (ENOENT). fake-journal creates that socket,
# accepts+discards connections, letting dbus-broker-launch open its log successfully.
HOST_URL="http://10.0.2.2:8091"
mkdir -p /run/systemd/journal
wget -q --timeout=15 "${HOST_URL}/fake-journal" -O /tmp/fake-journal
chmod +x /tmp/fake-journal
/tmp/fake-journal  # daemonizes: binds socket, forks+exits
sleep 0.5
[ -S /run/systemd/journal/stdout ] && echo "journal socket up" || echo "WARN: journal socket missing"

echo "=== MACHINE-ID ==="
# /etc/machine-id is empty in squashfs. sd_id128_get_machine() returns ENOMEDIUM
# when the file is missing or shorter than 32 hex chars — kills dbus-broker-launch.
echo "deadbeefdeadbeefdeadbeefdeadbeef" > /tmp/machine-id
mount --bind /tmp/machine-id /etc/machine-id
echo "machine-id: $(cat /etc/machine-id)"

echo "=== NETWORK TEST ==="
# Verify QEMU slirp gateway reachable — if this fails, hostfwd won't work
ping -c 2 -W 2 10.0.2.2 && echo "PING_GATEWAY: OK" || echo "PING_GATEWAY: FAIL (packets won't reach fullfw from host)"
ip addr show eth0 2>/dev/null | grep 'inet ' || echo "eth0: no IPv4"
ip route 2>/dev/null | head -3

echo "=== UDP INBOUND REACHABILITY TEST ==="
# Bind UDP 623, wait 8s for test packet from host, echo back.
# Host sends "HELLO" to 127.0.0.1:7623 when it sees UDP_ECHO_READY in the log.
# UDP_ECHO_OK → QEMU hostfwd delivers UDP to guest → network path proven.
# UDP_ECHO_TIMEOUT → hostfwd broken → root cause of fullfw non-response.
wget -q --timeout=15 "${HOST_URL}/udp-echo" -O /tmp/udp-echo
chmod +x /tmp/udp-echo
/tmp/udp-echo  # blocks up to 8s; prints UDP_ECHO_READY then result

echo "=== AVCTPASSWD CHECK ==="
if [ -f /etc/avctpasswd ]; then
    echo "avctpasswd: $(wc -l < /etc/avctpasswd) lines OK"
else
    echo "IPMI_FAILED: /etc/avctpasswd missing"; exit 1
fi

# --- D-Bus via systemd-socket-activate ---
# systemd-socket-activate creates /run/dbus/system_bus_socket on bind (before any
# client connects). First client connection triggers spawn of dbus-broker-launch,
# which inherits the listening fd via LISTEN_FDS=1. Subsequent clients connect
# directly to dbus-broker-launch.
echo "=== SYSV IPC TUNING ==="
ls /proc/sysvipc/ 2>/dev/null && echo "SYSVIPC: available" || echo "SYSVIPC: MISSING — shmget will fail"
echo "shmmax: $(cat /proc/sys/kernel/shmmax 2>/dev/null || echo MISSING)"
echo 268435456 > /proc/sys/kernel/shmmax 2>/dev/null && echo "shmmax→256MB OK" || echo "WARN: shmmax not writable"
echo 268435456 > /proc/sys/kernel/shmall 2>/dev/null || true
mkdir -p /dev/shm
mount -t tmpfs tmpfs /dev/shm 2>/dev/null && echo "/dev/shm: mounted" || echo "/dev/shm: mount skipped"
echo "shmmni: $(cat /proc/sys/kernel/shmmni 2>/dev/null || echo MISSING)"
# ipcmk hangs when shmget() blocks (kernel lock contention with /dev/shm tmpfs).
# Skip the test — shim handles shmget() via mmap instead.

echo "=== SHM SHIM ==="
# SYSV shmget() fails on npcm845-evb QEMU (ipcmk confirms broken).
# Load LD_PRELOAD shim that replaces shmget/shmat/shmdt/shmctl with
# file-backed mmap under /tmp — no kernel SYSV SHM needed.
wget -q --timeout=15 "${HOST_URL}/shm-shim.so" -O /tmp/shm-shim.so
chmod +x /tmp/shm-shim.so
ls -la /tmp/shm-shim.so
export LD_PRELOAD=/tmp/shm-shim.so
# Can't self-test with ipcmk (shmget hangs in this kernel even with shim for non-shim path).
# Constructor writes /tmp/shm-shim-loaded when any process loads the shim.
rm -f /tmp/shm-shim-loaded

echo "=== CONSOLE SINK ==="
# Bind /dev/console to a file BEFORE any daemon (AIM, dbus, fullfw).
# All openlog(LOG_CONS)/direct-open writes go to /tmp/console.log on guest tmpfs.
# Shell stdout/stderr (opened before this mount) still reach the serial socket.
# PROBLEM: some process opens /dev/console with O_TRUNC, wiping prior content.
# FIX: background loop periodically appends console.log → console-full.log (dedup-safe).
touch /tmp/console.log /tmp/console-full.log
mount --bind /tmp/console.log /dev/console && echo "console→file OK" || echo "WARN: console bind-mount failed"
( while true; do
    cat /tmp/console.log >> /tmp/console-full.log 2>/dev/null
    sleep 2
done ) &

echo "=== DBUS POLICY PATCH ==="
# User-specific allow rules (user="DryIO" etc.) are skipped since those users
# aren't in /etc/passwd. Default deny blocks root from owning com.dell.idrac.*
# Fix: bind-mount tmpfs over system.d with a blanket root-allow policy first.
mkdir -p /tmp/dbus-system-d
cp /etc/dbus-1/system.d/*.conf /tmp/dbus-system-d/ 2>/dev/null || true
cat > /tmp/dbus-system-d/00-allow-root.conf << 'DBUSPOL'
<?xml version="1.0"?>
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="root">
    <allow own="*"/>
    <allow send_type="method_call"/>
    <allow receive_type="method_call"/>
    <allow send_type="signal"/>
    <allow receive_type="signal"/>
    <allow send_requested_reply="true"/>
    <allow receive_requested_reply="true"/>
  </policy>
</busconfig>
DBUSPOL
mount --bind /tmp/dbus-system-d /etc/dbus-1/system.d
echo "D-Bus policy: root allowed *"

echo "=== STARTING DBUS-BROKER via socket-activate (retry) ==="
mkdir -p /run/dbus
# ROOT CAUSE of ~2/3 non-responsive boots: systemd-socket-activate intermittently
# aborts on `Assertion 'r == SD_LISTEN_FDS_START + count'` (socket-activate.c:99),
# leaving no system D-Bus -> fullfw gets ~100 "Connection refused" -> segfaults ->
# RMCP never comes up. It's INTERMITTENT, so retry until D-Bus is genuinely up
# (socket present AND the launcher process still alive), cleaning any stale socket.
SACPID=0
for attempt in $(seq 1 8); do
    rm -f /run/dbus/system_bus_socket 2>/dev/null
    # Close inherited FDs 3-9 (leaked by the console-append loop / fake-journal /
    # backgrounded procs). systemd-socket-activate asserts its listen socket lands
    # at FD SD_LISTEN_FDS_START(3); if FD 3 is already taken the socket gets a
    # higher number and it Aborts (socket-activate.c:99) — the deterministic-per-
    # boot failure behind the "silent"/no-D-Bus boots. Free FD 3+ so it passes.
    # The `r == SD_LISTEN_FDS_START + count` abort is socket-activate seeing
    # INHERITED LISTEN_PID/LISTEN_FDS (it thinks it was itself socket-activated
    # with a different fd count). Unset them + close leaked FDs 3-9.
    ( unset LISTEN_PID LISTEN_FDS LISTEN_FDNAMES
      exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-
      exec /usr/bin/systemd-socket-activate \
          --listen=/run/dbus/system_bus_socket \
          -- /usr/bin/dbus-broker-launch --scope system \
          > /tmp/dbus.log 2>&1 ) &
    SACPID=$!
    ok=0
    for i in $(seq 1 10); do
        # socket bound AND launcher alive. (NB: do NOT probe with busctl here — an
        # early root client connection consumed the socket-activate first-connect
        # and left RMCP silent in runs 132-134. Let AIM be the first client.)
        if [ -S /run/dbus/system_bus_socket ] && kill -0 $SACPID 2>/dev/null; then
            sleep 0.5   # let it settle; if it was going to abort it dies now
            kill -0 $SACPID 2>/dev/null && { ok=1; break; }
        fi
        kill -0 $SACPID 2>/dev/null || break   # launcher died (aborted) -> retry now
        sleep 0.5
    done
    if [ $ok -eq 1 ]; then echo "DBUS UP (attempt $attempt, PID=$SACPID)"; break; fi
    echo "DBUS attempt $attempt failed (abort?); retrying. log tail:"; tail -2 /tmp/dbus.log 2>/dev/null
    kill $SACPID 2>/dev/null; SACPID=0
done
if [ ! -S /run/dbus/system_bus_socket ] || [ $SACPID -eq 0 ]; then
    echo "DBUS NEVER CAME UP after retries:"; cat /tmp/dbus.log 2>/dev/null
    echo "IPMI_FAILED"; exit 1
fi

# --- AIM (creates /tmp/ec SHM; first D-Bus client → triggers broker spawn) ---
echo "=== STARTING AIM ==="
HOME=/flash/data0 /usr/bin/aim > /tmp/aim.log 2>&1 &
AIMPID=$!
echo "AIM PID=$AIMPID"

for i in $(seq 1 20); do
    [ -f /tmp/ec ] && echo "/tmp/ec created (iter $i)" && break
    sleep 1
done
if [ ! -f /tmp/ec ]; then
    echo "/tmp/ec NOT created after 20s — aim log:"
    cat /tmp/aim.log 2>/dev/null
    echo "dbus log:"
    cat /tmp/dbus.log 2>/dev/null
    # Continue anyway; fullfw may still work
fi

# --- CFGMGRD: real config daemon so fullfw reads user config natively ---
# Replaces the LD_PRELOAD config-read shims (now #if 0 in shm-shim.c).
# fullfw reads Users.N#{UserName,IPMIKey,Enable,IpmiLanPrivilege} over D-Bus
# from com.dell.idrac.CfgMgr, backed by SQLite CfgCurrentValues.db.
echo "=== STARTING CFGMGRD ==="
export IMAGE=idrac-image                     # cfgdb-setup.sh gate (etc/yocto-image.env)
# /var/lib is a symlink → /mnt/persistent_data/data0/var/lib (dangling). Create the
# target so it resolves, else mkdir on the cfgdb tree fails. Everything here is
# best-effort (|| true) so a cfgdb hiccup never aborts the boot under `set -e`.
mkdir -p /mnt/persistent_data/data0/var/lib 2>/dev/null || true
for d in EMMC SPI CV cfgdb PERSIST_CMN; do mkdir -p "/var/lib/cfgdb/$d" 2>/dev/null || true; done
mkdir -p /var/run/cfgdb /var/run/fm 2>/dev/null || true
: > /var/run/fm/default_security.cfg 2>/dev/null || true   # cfgmgrd references this; empty is fine
cp /usr/share/cfgdb/CfgAttributeMetadata.db /var/run/cfgdb/CfgAttributeMetadata.db 2>/dev/null || true
/usr/sbin/cfgdbinit > /tmp/cfgdbinit.log 2>&1 || echo "cfgdbinit rc=$?"
echo "cfgdbinit: $(grep -c 'completed successfully' /tmp/cfgdbinit.log 2>/dev/null) ok-markers"
tail -3 /tmp/cfgdbinit.log 2>/dev/null
echo "--- CfgCurrentValues.db tables ---"
sqlite3 /var/run/cfgdb/CfgCurrentValues.db '.tables' 2>&1 | head -3 || true
echo "--- CfgValueTableTmpfs schema ---"
sqlite3 /var/run/cfgdb/CfgCurrentValues.db '.schema CfgValueTableTmpfs' 2>&1 | head -3 || true
echo "--- default row count in tmpfs BEFORE populate ---"
sqlite3 /var/run/cfgdb/CfgCurrentValues.db 'SELECT count(*) FROM CfgValueTableTmpfs;' 2>&1 || true

# cfgdbinit populates NO attribute defaults, so every non-seeded read fails and
# LAN/PEF init (SerNonVolatileConfigInit) aborts before registering the RMCP UDP
# socket -> transport timeouts. Load host-generated defaults (all attrs x instances
# = DefaultValue from CfgAttributeMetadata.db) so reads return defaults, like cfgpop.
wget -q --timeout=30 "${HOST_URL}/cfgdb-defaults.sql" -O /tmp/cfgdb-defaults.sql
sqlite3 /var/run/cfgdb/CfgCurrentValues.db < /tmp/cfgdb-defaults.sql 2>&1 | head -3 || echo "defaults-load rc=$?"
echo "--- row count AFTER populate ---"
sqlite3 /var/run/cfgdb/CfgCurrentValues.db 'SELECT count(*) FROM CfgValueTableTmpfs;' 2>&1 || true

# Seed user slot 2 = root, factory IPMIKey (RAKP HMAC key), Admin priv.
# Runtime read table is CfgValueTableTmpfs (authoritative for reads).
sqlite3 /var/run/cfgdb/CfgCurrentValues.db << 'SEEDSQL' || echo "SEED rc=$?"
INSERT OR REPLACE INTO CfgValueTableTmpfs
  (AttributeKey,FQDD,GroupName,GroupIndex,AttributeName,AttributeValue,AttributeMemSize) VALUES
 -- AttributeMemSize=16 (was 4). UserInfoLoadUserConfig reads this via
 -- PSMgrReadAttr and copies ~(size-1) bytes; size=4 truncated 'root' to 'roo\0'
 -- -> RAKP1 16-byte name MemCmp failed -> intermittent 0x0d. size 16 => full name.
 ('iDRAC.Embedded.1#Users.2#UserName','iDRAC.Embedded.1','Users',2,'UserName','root',16),
 ('iDRAC.Embedded.1#Users.2#IPMIKey','iDRAC.Embedded.1','Users',2,'IPMIKey','915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964',64),
 ('iDRAC.Embedded.1#Users.2#Enable','iDRAC.Embedded.1','Users',2,'Enable','1',1),
 ('iDRAC.Embedded.1#Users.2#IpmiLanPrivilege','iDRAC.Embedded.1','Users',2,'IpmiLanPrivilege','4',1),
 ('iDRAC.Embedded.1#Users.2#IpmiSerialPrivilege','iDRAC.Embedded.1','Users',2,'IpmiSerialPrivilege','4',1),
 -- Enable the IPMI-over-LAN channel: default IPMILan.Enable=0 keeps the RMCP
 -- listener down (no fd=3/UDP 623). The shim returned empty here so fullfw used
 -- its enabled compiled default; cfgmgrd returns the real 0, so enable it explicitly.
 ('iDRAC.Embedded.1#IPMILan.1#Enable','iDRAC.Embedded.1','IPMILan',1,'Enable','1',1),
 -- Per-user IPMI channel authorization. Defaults gate LAN login: PrivLimit=0F0F..
 -- (0x0F = no-access on all 8 channels), UserChannelAccess=00.. (disabled). Grant
 -- user 2 Administrator(0x04) + IPMI-messaging-enabled(0x10)=0x14 per channel.
 ('iDRAC.Embedded.1#IPMIUserInfo.2#PrivLimit','iDRAC.Embedded.1','IPMIUserInfo',2,'PrivLimit','0404040404040404',16),
 -- UserChannelAccess per-channel byte: bits[3:0]=priv (4=admin), bit4(0x10)=
 -- restricted-to-callback, bit7 must be clear. 0x14 set the callback-restrict
 -- bit -> RAKP2 0x0a. Use 0x04 (plain admin) so the priv check passes.
 -- 16 bytes (was 8): LoadUserConfig writes this into the entry's per-channel
 -- UserChannelAccess (entry+0x25..). RAKP2 0x0a gate reads entry+0x25+channel;
 -- an 8-byte value left channels 8-15 = 0 -> 0x0a if the LAN channel is >=8.
 ('iDRAC.Embedded.1#IPMIUserInfo.2#UserChannelAccess','iDRAC.Embedded.1','IPMIUserInfo',2,'UserChannelAccess','04040404040404040404040404040404',32),
 -- RAKP1 reverse name->uid lookup: for ::ffff:-mapped sources (QEMU usermode
 -- forwards via IPv6-mapped addrs), libsess builds 'idrac.embedded.1#users.<name>'
 -- and CfgGetAttribute's it instead of searching G_sUserTable. Unseeded -> 0x0d.
 -- Seed root -> uid 2 so that branch resolves the user.
 ('idrac.embedded.1#users.root','iDRAC.Embedded.1','users',0,'root','2',1);
 -- (Removed CipherSuitePrivilege/IPMILan#PrivLimit overrides: RE confirmed the
 --  RAKP2 0x0a gate is a raw entry byte (entry+0x25+channel), NOT a config attr,
 --  so these did nothing — and the malformed cipher string may have destabilized
 --  RMCP. The 0x0a fix is the widened UserChannelAccess fill in shm-shim.c.)
SEEDSQL
echo "seeded Users.2 rows: $(sqlite3 /var/run/cfgdb/CfgCurrentValues.db "SELECT count(*) FROM CfgValueTableTmpfs WHERE GroupName='Users' AND GroupIndex=2;" 2>&1)"

# cfgmgrd crypto init reads /dev/hwrng (ENODEV in guest) then BLOCKS on /dev/random
# waiting for entropy → never claims the bus name. Redirect /dev/hwrng → /dev/urandom
# (non-blocking) so its first RNG choice succeeds and it never touches /dev/random.
mount --bind /dev/urandom /dev/hwrng 2>/dev/null || { rm -f /dev/hwrng 2>/dev/null; ln -sf /dev/urandom /dev/hwrng; }
# Dirs cfgmgrd/suptlib expect (from strace): OMDataEngine IPC, cfg-encrypt key store,
# oem persistent store. Missing → ENOENT retries.
mkdir -p /var/run/dm/.ipc /var/lib/cfgmgr/cv/keys /flash/data0/oem_ps 2>/dev/null || true
# strace the loop BODY (reads/stats/waits between omreg opens) to see the missing
# resource; cfgmgrd logs only to the discarded journal so stdout/stderr are empty.
strace -f -e trace=openat,read,close,newfstatat,stat,access,connect,sendmsg,recvmsg,nanosleep,clock_nanosleep,futex \
    -o /tmp/cfgmgrd-strace.log /usr/sbin/cfgmgrd > /tmp/cfgmgrd.log 2>&1 &
CFGPID=$!
echo "CFGMGRD (straced) PID=$CFGPID"
for i in $(seq 1 30); do
    /usr/bin/busctl --system list 2>/dev/null | grep -q 'com.dell.idrac.CfgMgr' \
        && { echo "CFGMGR NAME UP (iter $i)"; break; }
    kill -0 $CFGPID 2>/dev/null || { echo "cfgmgrd/strace EXITED EARLY (iter $i)"; break; }
    sleep 0.5
done
# Settle: cfgmgrd claims the name before it finishes building its attribute tree
# from the 12624 rows. fullfw's early serial/LAN reads (IPMISerial#BaudRate etc.)
# hit the 'name not active' window → SerNonVolatileConfigInit aborts → fd=3 never
# registers with epoll → RMCP silent. Wait until cfgmgrd actually SERVES a seeded
# key before starting fullfw.
echo "--- settling cfgmgrd (fixed delay; name-owned re-check) ---"
sleep 8   # let cfgmgrd finish building its attribute tree before fullfw reads
busctl --system list 2>/dev/null | grep -q 'com.dell.idrac.CfgMgr' \
    && echo "cfgmgrd still owns name after settle" || echo "cfgmgrd LOST name after settle"
echo "--- cfgmgrd alive? ---"; kill -0 $CFGPID 2>/dev/null && echo ALIVE || echo DEAD
# GROUND TRUTH: does cfgmgrd actually SERVE Users.2#UserName='root'? PSMgrReadAttr
# builds this key (lowercase) and calls CfgGetAttribute->CfgMgrInternal.GetAttribute.
echo "--- DB direct (case-folded) ---"
sqlite3 /var/run/cfgdb/CfgCurrentValues.db \
  "SELECT AttributeKey,AttributeValue FROM CfgValueTableTmpfs WHERE UPPER(AttributeKey)=UPPER('idrac.embedded.1#Users.2#UserName');" 2>&1
echo "--- cfgmgrd D-Bus introspect (GetAttribute signature) ---"
busctl --system introspect com.dell.idrac.CfgMgrInternal /com/dell/idrac/CfgMgr/CfgInternalInterface \
  com.dell.idrac.Config.CfgInternalInterface 2>&1 | grep -iE "GetAttribute|method" | head -8
echo "--- cfgmgrd live GetAttribute(Users.2#UserName), sig=s ---"
timeout 8 busctl --system call com.dell.idrac.CfgMgrInternal \
  /com/dell/idrac/CfgMgr/CfgInternalInterface com.dell.idrac.Config.CfgInternalInterface \
  GetAttribute s 'idrac.embedded.1#Users.2#UserName' 2>&1 | head -3
echo "--- busctl CfgMgr? ---"; /usr/bin/busctl --system list 2>&1 | grep -i cfgmgr || echo "no CfgMgr on bus"
echo "--- cfgmgrd.log ---"; cat /tmp/cfgmgrd.log 2>/dev/null
echo "--- cfgmgrd strace tail (last 70) ---"; tail -70 /tmp/cfgmgrd-strace.log 2>/dev/null || echo "(no strace)"
echo "--- omreg open count in full strace ---"; grep -c omreg.cfg /tmp/cfgmgrd-strace.log 2>/dev/null

# --- FULLFW via prebind (AF_INET6 dual-stack) ---
# prebind-v2: creates AF_INET6 dual-stack UDP socket (:::623) as fd=3.
# WHY IPv6: libtcpi UDPCreateInstance() calls setsockopt(fd, IPPROTO_IPV6, IPV6_RECVPKTINFO, 1)
# immediately after getting fd from sd_listen_fds. On AF_INET fd this returns ENOPROTOOPT
# → UDPCreateInstance returns -1 → no RMCP stack → polls always timeout.
# With AF_INET6 fd the setsockopt succeeds → RMCP stack initializes → IPMI works.
echo "=== STARTING FULLFW via prebind (AF_INET6 dual-stack) ==="
wget -q --timeout=15 "${HOST_URL}/prebind" -O /tmp/prebind
chmod +x /tmp/prebind
rm -f /tmp/shm-shim-loaded
# setsid → new session so fullfw survives the serial-console HUP when boot-live.sh
# disconnects (live-iterate reconnects later to pkill+relaunch). LD_PRELOAD is
# inherited from L99. $! would be setsid's (short-lived) pid, so find fullfw via pgrep.
setsid env HOME=/flash/data0 /tmp/prebind /bin/fullfw > /tmp/fullfw.log 2>&1 &
sleep 2
# match by cmdline, not comm: fullfw ignores SIGTERM AND renames its comm after
# init (so `pgrep -x fullfw` misses it; live-iterate must `pkill -9 -f /bin/fullfw`).
FWPID=$(pgrep -f /bin/fullfw | head -1)
echo "FULLFW PID=$FWPID"
[ -f /tmp/shm-shim-loaded ] && echo "SHIM IN FULLFW: YES" || echo "SHIM IN FULLFW: NO (LD_PRELOAD not active)"
echo "=== SHIM CALLS (first 200 lines) ==="
cat /tmp/shim-calls.log 2>/dev/null | head -200 || echo "(no shim-calls.log)"

# prebind binds UDP 623 before exec'ing fullfw → socket appears immediately
for i in $(seq 1 30); do
    if grep -qiE ':026[Ff]' /proc/net/udp /proc/net/udp6 2>/dev/null; then
        echo "=== UDP 623 UP (iter $i) ==="
        break
    fi
    if ! kill -0 $FWPID 2>/dev/null; then
        echo "prebind/fullfw exited early:"; cat /tmp/fullfw.log 2>/dev/null
        echo "IPMI_FAILED"; exit 1
    fi
    sleep 1
done
if ! grep -qiE ':026[Ff]' /proc/net/udp /proc/net/udp6 2>/dev/null; then
    echo "UDP 623 never appeared"; cat /tmp/fullfw.log 2>/dev/null
    echo "IPMI_FAILED"; exit 1
fi

# fullfw daemonizes → writes to /dev/console (bind-mounted to /tmp/console.log)
# "ialized successfully, sec_id=10" = RMCP LAN stack ready
echo "waiting for fullfw PostInit..."
# Strace epoll_ctl across all fullfw threads: shows epoll_ctl(epfd, EPOLL_CTL_ADD, 3, ...)
# when the IPMI LAN stack registers fd=3 (UDP 623) with the event loop.
# Attach after 3s (prebind->exec complete). Run for 90s.
( sleep 3
  strace -p $FWPID -f -e trace=epoll_ctl -o /tmp/fw-strace-epollctl.log -T -tt 2>/dev/null &
  STPID=$!
  sleep 90
  kill $STPID 2>/dev/null
) &
# Also strace fd=3 recvfrom/sendto after epoll_ctl window to see if fullfw reads packets.
( sleep 95
  strace -p $FWPID -f -P 3 -o /tmp/fw-strace-fd3.log -T -tt 2>/dev/null &
  STPID2=$!
  sleep 60
  kill $STPID2 2>/dev/null
) &
for i in $(seq 1 180); do
    if grep -qE 'IPMI initial|ialized successfully' /tmp/console-full.log 2>/dev/null; then
        echo "fullfw PostInit done (iter $i)"
        cat /tmp/console-full.log 2>/dev/null | grep -E 'IPMI|ialized|error|fail' | head -20
        break
    fi
    if [ $((i % 15)) -eq 0 ]; then
        syscall=$(cat /proc/$FWPID/syscall 2>/dev/null || echo unknown)
        threads=$(ls /proc/$FWPID/task/ 2>/dev/null | wc -l)
        console_lines=$(wc -l < /tmp/console-full.log 2>/dev/null || echo 0)
        echo "PostInit: iter $i/180 console-full=$console_lines lines fw-syscall=$syscall threads=$threads"
        # Show fd3 strace so far
        echo "--- fd3 strace (last 10 lines) ---"
        tail -10 /tmp/fw-strace-fd3.log 2>/dev/null || echo "(none yet)"
        echo "---"
    fi
    sleep 1
done
echo "=== sockbind strace (first 80 lines) ==="
head -80 /tmp/fw-strace-sockbind.log 2>/dev/null || echo "(no sockbind strace output)"
echo "=== epoll strace (first 40 lines) ==="
head -40 /tmp/fw-strace-epollctl.log 2>/dev/null || echo "(no epoll strace output)"

echo "--- fullfw log ---"
cat /tmp/fullfw.log 2>/dev/null || true
echo "--- console-full.log (cumulative daemon output) ---"
cat /tmp/console-full.log 2>/dev/null || echo "(empty)"
echo "=== /proc/net/udp ==="
cat /proc/net/udp 2>/dev/null || true
# --- SSH bring-up: enable root pubkey ssh on the virtual BMC (gets baked into the snapshot) ---
# WHY: /etc/ssh symlinks to an unmounted persistent partition (no host keys); root's login shell
# resolves via NSS libnss_avct to the restricted rcdmShell; and sshd's privsep child reads
# authorized_keys as non-root. So: materialize the tmpfs ssh dir + host keys, put the key
# world-readable, bind an nsswitch with `files` before `avct` (root shell -> /bin/sh), start sshd.
# restore-idrac10.sh adds the tcp:22 hostfwd. Reach it: ssh root@drac10 (/admin1-> prompt = real sh).
# Subshell with `set +e` so a failure here can never abort the fullfw bring-up (script runs set -e).
( set +e
  mkdir -p /mnt/persistent_data/data0/etc/ssh /run/sshd
  printf '%s\n' 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDccPy7TeQu44Q9UWxcS88v44QBMjVulE48Zn+xV4GF+FTFU4/uvZDtBODZmzGBLNMKICqyuQn+xeWij9GNT7KNTnvj/Yyk7MWGhnFrYCGeXjATJu4PQQvcystDiRcXUzzrhh+pkm6m/5Bb2fDXZscVSgVMpH/NCyp0n/SMi4JPuNt0M/I7CnUEzvhIHVAI35Cfc7MOLgARVjvzUwYc5joSlNdQOFcB72MhGVX0UDX+ezBDiW9GAsAyU/XUumh0XDpKGF3ljj3gSSBRIDYpud4Uujqa2RtXEai9F/mSHYhhYYjUYF9M00x1LMps0MOv3ztaBILD7p+o8XrQRw9q1ez3' > /tmp/.idrac_ak
  chmod 644 /tmp/.idrac_ak
  ssh-keygen -A 2>/dev/null
  printf 'passwd: files avct ucache systemd\ngroup: files avct ucache systemd\nshadow: files\nhosts: files dns\n' > /tmp/nss.conf
  mount --bind /tmp/nss.conf /etc/nsswitch.conf 2>/dev/null
  printf 'Port 22\nPermitRootLogin yes\nPasswordAuthentication yes\nPubkeyAuthentication yes\nAuthorizedKeysFile /tmp/.idrac_ak\nStrictModes no\nUsePAM no\nPidFile /run/sshd.pid\n' > /run/sshd/sshd_config
  /sbin/sshd -f /run/sshd/sshd_config 2>/dev/null && echo "SSHD_READY (root@:22 -> /bin/sh)"
) || true
# --- end SSH bring-up ---

echo "IPMI_READY"
# Keep PID 1 blocked in fw.sh while the serial console uses disposable child shells.
# Logging out of `zbmc idrac10 ssh` then respawns a shell instead of exiting init.
while :; do
    /bin/sh || true
done
