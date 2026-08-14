# iDRAC9 AVCT Write Primitives — Userspace-Driving ABI (Ghidra RE)

Reverse-engineered from the iDRAC9 firmware rootfs ARM kernel modules at
`/Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs/lib/modules/5.4.80.idrac/kernel/drivers/dell/`:

| Module | Size | Author / desc | Interface |
|--------|------|---------------|-----------|
| `swd-core.ko` | 36772 | Pablo Arias <pablo.arias@dell.com> — "ARM SWD support for Infineon and Cypress ARM devices v.0.1.0" | **sysfs** `/sys/class/swd/swdt%d/*` |
| `swd-gpio.ko` | 5724  | "SWD Linux GPIO support" (depends swd-core) | registers one port "nuvoton" |
| `vdm.ko`      | 34856 | "AESS VDM Driver", node `nuvoton,npcm750-vdm` | **char dev** `/dev/vdm` |

All four `.ko` are ELF32 ARM EABI5, **not stripped**, GPL — full symbol tables + strings present.
All loaded and decompiled cleanly in Ghidra (headless, `DecompToFile.java`). No objdump fallback needed
(objdump used only to confirm `_IOC` constants and the `_LC30="vdm"` device-node string).

Tooling note: `analyzeHeadless` requires the project dir to **pre-exist** (`mkdir` it; do not `rm -rf` it),
and `-scriptPath` is *additive* to `~/ghidra_scripts` — a clean temp scriptdir avoids the OSGi-bundle gotcha.

Source files: decompiled C at `/tmp/smm-decompiled/{swd-core,swd-gpio,vdm}.ko.c`.

⚠ **Privilege model (both drivers):** neither module calls `capable()`/`CAP_SYS_*` anywhere
(no such import in either symbol table). The *only* access gate is filesystem permissions on
`/dev/vdm` and `/sys/class/swd/swdt*` — root by default. Any process that can open those nodes
has the full primitive. No length/route/BDF sanity gate beyond what is noted per-call below.

---

## 1. swd-core.ko / swd-gpio.ko — neighbor-MCU SWD reflasher

### 1.1 Interface type: **sysfs**, not a char dev / ioctl

`swd-core` creates a class `swd` and, per registered port, a device `swdt%d`
(`device_create(swd_class,…,"swdt%d", id)` @ `swd_device_register` `0x10238`). It exposes
**sysfs attributes only** — there is no `/dev/swdtN` char node and no `file_operations`/ioctl.

Attribute table (`swd_attrs` @ `.data:0x5c`, plus binary attr `bin_attr_flash_data` @ `0x30`):

| sysfs file (under `/sys/class/swd/swdt0/`) | mode | handler @addr | action |
|---|---|---|---|
| `swdck_gpio` | rw | `swd_store/show_swdck_gpio` `0x504/0x758` | set/get SWD clock GPIO number → `info+0x8` |
| `swdd_gpio`  | rw | `swd_store/show_swdd_gpio` `0x490/0x73c`  | set/get SWD data  GPIO number → `info+0xa` |
| `access`     | rw | `access_store` `0x5b4` / `access_show` `0x7d8` | write `1`→connect SWD line (calls ops `access` fn = `gpio_swd_access`); `0`→release. Sets flags bit0. **Errors `-EINVAL` if both gpios not yet set.** |
| `flash_access` | rw | `swd_store_flash_access` `0x8f0` / `swd_show_flash_access` `0x7b0` | write `1`→`DeviceAcquire()` (enter SWD programming/acquire); `0`→leave. Sets flags bit1. **Requires bit0 (`access`) first** else `-ENXIO`. |
| `flash_erase` | wo | `swd_store_flash_erase` `0x874` | `EraseAllFlash()`. **Requires flags&3==3** (access+flash_access) else `-ENXIO`. |
| `reset`      | wo | `swd_store_reset` `0xad4` | `ResetMCU()` (toggles target XRES via SWD). Requires bit0. |
| `flash_data` | rw (bin) | write `swd_write_flash_data` `0x3c` / read `swd_read_flash_data` `0x12c` | **program / read flash bytes** at file offset → `ProgramFlashRow()` / `ReadFlashRow()`. Requires flags&3==3. |
| `flash_size` / `flash_block_size` / `flash_blocks_num` | ro | `0x7c4/0x7e8/0x804` | geometry (block size 0x80=128 B, set @register) |
| `dev_id`     | ro | `swd_show_dev_id` `0x9fc` | **probe / IDCODE** → `GetDeviceID()` prints `0x%lx`. Requires bit0. |
| `name`       | ro | `swd_show_name` `0x820` | port name string |

