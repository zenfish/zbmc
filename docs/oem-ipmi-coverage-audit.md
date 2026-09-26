<!-- html2md:auto source=docs/oem-ipmi-coverage-audit.html source-sha256=ce3ab5cc9473c4ece35fd1a88b1188fb522d7b59a6f06f2105e6146a859ff923 body-sha256=72ef0ca0cad2dce061c439dfb9c08d94b8a137c60a990cdb53f384a0caf8c3e8 -->

# OEM IPMI documentation and zipmi coverage audit

25 September 2026. Scope: all 11 tracked `boxes/*/zbmc.box` targets, existing zbmc and zipmi repository references, the AMI YAFU protocol reference, exact ASMB-787 firmware analysis, and its safe live QEMU probe set.

**Advantech ASMB-787 and Dell iDRAC10 are the first two targets whose exact current-firmware OEM surfaces and zipmi coverage are complete under the criteria below.** The other nine targets remain partial. “No complete repository catalog located” does not mean no documentation exists elsewhere.

Baseline fleet audit: zbmc `3c035c6`. ASMB completion uses zipmi 0.3.4; iDRAC10 completion uses zipmi 0.4.0 and the pinned YP95X 1.30.10.50-A00 image. Existing unrelated zbmc browser artifacts were excluded.

## Completeness criteria

A full reference requires firmware identity, command and selector identity, request and response fields, lengths, endianness, completion codes, authorization and channel constraints, side effects, feature gates, and evidence for each claim. A dispatch table establishes only part of that contract. A client-library wrapper is not proof that a particular BMC implements the command.

For zipmi, distinguish a descriptive catalog, name-to-opcode dispatch with caller-supplied bytes, structured request/response codecs, and exact-firmware verification. Raw transport can carry commands whose semantics the library does not implement. Empty codec registries do not exclude custom CLI handlers elsewhere; they do disprove interpreting catalog totals as counts of structured OEM codecs.

## All registered targets

