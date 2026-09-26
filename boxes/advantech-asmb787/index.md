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

The [firmware-bound command reference](../../../zipmi/docs/advantech_ASMB787-command-reference.html)
catalogs all 187 declared remote vendor rows with opcode, handler, module, privilege, request-length
constraint, interface mask, activation evidence, and explicit payload unknowns. The corresponding
zipmi native module exposes all 187 through named raw dispatch. Full payload semantics and structured
request/response codecs remain incomplete where the available binaries do not establish them.

The 187 rows comprise 85 core commands from `libipmimsghndlr.so.13.22.0`, 95 plugin commands from 37
`libipmiamioem*.so` modules, and seven platform commands from `libipmipdkcmds.so.6.0.0`. The 85 core
and seven platform rows are statically registered. Of the 95 plugin rows, 85 are feature-enabled or
eligible, but runtime map population was not directly observed; ten are feature-absent and remain
unproved: Media commands `0xca`, `0xcb`, `0xd7`, `0xd8`, `0xd9`, and `0xdc`; PLDM commands `0xd5` and
`0xd6`; and Remote KVM commands `0xc0` and `0xc1`.

The first 180 rows use NetFn `0x32`; the platform library adds five NetFn `0x30` commands and two
NetFn `0x3a` commands. The message-handler binary has SHA-256
`23e5b17be7125d100db9effea1772a57ee8ecd45da0569a5a331b8eb8d627539`.

Three additional NetFn `0x2e` SMM-local records exist in the PDK library, bringing the compiled total
to 190. They remain outside the 187-row remote vendor count until their transport exposure
is proved. The existing material also mixes in client wrappers and optional HPE/Quanta handlers that
this server image does not dispatch, so client-library presence is not evidence of ASMB-787 server
reachability. Do not treat the current material as a safe command catalog, and do not probe setters,
reset, restore, flash, credential, or firmware-update handlers on hardware that matters.