`swddev` struct (allocated in `swd_device_register`, stored as `dev_get_drvdata` at `dev+0x40`):
`+0x00` byte flags (bit0=access, bit1=flash_access), `+0x04` idr id, `+0x08` name,
`+0x10` 0x20-byte ops template (fn ptrs swdck_set/swdd_set/swdd_get/swdd_dir + `access`),
`+0x2c` ptr→`swd_info` {`+0`=blocksize, `+2`=blocks_num, `+6`=acquire-fn, `+8`=swdck gpio,
`+0xa`=swdd gpio, `+0xc`=line-reset/access-fn}, `+0x30` mutex, `+0x50` `struct device*`.

### 1.2 Port selection / GPIO binding (swd-gpio.ko)

`swd-gpio` `init_module` (`0x1016c`) registers exactly **one** port:
`gpio_swd_dev = swd_device_register("nuvoton", &gpio_swd_ops, …)` → creates `swdt0`.
**The GPIO pins are not hardcoded** — `info+0x8/+0xa` start at 0; the operator must write the
pin numbers via `swdck_gpio`/`swdd_gpio` before `access=1` (otherwise `access_store` returns
`-EINVAL` "gpios need to be defined"). `gpio_swd_access(dev,1)` (`0x100d8`) then
`gpio_request(swdck,"swd clock")`+output-high and `gpio_request(swdd,"swd data")`+output-high.
Bit-bang ops: `gpio_swd_swdck_set`/`swdd_set`/`swdd_get`/`swdd_dir` via `gpiod_*_raw`.

### 1.3 Userspace reflash recipe (neighbor MCU)

```sh
cd /sys/class/swd/swdt0
echo <SWDCK_pin> > swdck_gpio      # bind clock GPIO (NPCM GPIO number)
echo <SWDIO_pin> > swdd_gpio       # bind data  GPIO
echo 1 > access                    # SWD line-reset + connect  (flags bit0)
cat   dev_id                       # OPTIONAL probe: prints IDCODE/DPIDR e.g. 0x2ba01477
echo 1 > flash_access              # DeviceAcquire — enter programming mode (flags bit1)
echo 1 > flash_erase               # EraseAllFlash
dd if=newfw.bin of=flash_data bs=128   # ProgramFlashRow per block, offset = file pos
dd if=flash_data of=verify.bin bs=128  # OPTIONAL read-back  (ReadFlashRow)
echo 0 > flash_access
echo 1 > reset                     # ResetMCU → target runs new firmware
```

Target families: `DeviceAcquire`/`DeviceAcquireInfineon` (`0x2cd0`) and
`DeviceAcquireRenesas` (`0x1b08`); Infineon/Cypress PSoC SROM program path
(`ProgramFlashInfineon` `0x31d8`, `EraseAllFlashInfineon` `0x30f0`, `GetChipProtectionVal`,
`SetIMO48MHz`, `PollSromStatus`). So both Infineon and Renesas neighbor MCUs are supported.

### 1.4 ⚠ Arbitrary target-memory R/W (DAP / AHB-AP) — present but NOT exposed

The module **does** implement full ARM ADIv5 SWD-DP + MEM-AP primitives:

* `Read_IO(ap,addr,*out)` `0xf78` — writes MEM-AP **TAR=addr** (SWD hdr `0x8b`) then reads
  **DRW** (`0x9f`) ⇒ **arbitrary 32-bit read of any target address** (live SRAM, peripheral regs, not just flash).
* `Write_IO(ap,addr,data)` `0x1004` — TAR=addr (`0x8b`) then DRW=data (`0xbb`) ⇒ **arbitrary 32-bit write**.
* `Read_IO_Size`/`Write_IO_Size` `0x11c0/0x1054` — byte/half/word sized via CSW (`0xa3`).
* `Read_DAP`/`Write_DAP` `0xf10/0xf3c`, `GetDeviceID` `0xb70` = line-reset + read DPIDR (`0xa5`).

**These are internal kernel functions only.** They are *not* reachable through the sysfs surface
(no attr maps to a user-supplied address), and only `swd_device_register`/`_unregister` are in
`__ksymtab` (EXPORT_SYMBOL) — `Read_IO`/`Write_IO` are not even exported to sibling modules.
⇒ From a root shell the SWD interface gives you **flash erase/program/read-back, IDCODE probe,
and target reset** — *not* a generic peek/poke of the neighbor MCU's live memory. To get arbitrary
AHB-AP R/W you must add a kernel hook (insmod shim calling `Read_IO`/`Write_IO`, or patch in a sysfs
attr); the building blocks are fully present and ready at the addresses above.

---

## 2. vdm.ko — PCIe Vendor-Defined-Message injector

### 2.1 Interface: char dev `/dev/vdm`

