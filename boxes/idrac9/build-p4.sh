#!/usr/bin/env bash
# build-p4.sh — repack the Phase-4 initramfs (boot/initramfs.p4.xz) from init.p4.custom.
# Phase 4 = minimal-systemd mesh bring-up (mini.target, DefaultDependencies=no) used to tear
# down the dbus-broker -131 blocker. Reuses the patched kernel + p4.dtb already in boot/.
# Substitutes the VM pubkey (img/vmkey.pub) into the __PUBKEY__ placeholder.
# RUN: ./build-p4.sh   then   ./run-p4.sh
set -euo pipefail; cd "$(dirname "$0")"
[ -d img/initrd ] || { echo "FATAL: img/initrd (base initramfs) missing — run build.sh first"; exit 1; }
PUB="$(cat img/vmkey.pub)"
rm -rf img/initrd4 && cp -a img/initrd img/initrd4
sed "s|__PUBKEY__|$PUB|" init.p4.custom > img/initrd4/init
chmod +x img/initrd4/init
# ship synthesized cfgdb factory-default values into the initramfs (prep injects them); build
# them if missing. The real factory values live in flash we don't have — these come from the
# CfgAttributeMetadata defaults (scripts/build-cfgdb-defaults.py).
CVDB=img/cfgdb-defaults.db
META="${META:-}"
[ -f "$META" ] || { echo "FATAL: set META to the extracted iDRAC9 CfgAttributeMetadata.db" >&2; exit 1; }
# curated subset (network/IPMI/Users/Info groups) — full 10638-attr load stalls cfgmgr
CVGROUPS="CurrentIPv4,CurrentIPv6,IPv4,IPv4Static,IPv6,IPv6Static,NIC,NICStatic,CurrentNIC,NICVLAN,IPMILANConfig,IPMILan,IPMIIPConfig,IPMISOL,IPMISerial,SNMPTrapIPv4,Users,Info,IPBlocking,SecureDefaultPassword,IPMIUserInfo"
python3 scripts/build-cfgdb-defaults.py "$META" "$CVDB" evb "$CVGROUPS" >/dev/null
# provision IPMI user Users.2 = root, enabled, LAN-Administrator(4), all-priv(0x1FF), with the
# factory fleet IPMIKey -> RAKP authenticates. racadm can't set the password (needs the CIAM
# credential backend), so inject the full record straight into the store. (Users made writable
# in the metadata below so cfgmgr loads these instead of the read-only metadata defaults.)
IPMIKEY="${IPMIKEY:-915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964}"
sqlite3 "$CVDB" "
  UPDATE CfgValueTable SET AttributeValue='root'      WHERE GroupName='Users' AND GroupIndex=2 AND AttributeName='UserName';
  UPDATE CfgValueTable SET AttributeValue='1'         WHERE GroupName='Users' AND GroupIndex=2 AND AttributeName='Enable';
  UPDATE CfgValueTable SET AttributeValue='4'         WHERE GroupName='Users' AND GroupIndex=2 AND AttributeName='IpmiLanPrivilege';
  UPDATE CfgValueTable SET AttributeValue='511'       WHERE GroupName='Users' AND GroupIndex=2 AND AttributeName='Privilege';
  UPDATE CfgValueTable SET AttributeValue='1'         WHERE GroupName='Users' AND GroupIndex=2 AND AttributeName='SolEnable';
  UPDATE CfgValueTable SET AttributeValue='$IPMIKEY'  WHERE GroupName='Users' AND GroupIndex=2 AND AttributeName='IPMIKey';
  -- unblock fullfw's UserInfoInit 60s+ park (it polls this until set; absent on QEMU -> never
  -- services udp/623). SecureDefaultPassword now in CVGROUPS so the row exists; set it to 1.
  -- (metadata patch below also moves it DBLocation 3->2 so cfgmgr loads it into the datacache.)
  UPDATE CfgValueTable SET AttributeValue='1'         WHERE GroupName='SecureDefaultPassword' AND GroupIndex=1 AND AttributeName='DefaultUserCreated';
  -- THE 0x0d fix: RAKP1 (UserInfoSearchByNameAndPriv) requires root's per-channel access byte
  -- record[37+ch] to have priv-nibble>=4 AND bit 0x10. That byte is built by User_Access_Handler
  -- from IPMIUserInfo.2#UserChannelAccess (an 8-byte per-channel blob), which our DIRECT cfgdb
  -- seed never populated (factory/racadm create-flow writes it) -> byte 0x00 -> 0x0d. Set every
  -- channel to 0x14 (nibble 4 | bit 0x10; 0x14 & 0x70 = 0x10 covers the src2&0x70 term too).
  -- StdPayload=0x10 per channel as insurance if src2 reads StdPayload instead. NOT a password;
  -- IPMIKey (the RAKP HMAC key) is untouched. (RE: rakp_root_inclusion_predicate.txt)
  UPDATE CfgValueTable SET AttributeValue='1414141414141414' WHERE GroupName='IPMIUserInfo' AND GroupIndex=2 AND AttributeName='UserChannelAccess';
  UPDATE CfgValueTable SET AttributeValue='1010101010101010' WHERE GroupName='IPMIUserInfo' AND GroupIndex=2 AND AttributeName='StdPayload';"