| BMC | Full OEM documentation? | zipmi documentation and implementation | Missing proof |
|----|----|----|----|
| Advantech ASMB-787 | Complete exact-firmware remote catalog. The [firmware-bound reference](../../zipmi/docs/advantech_ASMB787-command-reference.md) covers 187/187 dispatch pairs and 462 handler-proven selector operations; opaque helper or union fields are explicitly bounded rather than guessed. | zipmi 0.3.4 provides complete named dispatch, exact raw contracts, 81 unambiguous structured codecs, safety gating, and live evidence for all 32 safely synthesizable read-only codecs. | No missing top-level or selector denominator. Variable/union operations intentionally remain raw-exact; mutating and destructive paths are not live-executed. |
| Dell iDRAC9 | Partial. [Comparison reference](../boxes/idrac10/idrac9-vs-idrac10-oem-diff.md) covers three libraries and 276 catalog entries, normalized to 240 capabilities; other libraries were outside that pass. | [7.20.30.50 module](../../zipmi/zipmi/scapy_ipmi/oem/idrac9.py): 276 descriptive rows, 271 dispatch rows, 100 registry names. CLI lists 632 entries, 276 with request/response documentation fields. Zero registered OEM codec pairs. | Whole-firmware denominator; unresolved schemas; exact-image behavior and codec coverage. |
| Dell iDRAC10 | Complete firmware-bound Dell OEM catalog. The [581-operation reference](../boxes/idrac10/idrac10-oem-reference.md) covers all 255 Dell-relevant top-level pairs, including 103 System Info selectors, nine OSA inner routes, DCMI activation, privileges, channels, side effects, completion codes, and evidence. Sixty-nine helper/SCBMC operations retain explicit bounded unknowns. | [1.30.10.50 module](../../zipmi/zipmi/scapy_ipmi/oem/idrac10.py): 581 unique named operations, 20 request codecs, 130 response codecs, exact raw execution for the remainder, and fail-closed safety gating. Fresh run `20260926T050202Z-c410ded2-1f95-43eb-99ad-6583f942e598` exercised all 13 strictly synthesizable safe reads: 11 CC00 and two target completion codes, with no transport failure. | No missing Dell-relevant pair or recovered selector denominator. Variable, delegated, union, and opaque SCBMC/helper payloads intentionally remain raw-exact; mutating, security-sensitive, destructive, and unresolved operations were not live-executed. |
| IEIT | Not established. No complete OEM catalog located in repository; [box reference](../boxes/ieit/index.md) documents operation. | [Inspur module](../../zipmi/zipmi/scapy_ipmi/oem/inspur.py) has one upstream OpenBMC command and no codecs. | No evidence that this provider matches the IEIT image. Brand similarity cannot establish compatibility. |
| Fujitsu iRMC | Partial semantics over a recovered inventory. [Power map](../boxes/irmc-fujitsu/oem-power-map.md) and [IPMI path](../boxes/irmc-fujitsu/ipmi-path.md): 160 table records, 148 active, 135 distinct pairs; some behavior remains unresolved. | No Fujitsu/iRMC OEM module or dedicated OEM reference located in zipmi. | Whole-surface schemas and target-specific zipmi integration. |
| Lenovo XCC | Selected mechanisms documented in the [handoff](lenovo-xcc-shell-script-handoff.md) and [findings](lenovo-xcc-shell-script-findings.md); no complete repository command catalog located. | No Lenovo/XCC OEM module or dedicated OEM reference located in zipmi. | Complete inventory, transport exposure, schemas, and target-specific integration. |
| HPE MegaRAC / XD670 | Handler inventory. [210 handlers across 45 modules](../boxes/megarac-hpe/IPMI.md); the document leaves per-library opcode extraction outstanding. | [MegaRAC](../../zipmi/zipmi/scapy_ipmi/oem/megarac.py): 95 names; [YAFU](../../zipmi/zipmi/scapy_ipmi/oem/yafu.py): 42. Both have zero codec pairs. Main MegaRAC CLI entries lack request/response fields; YAFU has 41 request and 42 response descriptions. | Resolve acknowledged NetFn uncertainty; reconcile symbols with opcodes and selectors. Shared AMI lineage does not imply identical commands. |
| NVIDIA OpenBMC | No complete target-specific catalog located in repository; [box reference](../boxes/nvidia-obmc/index.md) covers runtime. | [Upstream provider catalog](../../zipmi/zipmi/scapy_ipmi/oem/nvidia.py): eight selector-aware entries, ten registry names including fallbacks, zero codecs. | Compare the actual GB200 firmware providers and schemas against the upstream-derived catalog. |
| OpenBMC baseline | [Historical vanilla-image inventory](../boxes/openbmc/IPMI-REDFISH-INVENTORY.md) reports no vendor OEM handlers. [Build information](../boxes/openbmc/BUILD-INFO.md) warns that this image differs from the currently pinned derived image. | [OpenBMC module](../../zipmi/zipmi/scapy_ipmi/oem/openbmc.py) combines nine provider families: 137 merged registry names, four codec pairs from Intel/Google. This is not a baseline-image compatibility manifest. | Re-establish the no-OEM conclusion for the pinned image. Romulus evidence concerns a separate historical target. |
| Supermicro X10 | No complete OEM IPMI catalog located in repository. [Runtime reference](../boxes/supermicro-x10/README.md)'s Redfish extensions are not an OEM IPMI inventory. | [Legacy Supermicro module](../../zipmi/zipmi/scapy_ipmi/oem/supermicro.py) is X11-derived: 477 CLI entries, seven top-level registry names, zero codecs, no request/response fields in those CLI entries. | X10 firmware applicability and schemas. X11 support cannot be relabeled as X10 verification. |
| Supermicro X14 | No complete target-specific catalog located in zbmc; [reproduction reference](../boxes/supermicro-x14/REPRODUCE.md) covers runtime. | [01.01.06.07 module](../../zipmi/zipmi/scapy_ipmi/oem/supermicro_x14.py): 39 selector-aware entries, 46 registry names, zero codecs; unresolved registrations acknowledged. | Close registration gaps, specify payloads, and match the pinned firmware version. |

## ASMB-787: corrected evidence boundary

The corrected count is 187 declared remote vendor rows: 85 core commands, 95 plugin commands across 37 modules, and seven platform commands. The first 180 use NetFn `0x32`; the platform library contributes five NetFn `0x30` and two NetFn `0x3a` commands. Three additional NetFn `0x2e` SMM-local records remain outside that denominator pending transport proof, for 190 compiled records in all.

The 85 core and seven platform rows are statically registered. Exact loader/configuration analysis proves 93 of 95 plugin rows are runtime registered. Only PLDM `0xd5` and `0xd6` are skipped because their exact feature token is absent; they remain documented as compiled-but-inactive contracts.

The older 369-handler catalog mixed standard and vendor tables. Reanalysis confirms the dispatch record stores privilege at byte offset `+1` and request length at byte offset `+8`; the generated 187-row source now uses those corrected fields. The 369 total has a different scope and is not an alternative denominator.

The later reference is `/Volumes/yyy/phd/bmc/AMI/yafu/protocol.html`, section 3. It also includes client-library material from multiple platforms; inclusion there does not prove ASMB-787 server support.

**Completed deliverable:** the generated [command reference](../../zipmi/docs/advantech_ASMB787-command-reference.md) documents 462 operations across all 187 pairs, with exact handler evidence, activation, safety, and 33 live-backed operations. zipmi 0.3.4 implements every pair through named exact raw contracts and adds 81 structured codecs where the recovered framing is unambiguous.