`init_module` (`0x11888`): `platform_driver_register` (matches DT `nuvoton,npcm750-vdm`),
`alloc_chrdev_region(&vdm_dev,0,1,"vdm")` (or fixed major via module param `majornum`),
`cdev_add(vdm_cdev,…)`, `class_create("vdm")`, `device_create(...,"vdm")` ⇒ **`/dev/vdm`, minor 0,
class `/sys/class/vdm/vdm`**. `ioremap`s the AESS VDM TX/RX register blocks (`vdm_virt_addr`,
`vdma_virt_addr`) + GCR `0xf0800000`, allocates a 0x4000 DMA RX buffer, requests the VDMA IRQ
(`vdma_isr`). `fops = vdm_fops` @ `.data:0x260` → `open=vdm_open, release=vdm_release,
read=vdm_read, write=vdm_write, unlocked_ioctl=vdm_ioctl`.

Per-open **instance** struct (`kmem_cache_alloc` in `vdm_open` `0x101ec`, stored at `filp+0xb4`):
`+0x08` ushort **mBDF** (target PCIe Bus/Dev/Func), `+0x0c` RX ring base, `+0x10` byte "BDF-set"
flag, `+0x14` RX buf size (dflt 0x2000), `+0x18` TX buf ptr, `+0x1c` TX buf size (dflt 0x400),
`+0x20` circular-buffer hdr (`cbInit`), `+0x3c` error/status flags, `+0x40` byte counter,
`+0x44` wait-queue. Each `open()` is an independent RX subscriber keyed by its mBDF.

### 2.2 ioctl ABI — `vdm_ioctl` @ `0x11294`

Magic type **`0xe8`**, arg size 4 (`int`). Decoded `_IOC(dir,type,nr,size)`:

| cmd value | macro | nr | action |
|---|---|---|---|
| `0x4004e801` | `_IOW(0xe8,1,4)` | 1 | **SET_BDF** — copies 3 bytes from arg, packs `mBDF = bus<<8 \| (dev&0x1f)<<3 \| (func&7)`; sets BDF-set flag(+0x10). *Required before read/write.* |
| `0x4004e802` | `_IOW(0xe8,2,4)` | 2 | SET_TX_BUFSIZE — `kfree`+`kmalloc(arg)` TX buffer(+0x18), size→+0x1c |
| `0x4004e803` | `_IOW(0xe8,3,4)` | 3 | SET_RX_BUFSIZE — realloc RX buffer(+0xc), `cbInit` ring |
| `0x4004e804` | `_IOW(0xe8,4,4)` | 4 | STOP_TX — `disable_TX = (arg!=0)` |
| `0x4004e805` | `_IOW(0xe8,5,4)` | 5 | **RX enable/disable** — arg `0`→`vdm_enable_rx()`, non-0→`vdm_disable_rx()` |
| `0x8004e806` | `_IOR(0xe8,6,4)` | 6 | GET_BDF — returns 3 bytes {bus,dev,func} |
| `0x4004e807` | `_IOW(0xe8,7,4)` | 7 | RESET — `vdm_reset()` |
| `0x4004e808` | `_IOW(0xe8,8,4)` | 8 | SET_TIMEOUT — `vdm_set_timeout(arg)` |
| `0x4004e809` | `_IOW(0xe8,9,4)` | 9 | REINIT — close+`vdm_reset()`+open |
| `0x4004e80a` | `_IOW(0xe8,0xa,4)` | 10 | enable reset-detect poll |
| `0x4004e80b` | `_IOW(0xe8,0xb,4)` | 11 | GET reset/status flags (copies +0x3c to user; `8`=in-reset) |
| `0x4004e80c` | `_IOW(0xe8,0xc,4)` | 12 | CLEAR_ERRORS — bit0→`vdm_clear_errors`, bit2→re-init RX ring; `flags &= ~arg` |
| `0x4004e80d` | `_IOW(0xe8,0xd,4)` | 13 | DUMP_REGS (queue work) |

