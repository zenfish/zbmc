# Vanilla evb-ast2600 OpenBMC — build record

- **Image:** evb-ast2600.static.mtd (64 MiB, sha256 ab6b4c6317f6cd08f15cae8e8663ae06f0429671f9c69d9220898357c998ac35)
- **Source:** github.com/openbmc/openbmc @ 5d179dab3c66c8b89e059eeb17b038a2beb435d3 (3.1.0-dev-294-g5d179dab3c)
- **Target:** MACHINE=evb-ast2600, image = obmc-phosphor-image (full feature set)
- **Built on:** dell 192.168.0.21 (~/openbmc/build-evb), 8-core/15G, ~Jul 17-18 2026
- **Boot:** qemu-system-arm -M ast2600-evb -m 1G -nographic -drive file=evb-ast2600.static.mtd,format=raw,if=mtd -nic user,hostfwd=...  (see boot-test.sh)
- **Verified live:** SSH root/0penBmc; Redfish ServiceRoot; IPMI-LAN mc info (Mfr 0 = vanilla, FW 3.01)
- **Caps:** ssh + redfish + ipmi-remote + ipmi-local all green. Manufacturer 0 (no OEM) = clean baseline.

## Build gotchas hit (all self-inflicted via kill-to-retune; see feedback_dont_churn_running_builds)
- 4-thread llvm-native link OOM on 15G RAM  -> PARALLEL_MAKE:pn-llvm-native="-j 3"
- orphan-kill left stale pkgdata-sysroot     -> sqlite3 do_package FileExistsError (nuke stale dirs)
- kill mid gawk do_install -> stale image/    -> rm awk fails / 134 abort (bitbake -c cleansstate gawk)
- SPDX/SBOM final stage is SLOW (~6h at 99%, task 5990/6026) but completes — NOT a hang.
- fresh-clone on another host: `umask 022` required or OE sanity checker aborts pre-build.

## local.conf tuning
BB_NUMBER_THREADS="4"; PARALLEL_MAKE="-j 6"; PARALLEL_MAKE:pn-llvm-native="-j 3"; pn-nodejs-native="-j 3"
ERROR_QA:remove="host-user-contaminated" (only if build user is gid 0)
