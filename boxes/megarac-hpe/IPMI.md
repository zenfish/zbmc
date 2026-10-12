<!-- html2md:auto source=boxes/megarac-hpe/IPMI.html source-sha256=d7868e0e3798d41eb22aaac180956fa8f2fe97ed58fbace8e1feacb683a523cc body-sha256=cb34d25f980a626623c2f0318f38de2496c02a85d81519d5703602292d6c3c80 -->

zBMC runtime evidence · zipmi catalog synchronization

# HPE Cray XD670 v1.27 OEM IPMI dispatch

Exact-image replacement for the historical symbol-only inventory. The linked canonical ledger closes the registration and expanded-operation denominators; it does not claim that every operation is semantically complete or executable through zipmi.

**143**

firmware registration rows

**142**

unique NetFn/command addresses

**141**

effective commands

**791**

expanded operation rows

## Pinned evidence

|  |  |
|----|----|
| Signed HPM SHA-256 | `4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76` |
| Pristine SquashFS SHA-256 | `dd1d664f34ec5a2883fdcb1a10616154b266982a0997e59b3ce385f5f511afe5` |
| Frozen catalog SHA-256 | `c2ed76b6595617ef64370de3295ba055b88d280fa9e8ac416b40f65f10c737cc` |
| Operation-contract artifact SHA-256 | `cbb6574c4008787e158ecceec052f9506dd1eeba44307110cd7a99515062b516` |
| zipmi synchronization commit | `b6940ef5527c98513a5e3349c9e108917305491f` |

**Verified:** the 42 relevant ELFs are byte-identical between the pristine vendor root filesystem and the accepted zBMC input root filesystem. The runtime harness is modified; the analyzed userspace is not.

## Dispatch closure

The dispatcher contains 39 built-in YAFU/file registrations and 104 extension registrations. Feature activation and duplicate precedence are separate filters:

- `0x32`: 134 registrations and 133 effective addresses. All 95 canonical AMI plugin commands use this NetFn on XD670.
- `0x30`: four active Node Manager/platform registrations.
- `0x3e`: five HPM registrations, of which four are active. `IncreasePayloadSize` is inactive because `SUPPORT_HPM_IFC` is absent.
- `0x32/0x2c`: built-in `AMIYAFUStateless` wins because the core table is searched before extensions. The later `AMIOemSetRedisDB` registration is shadowed and is not an effective command at that address.

**Correction to the historical page:** exported handler symbols were not registrations. The old “210 handlers across 45 modules, primarily NetFn 0x30” description was not an opcode map and must not be used as one.

## Security-relevant boundaries

- `0x32/0x2a` reaches the Redis command bridge with callback privilege metadata. Static analysis shows a 250-byte local buffer and a request-length-derived copy without a local 250-byte bound. Exploitability remains **inferred** until the maximum deliverable callback length is proved.
- `0x32/0x2c` does not reach the Redis setter on this image because the built-in YAFU command shadows it.
- `0x32/0x5c` is the administrator REST bridge; `0x32/0x5d` mutates account/session state.
- `0x32/0x43` controls remote-debug service/certificate state and is not a safe probe.

## Safe live validation

Run `20261012T203124Z-77b23da6-aa05-4c9d-850d-36ad62509d34` reached READY 4/4 before and after four no-mutation requests:

- `0x32/0xa6` succeeded with `55 54 43` (“UTC”).
- `0x32/0x44 0x00` succeeded with `01 01 04 07 00 00`.
- `0x30/0xe0` returned completion code `0xc7`.
- `0x32/0x9d` returned completion code `0xff`; this was an error, not one byte of successful response data.

The guest stayed on the same QEMU process through the probes and was stopped cleanly afterward.

## Canonical operation ledger and partial semantics

Use the firmware-bound zipmi pages, not the generic MegaRAC catalog:

- [XD670 791-operation command reference](https://github.com/zenfish/zipmi/blob/main/docs/hpe-xd670-command-reference.html)
- [XD670 complete registration table](https://github.com/zenfish/zipmi/blob/main/docs/hpe-xd670-command-table.html)
- [Canonical machine-readable operation contracts](https://github.com/zenfish/zipmi/blob/main/zipmi/data/sources/hpe-xd670-operation-contracts.json)
- [Machine-readable zBMC/zipmi synchronization manifest](oem-ipmi-sync.json)

**Operation inventory complete; semantic decode incomplete:** zipmi now holds 141 shared implementation contracts, 141 XD670 target overlays, and 791 expanded operation rows. Only four reviewed read-only routes are runnable by name; the other 787 operations have no distinct route and fail closed rather than accepting guessed payloads.

## Remaining evidence limits

The ledger accounts for every effective command and recovered selector, but it is not a fully decoded protocol specification. Only 11 request layouts are complete; 780 are partial. Response layouts are 754 partial and 37 unknown. Exact interface-mask bit-to-transport labels, indirect authorization checks, and many BIOS, PECI, RAID, update, and service-control field meanings remain unresolved. These unknowns are preserved in the canonical contracts instead of being filled from another MegaRAC target.

Updated 12 October 2026 from exact-image static analysis and safe zBMC validation.
