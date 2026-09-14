<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=4eef3b8116b4f12ef8aa26f48d39ead1e85f4e2d92a05ebf8fa4ad8a97df042c body-sha256=582682a21fc7c5519c2443b1cee9d697df945c13dda37a6808d4378a73305ee3 -->

zbmc / preserved firmware

# Lenovo XClarity Controller

A cold-boot runtime for Lenovo XCC 6.92 on an AST2600 model with an experimental FPGA transport and eMMC GP0 implementation.

13 September status: [normal managed warm startup reached six-service READY in 3m37s](#managed-warm-20260913), but subsequent IPMI checks remain intermittent. Debby's private default now selects the matched TAP runtime. [Cold verification failed its one-hour startup window](#13-september-cold-verification-failed). Full reliable recovery is not complete.

## 14 September: IPMI probe mystery resolved

The intermittent IPMI failure was a zBMC probe-scheduling artifact, not persistent Lenovo credential loss. Packet evidence showed failed RMCP+ handshakes returning RAKP4 status `0x02` after the host-side client stalled between RAKP2 and RAKP3. Adjacent serialized IPMI checks passed with the same account and password, so the evidence pointed at probe contention/timing rather than firmware state.

Lenovo now opts into serialized service probes with a shared probe-bundle lock. The runlib serial path executes each service probe in a subshell so flock file descriptors opened by SSH/IPMI probes are closed before Redfish/Web probes run. Without that subshell scoping, a later curl inherited stale SSH/IPMI lock FDs and manual status could report false probe-busy failures. Lenovo SSH health is also bounded through the existing `zbmc_ssh` helper under `timeout`, preserving operator SSH behavior.

Final proof used one Lenovo QEMU, runtime `work/lenovo-xcc-warm/tap-power-recovery-20260914-TOKusQ`, run `20260914T175818Z-ef603b16-c8cf-455d-ae74-a5ba9f2f128e`. Managed warm startup reached `READY [6/6]` in 189 seconds with all required services stable for 92 seconds. Three manual `zbmc lenovo-xcc -v` checks passed `READY [6/6]` while the health watcher remained live. The final health history contained zero degraded, probe-busy, or authenticated-controller-read-failed samples.

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

## 13 September: disk-capture failure and recovery

The previous claim that a bare conversion of QEMU's temporary disk was a complete crash-consistent backup was incorrect. The converted qcow2 passed its container check, but unchanged backing data was absent: its 157,007,872-byte root filesystem read entirely as zeros, while the changed account file retained data. A boot from that copy failed with “Resize inode not valid”.

Filesystem salvage alone was insufficient: it moved missing directory entries into lost+found but could not restore absent file bytes. Those experiments were confined to disposable copies; original evidence was preserved.

Rejoining a fresh copy to the exact original seed restored the directory structure. Standard journal recovery then passed for UD0 and GP0, followed by full read-only filesystem checks. The recovered root filesystem and detached signature compared byte-for-byte with the intact seed. The manually salvaged copy was not used.

The capture helper now supplies the backing node explicitly. A disposable-image check verifies that the resulting standalone image contains both an unchanged pattern from the base and a changed pattern from the overlay. Container validity alone is not content completeness.

Reconstructed launch image SHA-256: `84a54c008300dfc2c9b63071025b64a75d501e9a6a7cb1289ee3a8c59a9b6ac4`. Boot under test: `20260913T162526Z-369ff65e-cf55-402e-be75-881acc92a354`. Authentication and full-service acceptance remain unverified.

## 13 September: native services recovered on TAP

The recovery involved two kinds of fixes: restoring native services, and correcting tests that misreported working services.

| Area | What changed |
|----|----|
| Disk | Reconstructed the recovery disk with its missing backing-image data. Filesystem checks and comparisons of the vendor rootfs and signature passed. |
| SSH startup | Created the missing `/var/run/sshd` directory. Changed the running listener from nice `5` to `-10`; subsequent authenticated CLI sessions worked. The priority effect was not isolated from tracing overhead. |
| SSH validation | Replaced `echo up`, which is invalid in Lenovo's management CLI, with supported `help`. Allowed a bounded 40-second probe. |
| IPMI | Enabled the global service, added account IPMI access by re-entering the existing password, then changed channel-1/user-2 privilege from `NO ACCESS` to `ADMINISTRATOR`. All through native interfaces, without password rotation. |
| Web validation | Replaced the old SLiRP-era console-marker requirement with actual login, authenticated session-identity verification, and logout. |
| Launcher | Fixed the background helper losing private configuration and consequently trying the factory password. |
| Status | Added `--all-services` to test all six services without changing the old run's exclusions or timeout history. |

Recovery synopsis

Authenticated Redfish reads were already working once the recovered services settled. TAP networking needed no further change in this pass. No replacement management service or new authentication bypass was introduced in this service-recovery pass.

**Proof:** two complete zBMC `READY [6/6]` results, more than two minutes apart, plus passing regression and runtime tests. **Follow-up:** the matched warm checkpoint was subsequently verified below; cold-boot reproduction and deployment as the default warm checkpoint remain outstanding.

Verified live in run `20260913T162526Z-369ff65e-cf55-402e-be75-881acc92a354`: zBMC reports all six services working. SSH authenticates and executes the native Lenovo CLI's help command; IPMI performs an authenticated controller read using cipher 17; Redfish reads a protected account; Web logs in, reads the matching session identity, and logs out. ICMP and the interactive serial console also pass.

    sudo tools/zbmc lenovo-xcc status -v --all-services
    Health    : READY [6/6 - ICMP, SSH, IPMI, Redfish, Web-UI, Console]

The explicit `--all-services` status option probes all six services regardless of the old run's exclusions. It does not edit the run manifest or erase its one-hour startup timeout. This live recovery is not proof of a reproducible cold boot or a tested warm checkpoint.

### What failed, and what fixed it

- The background Web helper did not load private configuration before the box descriptor. It could use the factory password. Both subprocess paths now load the private configuration; a non-exported-setting regression covers the helper.
- SSH first timed out before its banner. With guest load around 34 on two CPUs, a bounded trace showed slow but progressing process startup. After detaching the tracer and changing the existing SSH listener from nice 5 to -10, authenticated CLI commands passed. The scheduling effect was not isolated from tracing overhead. This scheduling change is live-only; cold-start reproduction remains unverified.
- The generic SSH validator sent `echo up`, which the native Lenovo CLI rejects. A box-specific health hook now executes supported `help`, requiring successful exit and the expected command listing. The background helper uses the same check. Lenovo's bounded probe allows 40 seconds.
- The Web marker was an old SLiRP startup prerequisite, not functional proof. Its vendor producer only waited for an nginx-ready file. The replacement follows the shipped Web client's nonce, login, session-info, and logout sequence.
- The first diagnostic Web client incorrectly put a JSON content-type header on empty GET requests: login succeeded, but session-info and logout returned HTTP400. Matching the shipped client—no content-type on these GETs—produced successful identity verification and logout. Tokens and passwords are not logged.
- IPMI required three independent settings: global protocol enablement, account interface permission, and channel privilege. Global enablement through authenticated Redfish succeeded. AccountTypes PATCH returned PasswordChangeRequired despite account GET reporting false.
- The documented native `users -ai` command required re-entry of the existing password to add IPMI access. That operation succeeded without rotating the password. Readback showed WebUI, Redfish, ManagerConsole, and IPMI retained together.
- IPMI still failed because channel1/user2 reported NO ACCESS. Standard local `ipmitool user priv 2 4 1` changed it to ADMINISTRATOR; readback and the host's authenticated controller read then passed. No authentication bypass or replacement IPMI service was used.

Evidence remains in the named run: `full-service-validation-20260913.log`, `service-state-20260913.log`, `ssh-priority-check-20260913.log`, `web-session-check2-20260913.log`, and redacted `ipmi-cli-provision-20260913.log`. The serial log records channel readback and original scheduling state. Targeted SSH/Web regressions, the status suite, and Lenovo runtime tests pass. An initial status-suite run failed its process-cleanup check; its reruns passed.

## 13 September: isolated TAP warm recovery verified

The recovered VM was flushed, then paused while QEMU performed a native full-disk backup and exported matching RAM/device migration state. Successful backup completion was checked before migration. The original VM resumed afterwards. The new private checkpoint passed qcow2 and gzip integrity checks; its disk and state hashes remained unchanged through the restore test. The previous checkpoint was not overwritten.

A separate instance restored the checkpoint using the identical QEMU executable and captured runtime-kernel bytes. The existing warm launcher expects `kernel-shell.zImage`, so the isolated test supplied the captured `kernel-runtime.zImage` bytes under that filename. Separate runtime files, sockets, and a PID file prevented accidental checks against the original.

The copy used an isolated Linux network namespace containing only loopback and TAP, with no external link. Its copied guest IP and MAC therefore could not collide with the original. Only one Lenovo VM ran during validation: the original remained paused and recoverable, then resumed when testing ended. The test copy remains paused and preserved.

- QEMU restore completed in **7.4 seconds**. This is state-load time, not full-service ready time.
- The serial shell executed a fresh console-liveness command.
- The first early zBMC check passed five services but failed IPMI. That failure is retained in the evidence.
- A bounded retry succeeded without any post-restore account or service configuration changes. The exact cause of the transient IPMI failure and precise ready time were not established.
- Subsequent full zBMC checks at **13:07:51 and 13:09:10 PDT** both reported `READY [6/6]`: ICMP, authenticated native SSH CLI, authenticated IPMI, protected Redfish, native Web login/session/logout, and Console.

The experiment used the existing low-level warm launcher, followed by `zbmc lenovo-xcc status -v --all-services` inside the isolated namespace. Status correctly labeled this test process unmanaged; a managed startup-time result is not claimed. The normal `start --warm` path still points to the older pre-TAP checkpoint and remains blocked. This experiment proves the newly captured, matched checkpoint—not arbitrary checkpoint compatibility or cold-boot persistence.

Checkpoint: `work/lenovo-xcc-warm/tap-checkpoint-20260913T200242Z`. Test evidence: `work/lenovo-xcc-warm/tap-warm-test-20260913T200242Z`, including initial `validation-1.txt`, both `settled-validation-*.txt`, `console-liveness.txt`, and `accepted.json`. Checkpoint contents are private because memory and disk can contain credentials.

**Disk SHA-256:** `8752a48d26bb187030af05881ec6440d3334d2e2bcd881318e605171349c8e46`

**Compressed migration-state SHA-256:** `85f70b2a80c5b882a4252e53f49300f8a1b82a87d92522a56fe3111cf09c0815`

## 13 September: cold verification failed

A fresh QEMU process booted the preserved, provisioned disk without saved RAM or incoming migration, on an isolated guest-owned TAP network. Filesystem and rootfs mount checks passed. This tests the provisioned disk, not automatic provisioning of the factory seed.

The first cold attempt identified a missing native SSH prerequisite: `/var/run/sshd`. An experimental repair in the deployed working tree adds directory creation with mode0755 to both replacement SSH launch paths and propagates mkdir/chmod failures. The regression fails on the previous source and passes on the repaired source. Two independent kernel builds were byte-identical, and the Lenovo runtime tests passed. This uncommitted repair remains under validation; it is not a published accepted build or a cold-service success claim.

**The repaired cold attempt still failed.** Native SSH launch was observed by27m46s, without the previous directory error, but no authenticated management service passed during the one-hour test. The last completed zBMC observation, at59m42s, passed ICMP and Console and failed SSH, IPMI, Redfish, and Web UI. One earlier ICMP sample also failed, then recovered. The candidate was paused and preserved after the deadline; the original instance was resumed.

SSH remained unreachable despite a live native daemon. The HTTP front end returned HTTP 502 during a diagnostic service-root request; authenticated Web probes later timed out. Guest CPU totals showed heavy high-priority platform activity and little CPU time for SSH at nice 5. Scheduling starvation is a hypothesis, not an isolated cause. No live service-priority, account, or password changes were applied during this cold attempt.

**Recovery verified:** the original instance passed all six zBMC checks again at 15:29:37 and 15:31:14 PDT after resume. Its historical startup-watch timeout remains preserved; these are fresh live-service results, not rewritten startup history.

Evidence on Debby: `work/lenovo-xcc-warm/tap-cold-sshd-test-20260913T2128` (console, exact QEMU argv, network hook, and validation results) and `work/lenovo-cold-sshd-20260913T2128` (controller log, build/test evidence, and original-instance revalidation). The captured checkpoint was protected by QEMU `snapshot=on`. Acceptance requires two six-service zBMC passes at least60seconds apart plus an executed console command; this run did not meet it.

## 13 September: managed warm startup passed; IPMI remains intermittent

After Debby rebooted, the preserved matched TAP checkpoint restored through normal `zbmc lenovo-xcc start --warm`. All six services passed at 84 seconds. IPMI then failed, recovered, and all required services passed a 67-second stability window; startup reached READY in 3m37s. A subsequent status passed 6/6, but the next default status at 16:42 PDT was DEGRADED 5/6 because IPMI failed again. This is not a claim of sustained IPMI reliability or successful cold startup.

Guard commit `87a1628` verifies checkpoint disk, RAM, runtime kernel, board data, source network and QEMU hashes before launch, requires destination TAP, and preserves old launcher logs/PID records on rejection. Default READY now requires SSH, IPMI, Redfish, Web UI and console, with shared ICMP validation. Focused guard, Lenovo runtime and status-spacing regressions passed.

Debby's private configuration now selects `work/lenovo-xcc-warm/tap-managed-20260913-i5gsSN`. Its previous configuration is preserved there as `zbmc.conf.before-managed`. Checkpoint disk/RAM and configuration are private and must not be published. Do not run build against this recovered runtime: build artifacts are not a replacement for its provisioned state.

Evidence: runtime `managed-start.log` and run `runs/20260913T233717Z-e2817348-3b92-477d-85de-40d7e397cc73`. Earlier statements above about an unreplaced default checkpoint describe the preceding experiments and are superseded by this managed restore. Cold service readiness remains unresolved.