cp -f "$CVDB" img/initrd4/cfgdb-defaults.db
# patched metadata: CurrentIPv4 made writable + default = our IP (read-only is why the injected
# CurrentIPv4 value got reset to 0.0.0.0). Regenerated here so the IP is one knob (CVIP). init
# bind-mounts it over the squashfs original so cfgmgr loads CurrentIPv4 writable=CVIP.
CVIP="${CVIP:-10.0.2.15}"; CVMASK="${CVMASK:-255.255.255.0}"; CVGW="${CVGW:-10.0.2.2}"
cp -f "$META" img/cfgmeta.db
sqlite3 img/cfgmeta.db "UPDATE AttributeMetaTable SET IsReadonly=0 WHERE GroupName IN ('CurrentIPv4','Users');
  -- Users.UserName is DBLocation=3 (credential-vault/CV store) on stock fw, but the CV path is
  -- broken in emulation (tmpfiles symlinks /var/lib/cfgdb/CV -> /mnt/cv/cfgdb dm-crypt mount we
  -- lack; CopyPasswordToCV moves only secret-class attrs, never UserName). Move it to
  -- DBLocation=2 so UserName=root flows EMMC->tmpfs->datacache, the SAME proven path as
  -- IPMIKey/IpmiLanPrivilege (which load fine). RAKP needs UserName+IPMIKey, not Password, so
  -- leaving Password in the broken CV store is fine.
  UPDATE AttributeMetaTable SET DBLocation=2 WHERE GroupName='Users' AND AttributeName='UserName';
  -- fullfw UserInfoInit (libsess 0x447b0610) parks its WHOLE init thread polling
  -- securedefaultpassword.1#defaultusercreated for 60s, then proceeds; but the attr is
  -- DBLocation=3 (CV store, broken in emu) so it's ABSENT from the datacache -> fullfw's RMCP
  -- listener (UDPCreateInstance/RMCPListenTask) never services udp/623 on a clean boot. Move it
  -- to DBLocation=2 + default 1 (same trick as Users.UserName) so it loads into the datacache and
  -- the poll passes on iteration 1 -> init proceeds straight to recvmsg(623). (RE: fullfw cold-boot
  -- RMCP-listener gate.)
  UPDATE AttributeMetaTable SET DBLocation=2, DefaultValue='1' WHERE GroupName='SecureDefaultPassword' AND AttributeName='DefaultUserCreated';
  UPDATE AttributeMetaTable SET DefaultValue='$CVIP'   WHERE GroupName='CurrentIPv4' AND AttributeName='Address';
  UPDATE AttributeMetaTable SET DefaultValue='$CVMASK' WHERE GroupName='CurrentIPv4' AND AttributeName='Netmask';
  UPDATE AttributeMetaTable SET DefaultValue='$CVGW'   WHERE GroupName='CurrentIPv4' AND AttributeName='Gateway';
  UPDATE AttributeMetaTable SET DefaultValue='1'       WHERE GroupName='CurrentIPv4' AND AttributeName='Enable';"
cp -f img/cfgmeta.db img/initrd4/cfgmeta.db
# (No libtcpi patch: the UDPCreateInstance "NIC bail" at 0x376c is a RED HERRING — the NIC index is
# provably 0 (LANChannelInit passes 0), so cmp 1,0; bls never fires. The actual cause of fullfw
# not servicing udp/623 was the SOCKET FAMILY: UDPCreateInstance does an unconditional
# setsockopt(IPV6_RECVPKTINFO) that returns -1 on an AF_INET socket -> RMCPCreateSocketInstance
# fail -> fullfw exits. Fix is in init.p4: socket-activate fullfw on [::]:623 (IPv6 dual-stack),
# matching stock fullfw.socket's BindIPv6Only=both. bindv6only=0 still catches the v4 hostfwd.)
(cd img/initrd4 && find . | cpio -o -H newc 2>/dev/null | xz --check=crc32 -c) > boot/initramfs.p4.xz
echo "built boot/initramfs.p4.xz ($(wc -c < boot/initramfs.p4.xz) bytes)"
