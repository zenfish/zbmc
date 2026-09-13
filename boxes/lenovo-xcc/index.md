<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=beaf59751515d9e91b03184de5b90daa0b9ee69297553ccd46e94ed4801a8881 body-sha256=945c28974512b93170bff31044dc00ca78bd587256cfaf0c7e28f3a3bc7ec098 -->

zbmc / preserved firmware

# Lenovo XClarity Controller

A cold-boot runtime for Lenovo XCC 6.92 on an AST2600 model with an experimental FPGA transport and eMMC GP0 implementation.

Latest result, 13 September: [all six services pass zBMC validation on TAP](#native-services-recovery), including a [matched checkpoint restored in an isolated TAP network](#tap-warm-checkpoint). Cold-boot reproduction remains unverified; the old default warm checkpoint has not been replaced.

## Verified executable diagnostic RAM — 2026-09-13

The derived boot image creates a 16 MB, root-only executable tmpfs at `/tmp/zbmc-tools`. This was verified after the vendor mount lock activated: the directory remained writable and executable, `strace 6.13 -V` returned zero, and an actual trace of `/bin/true` exited successfully.

**This is diagnostic-tool acceptance, not full BMC readiness.** SSH session creation and IPMI remained unresolved in the preceding run. Do not infer their recovery from this change. The older service observations below are historical; the pre-TAP warm checkpoint is not a verified restore path for the current TAP topology.

### Why it must happen during boot

The running firmware mounts its ordinary writable filesystems with `noexec` and rejects new mounts once its welded-mount lock is active. A runtime attempt to mount executable tmpfs failed with exit 32. `build-shell-kernel.py` now creates the child mount after the existing `/rootfs/tmp` bind and before `switch_root` and the lock. Its options are `size=16m,mode=0700,nodev,nosuid,exec`. The parent `/tmp` remains `noexec`; the vendor rootfs and its signature verification remain unchanged.

### Use in the verified guest

    grep ' /tmp/zbmc-tools ' /proc/mounts
    /tmp/zbmc-tools/strace -V
    /tmp/zbmc-tools/strace -e trace=exit_group -o /tmp/zbmc-tools/smoke.log /bin/true
    cat /tmp/zbmc-tools/smoke.log
    # exit_group(0) = ?
    # +++ exited with 0 +++

The launcher uses an isolated musl loader and library directory inside the diagnostic mount. It does not replace Lenovo's system libraries. Keep traces private: unrestricted tracing of authentication processes can capture credentials or session data.

### Reboot and tool loading

The boot change recreates an *empty* RAM filesystem on each cold boot. Tools and traces disappear at shutdown; they are not embedded in the kernel or automatically downloaded. On Debby, retained copies are `work/lenovo-xcc-warm/diagnostics/tracer.tar.gz` and `diagnostics/strace`. The bundle contains Alpine 3.22 ARMv7 strace 6.13-r0 and its resolved dependencies, fetched using the official ARMv7 signing keys.

To reload, temporarily serve only that diagnostics directory from the host, transfer both files into `/tmp/zbmc-tools`, then run the following in the guest. Stop the temporary file server after transfer.

    cd /tmp/zbmc-tools
    echo '1b829934dca644491d927128231d2439a4dc9c2aa8e35242c664d5e2c4baf6d4  tracer.tar.gz' | sha256sum -c - &&
    tar -xzf tracer.tar.gz && chmod 700 strace && ./strace -V

### Evidence and reproduction

- Run: `20260913T075806Z-c33af0c9-0e6f-401b-95b9-83e9ecec3554`. Raw proof is in that run's `console.log`: `XCC_DIAGNOSTIC_RAM_READY`, the later mount-lock message, `RAM_EXEC_PROOF_RC=0`, and `STRACE_SMOKE_RC=0`.
- Kernel SHA-256: `8448b4c473e9488f69ec3fbe7a4fbe0c88ce19370a0d00690c05d48d29ceaea6`. Two independent builds were byte-identical; original image size and appended tail were preserved.
- `tests/lenovo-xcc-runtime.sh` and `git diff --check` passed. Build through `zbmc lenovo-xcc build`; the updated hash is pinned in `build.sh`.
- The previous kernel and a mode-0600 disk capture were retained before restart. **Correction, 13 September:** that capture omitted unchanged backing-disk data despite passing its qcow2 check. See the [capture failure and recovery](#backing-capture-correction) below. It was not a complete disk backup or a RAM checkpoint.

## Failed approaches and lessons — 2026-09-12–13

This is a sanitized record of the Lenovo cold-service and diagnostic-tool investigation, including our diagnostic mistakes. “Observed” means measured in a run; “decoded” means established from vendor code; rejected designs are not presented as executed experiments. Unresolved causes remain unresolved.

| Attempt or assumption | Evidence / outcome | Lesson |
|----|----|----|
| Treat build readiness, root-page HTTP 200, or disabled probes as working management services. | Artifacts and a public page were available while authenticated services failed or were untested. The run also had Web-UI validation disabled. | Separate boot, transport, authentication, session creation, and useful operations. An excluded test is not a pass; label historical results explicitly. |
| Reuse the 94-second warm-start result as a cold-start expectation. | That result came from a provisioned, pre-TAP checkpoint. The new cold boot took several minutes merely to verify and mount its rootfs. | Record cold versus warm and network topology with every timing and acceptance claim. |
| Assume the blacklisted `ipmi_gateway` pathname explained LAN IPMI failure. | The path is a pruning-warning stub, not a demonstrated LAN daemon. Its startup banner was not functional proof. | Trace the actual service owner and account/global/channel gates. Do not replace a missing-looking binary before establishing its role. |
| Run the SSH health probe in a fresh shell without loading private configuration. | Non-exported configuration was lost. A regression failed before and passed after fix `afb6e67`. | Readiness must use the same configuration as the operator command. |
| Declare SSH settings without a Lenovo `zbmc_ssh` handler. | The command returned command-not-found / exit 127. Fixed by `176d5da`. | Test the public command path, not just the descriptor fields. |
| Launch SSH without checking its prerequisite directory or stderr. | The daemon reported `Missing privilege separation directory: /var/run/sshd`. Creating it addressed that prerequisite, not the later PAM failure. | Capture stdout, stderr, and exit status. A launch attempt is not a running service. |
| Poll guest `/proc/net/tcp` inside the SSH launcher. | The wrapper stalled during guest-side process/socket inspection. | Keep launch separate from bounded host-side protocol validation; do not put another readiness loop inside it. |
| Change the bootstrap marker based only on the visible wrapper source. | The composed boot image already emitted the original marker. The proposed change was reverted. | Inspect the complete artifact before changing a boot gate. |
| Remove live SSH script bind mounts to restore vendor startup. | The welded-mount policy rejected removal, exit 32. The original startup scripts were not restored. | A failed unmount changes nothing. Do not describe the intended state as the actual state. |
| Change scheduling priorities and try a temporary SSH listener on port 2222. | Priority changes were measured; the debug listener started, but the host connection timed out. A later port-22 listener completed key exchange. The eventual PAM session failure persisted. | Do not attribute success to a priority change without a controlled comparison, or call the timeout a proven firewall failure. |
| Interpret factory-login `sshpass` exit 5 as a wrong password. | Interactive PAM reached the mandatory password-change flow and reported a successful change. | An interactive password-change requirement is not equivalent to credential rejection. Verify a fresh login afterwards. |
| Treat authentication success as a usable SSH session. | Fresh SSH accepted the identity but exited 254: `PAM session not opened`. A password-only retry did not resolve it. | Require session creation and a valid native command result, not authentication alone. |
| Read “User not known” as a missing account or assume the two-session limit was exhausted. | PAM logged USERID and login success, then session-manager `Internal error!`. Decoded code converts failed AIM session-type lookup into `PAM_USER_UNKNOWN`. | The displayed error loses the underlying cause. Neither an absent account nor session exhaustion was established. |
| Blame empty session directories, a stale PID, or a deadlock. | Decoded code accepts empty directories. Registration matched the live SM PID and queue; queue size was zero. One thread snapshot showed a receive wait. | These checks narrow the problem but do not prove a timeout or deadlock. The exact session-lookup failure remains unknown. |
| Enable only global IPMI. | The native global setting changed from false to true and read back true, but authenticated IPMI still failed. USERID's reported AccountTypes lacked IPMI. | Global enablement, account interface access, and channel privilege are separate checks. |
| Add IPMI through an authenticated Redfish account PATCH. | HTTP 403 `PasswordChangeRequired`, although account GET reported `PasswordChangeRequired=false`. Readback confirmed no AccountTypes change. | Account representation and authentication middleware can disagree. Preserve both observations rather than choosing the convenient one. |
| Retry with a fresh Redfish token to eliminate stale Basic-auth state. | Session creation returned 201 and a manager read returned 200, but the same PATCH still returned 403. Test sessions were removed with 204. | Fresh login was not the fix. Read access did not establish working account modification. |
| Submit the configured password through the normal Redfish Password PATCH. | HTTP 400 `PropertyValueFormatError`, with message argument “null”, despite a JSON string request. Length and character-class checks passed. | Do not infer that the request contained null. Reuse and minimum-change-interval policies were plausible, not proven causes; no further change was claimed. |
| Restart the vendor security/session manager. | After a private configuration backup, the replacement SM registered and reached ready. SSH still failed at session creation. | Restart did not fix the defect. Inspect restart scripts first: this one also initializes account/certificate state. Never confuse restart with its destructive reset operation. |
| Propose recovery before capturing the decisive syscall trace. | Logs and ARM disassembly localized the failing call, but there was no syscall trace of that failure. | Say “localized, not explained.” Establish a bounded tracing path early instead of spending repeated cycles on hypotheses. |
| Use the firmware's `/usr/bin/strace`. | It was a dangling link into the absent optional debug filesystem. | Check the resolved executable and its loader, not just whether a pathname exists. |
| Fetch ARM packages using an x86 container's default package state and keys. | Fetch initially lacked an index; an explicit ARM index update then failed signature validation with the wrong architecture's keys. | Use the ARM repository index and the supplied ARMv7 key directory. Signature verification remained enabled. |
| Copy a verified tracer to `/tmp`, or consider `/run`, `/var/log`, `/dev`, and `/proc`. | Transfer and checksum succeeded, but execution from /tmp failed 126. The other writable mount locations inspected were also noexec; /var/log resolved into the noexec whitelist filesystem. | Changing directory names does not change mount flags. /proc is not ordinary file storage. |
| Mount a new executable RAM filesystem after boot. | Kernel: `welded mounts are locked, refusing mount`; exit 32. No diagnostic mount was created. | Move the mount creation to the existing early-boot integration point. The verified solution is above. |
| Use an interpreter-based tracer instead. | Python and ctypes worked, but python-ptrace imports stalled and were interrupted before attachment. Source inspection found ARM register support but no ARM32 syscall-name selection in that revision. | Register support is not complete tracer support. No SSH/SM trace was obtained from this attempt; ordinary interpreter execution was not proof of tracing. |
| Put tools directly into the signed SquashFS or embed the bundle in the fixed kernel region. | These were rejected designs, not failed boots. Replacing the signed filesystem would invalidate its signature; the recompressed boot archive had only about 2.5 KB spare. | Inspect integrity and capacity constraints first. A small early mount hook plus later tool loading fit the existing image. |
| Accept QMP disk-backup completion or a qcow2 check as proof of a usable backup. | The QMP target disappeared for an unexplained reason. The fallback conversion of the temporary overlay passed `qemu-img check` but omitted unchanged backing data. | Capture the complete runtime backing graph. Verify filesystem consistency and known firmware bytes, not just container structure. The original fallback was incomplete; see the recovery correction below. |

The failed runtime experiments are retained in run `20260913T020333Z-10a78c9d-b001-44e4-a9e4-9c5f2f4ec2cb`; the successful diagnostic-mount proof is in the later run listed above. Raw operator logs and private backups are not published here. No credentials, tokens, or account-store contents are needed to reproduce the lessons.

## Historical remote IPMI — warm restore, 2026-09-10

A matched RAM and full-disk checkpoint passed three authenticated IPMI reads after an independent restore. The normal managed entry restored a second instance and reached READY in 94 seconds, with authenticated IPMI stable for 68 seconds. These are historical results, not current TAP acceptance; the commands below document that earlier run.

    cd ~/src/oob/zbmc
    sudo ./tools/zbmc lenovo-xcc start --warm --no-web
    sudo ./tools/zbmc lenovo-xcc ipmi mc info
    sudo ./tools/zbmc lenovo-xcc ipmi chassis status

Debby deployment: 10.250.0.45, standard UDP/623; private zbmc.conf supplies ZBMC_LENOVO_DIR and ZBMC_LENOVO_PASSWORD. USERID uses a changed password, not the factory password. Checkpoint files are private and are not distributed by build.sh. The preserved original and validation VMs remain paused on separate addresses/ports.

Restore requires the matched ckpt/state.gz and ckpt/emmc.qcow2, recorded boot artifacts, and exact QEMU SHA-256 0239888e57aeb1f73508f90eddd042f295988a275145a9717b0878cda041da69. ckpt/manifest.json records hashes. Native authentication and account/channel permissions remain enforced. Snapshot restore discards changes made after capture; provisioned settings are stored in the captured state.

Observed warm HTTPS root returns 200, but web-login correctness is not part of this IPMI acceptance. The cold-only observations below are historical, not current remote-IPMI readiness claims.

Verified

HTTPS 200

Vendor page identifies as XCC Web Server and Lenovo XClarity Controller 2.

Cold only

~46 minutes

The default contract reached READY on Debby in 46m06s, including the 60-second hold.

Verified

Serial root shell

The host-local console socket provides an emulator-only diagnostic shell; network SSH remains disabled.

## What the runtime changes

The kernel and signed rootfs are preserved. The built-in initramfs adds a runtime observer and replaces `vpdoctor` with a sleeping process because the physical watchdog/platform contract is unavailable. The AST2600 watchdog remains modeled, but QEMU ignores its reset action: under slower TCG execution it expires before XCC finishes starting services. The SRAM image selects Newyork-pass1 but is reconstructed from preserved platform assets; it is not a physical SRAM capture.

Lenovo's DHCP hook receives QEMU's lease but its `avctifconfig` control path does not install the accepted address in Linux. The emulator-only getty hook waits for Lenovo's own DHCP completion marker, then installs QEMU user networking's fixed `10.0.2.15/24` address and `10.0.2.2` default route. Health probing waits for both this network marker and the vendor's Web-Available marker.

## Run

    ./tools/zbmc lenovo-xcc build
    sudo ./tools/zbmc lenovo-xcc start
    ./tools/zbmc lenovo-xcc console
    ./tools/zbmc lenovo-xcc web
    ./tools/zbmc lenovo-xcc status

## Pinned inputs

- Preserved zImage plus a deterministic block-spliced serial-shell derivative
- Lenovo DTB, reconstructed SRAM, and PTABLES
- Compressed 7 GiB initialized eMMC image
- QEMU 11 FPGA/eMMC GP0 patch with bounded tracing

## Diagnostic console

Lenovo’s normal `lcw_login` requires a response signed by a vendor debug key that is not present in the firmware. The derived kernel changes only the built-in initramfs: before normal `switch_root`, it bind-mounts an emulator-only getty launcher over the serial login script. The original kernel, eMMC, root filesystem, and appended DTBs remain unchanged. Access is limited to the host Unix socket exposed by `zbmc console`.

## Authenticated remote IPMI

Verified on 2026-09-09 with both standard ipmitool and zipmi: repeated controller information and chassis status reads succeed using cipher suite 17. Account role and IPMI channel privilege are separate: the native Administrator role did not grant channel access until standard local `ipmitool user priv 2 4 1` set channel 1, user 2 to ADMINISTRATOR.

Provision through supported management interfaces: change the mandatory factory password, enable IPMI for USERID and globally with native users/portcontrol, then verify the channel privilege. Preserve the provisioned disk: normal runtime writes use a temporary overlay. Factory image builds do not contain this account change. A saved provisioned disk is under managed cold-boot verification. The launcher uses fdtget/fdtput from device-tree-compiler to derive a separate kernel-runtime.zImage: only appended device-tree boot arguments change, adding the native 1800-second Gunicorn startup timeout. This firmware ignores the external QEMU -append value.

    # In private, mode-0600 zbmc.conf:
    ZBMC_LENOVO_PASSWORD='your-provisioned-password'

    ./tools/zbmc lenovo-xcc ipmi mc info
    ./tools/zbmc lenovo-xcc ipmi chassis status

The command and readiness paths use the same password-authenticated ipmitool call, with the password passed through its environment. IPMI readiness requires a successful controller read. SSH and Redfish are outside the readiness contract; successful IPMI does not establish Web login health.

Large artifacts are SHA-256 pinned at git.trouble.org. Firmware remains subject to its vendor license.
