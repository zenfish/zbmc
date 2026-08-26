#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
source_file="$repo/boxes/idrac10/shm-shim.c"
build_dir="$(mktemp -d)"
trap 'rm -r "$build_dir"' EXIT
shim="$build_dir/shm-shim.so"

wrapper="$(sed -n '/RequestHandleTableSearch(/,/^}/p' "$source_file")"
[ -n "$wrapper" ] || { echo "RequestHandleTableSearch wrapper missing" >&2; exit 1; }

[ "$(grep -Ec 'case 0x(0001|0601):' <<<"$wrapper")" -eq 2 ]
[ "$(grep -Ec 'case 0x[[:xdigit:]]+:' <<<"$wrapper")" -eq 2 ]
! grep -Eq 'out->(selector|required_priv|request_len|reserved)[[:space:]]*=' <<<"$wrapper"
! grep -q 'shmget ENOENT (no IPC_CREAT, not found)' "$source_file"
grep -q '#define UNKNOWN_SDC_SIZE 54340' "$source_file"
grep -q 'n->size  = size > 0 ? size : UNKNOWN_SDC_SIZE;' "$source_file"
grep -q '#define IPMI_CMD_TABLE_GOT_OFFSET      0x1175e0' "$source_file"
grep -q '#define IPMI_CMD_TABLE_SIZE_GOT_OFFSET 0x117610' "$source_file"
grep -q 'selector != 0x0601' "$source_file"
grep -q 'patch_ipmi_command_table(mfd);' "$source_file"

real_line="$(grep -n 'found = real_fn(message, out);' <<<"$wrapper" | cut -d: -f1)"
replace_line="$(grep -n 'out->handler =' <<<"$wrapper" | head -1 | cut -d: -f1)"
[ "$real_line" -lt "$replace_line" ]

zig cc -shared -fPIC -o "$shim" "$source_file" \
    -target aarch64-linux-gnu -ldl -lpthread -O2

/usr/bin/objdump -t "$shim" | grep -Eq '[[:space:]]RequestHandleTableSearch$'

disassembly="$(/usr/bin/objdump -d "$shim")"
for symbol in RequestHandleTableSearch CmdGetDeviceID shim_get_chassis_status; do
    awk -v symbol="$symbol" '
        $0 ~ "<" symbol ">:" {
            getline
            if ($0 ~ /(bti[[:space:]]+c|paciasp)/) found = 1
        }
        END { exit(found ? 0 : 1) }
    ' <<<"$disassembly" || {
        echo "$symbol lacks an AArch64 indirect-call landing pad" >&2
        exit 1
    }
done

echo "idrac10 dispatch shim ABI, allowlist, build, and BTI: PASS"