## iDRAC10: exact denominator and bounded implementation

The pinned YP95X image contributes 429 physical dispatch rows: 238 OEM-table rows, 138 master-table rows, 44 DCMI alternate rows, and nine OSA inner rows. These collapse to 383 unique `(NetFn, command, handler)` triples and 346 apparent pairs. Five pairs are OSA inner-only identities behind outer `0x2e/0xcc`; after separating standard-only handlers, the Dell-relevant remote denominator is 255 top-level pairs.

The canonical reference expands recovered selectors into 581 unique operation identities, including 49 Set System Info and 54 Get System Info selector contracts. The formerly undetermined `DellCmdNodeMgrDebugInfo` route is proven at `0x06/0x33` and retained separately from its identical `0x2e/0xe0` registration. Fifteen DCMI routes activate only when `/flash/data0/BMC_Data/dcmi` begins with ASCII `1`; the other 45 alternate/proxy records remain statically loaded.

Every operation now has an evidence-backed safety class. Totals are 215 safe, 165 mutating, 119 security-sensitive, 13 destructive, and 69 explicitly unknown at opaque helper or physical-SCBMC boundaries. The nine OSA inner routes inherit Callback privilege from the outer dispatcher because their inner privilege metadata is not re-enforced; this includes the destructive OSA reset handler. zipmi therefore requires `--unsafe` for every operation outside the audited safe/exact subset.

zipmi 0.4.0 exposes all 581 identities, generates 20 exact request codecs and 130 exact response codecs, and keeps 451 partial, variable, union, delegated, or opaque operations raw-exact. The fresh post-reboot live artifact is [`20260926T050202Z-safe-live.json`](../boxes/idrac10/evidence/20260926T050202Z-safe-live.json) (SHA-256 `5fc576d227ddcd053f950b6b9b725319159bd00fa267a803dfc5407fa6a51a6c`).

## What zipmi's counts establish

`oem_command_totals()` now returns 2,219 known and 2,142 named entries across the CLI vendor keys. These are not 2,219 fully specified, tested commands: descriptive rows, dispatch pairs, selector operations, fallbacks, and CLI entries use different counting units.

[The registry](../../zipmi/zipmi/scapy_ipmi/oem/_registry.py) stores vendor-scoped names separately from payload classes. [Named CLI dispatch](../../zipmi/zipmi/cli/oem_cmds.py) prepends only exact handler-proven prefixes and enforces the target safety policy. ASMB live-verification fields now preserve exact request bytes, completion codes, and response data.

Fresh isolated imports produced these counts. Isolation matters because the registry is global and multiple vendors can merge or overwrite the same keys.

| Module | Registered names | Payload pairs | Request classes | Response classes |
|----|----|----|----|----|
| advantech-asmb787 | 187 | 81 | 81 | 81 |
| dell | 204 | 2 | 2 | 1 |
| idrac9 | 100 | 0 | 0 | 0 |
| idrac10 | 255 catalog pairs / 581 operations | 130 | 20 | 130 |
| supermicro | 7 | 0 | 0 | 0 |
| supermicro_x14 | 46 | 0 | 0 | 0 |
| megarac | 95 | 0 | 0 | 0 |
| yafu | 42 | 0 | 0 | 0 |
| inspur | 1 | 0 | 0 | 0 |
| nvidia | 10 | 0 | 0 | 0 |
| openpower | 3 | 0 | 0 | 0 |
| openbmc | 137 | 4 | 3 | 2 |

## Sources, verification, and limits

Local source links above assume sibling zbmc and zipmi checkouts. The inventory search covered box references and shared repository docs. For ASMB-787, exact-image run `20260926T031044Z-cc48e36e-4cc4-4f24-8052-6baa12c24fa2` reached six-service READY and exercised every safely synthesizable read-only codec. For iDRAC10, run `20260926T050202Z-c410ded2-1f95-43eb-99ad-6583f942e598` reached READY in 22 seconds; the strict safe allowlist produced 11 CC00 responses plus expected CCFF/CCC1 target rejections and no transport failure. No target completeness percentage is claimed where another firmware's denominator remains unknown.

The [IPMI specification](https://www.intel.com/content/dam/www/public/us/en/documents/specification-updates/ipmi-intelligent-platform-mgt-interface-spec-2nd-gen-v2-0-spec-update.pdf) assigns OEM behavior and privilege requirements to the OEM. Upstream [OpenBMC registration code](https://github.com/openbmc/phosphor-host-ipmid/blob/master/ipmid-new.cpp) supplies architectural context, not proof of a pinned image's provider set. Repository-specific conclusions come from the local references and offline imports.
