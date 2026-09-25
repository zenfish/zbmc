<!-- html2md:auto source=docs/oem-ipmi-coverage-audit.html source-sha256=36d086ea55ae0aff6afb4719318a890e8df55e40910e7106314703aa6e815b8a body-sha256=3a3e806eed08cf0406349ae4e79cf52aeb2d3901d22d43200152377ff2dc2d85 -->

# OEM IPMI documentation and zipmi coverage audit

25 September 2026. Scope: all 11 tracked `boxes/*/zbmc.box` targets, existing zbmc and zipmi repository references, and the existing AMI YAFU protocol reference. This is an offline documentation and implementation audit, not a fresh firmware extraction or live compatibility test.

**No inspected target has evidence sufficient to certify both a fully documented current-firmware OEM surface and complete zipmi support.** Several targets have substantial references. “No complete repository catalog located” does not mean no documentation exists elsewhere.

Audited revisions: zbmc `d814fc8badca4116f089cbc9b772df3c95df5ef2`; zipmi `436cd000dc4973f4606deae79a51d9897b880265`. zipmi was clean. Existing unrelated zbmc lesson changes and browser artifacts were excluded.

## Completeness criteria

A full reference requires firmware identity, command and selector identity, request and response fields, lengths, endianness, completion codes, authorization and channel constraints, side effects, feature gates, and evidence for each claim. A dispatch table establishes only part of that contract. A client-library wrapper is not proof that a particular BMC implements the command.

For zipmi, distinguish a descriptive catalog, name-to-opcode dispatch with caller-supplied bytes, structured request/response codecs, and exact-firmware verification. Raw transport can carry commands whose semantics the library does not implement. Empty codec registries do not exclude custom CLI handlers elsewhere; they do disprove interpreting catalog totals as counts of structured OEM codecs.

## All registered targets

| BMC | Full OEM documentation? | zipmi documentation and implementation | Missing proof |
|----|----|----|----|
| Advantech ASMB-787 | No. [Existing audit](../boxes/advantech-asmb787/index.md): 186 registered vendor pairs; 107 mapped in the earlier corpus, 79 unmapped, approximately ten with focused framing analysis. | [A dispatch catalog exists](../../zipmi/docs/advantech_ASMB787-command-table.md); no native Advantech module. Shared MegaRAC/YAFU metadata does not establish exact ASMB coverage. | Resolve contradictory field interpretation, document every request/response, reconcile the firmware command set against zipmi. |
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

## ASMB-787: reference reconciliation still required

The earlier audit counted 85 core entries plus 94 plugin entries across 37 modules, plus seven platform entries, yielding 186 vendor pairs. It separately excluded three SMM-local records pending transport proof. This audit inherits those counts from checked-in evidence; it did not rerun firmware extraction. Static registration also does not prove every command is reachable over LAN in every runtime state.

The older zipmi catalog advertises 369 handlers across 50 tables, including standard commands. Its stated layout places request length at offset +1 and privilege at +8; the later AMI protocol reference places privilege at +1 and request length at +8. The old table consequently contains supposed privileges outside the normal IPMI level range. Its privilege and request-length columns must not be treated as verified. The 369 total is not an alternative denominator for 186 vendor pairs.

The later reference is `/Volumes/yyy/phd/bmc/AMI/yafu/protocol.html`, section 3. It also includes client-library material from multiple platforms; inclusion there does not prove ASMB-787 server support. Neither conflicting reference constitutes the finished command-by-command specification requested.

**Remaining deliverable:** the corrected, firmware-bound ASMB-787 command reference with complete semantics and corresponding supported zipmi behavior. This audit completes the evidence comparison; it does not complete that implementation or resolve unknown protocol fields.

## What zipmi's counts establish

The README says 1,725 OEM commands. At the audited revision, `oem_command_totals()` returns 1,767 known and 1,695 named across 16 CLI vendor keys. These are not 1,767 fully specified, tested commands. Descriptive rows, dispatch records, selector-aware entries, fallback names, and CLI entries use different counting units.

[The registry](../../zipmi/zipmi/scapy_ipmi/oem/_registry.py) synthesizes pair-only fallback names for selector keys and stores names separately from payload classes. [Named CLI dispatch](../../zipmi/zipmi/cli/oem_cmds.py) prepends selectors to caller-supplied bytes and uses raw transport. All inspected CLI listings had empty live-verification fields; this means that field supplies no evidence, not that no historical testing exists elsewhere.

Fresh isolated imports produced these counts. Isolation matters because the registry is global and multiple vendors can merge or overwrite the same keys.

| Module | Registered names | Payload pairs | Request classes | Response classes |
|----|----|----|----|----|
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

Local source links above assume sibling zbmc and zipmi checkouts. The inventory search covered box references and shared repository docs. No BMC services were started and no IPMI packets were sent. No target completeness percentage can be calculated where the complete firmware denominator remains unknown.

The [IPMI specification](https://www.intel.com/content/dam/www/public/us/en/documents/specification-updates/ipmi-intelligent-platform-mgt-interface-spec-2nd-gen-v2-0-spec-update.pdf) assigns OEM behavior and privilege requirements to the OEM. Upstream [OpenBMC registration code](https://github.com/openbmc/phosphor-host-ipmid/blob/master/ipmid-new.cpp) supplies architectural context, not proof of a pinned image's provider set. Repository-specific conclusions come from the local references and offline imports.
