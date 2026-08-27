# HPE iLO 5: Renode experiment

This is the next zoo target, but it is **not yet a `zbmc` fleet box**. The preserved HPE bootloader and kernel run under Renode 1.16.1 and reach the Green Hills INTEGRITY scheduler. The 31 MB `elf_secure` application image is decrypted but not loaded, so SSH, IPMI, Redfish, and the Web-UI do not run.

## Reproduce

The newest local firmware package that the published Airbus keys fully decrypt is iLO 5 v2.41. Its `bootloader1_main.raw` and `kernel_main.bin` are byte-identical to v2.33, the version used to develop the Renode model.

```bash
python3 -m venv work/deps/ilo5-python
work/deps/ilo5-python/bin/pip install pycryptodome==3.23.0
export PATH="$PWD/work/deps/ilo5-python/bin:$PATH"
./tools/install-renode-runtime --write
./tools/unpack-ilo5 /full/path/ilo5_241_linux.rpm
./tools/unpack-ilo5 --write /full/path/ilo5_241_linux.rpm work/ilo5-241
./experiments/ilo5/run-renode work/ilo5-241/modules
```

Debian's `python3-pycryptodome` package exposes the compatible `Cryptodome`
namespace and is also supported.

`run-renode` requires Renode 1.16.1 from release commit `d66b0c2a`; packaging build numbers may differ by platform. Set `RENODE=/full/path/to/renode` when it is not on `PATH`. Every run records the generated images, UART, Renode log, execution trace, and summary under `work/ilo5/runs/`.

## Version boundary

| Firmware | Local result | Use |
|---|---|---|
| 2.33 | Fully decrypted; historical Renode development base | Historical baseline |
| 2.41 | Fully decrypted; bootloader and kernel match 2.33 byte-for-byte | Current package and runtime core |
| 2.71 | Outer package decrypted; `elf_secure` key unavailable | Static inventory only |
| 3.19 | Newest local package; old outer key fails AES-GCM authentication | Provenance only |

The 2,082-byte `ilo5_319.clear.bin` is not decrypted firmware. It is the signed header written after authentication failed. `tools/unpack-ilo5` rejects that partial output.

## What is modeled or changed

- The HPE bootloader and kernel remain vendor code.
- A bootblock service page is reconstructed so the bootloader can print and query boot mode.
- GXP system, UART, DDR-status, DDR-PHY, and device-mailbox behavior is modeled in Renode.
- Physical DDR training and memory tests are skipped because Renode RAM has no data eye to train.
- Ten guarded kernel instructions bypass unsupported CPU debug state, an early scheduler dead end, a dangling bootloader string pointer, and absent NVRAM validation.

Success proves the preserved bootloader-to-kernel handoff and scheduler path. It does not prove application startup or any management protocol.

## Next wall

The kernel reaches `wfi` without a modeled periodic timer. After timer scheduling works, the experiment must place `elf_secure` where the HPE stager expects it and reconstruct only the missing platform environment needed to start the preserved vendor services. It should become a `zbmc` box only when at least one real management service is functionally reachable.
