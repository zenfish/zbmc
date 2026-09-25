# zbmc Advantech ASMB-787

## Extracting the filesystem

`build.sh` leaves the FMH-carved inputs in `work/advantech-asmb787/unpacked`. Extract the patched root filesystem into the requested tree:

    mkdir -p work/advantech-asmb787/fs
    RSQ=$(find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -type f -printf '%s %p\n' | sort -nr | head -1 | cut -d' ' -f2-)
    unsquashfs -d work/advantech-asmb787/fs/rootfs "$RSQ"
    find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -print

Extract every embedded filesystem from the packed NOR as well:

    mkdir -p work/advantech-asmb787/fs/{rootfs,www,conf,bkupconf,dre}
    mapfile -t sqsh < <(find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -type f -printf '%s %p\n' | sort -nr | cut -d' ' -f2-)
    unsquashfs -d work/advantech-asmb787/fs/rootfs "${sqsh[0]}"
    unsquashfs -d work/advantech-asmb787/fs/www "${sqsh[1]}"
    for spec in "0xd0000 0x1f0000 conf" "0x2d0000 0x1f0000 bkupconf" "0x2e10000 0 dre"; do
      set -- $spec; args=(if=firmware/encrypted_ASMB-787_20220912.ima_enc of="work/advantech-asmb787/fs/$3.jffs2" bs=1 skip=$(( $1 )) status=none)
      [ "$2" = 0 ] || args+=(count=$(( $2 )))
      dd "${args[@]}"
      jefferson -f -d "work/advantech-asmb787/fs/$3" "work/advantech-asmb787/fs/$3.jffs2"
    done

The rootfs artifact is the QEMU-patched copy; the other trees come from the original firmware.

## Service acceptance

Debby cold run `20260925T214443Z-ce946490-918d-40af-83be-b2957f51c753` reached
`READY [6/6 - ICMP, SSH, IPMI, Redfish, Web-UI, Console]` in 672 seconds. The acceptance probes use
authenticated operations rather than open-port checks: SSH executes an exact marker, IPMI runs
`mc info`, Redfish reads a protected resource, and the Web UI creates a session, reads administrator
dashboard data, and logs out. The serial console also executed a marked command as UID 0.

## OEM IPMI documentation coverage

**No: full command semantics are not yet documented.** A static audit of this exact firmware recovered
186 vendor dispatch entries: 85 built into `libipmimsghndlr.so.13.22.0`, 94 from 37 loadable
`libipmiamioem*.so` modules, and seven platform entries from `libipmipdkcmds.so.6.0.0`. The first 179
are unique NetFn `0x32` commands; the platform library adds five NetFn `0x30` commands and two NetFn
`0x3a` commands. The message-handler binary has SHA-256
`23e5b17be7125d100db9effea1772a57ee8ecd45da0569a5a331b8eb8d627539`.

The dispatch tables establish the opcode, minimum privilege, fixed or variable request length, module,
and handler name. Existing YAFU research documents the firmware-update block and selected
security-sensitive handlers, but only 107 of the 186 remotely dispatched NetFn/command pairs are
mapped anywhere in the current corpus; 79 are unmapped, and only about ten have focused request and
response framing analysis. Most mapped entries still lack selector definitions, full field layouts,
completion-code behavior, side effects, channel restrictions, or runtime feature gates.

Three additional NetFn `0x2e` SMM-local records exist in the PDK library, bringing the compiled total
to 189. They remain outside the 186-command remotely dispatched count until their transport exposure
is proved. The existing material also mixes in client wrappers and optional HPE/Quanta handlers that
this server image does not dispatch, so client-library presence is not evidence of ASMB-787 server
reachability. Do not treat the current material as a safe command catalog, and do not probe setters,
reset, restore, flash, credential, or firmware-update handlers on hardware that matters.