(Inputs ≤`0x4004e803` go through a `__kmalloc`; the `coproc_*Domain_Access_Control` blocks around
`arm_copy_to/from_user` are the kernel's uaccess-enable, not a security check.)

### 2.3 Injecting a VDM — `vdm_write` @ `0x10da4`

`write(fd, buf, count)` layout: **`buf[0]` = route_type**, **`buf[1..count-1]` = VDM payload bytes**.
Flow: copy `count-1` payload bytes into the instance TX buffer(+0x18); read `buf[0]` as route_type;
then `vdm_SendMessage(route_type, mBDF, txbuf, count-1)`.

Validation (the *only* checks): `count-1 ≤ TX_bufsize`(+0x1c) else `-EINVAL`; `count ≥ 2` else
`-EINVAL`; BDF-set flag(+0x10) must be set else `-ENXIO`; not in PCIe reset (`vdm_is_in_reset`) else
`-EPIPE`; `disable_TX` clear. **No privilege check, no validation that the target BDF exists or that
the route/payload is well-formed.** route_type is coerced: anything not `0x10`/`0x12` (and not
`0x10`/`0x13`) → forced to `0x13`. Valid route_types:
* **`0x12` = Route-by-ID** → message is targeted at `mBDF` (the BDF is byte-swapped into the VDM header).
* **`0x10` / `0x13`** → route to Root Complex / broadcast (BDF not embedded).

`vdm_SendMessage` @ `0x11e94` builds the message into the AESS TX FIFO (`vdm_virt_addr[3]`):
header word `0xb41a0000 | (byteswap(mBDF) if route 0x12)` — **`0xb41a`** is the embedded
vendor/header tag — then control word with length, then payload in 4-byte words, max **0x74 (116)
bytes per hardware transfer**, looping for longer payloads; polls `vdm_virt_addr[0]` bit0 for done
(100×`nano_delay`, returns `-EPIPE` on timeout). Payload length bounded only by the user-set TX buffer.

### 2.4 Receiving VDMs — `vdm_read` @ `0x1051c`

`read(fd, buf, count)` drains up to `count/4` 32-bit words from the instance RX ring (`cbRead`) into
`buf`, **blocking** on the wait-queue(+0x44) until data arrives or a PCIe reset. Returns bytes read,
or `-ENXIO` (no BDF set), `-EPIPE` (reset), `-ENODATA`(-4)/`-EOVERFLOW`(-11) on ring conditions.
RX must first be armed with ioctl 5 (arg 0). The IRQ tasklet (`vdma_isr`/`receive_packet_func`)
demuxes inbound VDMs to the instance whose `mBDF` matches the sender BDF; unmatched packets go to
`pVDM_Instance_Default` (the instance that did `SET_BDF` with BDF 0). HW/DMA/user-buffer overflow and
PCIe-bus-reset events are logged and surfaced via the status flags(+0x3c).

### 2.5 Userspace inject recipe

```c
#include <sys/ioctl.h>
#define VDM_SET_BDF    _IOW(0xe8,1,int)   /* 0x4004e801 */
#define VDM_SET_TXSIZE _IOW(0xe8,2,int)   /* 0x4004e802 */
#define VDM_RX_ENABLE  _IOW(0xe8,5,int)   /* 0x4004e805 */
int fd = open("/dev/vdm", O_RDWR);
unsigned char bdf[3] = { bus, dev, func };      /* dev 0-31, func 0-7 */
ioctl(fd, VDM_SET_BDF,    bdf);                 /* select target endpoint  */
ioctl(fd, VDM_SET_TXSIZE, (int)4096);           /* (optional) grow TX buf   */
unsigned char msg[1 + N];
msg[0] = 0x12;                                  /* route-by-ID to that BDF  */
memcpy(&msg[1], payload, N);                    /* N VDM payload bytes      */
write(fd, msg, 1 + N);                          /* INJECT                   */
/* to sniff replies: */ ioctl(fd, VDM_RX_ENABLE, 0); read(fd, rxbuf, sizeof rxbuf);
```

---

## Function/address index (for follow-on work)

* **swd-core.ko**: `swd_device_register 0x1fc` (EXPORT), `DeviceAcquire 0xbc4`,
  `DeviceAcquireInfineon 0x2cd0`, `DeviceAcquireRenesas 0x1b08`, `EraseAllFlash 0xc98`,
  `ProgramFlashRow 0xd50`, `ReadFlashRow 0xe40`, `ResetMCU 0xe84`, `GetDeviceID 0xb70`,
  `Read_IO 0xf78`, `Write_IO 0x1004`, `Read_IO_Size 0x11c0`, `Write_IO_Size 0x1054`,
  `Read_DAP 0xf10`, `Write_DAP 0xf3c`, `Swd_LineReset 0x1988`, `Swd_ReadPacket 0x16f0`,
  `Swd_WritePacket 0x1868`.
* **swd-gpio.ko**: `init_module 0x1016c`, `gpio_swd_access 0x100d8`, ops `gpio_swd_ops`.
* **vdm.ko**: `vdm_ioctl 0x11294`, `vdm_write 0x10da4`, `vdm_read 0x1051c`,
  `vdm_SendMessage 0x11e94`, `vdm_open 0x101ec`, `vdm_enable_rx 0x12118`, `vdm_reset 0x12088`,
  `init_module 0x11888`, fops `vdm_fops @ .data:0x260`.

Build provenance string in vdm.ko:
`/home/jenkins/agent/workspace/build-arev/externalsrc/drivers-idrac-arm/common-aess-vdm-drv/vdm_common.c`.
