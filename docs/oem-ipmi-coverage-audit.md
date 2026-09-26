<!-- html2md:auto source=docs/oem-ipmi-coverage-audit.html source-sha256=9ba9cce7d4712352054e66c3910871af975cea6d462afa494c2b413992650209 body-sha256=d547b51e4745a3e092a7b103eb0c6e1cc74a5928eaa6c278ce598853632b1840 -->

# OEM IPMI documentation and zipmi coverage audit

25 September 2026. Scope: all 11 tracked `boxes/*/zbmc.box` targets, existing zbmc and zipmi repository references, the AMI YAFU protocol reference, exact ASMB-787 firmware analysis, and its safe live QEMU probe set.

**Advantech ASMB-787 is the first target whose exact current-firmware OEM surface and zipmi coverage are complete under the criteria below.** The other ten targets remain partial. “No complete repository catalog located” does not mean no documentation exists elsewhere.

Baseline fleet audit: zbmc `3c035c6`; ASMB completion builds on zbmc `aab63d8` and zipmi `4519150` (version 0.3.4). Existing unrelated zbmc browser artifacts were excluded.

## Completeness criteria

A full reference requires firmware identity, command and selector identity, request and response fields, lengths, endianness, completion codes, authorization and channel constraints, side effects, feature gates, and evidence for each claim. A dispatch table establishes only part of that contract. A client-library wrapper is not proof that a particular BMC implements the command.

For zipmi, distinguish a descriptive catalog, name-to-opcode dispatch with caller-supplied bytes, structured request/response codecs, and exact-firmware verification. Raw transport can carry commands whose semantics the library does not implement. Empty codec registries do not exclude custom CLI handlers elsewhere; they do disprove interpreting catalog totals as counts of structured OEM codecs.

## All registered targets

| BMC | Full OEM documentation? | zipmi documentation and implementation | Missing proof |
|----|----|----|----|
| Advantech ASMB-787 | Complete exact-firmware remote catalog. The [firmware-bound reference](../../zipmi/docs/advantech_ASMB787-command-reference.md) covers 187/187 dispatch pairs and 462 handler-proven selector operations; opaque helper or union fields are explicitly bounded rather than guessed. | zipmi 0.3.4 provides complete named dispatch, exact raw contracts, 81 unambiguous structured codecs, safety gating, and live evidence for all 32 safely synthesizable read-only codecs. | No missing top-level or selector denominator. Variable/union operations intentionally remain raw-exact; mutating and destructive paths are not live-executed. |
| Dell iDRAC9 | Partial. [Comparison reference](../boxes/idrac10/idrac9-vs-idrac10-oem-diff.md) covers three libraries and 276 catalog entries, normalized to 240 capabilities; other libraries were outside that pass. | [7.20.30.50 module](../../zipmi/zipmi/scapy_ipmi/oem/idrac9.py): 276 descriptive rows, 271 dispatch rows, 100 registry names. CLI lists 632 entries, 276 with request/response documentation fields. Zero registered OEM codec pairs. | Whole-firmware denominator; unresolved schemas; exact-image behavior and codec coverage. |
| Dell iDRAC10 | Extensive but incomplete. [446-entry reference](../boxes/idrac10/idrac10-oem-reference.md) retains undetermined wire IDs and response fields; [dispatch tables](../boxes/idrac10/idrac10-dispatch-tables.md) add evidence. | [1.30.10.50 module](../../zipmi/zipmi/scapy_ipmi/oem/idrac10.py): 446 descriptive rows, 383 dispatch rows, 340 registry names; CLI 443 entries with request/response fields. Zero registered OEM codec pairs. | Resolve unknown fields, distinguish grouped entries from unique commands, and verify target-specific behavior. |
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

## What zipmi's counts establish

`oem_command_totals()` now returns 2,219 known and 2,142 named entries across the CLI vendor keys. These are not 2,219 fully specified, tested commands: descriptive rows, dispatch pairs, selector operations, fallbacks, and CLI entries use different counting units.

[The registry](../../zipmi/zipmi/scapy_ipmi/oem/_registry.py) stores vendor-scoped names separately from payload classes. [Named CLI dispatch](../../zipmi/zipmi/cli/oem_cmds.py) prepends only exact handler-proven prefixes and enforces the target safety policy. ASMB live-verification fields now preserve exact request bytes, completion codes, and response data.

Fresh isolated imports produced these counts. Isolation matters because the registry is global and multiple vendors can merge or overwrite the same keys.

| Module | Registered names | Payload pairs | Request classes | Response classes |
|----|----|----|----|----|
| advantech-asmb787 | 187 | 81 | 81 | 81 |
| dell | 204 | 2 | 2 | 1 |
| idrac9 | 100 | 0 | 0 | 0 |
| idrac10 | 340 | 0 | 0 | 0 |
| supermicro | 7 | 0 | 0 | 0 |
| supermicro_x14 | 46 | 0 | 0 | 0 |
| megarac | 95 | 0 | 0 | 0 |
| yafu | 42 | 0 | 0 | 0 |
| inspur | 1 | 0 | 0 | 0 |
| nvidia | 10 | 0 | 0 | 0 |
| openpower | 3 | 0 | 0 | 0 |
| openbmc | 137 | 4 | 3 | 2 |

## Sources, verification, and limits

Local source links above assume sibling zbmc and zipmi checkouts. The inventory search covered box references and shared repository docs. For ASMB-787, exact-image run `20260926T031044Z-cc48e36e-4cc4-4f24-8052-6baa12c24fa2` reached six-service READY and exercised every safely synthesizable read-only codec. No target completeness percentage is claimed where another firmware's denominator remains unknown.

The [IPMI specification](https://www.intel.com/content/dam/www/public/us/en/documents/specification-updates/ipmi-intelligent-platform-mgt-interface-spec-2nd-gen-v2-0-spec-update.pdf) assigns OEM behavior and privilege requirements to the OEM. Upstream [OpenBMC registration code](https://github.com/openbmc/phosphor-host-ipmid/blob/master/ipmid-new.cpp) supplies architectural context, not proof of a pinned image's provider set. Repository-specific conclusions come from the local references and offline imports.
