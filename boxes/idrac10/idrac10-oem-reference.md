<!-- html2md:auto source=boxes/idrac10/idrac10-oem-reference.html -->

# iDRAC10 — OEM IPMI Command Reference

446 reverse-engineered Dell OEM commands. Sections use a **fixed taxonomy** — section N is the same category in every generation, so these roll up into one Dell manual. Commands are numbered `section.command` (e.g. 5.3), spec-style. **Impact** (Critical High Medium Low) is a heuristic over the RE'd security notes + verb — the security text is real RE, the bucketing a reading aid. Critical = credential disclosure / arbitrary hardware access / destructive-data; High = firmware/boot/factory/power-cycle/memory-safety. **Privilege**: C=Callback U=User O=Operator A=Admin; **X**=minimum required, • = also permitted higher.

Impact spread: Critical 32 · High 45 · Medium 343 · Low 26. Type in the filter bar (top) to narrow to matching rows/commands.

Live-verified on a running box: **402/445** probed handlers confirmed real (live ✓ data 46 · dispatched 251 · Dell-CC 105; gated 17 · absent 26). Destructive-named commands were not probed.

## Contents

- [1. Bootstrap Credentials & Attestation](#sec-0) (17)
- [2. In-Band iSM Bridge (KCS/host)](#sec-1) (80)
- [3. Lifecycle Controller / MASER](#sec-2) (131)
- 4\. vFlash / SD Storage (0)
- [5. DCMI](#sec-4) (45)
- [6. Node Manager & Power / Thermal](#sec-5) (84)
- 7\. Remote Enablement / Provisioning (0)
- 8\. SupportAssist / Diagnostics / ToolSet (0)
- [9. Modular / Blade / CMC / KVM](#sec-8) (26)
- [10. Chassis / Front Panel / LCD](#sec-9) (8)
- [11. Serial / Terminal](#sec-10) (6)
- [12. Config / System Info](#sec-11) (10)
- [13. Backplane / Drive](#sec-12) (2)
- [14. OSA / OEM Misc](#sec-13) (13)
- [15. Other / Uncategorised](#sec-14) (24)

## Command / Privilege Table (spec Table G-1 form)

Cmd# and Handler link to the full entry; § links to the section.

| Cmd# | § | NetFn | CMD | Sub | Handler | Imp | Live | C | U | O | A |
|----|----|----|----|----|----|----|----|----|----|----|----|
| [`15.1`](#cmd-15-1) | [15](#sec-14) | `undetermined` | `undetermined` |  | [DellCmdNodeMgrDebugInfo](#cmd-15-1) | M |  |  |  |  |  |
| [`10.1`](#cmd-10-1) | [10](#sec-9) | `0x00` | `0x00` |  | [CmdOEMGetChassisCapabilities](#cmd-10-1) | M | live ✓ |  | X | • | • |
| [`10.2`](#cmd-10-2) | [10](#sec-9) | `0x00` | `0x01` |  | [DellCmdGetChassisStatus](#cmd-10-2) | M | live ✓ |  | X | • | • |
| [`10.3`](#cmd-10-3) | [10](#sec-9) | `0x00` | `0x04` |  | [CmdOEMChassisIdentify](#cmd-10-3) | M | live ✓ |  |  | X | • |
| [`10.4`](#cmd-10-4) | [10](#sec-9) | `0x00` | `0x05` |  | [CmdOEMSetChassisCapabilities](#cmd-10-4) | M | live ✓ |  |  |  | X |
| [`15.2`](#cmd-15-2) | [15](#sec-14) | `0x00` | `0x08` |  | [OEMCmdSetSystemBootOptions](#cmd-15-2) | M | live ✓ |  |  | X | • |
| [`10.5`](#cmd-10-5) | [10](#sec-9) | `0x00` | `0x0a` |  | [DellCmdSetFrntPanelState](#cmd-10-5) | M | live ✓ |  | X | • | • |
| [`15.3`](#cmd-15-3) | [15](#sec-14) | `0x06` | `0x04` |  | [CmdOEMGetSelfTestResults](#cmd-15-3) | M | live ✓ |  | X | • | • |
| [`15.4`](#cmd-15-4) | [15](#sec-14) | `0x06` | `0x05` |  | [CmdOEMManufacturingTestOn](#cmd-15-4) | M | live ✓ |  |  |  | X |
| [`15.5`](#cmd-15-5) | [15](#sec-14) | `0x06` | `0x0a` |  | [CmdOEMGetCommandSupport](#cmd-15-5) | M | live ✓ |  | X | • | • |
| [`9.1`](#cmd-9-1) | [9](#sec-8) | `0x06` | `0x32` |  | [CmdOEMEnableMsgChannelRecv](#cmd-9-1) | M | absent |  | X | • | • |
| [`9.2`](#cmd-9-2) | [9](#sec-8) | `0x06` | `0x42` |  | [CmdOEMGetChannelInfo](#cmd-9-2) | M | live ✓ |  | X | • | • |
| [`9.3`](#cmd-9-3) | [9](#sec-8) | `0x06` | `0x43` |  | [OEMCmdSetUserAccess](#cmd-9-3) | M | live ✓ |  |  |  | X |
| [`9.4`](#cmd-9-4) | [9](#sec-8) | `0x06` | `0x45` |  | [OEMCmdSetUserName](#cmd-9-4) | ! | live ✓ |  |  |  | X |
| [`9.5`](#cmd-9-5) | [9](#sec-8) | `0x06` | `0x47` |  | [CmdOEMSetUserPassword](#cmd-9-5) | ! | live ✓ |  |  |  | X |
| [`15.6`](#cmd-15-6) | [15](#sec-14) | `0x06` | `0x56` |  | [OEMCmdSetChannelSecurityKeys](#cmd-15-6) | ! | live ✓ |  |  |  | X |
| [`9.6`](#cmd-9-6) | [9](#sec-8) | `0x0a` | `0x11` |  | [CmdOEMReadFRUData](#cmd-9-6) | M | live ✓ |  | X | • | • |
| [`9.7`](#cmd-9-7) | [9](#sec-8) | `0x0a` | `0x43` |  | [CmdOEMGetSELEntry](#cmd-9-7) | M | live ✓ |  | X | • | • |
| [`9.8`](#cmd-9-8) | [9](#sec-8) | `0x0a` | `0x49` |  | [CmdOEMSetSELTime](#cmd-9-8) | M | live ✓ |  |  | X | • |
| [`11.1`](#cmd-11-1) | [11](#sec-10) | `0x0c` | `0x10` |  | [DellCmdSetSerModemConfigParam](#cmd-11-1) | M | live ✓ |  |  |  | X |
| [`11.2`](#cmd-11-2) | [11](#sec-10) | `0x0c` | `0x11` |  | [DellCmdGetSerModemConfigParam](#cmd-11-2) | M | live ✓ |  |  | X | • |
| [`11.3`](#cmd-11-3) | [11](#sec-10) | `0x0c` | `0x21` |  | [DellCmdSetSOLConfiguration](#cmd-11-3) | M | live ✓ |  |  |  | X |
| [`11.4`](#cmd-11-4) | [11](#sec-10) | `0x0c` | `0x22` |  | [DellCmdGetSOLConfiguration](#cmd-11-4) | M | live ✓ |  | X | • | • |
| [`1.1`](#cmd-1-1) | [1](#sec-0) | `0x2c` | `0x01` |  | [CmdDcmiGetDcmiCapabilityInfo](#cmd-1-1) | M | absent |  |  |  |  |
| [`1.2`](#cmd-1-2) | [1](#sec-0) | `0x2c` | `0x01` |  | [DellCmdGetMgrCertFingerprint](#cmd-1-2) | M | absent |  |  |  | X |
| [`1.3`](#cmd-1-3) | [1](#sec-0) | `0x2c` | `0x02` |  | [CmdDcmiGetPowerReading](#cmd-1-3) | M | absent |  | X | • | • |
| [`1.4`](#cmd-1-4) | [1](#sec-0) | `0x2c` | `0x02` |  | [DellCmdGetBootstrapCredentials](#cmd-1-4) | ! | absent |  |  |  | X |
| [`1.5`](#cmd-1-5) | [1](#sec-0) | `0x2c` | `0x03` |  | [CmdDcmiGetPowerLimit](#cmd-1-5) | M | absent |  | X | • | • |
| [`1.6`](#cmd-1-6) | [1](#sec-0) | `0x2c` | `0x04` |  | [CmdDcmiSetPowerLimit](#cmd-1-6) | M | absent |  |  | X | • |
| [`1.7`](#cmd-1-7) | [1](#sec-0) | `0x2c` | `0x05` |  | [CmdDcmiActDeactPowerLimit](#cmd-1-7) | M | absent |  |  | X | • |
| [`1.8`](#cmd-1-8) | [1](#sec-0) | `0x2c` | `0x06` |  | [CmdDcmiGetAssetTag](#cmd-1-8) | M | absent |  | X | • | • |
| [`1.9`](#cmd-1-9) | [1](#sec-0) | `0x2c` | `0x07` |  | [CmdDcmiGetDcmiSensorInfo](#cmd-1-9) | M | absent |  |  | X | • |
| [`1.10`](#cmd-1-10) | [1](#sec-0) | `0x2c` | `0x08` |  | [CmdDcmiSetAssetTag](#cmd-1-10) | M | absent |  |  | X | • |
| [`1.11`](#cmd-1-11) | [1](#sec-0) | `0x2c` | `0x09` |  | [CmdDcmiGetManagementControllerIdStr](#cmd-1-11) | ! | absent |  | X | • | • |
| [`1.12`](#cmd-1-12) | [1](#sec-0) | `0x2c` | `0x0a` |  | [CmdDcmiSetManagementControllerIdStr](#cmd-1-12) | H | absent |  |  |  | X |
| [`1.13`](#cmd-1-13) | [1](#sec-0) | `0x2c` | `0x0b` |  | [CmdDcmiSetThermalLimit](#cmd-1-13) | M | absent |  |  | X | • |
| [`1.14`](#cmd-1-14) | [1](#sec-0) | `0x2c` | `0x0c` |  | [CmdDcmiGetThermalLimit](#cmd-1-14) | M | absent |  | X | • | • |
| [`1.15`](#cmd-1-15) | [1](#sec-0) | `0x2c` | `0x10` |  | [CmdDcmiGetTemperatureReadings](#cmd-1-15) | M | absent |  | X | • | • |
| [`1.16`](#cmd-1-16) | [1](#sec-0) | `0x2c` | `0x12` |  | [CmdDcmiSetDMCIConfigParam](#cmd-1-16) | ! | absent |  |  |  | X |
| [`1.17`](#cmd-1-17) | [1](#sec-0) | `0x2c` | `0x13` |  | [CmdDcmiGetDMCIConfigParam](#cmd-1-17) | H | absent |  | X | • | • |
| [`12.1`](#cmd-12-1) | [12](#sec-11) | `0x2e` | `0x01` |  | [CmdResvExtendedConfigure](#cmd-12-1) | M | live ✓ |  | X | • | • |
| [`12.2`](#cmd-12-2) | [12](#sec-11) | `0x2e` | `0x02` |  | [CmdGetExtendedConfigure](#cmd-12-2) | ! | live ✓ |  | X | • | • |
| [`12.3`](#cmd-12-3) | [12](#sec-11) | `0x2e` | `0x03` |  | [CmdSetExtendedConfigure](#cmd-12-3) | M | live ✓ |  |  |  | X |
| [`15.7`](#cmd-15-7) | [15](#sec-14) | `0x2e` | `0x04` |  | [CmdPOSTEvent](#cmd-15-7) | M | live ✓ |  |  |  | X |
| [`11.5`](#cmd-11-5) | [11](#sec-10) | `0x2e` | `0x07` |  | [CmdTerminalSYS](#cmd-11-5) | H | absent |  | X | • | • |
| [`11.6`](#cmd-11-6) | [11](#sec-10) | `0x2e` | `0x08` |  | [CmdTerminalSYSDRAC](#cmd-11-6) | H | absent |  | X | • | • |
| [`14.1`](#cmd-14-1) | [14](#sec-13) | `0x2e` | `0x21` |  | [CmdResetToDefault](#cmd-14-1) | M | live ✓ |  |  |  | X |
| [`6.1`](#cmd-6-1) | [6](#sec-5) | `0x2e` | `0x40` | `0x40` | [DellNMCommand/0x40](#cmd-6-1) | M | live ✓ |  |  |  | X |
| [`6.2`](#cmd-6-2) | [6](#sec-5) | `0x2e` | `0x41` | `0x41` | [DellNMCommand/0x41](#cmd-6-2) | M | live ✓ |  |  |  | X |
| [`6.3`](#cmd-6-3) | [6](#sec-5) | `0x2e` | `0x42` | `0x42` | [DellNMCommand/0x42](#cmd-6-3) | M | live ✓ |  |  |  | X |
| [`6.4`](#cmd-6-4) | [6](#sec-5) | `0x2e` | `0x43` | `0x43` | [DellNMCommand/0x43](#cmd-6-4) | M | live ✓ |  |  |  | X |
| [`6.5`](#cmd-6-5) | [6](#sec-5) | `0x2e` | `0x44` | `0x44` | [DellNMCommand/0x44](#cmd-6-5) | M | live ✓ |  |  |  | X |
| [`6.6`](#cmd-6-6) | [6](#sec-5) | `0x2e` | `0x45` | `0x45` | [DellNMCommand/0x45](#cmd-6-6) | M | live ✓ |  |  |  | X |
| [`6.7`](#cmd-6-7) | [6](#sec-5) | `0x2e` | `0x46` | `0x46` | [DellNMCommand/0x46](#cmd-6-7) | M | live ✓ |  |  |  | X |
| [`6.8`](#cmd-6-8) | [6](#sec-5) | `0x2e` | `0x4b` | `0x4b` | [DellNMCommand/0x4b](#cmd-6-8) | M | live ✓ |  |  |  | X |
| [`6.9`](#cmd-6-9) | [6](#sec-5) | `0x2e` | `0x60` | `0x60` | [DellNMCommand/0x60](#cmd-6-9) | M | live ✓ |  |  |  | X |
| [`6.10`](#cmd-6-10) | [6](#sec-5) | `0x2e` | `0x61` | `0x61` | [DellNMCommand/0x61](#cmd-6-10) | M | live ✓ |  |  |  | X |
| [`6.11`](#cmd-6-11) | [6](#sec-5) | `0x2e` | `0x64` | `0x64` | [DellNMCommand/0x64](#cmd-6-11) | M | live ✓ |  |  |  | X |
| [`6.12`](#cmd-6-12) | [6](#sec-5) | `0x2e` | `0x65` | `0x65` | [DellNMCommand/0x65](#cmd-6-12) | M | live ✓ |  |  |  | X |
| [`6.13`](#cmd-6-13) | [6](#sec-5) | `0x2e` | `0x66` | `0x66` | [DellNMCommand/0x66](#cmd-6-13) | M | live ✓ |  |  |  | X |
| [`6.14`](#cmd-6-14) | [6](#sec-5) | `0x2e` | `0x67` | `0x67` | [DellNMCommand/0x67](#cmd-6-14) | M | live ✓ |  |  |  | X |
| [`6.15`](#cmd-6-15) | [6](#sec-5) | `0x2e` | `0x68` | `0x68` | [DellNMCommand/0x68](#cmd-6-15) | M | live ✓ |  |  |  | X |
| [`6.16`](#cmd-6-16) | [6](#sec-5) | `0x2e` | `0x69` | `0x69` | [DellNMCommand/0x69](#cmd-6-16) | M | live ✓ |  |  |  | X |
| [`6.17`](#cmd-6-17) | [6](#sec-5) | `0x2e` | `0x80` | `0x80` | [DellNMCommand/0x80](#cmd-6-17) | M | live ✓ |  |  |  | X |
| [`6.18`](#cmd-6-18) | [6](#sec-5) | `0x2e` | `0x81` | `0x81` | [DellNMCommand/0x81](#cmd-6-18) | M | live ✓ |  |  |  | X |
| [`6.19`](#cmd-6-19) | [6](#sec-5) | `0x2e` | `0x82` | `0x82` | [DellNMCommand/0x82](#cmd-6-19) | H | live ✓ |  |  |  | X |
| [`6.20`](#cmd-6-20) | [6](#sec-5) | `0x2e` | `0xa8` | `0xa8` | [DellNMCommand/0xa8](#cmd-6-20) | ! | live ✓ |  |  |  | X |
| [`6.21`](#cmd-6-21) | [6](#sec-5) | `0x2e` | `0xb7` | `0xb7` | [DellNMCommand/0xb7](#cmd-6-21) | M | live ✓ |  |  |  | X |
| [`6.22`](#cmd-6-22) | [6](#sec-5) | `0x2e` | `0xba` | `0xba` | [DellNMCommand/0xba](#cmd-6-22) | M | live ✓ |  |  |  | X |
| [`6.23`](#cmd-6-23) | [6](#sec-5) | `0x2e` | `0xc0` | `0xc0` | [DellNMCommand/0xc0](#cmd-6-23) | M | live ✓ |  |  |  | X |
| [`6.24`](#cmd-6-24) | [6](#sec-5) | `0x2e` | `0xc1` | `0xc1` | [DellNMCommand/0xc1](#cmd-6-24) | M | live ✓ |  |  |  | X |
| [`6.25`](#cmd-6-25) | [6](#sec-5) | `0x2e` | `0xc2` | `0xc2` | [DellNMCommand/0xc2](#cmd-6-25) | M | live ✓ |  |  |  | X |
| [`6.26`](#cmd-6-26) | [6](#sec-5) | `0x2e` | `0xc3` | `0xc3` | [DellNMCommand/0xc3](#cmd-6-26) | M | live ✓ |  |  |  | X |
| [`6.27`](#cmd-6-27) | [6](#sec-5) | `0x2e` | `0xc4` | `0xc4` | [DellNMCommand/0xc4](#cmd-6-27) | M | live ✓ |  |  |  | X |
| [`6.28`](#cmd-6-28) | [6](#sec-5) | `0x2e` | `0xc5` | `0xc5` | [DellNMCommand/0xc5](#cmd-6-28) | H | live ✓ |  |  |  | X |
| [`6.29`](#cmd-6-29) | [6](#sec-5) | `0x2e` | `0xc6` | `0xc6` | [DellNMCommand/0xc6](#cmd-6-29) | M | live ✓ |  |  |  | X |
| [`6.30`](#cmd-6-30) | [6](#sec-5) | `0x2e` | `0xc7` | `0xc7` | [DellNMCommand/0xc7](#cmd-6-30) | M | live ✓ |  |  |  | X |
| [`6.31`](#cmd-6-31) | [6](#sec-5) | `0x2e` | `0xc8` | `0xc8` | [DellNMCommand/0xc8](#cmd-6-31) | M | live ✓ |  |  |  | X |
| [`6.32`](#cmd-6-32) | [6](#sec-5) | `0x2e` | `0xc9` | `0xc9` | [DellNMCommand/0xc9](#cmd-6-32) | M | live ✓ |  |  |  | X |
| [`6.33`](#cmd-6-33) | [6](#sec-5) | `0x2e` | `0xca` | `0xca` | [DellNMCommand/0xca](#cmd-6-33) | M | live ✓ |  |  |  | X |
| [`6.34`](#cmd-6-34) | [6](#sec-5) | `0x2e` | `0xcb` | `0xcb` | [DellNMCommand/0xcb](#cmd-6-34) | M | live ✓ |  |  |  | X |
| [`14.2`](#cmd-14-2) | [14](#sec-13) | `0x2e` | `0xcc` | `0x06 0x00` | [CmdOSAOEMCmdHandler/CmdGetFWVersion](#cmd-14-2) | M | live ✓ | X | • | • | • |
| [`14.3`](#cmd-14-3) | [14](#sec-13) | `0x2e` | `0xcc` | `0x06 0x01` | [CmdOSAOEMCmdHandler/CmdGetFWID](#cmd-14-3) | M | live ✓ | X | • | • | • |
| [`14.4`](#cmd-14-4) | [14](#sec-13) | `0x2e` | `0xcc` | `0x06 0x40` | [CmdOSAOEMCmdHandler/CmdSetSysGUID](#cmd-14-4) | M | live ✓ | X | • | • | • |
| [`14.5`](#cmd-14-5) | [14](#sec-13) | `0x2e` | `0xcc` | `0x06 0x41` | [CmdOSAOEMCmdHandler/CmdSetBMCSA](#cmd-14-5) | M | live ✓ | X | • | • | • |
| [`14.6`](#cmd-14-6) | [14](#sec-13) | `0x2e` | `0xcc` | `0x06 0x42` | [CmdOSAOEMCmdHandler/CmdGetBMCSA](#cmd-14-6) | M | live ✓ | X | • | • | • |
| [`14.7`](#cmd-14-7) | [14](#sec-13) | `0x2e` | `0xcc` | `0x04 0x40` | [CmdOSAOEMCmdHandler/CmdSensorTest](#cmd-14-7) | M | live ✓ | X | • | • | • |
| [`14.8`](#cmd-14-8) | [14](#sec-13) | `0x2e` | `0xcc` | `0x0a 0x01` | [CmdOSAOEMCmdHandler/CmdResetToDefaultOSA](#cmd-14-8) | ! | live ✓ | X | • | • | • |
| [`14.9`](#cmd-14-9) | [14](#sec-13) | `0x2e` | `0xcc` | `0x10 0x00` | [CmdOSAOEMCmdHandler/CmdMemoryChk](#cmd-14-9) | ! | live ✓ | X | • | • | • |
| [`14.10`](#cmd-14-10) | [14](#sec-13) | `0x2e` | `0xcc` | `0x10 0x01` | [CmdOSAOEMCmdHandler/CmdGetDynaAllocMemorySize](#cmd-14-10) | M | live ✓ | X | • | • | • |
| [`6.35`](#cmd-6-35) | [6](#sec-5) | `0x2e` | `0xce` | `0xce` | [DellNMCommand/0xce](#cmd-6-35) | M | live ✓ |  |  |  | X |
| [`6.36`](#cmd-6-36) | [6](#sec-5) | `0x2e` | `0xcf` | `0xcf` | [DellNMCommand/0xcf](#cmd-6-36) | M | live ✓ |  |  |  | X |
| [`6.37`](#cmd-6-37) | [6](#sec-5) | `0x2e` | `0xd0` | `0xd0` | [DellNMCommand/0xd0](#cmd-6-37) | M | live ✓ |  |  |  | X |
| [`6.38`](#cmd-6-38) | [6](#sec-5) | `0x2e` | `0xd1` | `0xd1` | [DellNMCommand/0xd1](#cmd-6-38) | M | live ✓ |  |  |  | X |
| [`6.39`](#cmd-6-39) | [6](#sec-5) | `0x2e` | `0xd2` | `0xd2` | [DellNMCommand/0xd2](#cmd-6-39) | M | live ✓ |  |  |  | X |
| [`6.40`](#cmd-6-40) | [6](#sec-5) | `0x2e` | `0xd3` | `0xd3` | [DellNMCommand/0xd3](#cmd-6-40) | M | live ✓ |  |  |  | X |
| [`6.41`](#cmd-6-41) | [6](#sec-5) | `0x2e` | `0xd4` | `0xd4` | [DellNMCommand/0xd4](#cmd-6-41) | M | live ✓ |  |  |  | X |
| [`6.42`](#cmd-6-42) | [6](#sec-5) | `0x2e` | `0xd7` | `0xd7` | [DellNMCommand/0xd7](#cmd-6-42) | M | live ✓ |  |  |  | X |
| [`6.43`](#cmd-6-43) | [6](#sec-5) | `0x2e` | `0xd8` | `0xd8` | [DellNMCommand/0xd8](#cmd-6-43) | M | live ✓ |  |  |  | X |
| [`6.44`](#cmd-6-44) | [6](#sec-5) | `0x2e` | `0xd9` | `0xd9` | [DellNMCommand/0xd9](#cmd-6-44) | H | live ✓ |  |  |  | X |
| [`6.45`](#cmd-6-45) | [6](#sec-5) | `0x2e` | `0xdc` | `0xdc` | [DellNMCommand/0xdc](#cmd-6-45) | M | live ✓ |  |  |  | X |
| [`6.46`](#cmd-6-46) | [6](#sec-5) | `0x2e` | `0xdf` | `0xdf` | [DellNMCommand/0xdf](#cmd-6-46) | M | live ✓ |  |  |  | X |
| [`15.8`](#cmd-15-8) | [15](#sec-14) | `0x2e` | `0xe0` |  | [DellCmdNodeMgrDebugInfo](#cmd-15-8) | M | live ✓ |  |  |  | X |
| [`15.9`](#cmd-15-9) | [15](#sec-14) | `0x2e` | `0xe1` |  | [DellCmdNodeMgrSendRaw](#cmd-15-9) | M | live ✓ |  |  |  | X |
| [`6.47`](#cmd-6-47) | [6](#sec-5) | `0x2e` | `0xea` |  | [DellNMCommand/PowerBudget](#cmd-6-47) | M | live ✓ |  |  |  | X |
| [`6.48`](#cmd-6-48) | [6](#sec-5) | `0x2e` | `0xf0` |  | [DellNMCommand/SNMPAlertTrapDest](#cmd-6-48) | M | live ✓ |  |  |  | X |
| [`6.49`](#cmd-6-49) | [6](#sec-5) | `0x2e` | `0xf1` |  | [DellNMCommand/0xf1](#cmd-6-49) | M | live ✓ |  |  |  | X |
| [`6.50`](#cmd-6-50) | [6](#sec-5) | `0x2e` | `0xf2` |  | [DellNMCommand/CMCInfo](#cmd-6-50) | M | live ✓ |  |  |  | X |
| [`6.51`](#cmd-6-51) | [6](#sec-5) | `0x2e` | `0xf3` |  | [DellNMCommand/SysInfoParam243](#cmd-6-51) | M | live ✓ |  |  |  | X |
| [`6.52`](#cmd-6-52) | [6](#sec-5) | `0x2e` | `0xf4` |  | [DellNMCommand/SystemRevision](#cmd-6-52) | M | live ✓ |  |  |  | X |
| [`6.53`](#cmd-6-53) | [6](#sec-5) | `0x2e` | `0xf5` |  | [DellNMCommand/0xf5](#cmd-6-53) | M | live ✓ |  |  |  | X |
| [`6.54`](#cmd-6-54) | [6](#sec-5) | `0x2e` | `0xf6` |  | [DellNMCommand/NodeIDInfo](#cmd-6-54) | M | live ✓ |  |  |  | X |
| [`5.1`](#cmd-5-1) | [5](#sec-4) | `0x30` | `0x11` |  | [DellDCSSCBMCWrapper/0x11](#cmd-5-1) | M | live ✓ |  |  |  | X |
| [`5.2`](#cmd-5-2) | [5](#sec-4) | `0x30` | `0x12` |  | [DellDCSSCBMCWrapper/0x12](#cmd-5-2) | M | gated |  |  |  | X |
| [`5.3`](#cmd-5-3) | [5](#sec-4) | `0x30` | `0x13` |  | [DellDCSSCBMCWrapper/0x13](#cmd-5-3) | M | live ✓ |  |  |  | X |
| [`5.4`](#cmd-5-4) | [5](#sec-4) | `0x30` | `0x14` |  | [DellDCSSCBMCWrapper/0x14](#cmd-5-4) | M | gated |  |  |  | X |
| [`5.5`](#cmd-5-5) | [5](#sec-4) | `0x30` | `0x15` |  | [DellDCSSCBMCWrapper/0x15](#cmd-5-5) | M | live ✓ |  |  |  | X |
| [`5.6`](#cmd-5-6) | [5](#sec-4) | `0x30` | `0x16` |  | [DellDCSSCBMCWrapper/0x16](#cmd-5-6) | M | gated |  |  |  | X |
| [`5.7`](#cmd-5-7) | [5](#sec-4) | `0x30` | `0x17` |  | [DellDCSSCBMCWrapper/0x17](#cmd-5-7) | M | live ✓ |  |  |  | X |
| [`9.9`](#cmd-9-9) | [9](#sec-8) | `0x30` | `0x18` |  | [DellCmdGetBladeSlotId](#cmd-9-9) | M | live ✓ |  |  |  | X |
| [`5.8`](#cmd-5-8) | [5](#sec-4) | `0x30` | `0x19` |  | [DellDCSSCBMCWrapper/0x19](#cmd-5-8) | ! | live ✓ |  |  |  | X |
| [`5.9`](#cmd-5-9) | [5](#sec-4) | `0x30` | `0x1a` |  | [DellDCSSCBMCWrapper](#cmd-5-9) | M | gated |  |  |  | X |
| [`5.10`](#cmd-5-10) | [5](#sec-4) | `0x30` | `0x1b` |  | [DellDCSSCBMCWrapper](#cmd-5-10) | M | live ✓ |  |  |  | X |
| [`10.6`](#cmd-10-6) | [10](#sec-9) | `0x30` | `0x1c` |  | [DellCmdReadWriteFrontPanel](#cmd-10-6) | M | live ✓ |  |  |  | X |
| [`5.11`](#cmd-5-11) | [5](#sec-4) | `0x30` | `0x1d` |  | [DellDCSSCBMCWrapper](#cmd-5-11) | M | live ✓ |  |  |  | X |
| [`5.12`](#cmd-5-12) | [5](#sec-4) | `0x30` | `0x1e` |  | [DellDCSSCBMCWrapper](#cmd-5-12) | M | live ✓ |  |  |  | X |
| [`5.13`](#cmd-5-13) | [5](#sec-4) | `0x30` | `0x1f` |  | [DellDCSSCBMCWrapper](#cmd-5-13) | M | gated |  |  |  | X |
| [`5.14`](#cmd-5-14) | [5](#sec-4) | `0x30` | `0x20` |  | [DellDCSSCBMCWrapper](#cmd-5-14) | M | live ✓ |  |  |  | X |
| [`14.11`](#cmd-14-11) | [14](#sec-13) | `0x30` | `0x21` |  | [CmdResetToDefault](#cmd-14-11) | M | live ✓ |  |  |  | X |
| [`5.15`](#cmd-5-15) | [5](#sec-4) | `0x30` | `0x22` |  | [DellDCSSCBMCWrapper](#cmd-5-15) | M | live ✓ |  |  |  | X |
| [`5.16`](#cmd-5-16) | [5](#sec-4) | `0x30` | `0x23` |  | [DellDCSSCBMCWrapper](#cmd-5-16) | M | gated |  |  |  | X |
| [`15.10`](#cmd-15-10) | [15](#sec-14) | `0x30` | `0x24` |  | [DellSetTeamingMode](#cmd-15-10) | M | live ✓ |  |  |  | X |
| [`5.17`](#cmd-5-17) | [5](#sec-4) | `0x30` | `0x25` |  | [DellDCSSCBMCWrapper](#cmd-5-17) | M | gated |  |  |  | X |
| [`5.18`](#cmd-5-18) | [5](#sec-4) | `0x30` | `0x26` |  | [DellDCSSCBMCWrapper](#cmd-5-18) | M | live ✓ |  |  |  | X |
| [`6.55`](#cmd-6-55) | [6](#sec-5) | `0x30` | `0x26` | `0xc0` | [DellNMCommand/0xC0](#cmd-6-55) | M | live ✓ |  |  |  | X |
| [`6.56`](#cmd-6-56) | [6](#sec-5) | `0x30` | `0x26` | `0xc1` | [DellNMCommand/0xC1](#cmd-6-56) | M | live ✓ |  |  |  | X |
| [`6.57`](#cmd-6-57) | [6](#sec-5) | `0x30` | `0x26` | `0xc2` | [DellNMCommand/0xC2](#cmd-6-57) | M | live ✓ |  |  |  | X |
| [`6.58`](#cmd-6-58) | [6](#sec-5) | `0x30` | `0x26` | `0xc7` | [DellNMCommand/0xC7](#cmd-6-58) | M | live ✓ |  |  |  | X |
| [`6.59`](#cmd-6-59) | [6](#sec-5) | `0x30` | `0x26` | `0xc8` | [DellNMCommand/0xC8](#cmd-6-59) | M | live ✓ |  |  |  | X |
| [`6.60`](#cmd-6-60) | [6](#sec-5) | `0x30` | `0x26` | `0xc9` | [DellNMCommand/0xC9](#cmd-6-60) | M | live ✓ |  |  |  | X |
| [`6.61`](#cmd-6-61) | [6](#sec-5) | `0x30` | `0x26` | `0xca` | [DellNMCommand/0xCA](#cmd-6-61) | M | live ✓ |  |  |  | X |
| [`6.62`](#cmd-6-62) | [6](#sec-5) | `0x30` | `0x26` | `0xcb` | [DellNMCommand/0xCB](#cmd-6-62) | M | live ✓ |  |  |  | X |
| [`6.63`](#cmd-6-63) | [6](#sec-5) | `0x30` | `0x26` | `0xce` | [DellNMCommand/0xCE](#cmd-6-63) | M | live ✓ |  |  |  | X |
| [`6.64`](#cmd-6-64) | [6](#sec-5) | `0x30` | `0x26` | `0xd0` | [DellNMCommand/0xD0](#cmd-6-64) | M | live ✓ |  |  |  | X |
| [`12.4`](#cmd-12-4) | [12](#sec-11) | `0x30` | `0x27` |  | [DellGetInternalVariable](#cmd-12-4) | M | live ✓ |  |  |  | X |
| [`15.11`](#cmd-15-11) | [15](#sec-14) | `0x30` | `0x28` |  | [CmdSetNICSelectionFailover](#cmd-15-11) | M | live ✓ |  |  |  | X |
| [`15.12`](#cmd-15-12) | [15](#sec-14) | `0x30` | `0x29` |  | [CmdGetNICSelectionFailover](#cmd-15-12) | M | live ✓ |  |  |  | X |
| [`5.19`](#cmd-5-19) | [5](#sec-4) | `0x30` | `0x2a` |  | [DellDCSSCBMCWrapper](#cmd-5-19) | M | live ✓ |  |  |  | X |
| [`5.20`](#cmd-5-20) | [5](#sec-4) | `0x30` | `0x2b` |  | [DellDCSSCBMCWrapper](#cmd-5-20) | M | gated |  |  |  | X |
| [`5.21`](#cmd-5-21) | [5](#sec-4) | `0x30` | `0x2c` |  | [DellDCSSCBMCWrapper](#cmd-5-21) | M | gated |  |  |  | X |
| [`5.22`](#cmd-5-22) | [5](#sec-4) | `0x30` | `0x2d` |  | [DellDCSSCBMCWrapper](#cmd-5-22) | M | gated |  |  |  | X |
| [`5.23`](#cmd-5-23) | [5](#sec-4) | `0x30` | `0x2e` |  | [DellDCSSCBMCWrapper](#cmd-5-23) | M | gated |  |  |  | X |
| [`5.24`](#cmd-5-24) | [5](#sec-4) | `0x30` | `0x2f` |  | [DellDCSSCBMCWrapper](#cmd-5-24) | H | gated |  |  |  | X |
| [`6.65`](#cmd-6-65) | [6](#sec-5) | `0x30` | `0x30` |  | [DellSetFanControlParameters](#cmd-6-65) | M | live ✓ |  |  |  | X |
| [`6.66`](#cmd-6-66) | [6](#sec-5) | `0x30` | `0x31` |  | [DellGetFanControlParameters](#cmd-6-66) | M | live ✓ |  |  |  | X |
| [`10.7`](#cmd-10-7) | [10](#sec-9) | `0x30` | `0x32` |  | [DellQueryChassisIdentifyStatus](#cmd-10-7) | M | live ✓ |  | X | • | • |
| [`15.13`](#cmd-15-13) | [15](#sec-14) | `0x30` | `0x33` |  | [DellQueryGetCPLDRevision](#cmd-15-13) | H | live ✓ |  | X | • | • |
| [`6.67`](#cmd-6-67) | [6](#sec-5) | `0x30` | `0x35` |  | [DellCmdFreshAir](#cmd-6-67) | M | live ✓ |  | X | • | • |
| [`13.1`](#cmd-13-1) | [13](#sec-12) | `0x30` | `0x36` |  | [DellPcieSSDFRU](#cmd-13-1) | M | live ✓ |  | X | • | • |
| [`5.25`](#cmd-5-25) | [5](#sec-4) | `0x30` | `0x44` |  | [DellDCSSCBMCWrapper](#cmd-5-25) | M | live ✓ |  |  |  | X |
| [`5.26`](#cmd-5-26) | [5](#sec-4) | `0x30` | `0x48` |  | [DellDCSSCBMCWrapper](#cmd-5-26) | M | live ✓ |  |  |  | X |
| [`5.27`](#cmd-5-27) | [5](#sec-4) | `0x30` | `0x49` |  | [DellDCSSCBMCWrapper](#cmd-5-27) | M | gated |  |  |  | X |
| [`5.28`](#cmd-5-28) | [5](#sec-4) | `0x30` | `0x4a` |  | [DellDCSSCBMCWrapper](#cmd-5-28) | M | live ✓ |  |  |  | X |
| [`5.29`](#cmd-5-29) | [5](#sec-4) | `0x30` | `0x4b` |  | [DellDCSSCBMCWrapper](#cmd-5-29) | M | live ✓ |  |  |  | X |
| [`5.30`](#cmd-5-30) | [5](#sec-4) | `0x30` | `0x4c` |  | [DellDCSSCBMCWrapper](#cmd-5-30) | M | live ✓ |  |  |  | X |
| [`5.31`](#cmd-5-31) | [5](#sec-4) | `0x30` | `0x4d` |  | [DellDCSSCBMCWrapper](#cmd-5-31) | M | gated |  |  |  | X |
| [`9.10`](#cmd-9-10) | [9](#sec-8) | `0x30` | `0x51` |  | [DellCmdGetHostEventStatus](#cmd-9-10) | M | live ✓ |  |  |  | X |
| [`6.68`](#cmd-6-68) | [6](#sec-5) | `0x30` | `0x87` |  | [DellCmdServerPwrOnResponse](#cmd-6-68) | M | live ✓ |  |  |  | X |
| [`6.69`](#cmd-6-69) | [6](#sec-5) | `0x30` | `0x8c` |  | [DellCmdRequestedAirflow](#cmd-6-69) | M | absent |  |  |  | X |
| [`9.11`](#cmd-9-11) | [9](#sec-8) | `0x30` | `0x8d` |  | [DellCmdVKVMStatus](#cmd-9-11) | M | absent |  |  |  | X |
| [`9.12`](#cmd-9-12) | [9](#sec-8) | `0x30` | `0x8e` |  | [DellCmdVMediaStatus](#cmd-9-12) | M | absent |  |  |  | X |
| [`6.70`](#cmd-6-70) | [6](#sec-5) | `0x30` | `0x8f` |  | [DellCmdServerPwrConsumption](#cmd-6-70) | M | absent |  |  |  | X |
| [`9.13`](#cmd-9-13) | [9](#sec-8) | `0x30` | `0x90` |  | [DellCmdGetIMCStatusRegister](#cmd-9-13) | H | absent |  |  |  | X |
| [`9.14`](#cmd-9-14) | [9](#sec-8) | `0x30` | `0x91` |  | [DellCmdIMCFirmwareUpdate](#cmd-9-14) | H | live ✓ |  |  |  | X |
| [`9.15`](#cmd-9-15) | [9](#sec-8) | `0x30` | `0x92` |  | [DellCmdEDIDInfo](#cmd-9-15) | M | live ✓ |  |  |  | X |
| [`9.16`](#cmd-9-16) | [9](#sec-8) | `0x30` | `0x93` |  | [DellCmdLCDReadFromStaging](#cmd-9-16) | M | live ✓ |  | X | • | • |
| [`9.17`](#cmd-9-17) | [9](#sec-8) | `0x30` | `0x94` |  | [DellCmdLCDReadFromQueue](#cmd-9-17) | M | live ✓ |  | X | • | • |
| [`6.71`](#cmd-6-71) | [6](#sec-5) | `0x30` | `0x95` |  | [DellCmdChassisFanStatus](#cmd-6-71) | M | live ✓ |  |  |  | X |
| [`9.18`](#cmd-9-18) | [9](#sec-8) | `0x30` | `0x96` |  | [DellCmdLoginAccess](#cmd-9-18) | ! | live ✓ |  |  |  | X |
| [`9.19`](#cmd-9-19) | [9](#sec-8) | `0x30` | `0x97` |  | [DellCmdSetIMCStatusRegister](#cmd-9-19) | M | live ✓ |  |  |  | X |
| [`9.20`](#cmd-9-20) | [9](#sec-8) | `0x30` | `0x98` |  | [DellCmdLEDStatus](#cmd-9-20) | M | live ✓ |  |  |  | X |
| [`9.21`](#cmd-9-21) | [9](#sec-8) | `0x30` | `0x99` |  | [DellCmdGetLastPostCode](#cmd-9-21) | M | live ✓ |  |  |  | X |
| [`9.22`](#cmd-9-22) | [9](#sec-8) | `0x30` | `0x9a` |  | [DellCmdMemThrottlingCtrl](#cmd-9-22) | M | live ✓ |  |  |  | X |
| [`6.72`](#cmd-6-72) | [6](#sec-5) | `0x30` | `0x9b` |  | [DellCmdGetPowerCycleInterval](#cmd-6-72) | H | live ✓ |  |  |  | X |
| [`6.73`](#cmd-6-73) | [6](#sec-5) | `0x30` | `0x9c` |  | [DellPwrGetPwrConsumptionData](#cmd-6-73) | M | live ✓ |  | X | • | • |
| [`6.74`](#cmd-6-74) | [6](#sec-5) | `0x30` | `0x9d` |  | [DellPwrResetPwrConsumptionData](#cmd-6-74) | ! | live ✓ |  |  |  | X |
| [`6.75`](#cmd-6-75) | [6](#sec-5) | `0x30` | `0x9e` |  | [DellCmdBladeACPowerCycle](#cmd-6-75) | H | live ✓ |  |  |  | X |
| [`15.14`](#cmd-15-14) | [15](#sec-14) | `0x30` | `0x9f` |  | [DellCmdSpecialACCycle](#cmd-15-14) | H | absent |  |  |  | X |
| [`15.15`](#cmd-15-15) | [15](#sec-14) | `0x30` | `0xa0` |  | [CmdGetSoftLockStatus](#cmd-15-15) | M | live ✓ |  | X | • | • |
| [`3.1`](#cmd-3-1) | [3](#sec-2) | `0x30` | `0xa1` | `0x00` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERGetProvOptions](#cmd-3-1) | M | live ✓ |  | X | • | • |
| [`3.2`](#cmd-3-2) | [3](#sec-2) | `0x30` | `0xa1` | `0x01` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERSetSystemReq](#cmd-3-2) | M | live ✓ |  | X | • | • |
| [`3.3`](#cmd-3-3) | [3](#sec-2) | `0x30` | `0xa1` | `0x02` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERAttachPartition](#cmd-3-3) | M | live ✓ |  | X | • | • |
| [`3.4`](#cmd-3-4) | [3](#sec-2) | `0x30` | `0xa1` | `0x03` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERDetachPartition](#cmd-3-4) | M | live ✓ |  | X | • | • |
| [`3.5`](#cmd-3-5) | [3](#sec-2) | `0x30` | `0xa1` | `0x04` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTLogLCLEvent](#cmd-3-5) | H | live ✓ |  | X | • | • |
| [`3.6`](#cmd-3-6) | [3](#sec-2) | `0x30` | `0xa1` | `0x05` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTGetBootVolLabel](#cmd-3-6) | M | live ✓ |  | X | • | • |
| [`3.7`](#cmd-3-7) | [3](#sec-2) | `0x30` | `0xa1` | `0x06` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTSetBIOSPassword](#cmd-3-7) | ! | live ✓ |  | X | • | • |
| [`3.8`](#cmd-3-8) | [3](#sec-2) | `0x30` | `0xa1` | `0x07` | [CmdOEMPOSTMASERAccess/CmdOEMPOSTSetBIOSSHAPassword](#cmd-3-8) | ! | live ✓ |  | X | • | • |
| [`3.9`](#cmd-3-9) | [3](#sec-2) | `0x30` | `0xa2` | `0x00` | [CmdOEMMASERPartitionAccess/CmdOEMLockMASER](#cmd-3-9) | M | live ✓ |  |  |  | X |
| [`3.10`](#cmd-3-10) | [3](#sec-2) | `0x30` | `0xa2` | `0x01` | [CmdOEMMASERPartitionAccess/CmdOEMUnLockMASER](#cmd-3-10) | M | live ✓ |  |  |  | X |
| [`3.11`](#cmd-3-11) | [3](#sec-2) | `0x30` | `0xa2` | `0x02` | [CmdOEMMASERPartitionAccess/CmdOEMMASERLockWDreset](#cmd-3-11) | M | live ✓ |  |  |  | X |
| [`3.12`](#cmd-3-12) | [3](#sec-2) | `0x30` | `0xa2` | `0x03` | [CmdOEMMASERPartitionAccess/CmdOEMGetPartitionIndexInfo](#cmd-3-12) | M | live ✓ |  |  |  | X |
| [`3.13`](#cmd-3-13) | [3](#sec-2) | `0x30` | `0xa2` | `0x04` | [CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfo](#cmd-3-13) | M | live ✓ |  |  |  | X |
| [`3.14`](#cmd-3-14) | [3](#sec-2) | `0x30` | `0xa2` | `0x05` | [CmdOEMMASERPartitionAccess/CmdOEMAttachPartitions](#cmd-3-14) | M | live ✓ |  |  |  | X |
| [`3.15`](#cmd-3-15) | [3](#sec-2) | `0x30` | `0xa2` | `0x06` | [CmdOEMMASERPartitionAccess/CmdOEMDetachPartitions](#cmd-3-15) | M | live ✓ |  |  |  | X |
| [`3.16`](#cmd-3-16) | [3](#sec-2) | `0x30` | `0xa2` | `0x07` | [CmdOEMMASERPartitionAccess/CmdOEMCreateDynamicPartition](#cmd-3-16) | M | live ✓ |  |  |  | X |
| [`3.17`](#cmd-3-17) | [3](#sec-2) | `0x30` | `0xa2` | `0x08` | [CmdOEMMASERPartitionAccess/CmdOEMDeleteDynamicPartition](#cmd-3-17) | H | live ✓ |  |  |  | X |
| [`3.18`](#cmd-3-18) | [3](#sec-2) | `0x30` | `0xa2` | `0x09` | [CmdOEMMASERPartitionAccess/CmdOEMSecureUpdatePartition](#cmd-3-18) | ! | live ✓ |  |  |  | X |
| [`3.19`](#cmd-3-19) | [3](#sec-2) | `0x30` | `0xa2` | `0x0a` | [CmdOEMMASERPartitionAccess/CmdOEMCheckMASER_IPMIcmdStatus](#cmd-3-19) | M | live ✓ |  |  |  | X |
| [`3.20`](#cmd-3-20) | [3](#sec-2) | `0x30` | `0xa2` | `0x0b` | [CmdOEMMASERPartitionAccess/CmdOEMChangePartitionAccessType](#cmd-3-20) | H | live ✓ |  |  |  | X |
| [`3.21`](#cmd-3-21) | [3](#sec-2) | `0x30` | `0xa2` | `0x0c` | [CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfoByName](#cmd-3-21) | M | live ✓ |  |  |  | X |
| [`3.22`](#cmd-3-22) | [3](#sec-2) | `0x30` | `0xa2` | `0x10` | [CmdOEMMASERPartitionAccess/CmdOEMGetUEFIFlag](#cmd-3-22) | H | live ✓ |  |  |  | X |
| [`3.23`](#cmd-3-23) | [3](#sec-2) | `0x30` | `0xa2` | `0x11` | [CmdOEMMASERPartitionAccess/CmdOEMSetUEFIFlag](#cmd-3-23) | H | live ✓ |  |  |  | X |
| [`3.24`](#cmd-3-24) | [3](#sec-2) | `0x30` | `0xa2` | `0x12` | [CmdOEMMASERPartitionAccess/CmdOEMLockMASER_LockACK](#cmd-3-24) | M | live ✓ |  |  |  | X |
| [`3.25`](#cmd-3-25) | [3](#sec-2) | `0x30` | `0xa2` | `0x13` | [CmdOEMMASERPartitionAccess/CmdOEMAck](#cmd-3-25) | M | live ✓ |  |  |  | X |
| [`3.26`](#cmd-3-26) | [3](#sec-2) | `0x30` | `0xa2` | `0x14` | [CmdOEMMASERPartitionAccess/CmdOEMLCLWipe](#cmd-3-26) | ! | live ✓ |  |  |  | X |
| [`3.27`](#cmd-3-27) | [3](#sec-2) | `0x30` | `0xa2` | `0x15` | [CmdOEMMASERPartitionAccess/CmdOEMUtility_Request](#cmd-3-27) | M | live ✓ |  |  |  | X |
| [`3.28`](#cmd-3-28) | [3](#sec-2) | `0x30` | `0xa2` | `0x16` | [CmdOEMMASERPartitionAccess/CmdOEMUtility_Status](#cmd-3-28) | M | live ✓ |  |  |  | X |
| [`3.29`](#cmd-3-29) | [3](#sec-2) | `0x30` | `0xa2` | `0x20` | [CmdOEMMASERPartitionAccess/CmdOEMBeginSECUPD](#cmd-3-29) | H | live ✓ |  |  |  | X |
| [`3.30`](#cmd-3-30) | [3](#sec-2) | `0x30` | `0xa2` | `0x21` | [CmdOEMMASERPartitionAccess/CmdOEMStartSECUPD_PM](#cmd-3-30) | H | live ✓ |  |  |  | X |
| [`3.31`](#cmd-3-31) | [3](#sec-2) | `0x30` | `0xa2` | `0x22` | [CmdOEMMASERPartitionAccess/CmdOEMProcessSECUPD](#cmd-3-31) | H | live ✓ |  |  |  | X |
| [`3.32`](#cmd-3-32) | [3](#sec-2) | `0x30` | `0xa2` | `0x23` | [CmdOEMMASERPartitionAccess/CmdOEMEndSECUPD](#cmd-3-32) | H | live ✓ |  |  |  | X |
| [`3.33`](#cmd-3-33) | [3](#sec-2) | `0x30` | `0xa2` | `0x24` | [CmdOEMMASERPartitionAccess/CmdOEMADByName](#cmd-3-33) | M | live ✓ |  |  |  | X |
| [`3.34`](#cmd-3-34) | [3](#sec-2) | `0x30` | `0xa2` | `0x26` | [CmdOEMMASERPartitionAccess/CmdOEMSingleIPMI](#cmd-3-34) | M | live ✓ |  |  |  | X |
| [`3.35`](#cmd-3-35) | [3](#sec-2) | `0x30` | `0xa2` | `0x27` | [CmdOEMMASERPartitionAccess/CmdOEMGetPkgCacheUpdateFlag](#cmd-3-35) | M | live ✓ |  |  |  | X |
| [`3.36`](#cmd-3-36) | [3](#sec-2) | `0x30` | `0xa3` | `0x00` | [CmdOEMRemoteEnablement/GetAutoDiscovery](#cmd-3-36) | L | live ✓ |  | X | • | • |
| [`3.37`](#cmd-3-37) | [3](#sec-2) | `0x30` | `0xa3` | `0x01` | [CmdOEMRemoteEnablement/SetAutoDiscovery](#cmd-3-37) | M | live ✓ |  | X | • | • |
| [`3.38`](#cmd-3-38) | [3](#sec-2) | `0x30` | `0xa3` | `0x02` | [CmdOEMRemoteEnablement/SignCertificate](#cmd-3-38) | M | live ✓ |  | X | • | • |
| [`3.39`](#cmd-3-39) | [3](#sec-2) | `0x30` | `0xa3` | `0x03` | [CmdOEMRemoteEnablement/GetCertificateStatus](#cmd-3-39) | L | live ✓ |  | X | • | • |
| [`3.40`](#cmd-3-40) | [3](#sec-2) | `0x30` | `0xa3` | `0x04` | [CmdOEMRemoteEnablement/GetRECapabilitiesBitmap](#cmd-3-40) | L | live ✓ |  | X | • | • |
| [`3.41`](#cmd-3-41) | [3](#sec-2) | `0x30` | `0xa3` | `0x05` | [CmdOEMRemoteEnablement/SetRECapabilitiesBitmap](#cmd-3-41) | M | live ✓ |  | X | • | • |
| [`3.42`](#cmd-3-42) | [3](#sec-2) | `0x30` | `0xa3` | `0x06` | [CmdOEMRemoteEnablement/GetProvisioningServerInfo](#cmd-3-42) | L | live ✓ |  | X | • | • |
| [`3.43`](#cmd-3-43) | [3](#sec-2) | `0x30` | `0xa3` | `0x07` | [CmdOEMRemoteEnablement/SetProvisioningServerInfo](#cmd-3-43) | M | live ✓ |  | X | • | • |
| [`3.44`](#cmd-3-44) | [3](#sec-2) | `0x30` | `0xa3` | `0x08` | [CmdOEMRemoteEnablement/GetDiscoveryRestartOptions](#cmd-3-44) | L | live ✓ |  | X | • | • |
| [`3.45`](#cmd-3-45) | [3](#sec-2) | `0x30` | `0xa3` | `0x09` | [CmdOEMRemoteEnablement/SetDiscoveryRestartOptions](#cmd-3-45) | M | live ✓ |  | X | • | • |
| [`3.46`](#cmd-3-46) | [3](#sec-2) | `0x30` | `0xa3` | `0x0a` | [CmdOEMRemoteEnablement/GetCCRFeatureState](#cmd-3-46) | L | live ✓ |  | X | • | • |
| [`3.47`](#cmd-3-47) | [3](#sec-2) | `0x30` | `0xa3` | `0x0b` | [CmdOEMRemoteEnablement/SetCCRFeatureState](#cmd-3-47) | M | live ✓ |  | X | • | • |
| [`3.48`](#cmd-3-48) | [3](#sec-2) | `0x30` | `0xa3` | `0x0c` | [CmdOEMRemoteEnablement/GetCCRUpdateFWMode](#cmd-3-48) | L | live ✓ |  | X | • | • |
| [`3.49`](#cmd-3-49) | [3](#sec-2) | `0x30` | `0xa3` | `0x0d` | [CmdOEMRemoteEnablement/SetCCRUpdateFWMode](#cmd-3-49) | M | live ✓ |  | X | • | • |
| [`3.50`](#cmd-3-50) | [3](#sec-2) | `0x30` | `0xa3` | `0x0e` | [CmdOEMRemoteEnablement/GetCCRConfigurationState](#cmd-3-50) | L | live ✓ |  | X | • | • |
| [`3.51`](#cmd-3-51) | [3](#sec-2) | `0x30` | `0xa3` | `0x0f` | [CmdOEMRemoteEnablement/SetCCRConfigurationState](#cmd-3-51) | M | live ✓ |  | X | • | • |
| [`3.52`](#cmd-3-52) | [3](#sec-2) | `0x30` | `0xa3` | `0x10` | [CmdOEMRemoteEnablement/GetCCRAutoSyncState](#cmd-3-52) | L | live ✓ |  | X | • | • |
| [`3.53`](#cmd-3-53) | [3](#sec-2) | `0x30` | `0xa3` | `0x11` | [CmdOEMRemoteEnablement/SetCCRAutoSyncState](#cmd-3-53) | M | live ✓ |  | X | • | • |
| [`3.54`](#cmd-3-54) | [3](#sec-2) | `0x30` | `0xa3` | `0x12` | [CmdOEMRemoteEnablement/GetDHStatus](#cmd-3-54) | L | live ✓ |  | X | • | • |
| [`3.55`](#cmd-3-55) | [3](#sec-2) | `0x30` | `0xa3` | `0x13` | [CmdOEMRemoteEnablement/RemoveCertificate](#cmd-3-55) | M | live ✓ |  | X | • | • |
| [`3.56`](#cmd-3-56) | [3](#sec-2) | `0x30` | `0xa3` | `0x14` | [CmdOEMRemoteEnablement/SkipISOBoot](#cmd-3-56) | M | live ✓ |  | X | • | • |
| [`3.57`](#cmd-3-57) | [3](#sec-2) | `0x30` | `0xa3` | `0x15` | [CmdOEMRemoteEnablement/DisconnectNetworkISO](#cmd-3-57) | M | live ✓ |  | X | • | • |
| [`3.58`](#cmd-3-58) | [3](#sec-2) | `0x30` | `0xa3` | `0x16` | [CmdOEMRemoteEnablement/ChangeRFSToAttachMode](#cmd-3-58) | M | live ✓ |  | X | • | • |
| [`3.59`](#cmd-3-59) | [3](#sec-2) | `0x30` | `0xa3` | `0x17` | [CmdOEMRemoteEnablement/ReCapabilityForDup](#cmd-3-59) | M | live ✓ |  | X | • | • |
| [`3.60`](#cmd-3-60) | [3](#sec-2) | `0x30` | `0xa3` | `0xfffffff0` | [CmdOEMRemoteEnablement/UEFILOGService](#cmd-3-60) | M | live ✓ |  | X | • | • |
| [`3.61`](#cmd-3-61) | [3](#sec-2) | `0x30` | `0xa4` | `0x00` | [CmdOEMvFlash/GetCardInfo](#cmd-3-61) | L | live ✓ |  | X | • | • |
| [`3.62`](#cmd-3-62) | [3](#sec-2) | `0x30` | `0xa4` | `0x01` | [CmdOEMvFlash/CardControl](#cmd-3-62) | M | live ✓ |  | X | • | • |
| [`3.63`](#cmd-3-63) | [3](#sec-2) | `0x30` | `0xa4` | `0x10` | [CmdOEMvFlash/GetPartitionIndexInfo](#cmd-3-63) | L | live ✓ |  | X | • | • |
| [`3.64`](#cmd-3-64) | [3](#sec-2) | `0x30` | `0xa4` | `0x11` | [CmdOEMvFlash/GetPartitionInfo](#cmd-3-64) | L | live ✓ |  | X | • | • |
| [`3.65`](#cmd-3-65) | [3](#sec-2) | `0x30` | `0xa4` | `0x12` | [CmdOEMvFlash/AttachPartitions](#cmd-3-65) | M | live ✓ |  | X | • | • |
| [`3.66`](#cmd-3-66) | [3](#sec-2) | `0x30` | `0xa4` | `0x13` | [CmdOEMvFlash/DetachPartitions](#cmd-3-66) | M | live ✓ |  | X | • | • |
| [`3.67`](#cmd-3-67) | [3](#sec-2) | `0x30` | `0xa4` | `0x14` | [CmdOEMvFlash/SetBootPartition](#cmd-3-67) | H | live ✓ |  | X | • | • |
| [`3.68`](#cmd-3-68) | [3](#sec-2) | `0x30` | `0xa4` | `0x15` | [CmdOEMvFlash/GetBootPartition](#cmd-3-68) | H | live ✓ |  | X | • | • |
| [`3.69`](#cmd-3-69) | [3](#sec-2) | `0x30` | `0xa4` | `0x20` | [CmdOEMvFlash/CreateEmptyPartition](#cmd-3-69) | H | live ✓ |  | X | • | • |
| [`3.70`](#cmd-3-70) | [3](#sec-2) | `0x30` | `0xa4` | `0x21` | [CmdOEMvFlash/FormatPartition](#cmd-3-70) | H | live ✓ |  | X | • | • |
| [`3.71`](#cmd-3-71) | [3](#sec-2) | `0x30` | `0xa4` | `0x22` | [CmdOEMvFlash/ChangePartitionAccessType](#cmd-3-71) | M | live ✓ |  | X | • | • |
| [`3.72`](#cmd-3-72) | [3](#sec-2) | `0x30` | `0xa4` | `0x23` | [CmdOEMvFlash/DeletePartition](#cmd-3-72) | H | live ✓ |  | X | • | • |
| [`3.73`](#cmd-3-73) | [3](#sec-2) | `0x30` | `0xa4` | `0x24` | [CmdOEMvFlash/GetJobStatus](#cmd-3-73) | L | live ✓ |  | X | • | • |
| [`3.74`](#cmd-3-74) | [3](#sec-2) | `0x30` | `0xa4` | `0x25` | [CmdOEMvFlash/GetPartitionStatus](#cmd-3-74) | L | live ✓ |  | X | • | • |
| [`3.75`](#cmd-3-75) | [3](#sec-2) | `0x30` | `0xa5` | `0x00` | [CmdOEMDellFactory/CreateFactoryHWInventory](#cmd-3-75) | H | live ✓ |  | X | • | • |
| [`3.76`](#cmd-3-76) | [3](#sec-2) | `0x30` | `0xa5` | `0x01` | [CmdOEMDellFactory/RecreateMASERDeprecated](#cmd-3-76) | H | live ✓ |  | X | • | • |
| [`3.77`](#cmd-3-77) | [3](#sec-2) | `0x30` | `0xa5` | `0x02` | [CmdOEMDellFactory/GetFactoryStatus](#cmd-3-77) | H | live ✓ |  | X | • | • |
| [`3.78`](#cmd-3-78) | [3](#sec-2) | `0x30` | `0xa5` | `0x03` | [CmdOEMDellFactory/PlatformCacheCleanup](#cmd-3-78) | M | live ✓ |  | X | • | • |
| [`3.79`](#cmd-3-79) | [3](#sec-2) | `0x30` | `0xa5` | `0x04` | [CmdOEMDellFactory/SecureDefaultPassword](#cmd-3-79) | ! | live ✓ |  | X | • | • |
| [`3.80`](#cmd-3-80) | [3](#sec-2) | `0x30` | `0xa6` | `0x00` | [CmdOEMBackupRestore/PopulateBackupCmd](#cmd-3-80) | H | live ✓ |  | X | • | • |
| [`3.81`](#cmd-3-81) | [3](#sec-2) | `0x30` | `0xa6` | `0x01` | [CmdOEMBackupRestore/SendBackupCmd](#cmd-3-81) | M | live ✓ |  | X | • | • |
| [`3.82`](#cmd-3-82) | [3](#sec-2) | `0x30` | `0xa6` | `0x02` | [CmdOEMBackupRestore/PopulateRestoreCmd](#cmd-3-82) | H | live ✓ |  | X | • | • |
| [`3.83`](#cmd-3-83) | [3](#sec-2) | `0x30` | `0xa6` | `0x03` | [CmdOEMBackupRestore/SendRestoreCmd](#cmd-3-83) | M | live ✓ |  | X | • | • |
| [`3.84`](#cmd-3-84) | [3](#sec-2) | `0x30` | `0xa6` | `0x04` | [CmdOEMBackupRestore/QueryJobStatus](#cmd-3-84) | L | live ✓ |  | X | • | • |
| [`3.85`](#cmd-3-85) | [3](#sec-2) | `0x30` | `0xa6` | `0x05` | [CmdOEMBackupRestore/QueryJobID](#cmd-3-85) | L | live ✓ |  | X | • | • |
| [`3.86`](#cmd-3-86) | [3](#sec-2) | `0x30` | `0xa6` | `0x06` | [CmdOEMBackupRestore/CancelCmd](#cmd-3-86) | M | live ✓ |  | X | • | • |
| [`3.87`](#cmd-3-87) | [3](#sec-2) | `0x30` | `0xa6` | `0x07` | [CmdOEMBackupRestore/SetJobStatusCmd](#cmd-3-87) | H | live ✓ |  | X | • | • |
| [`3.88`](#cmd-3-88) | [3](#sec-2) | `0x30` | `0xa6` | `0x0a` | [CmdOEMBackupRestore/GetAutoFeatureStatus](#cmd-3-88) | L | live ✓ |  | X | • | • |
| [`3.89`](#cmd-3-89) | [3](#sec-2) | `0x30` | `0xa6` | `0x0b` | [CmdOEMBackupRestore/GetAutoRestoreVflCap](#cmd-3-89) | L | live ✓ |  | X | • | • |
| [`3.90`](#cmd-3-90) | [3](#sec-2) | `0x30` | `0xa8` | `0x00` | [CmdOEMSupportAssist/NativeOSCollection](#cmd-3-90) | M | live ✓ |  | X | • | • |
| [`3.91`](#cmd-3-91) | [3](#sec-2) | `0x30` | `0xa8` | `0x01` | [CmdOEMSupportAssist/NativeOSCollectionStarted](#cmd-3-91) | M | live ✓ |  | X | • | • |
| [`3.92`](#cmd-3-92) | [3](#sec-2) | `0x30` | `0xa8` | `0x02` | [CmdOEMSupportAssist/NativeOSCollectionEnded](#cmd-3-92) | ! | live ✓ |  | X | • | • |
| [`3.93`](#cmd-3-93) | [3](#sec-2) | `0x30` | `0xa8` | `0x03` | [CmdOEMSupportAssist/ExposeiSMInstaller](#cmd-3-93) | M | live ✓ |  | X | • | • |
| [`3.94`](#cmd-3-94) | [3](#sec-2) | `0x30` | `0xa8` | `0x04` | [CmdOEMSupportAssist/HideiSMInstaller](#cmd-3-94) | M | live ✓ |  | X | • | • |
| [`3.95`](#cmd-3-95) | [3](#sec-2) | `0x30` | `0xa8` | `0x05` | [CmdOEMSupportAssist/GetStatus](#cmd-3-95) | L | live ✓ |  | X | • | • |
| [`3.96`](#cmd-3-96) | [3](#sec-2) | `0x30` | `0xa8` | `0x06` | [CmdOEMSupportAssist/CollectData](#cmd-3-96) | M | live ✓ |  | X | • | • |
| [`3.97`](#cmd-3-97) | [3](#sec-2) | `0x30` | `0xa8` | `0x07` | [CmdOEMSupportAssist/GetCollectDataStatus](#cmd-3-97) | L | live ✓ |  | X | • | • |
| [`3.98`](#cmd-3-98) | [3](#sec-2) | `0x30` | `0xa8` | `0x08` | [CmdOEMSupportAssist/HideCollectDataResult](#cmd-3-98) | M | live ✓ |  | X | • | • |
| [`3.99`](#cmd-3-99) | [3](#sec-2) | `0x30` | `0xa8` | `0x09` | [CmdOEMSupportAssist/CollectDataCancel](#cmd-3-99) | M | live ✓ |  | X | • | • |
| [`3.100`](#cmd-3-100) | [3](#sec-2) | `0x30` | `0xa8` | `0x10` | [CmdOEMSupportAssist/JobInProgressPendingSignal](#cmd-3-100) | M | live ✓ |  | X | • | • |
| [`3.101`](#cmd-3-101) | [3](#sec-2) | `0x30` | `0xa9` | `0x10` | [CmdOEMMASER_PM/CmdOEMGetPMUpdateFlag](#cmd-3-101) | M | live ✓ |  |  |  | X |
| [`3.102`](#cmd-3-102) | [3](#sec-2) | `0x30` | `0xa9` | `0x11` | [CmdOEMMASER_PM/CmdOEMClrPMUpdateFlag](#cmd-3-102) | M | live ✓ |  |  |  | X |
| [`3.103`](#cmd-3-103) | [3](#sec-2) | `0x30` | `0xa9` | `0x12` | [CmdOEMMASER_PM/CmdOEMGetPMStatus](#cmd-3-103) | M | live ✓ |  |  |  | X |
| [`3.104`](#cmd-3-104) | [3](#sec-2) | `0x30` | `0xa9` | `0x13` | [CmdOEMMASER_PM/CmdOEMGetPMDefaultBrand](#cmd-3-104) | M | live ✓ |  |  |  | X |
| [`3.105`](#cmd-3-105) | [3](#sec-2) | `0x30` | `0xa9` | `0x14` | [CmdOEMMASER_PM/CmdOEMGetPMRebrand](#cmd-3-105) | M | live ✓ |  |  |  | X |
| [`3.106`](#cmd-3-106) | [3](#sec-2) | `0x30` | `0xa9` | `0x15` | [CmdOEMMASER_PM/CmdOEMSetPMInstall](#cmd-3-106) | M | live ✓ |  |  |  | X |
| [`3.107`](#cmd-3-107) | [3](#sec-2) | `0x30` | `0xa9` | `0x17` | [CmdOEMMASER_PM/GetBIOSRTDFlag](#cmd-3-107) | L | live ✓ |  |  |  | X |
| [`3.108`](#cmd-3-108) | [3](#sec-2) | `0x30` | `0xa9` | `0x18` | [CmdOEMMASER_PM/ClearBIOSRTDFlag](#cmd-3-108) | M | live ✓ |  |  |  | X |
| [`3.109`](#cmd-3-109) | [3](#sec-2) | `0x30` | `0xa9` | `0x19` | [CmdOEMMASER_PM/SetBIOSRTDFlag](#cmd-3-109) | M | live ✓ |  |  |  | X |
| [`3.110`](#cmd-3-110) | [3](#sec-2) | `0x30` | `0xa9` | `0x1a` | [CmdOEMMASER_PM/CmdOEMCmplntUpdValidate](#cmd-3-110) | M | live ✓ |  |  |  | X |
| [`3.111`](#cmd-3-111) | [3](#sec-2) | `0x30` | `0xa9` | `0x1b` | [CmdOEMMASER_PM/CmdOEMCmplntUpdValidateStatus](#cmd-3-111) | M | live ✓ |  |  |  | X |
| [`3.112`](#cmd-3-112) | [3](#sec-2) | `0x30` | `0xa9` | `0x1c` | [CmdOEMMASER_PM/CmdOEMCmplntUpdUpdate](#cmd-3-112) | M | live ✓ |  |  |  | X |
| [`3.113`](#cmd-3-113) | [3](#sec-2) | `0x30` | `0xa9` | `0x1d` | [CmdOEMMASER_PM/CmdOEMCmplntUpdQueryStatus](#cmd-3-113) | M | live ✓ |  |  |  | X |
| [`3.114`](#cmd-3-114) | [3](#sec-2) | `0x30` | `0xa9` | `0x1e` | [CmdOEMMASER_PM/CmdOemGetLCStatus](#cmd-3-114) | M | live ✓ |  |  |  | X |
| [`3.115`](#cmd-3-115) | [3](#sec-2) | `0x30` | `0xa9` | `0x2f` | [CmdOEMMASER_PM/CmdOEMGetBIOSPasswordInfo](#cmd-3-115) | ! | live ✓ |  |  |  | X |
| [`3.116`](#cmd-3-116) | [3](#sec-2) | `0x30` | `0xaa` | `0x01` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERUpdateInventoryOrXML](#cmd-3-116) | M | live ✓ |  | X | • | • |
| [`3.117`](#cmd-3-117) | [3](#sec-2) | `0x30` | `0xaa` | `0x03` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERLogEntry](#cmd-3-117) | H | live ✓ |  | X | • | • |
| [`3.118`](#cmd-3-118) | [3](#sec-2) | `0x30` | `0xaa` | `0x0b` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryCurrentRecords](#cmd-3-118) | M | live ✓ |  | X | • | • |
| [`3.119`](#cmd-3-119) | [3](#sec-2) | `0x30` | `0xaa` | `0x0c` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryRecordHistory](#cmd-3-119) | M | live ✓ |  | X | • | • |
| [`3.120`](#cmd-3-120) | [3](#sec-2) | `0x30` | `0xaa` | `0x0d` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryEventRecord](#cmd-3-120) | M | live ✓ |  | X | • | • |
| [`3.121`](#cmd-3-121) | [3](#sec-2) | `0x30` | `0xaa` | `0x0e` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryDependency](#cmd-3-121) | M | live ✓ |  | X | • | • |
| [`3.122`](#cmd-3-122) | [3](#sec-2) | `0x30` | `0xaa` | `0x0f` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERHistory](#cmd-3-122) | M | live ✓ |  | X | • | • |
| [`3.123`](#cmd-3-123) | [3](#sec-2) | `0x30` | `0xaa` | `0x10` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERHWInventory](#cmd-3-123) | M | live ✓ |  | X | • | • |
| [`3.124`](#cmd-3-124) | [3](#sec-2) | `0x30` | `0xaa` | `0x11` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERFactoryHWInventoryGet](#cmd-3-124) | H | live ✓ |  | X | • | • |
| [`3.125`](#cmd-3-125) | [3](#sec-2) | `0x30` | `0xaa` | `0x15` | [CmdOEMMASERLCLAccess/CmdOEMLCLMASERGetLCLStatus](#cmd-3-125) | M | live ✓ |  | X | • | • |
| [`3.126`](#cmd-3-126) | [3](#sec-2) | `0x30` | `0xaa` | `0x16` | [CmdOEMMASERLCLAccess/CmdOEMLCLGetUSCVer](#cmd-3-126) | M | live ✓ |  | X | • | • |
| [`3.127`](#cmd-3-127) | [3](#sec-2) | `0x30` | `0xaa` | `0x17` | [CmdOEMMASERLCLAccess/CmdOEMLCLCopyMUTData](#cmd-3-127) | M | live ✓ |  | X | • | • |
| [`3.128`](#cmd-3-128) | [3](#sec-2) | `0x30` | `0xab` |  | [CmdOEMGetMASERInfo](#cmd-3-128) | M | live ✓ |  | X | • | • |
| [`3.129`](#cmd-3-129) | [3](#sec-2) | `0x30` | `0xad` |  | [CmdOEMGetMASERType](#cmd-3-129) | M | live ✓ |  | X | • | • |
| [`3.130`](#cmd-3-130) | [3](#sec-2) | `0x30` | `0xae` |  | [CmdOEMGetMASERAccessState](#cmd-3-130) | M | live ✓ |  |  |  | X |
| [`3.131`](#cmd-3-131) | [3](#sec-2) | `0x30` | `0xaf` |  | [CmdOEMSetMASERAccessState](#cmd-3-131) | M | live ✓ |  | X | • | • |
| [`6.76`](#cmd-6-76) | [6](#sec-5) | `0x30` | `0xb0` |  | [DellPwrPSUInfo](#cmd-6-76) | H | live ✓ |  |  |  | X |
| [`6.77`](#cmd-6-77) | [6](#sec-5) | `0x30` | `0xb3` |  | [DellPwrRealTimePwrConsumption](#cmd-6-77) | M | live ✓ |  |  |  | X |
| [`10.8`](#cmd-10-8) | [10](#sec-9) | `0x30` | `0xb5` |  | [DellCmdGetFrontPanelInfo](#cmd-10-8) | M | live ✓ |  | X | • | • |
| [`6.78`](#cmd-6-78) | [6](#sec-5) | `0x30` | `0xb6` |  | [DellPwrPSUFirmwareUpdate](#cmd-6-78) | H | live ✓ |  |  |  | X |
| [`6.79`](#cmd-6-79) | [6](#sec-5) | `0x30` | `0xb7` |  | [DellPwrPSUFirmwareUpdateStatus](#cmd-6-79) | H | live ✓ |  |  |  | X |
| [`15.16`](#cmd-15-16) | [15](#sec-14) | `0x30` | `0xb8` |  | [QueueSpdDimmInfoCmd](#cmd-15-16) | M | live ✓ |  | X | • | • |
| [`15.17`](#cmd-15-17) | [15](#sec-14) | `0x30` | `0xb9` |  | [QueueSpdDimmInfoCmd](#cmd-15-17) | M | live ✓ |  |  |  | X |
| [`6.80`](#cmd-6-80) | [6](#sec-5) | `0x30` | `0xba` |  | [DellPwrCapEnable](#cmd-6-80) | M | live ✓ |  |  |  | X |
| [`6.81`](#cmd-6-81) | [6](#sec-5) | `0x30` | `0xbb` |  | [DellPwrHeadroom](#cmd-6-81) | M | live ✓ |  |  |  | X |
| [`15.18`](#cmd-15-18) | [15](#sec-14) | `0x30` | `0xbc` |  | [DellCPLDAccessStatus](#cmd-15-18) | ! | live ✓ |  |  |  | X |
| [`9.23`](#cmd-9-23) | [9](#sec-8) | `0x30` | `0xbd` |  | [DellCmdIMCFeatureSupport](#cmd-9-23) | M | live ✓ |  |  |  | X |
| [`15.19`](#cmd-15-19) | [15](#sec-14) | `0x30` | `0xbe` |  | [DellRollbackFW](#cmd-15-19) | H | live ✓ |  |  |  | X |
| [`15.20`](#cmd-15-20) | [15](#sec-14) | `0x30` | `0xbf` |  | [DellGetFWVersion](#cmd-15-20) | M | live ✓ |  | X | • | • |
| [`6.82`](#cmd-6-82) | [6](#sec-5) | `0x30` | `0xc0` |  | [DellPwrEfficiency](#cmd-6-82) | M | live ✓ |  | X | • | • |
| [`15.21`](#cmd-15-21) | [15](#sec-14) | `0x30` | `0xc1` |  | [DellGetActiveLOM](#cmd-15-21) | M | live ✓ |  | X | • | • |
| [`9.24`](#cmd-9-24) | [9](#sec-8) | `0x30` | `0xc3` |  | [DellCmdCMCFeatureSupport](#cmd-9-24) | M | live ✓ |  | X | • | • |
| [`5.32`](#cmd-5-32) | [5](#sec-4) | `0x30` | `0xc5` |  | [DellDCSSCBMCWrapper](#cmd-5-32) | M | gated |  |  |  | X |
| [`5.33`](#cmd-5-33) | [5](#sec-4) | `0x30` | `0xc6` |  | [DellDCSSCBMCWrapper](#cmd-5-33) | M | gated |  |  |  | X |
| [`5.34`](#cmd-5-34) | [5](#sec-4) | `0x30` | `0xc7` |  | [DellDCSSCBMCWrapper](#cmd-5-34) | M | live ✓ |  |  |  | X |
| [`5.35`](#cmd-5-35) | [5](#sec-4) | `0x30` | `0xc8` |  | [DellDCSSCBMCWrapper](#cmd-5-35) | M | live ✓ |  |  |  | X |
| [`9.25`](#cmd-9-25) | [9](#sec-8) | `0x30` | `0xc9` |  | [DellCmdBladeVirtualMAC](#cmd-9-25) | M | live ✓ |  |  |  | X |
| [`9.26`](#cmd-9-26) | [9](#sec-8) | `0x30` | `0xcb` |  | [DellCmdBladeChassisInfo](#cmd-9-26) | H | live ✓ |  |  |  | X |
| [`6.83`](#cmd-6-83) | [6](#sec-5) | `0x30` | `0xcc` |  | [DellPwrAverageInterval](#cmd-6-83) | M | live ✓ |  |  |  | X |
| [`6.84`](#cmd-6-84) | [6](#sec-5) | `0x30` | `0xcd` |  | [DellPwrAverageRange](#cmd-6-84) | ! | live ✓ |  |  |  | X |
| [`2.1`](#cmd-2-1) | [2](#sec-1) | `0x30` | `0xce` | `0x0` | [SubCmdHandler/0xce/SystemPowerCapacity](#cmd-2-1) | M | live ✓ |  |  |  | X |
| [`2.2`](#cmd-2-2) | [2](#sec-1) | `0x30` | `0xce` | `0x1` | [SubCmdHandler/0xce/PhysicalTopology](#cmd-2-2) | M | live ✓ |  |  |  | X |
| [`2.3`](#cmd-2-3) | [2](#sec-1) | `0x30` | `0xce` | `0x3` | [SubCmdHandler/0xce/getActivePowerPolicy](#cmd-2-3) | L | live ✓ |  |  |  | X |
| [`2.4`](#cmd-2-4) | [2](#sec-1) | `0x30` | `0xce` | `0x4` | [SubCmdHandler/0xce/PSURapidON](#cmd-2-4) | M | live ✓ |  |  |  | X |
| [`2.5`](#cmd-2-5) | [2](#sec-1) | `0x30` | `0xce` | `0x5` | [SubCmdHandler/0xce/getPSUSysCapability](#cmd-2-5) | L | live ✓ |  |  |  | X |
| [`2.6`](#cmd-2-6) | [2](#sec-1) | `0x30` | `0xce` | `0x6` | [SubCmdHandler/0xce/PSUPFC](#cmd-2-6) | M | live ✓ |  |  |  | X |
| [`2.7`](#cmd-2-7) | [2](#sec-1) | `0x30` | `0xce` | `0x9` | [SubCmdHandler/0xce/ThermalSetting](#cmd-2-7) | M | live ✓ |  |  |  | X |
| [`2.8`](#cmd-2-8) | [2](#sec-1) | `0x30` | `0xce` | `0xa` | [SubCmdHandler/0xce/getTempSensorNumber](#cmd-2-8) | L | live ✓ |  |  |  | X |
| [`2.9`](#cmd-2-9) | [2](#sec-1) | `0x30` | `0xce` | `0xb` | [SubCmdHandler/0xce/DellOEMCmdPwrSimulationMngmnt](#cmd-2-9) | M | live ✓ |  |  |  | X |
| [`2.10`](#cmd-2-10) | [2](#sec-1) | `0x30` | `0xce` | `0xd` | [SubCmdHandler/0xce/VRConfiguration](#cmd-2-10) | M | live ✓ |  |  |  | X |
| [`2.11`](#cmd-2-11) | [2](#sec-1) | `0x30` | `0xce` | `0xe` | [SubCmdHandler/0xce/TempReadings](#cmd-2-11) | M | live ✓ |  |  |  | X |
| [`2.12`](#cmd-2-12) | [2](#sec-1) | `0x30` | `0xce` | `0xf` | [SubCmdHandler/0xce/getPowerReading](#cmd-2-12) | L | live ✓ |  |  |  | X |
| [`2.13`](#cmd-2-13) | [2](#sec-1) | `0x30` | `0xce` | `0x10` | [SubCmdHandler/0xce/pwrBudgetCheck](#cmd-2-13) | M | live ✓ |  |  |  | X |
| [`2.14`](#cmd-2-14) | [2](#sec-1) | `0x30` | `0xce` | `0x11` | [SubCmdHandler/0xce/psuHotSpareThreshold](#cmd-2-14) | M | live ✓ |  |  |  | X |
| [`2.15`](#cmd-2-15) | [2](#sec-1) | `0x30` | `0xce` | `0x12` | [SubCmdHandler/0xce/slbOverRide](#cmd-2-15) | M | live ✓ |  |  |  | X |
| [`2.16`](#cmd-2-16) | [2](#sec-1) | `0x30` | `0xce` | `0x13` | [SubCmdHandler/0xce/clstOverRide](#cmd-2-16) | M | live ✓ |  |  |  | X |
| [`2.17`](#cmd-2-17) | [2](#sec-1) | `0x30` | `0xce` | `0x14` | [SubCmdHandler/0xce/psuMismatchOverRide](#cmd-2-17) | M | live ✓ |  |  |  | X |
| [`2.18`](#cmd-2-18) | [2](#sec-1) | `0x30` | `0xce` | `0x15` | [SubCmdHandler/0xce/updateGpGPUPBT](#cmd-2-18) | M | live ✓ |  |  |  | X |
| [`2.19`](#cmd-2-19) | [2](#sec-1) | `0x30` | `0xce` | `0x16` | [SubCmdHandler/0xce/ThermalOverride](#cmd-2-19) | M | live ✓ |  |  |  | X |
| [`2.20`](#cmd-2-20) | [2](#sec-1) | `0x30` | `0xce` | `0x17` | [SubCmdHandler/0xce/PowerThermalTableInfo](#cmd-2-20) | M | live ✓ |  |  |  | X |
| [`2.21`](#cmd-2-21) | [2](#sec-1) | `0x30` | `0xce` | `0x18` | [SubCmdHandler/0xce/ThermalEBInfo](#cmd-2-21) | M | live ✓ |  |  |  | X |
| [`2.22`](#cmd-2-22) | [2](#sec-1) | `0x30` | `0xce` | `0x19` | [SubCmdHandler/0xce/psuDisableACDiscHandler](#cmd-2-22) | M | live ✓ |  |  |  | X |
| [`2.23`](#cmd-2-23) | [2](#sec-1) | `0x30` | `0xce` | `0x1a` | [SubCmdHandler/0xce/PSUFixedInputBulkVoltage](#cmd-2-23) | M | live ✓ |  |  |  | X |
| [`2.24`](#cmd-2-24) | [2](#sec-1) | `0x30` | `0xce` | `0x1b` | [SubCmdHandler/0xce/LiquidCoolingSensorConfig](#cmd-2-24) | M | live ✓ |  |  |  | X |
| [`2.25`](#cmd-2-25) | [2](#sec-1) | `0x30` | `0xce` | `0x1c` | [SubCmdHandler/0xce/powerExtendedCmds](#cmd-2-25) | M | live ✓ |  |  |  | X |
| [`2.26`](#cmd-2-26) | [2](#sec-1) | `0x30` | `0xcf` | `0x00` | [SubCmdHandler/0xcf/OSBmcPtAttributes](#cmd-2-26) | ! | live ✓ |  |  |  | X |
| [`2.27`](#cmd-2-27) | [2](#sec-1) | `0x30` | `0xcf` | `0x02` | [SubCmdHandler/0xcf/OSBmcPtUSB](#cmd-2-27) | M | live ✓ |  |  |  | X |
| [`2.28`](#cmd-2-28) | [2](#sec-1) | `0x30` | `0xcf` | `0x03` | [SubCmdHandler/0xcf/OSBmcPtLOM](#cmd-2-28) | M | live ✓ |  |  |  | X |
| [`14.12`](#cmd-14-12) | [14](#sec-13) | `0x30` | `0xd0` | `0x01` | [CmdOEMMiscCmd/OEMMiscCMDEventSELFiltering](#cmd-14-12) | M | live ✓ |  |  |  | X |
| [`14.13`](#cmd-14-13) | [14](#sec-13) | `0x30` | `0xd0` | `0x02` | [CmdOEMMiscCmd/SubCmdHandler](#cmd-14-13) | M | live ✓ |  |  |  | X |
| [`2.29`](#cmd-2-29) | [2](#sec-1) | `0x30` | `0xd1` | `0x00` | [SubCmdHandler/0xd1/LicensingResetFlag](#cmd-2-29) | M | live ✓ |  |  |  | X |
| [`2.30`](#cmd-2-30) | [2](#sec-1) | `0x30` | `0xd1` | `0x01` | [SubCmdHandler/0xd1/LicensingEntireBitmap](#cmd-2-30) | M | live ✓ |  |  |  | X |
| [`2.31`](#cmd-2-31) | [2](#sec-1) | `0x30` | `0xd1` | `0x02` | [SubCmdHandler/0xd1/LicensingSingleStatus](#cmd-2-31) | M | live ✓ |  |  |  | X |
| [`2.32`](#cmd-2-32) | [2](#sec-1) | `0x30` | `0xd1` | `0x05` | [SubCmdHandler/0xd1/LicensableDeviceList](#cmd-2-32) | M | live ✓ |  |  |  | X |
| [`2.33`](#cmd-2-33) | [2](#sec-1) | `0x30` | `0xd1` | `0x06` | [SubCmdHandler/0xd1/LicensableDeviceCurrentClass](#cmd-2-33) | M | live ✓ |  |  |  | X |
| [`2.34`](#cmd-2-34) | [2](#sec-1) | `0x30` | `0xd1` | `0x07` | [SubCmdHandler/0xd1/LicensableDeviceInformation](#cmd-2-34) | H | live ✓ |  |  |  | X |
| [`2.35`](#cmd-2-35) | [2](#sec-1) | `0x30` | `0xd1` | `0x08` | [SubCmdHandler/0xd1/LicensableDeviceLicenseList](#cmd-2-35) | M | live ✓ |  |  |  | X |
| [`2.36`](#cmd-2-36) | [2](#sec-1) | `0x30` | `0xd1` | `0x09` | [SubCmdHandler/0xd1/LicensableDeviceLicenseInfo](#cmd-2-36) | M | live ✓ |  |  |  | X |
| [`2.37`](#cmd-2-37) | [2](#sec-1) | `0x30` | `0xd1` | `0xff` | [SubCmdHandler/0xd1/LicensingPCBAtest](#cmd-2-37) | M | live ✓ |  |  |  | X |
| [`2.38`](#cmd-2-38) | [2](#sec-1) | `0x30` | `0xd2` |  | [RacMw_TransferData](#cmd-2-38) | ! | live ✓ |  | X | • | • |
| [`2.39`](#cmd-2-39) | [2](#sec-1) | `0x30` | `0xd3` | `0x2` | [SubCmdHandler/0xd3/HiiIntegerSet](#cmd-2-39) | M | live ✓ |  |  |  | X |
| [`2.40`](#cmd-2-40) | [2](#sec-1) | `0x30` | `0xd3` | `0x3` | [SubCmdHandler/0xd3/HiiIntegerGet](#cmd-2-40) | M | live ✓ |  |  |  | X |
| [`2.41`](#cmd-2-41) | [2](#sec-1) | `0x30` | `0xd3` | `0x4` | [SubCmdHandler/0xd3/HiiStringSet](#cmd-2-41) | M | live ✓ |  |  |  | X |
| [`2.42`](#cmd-2-42) | [2](#sec-1) | `0x30` | `0xd3` | `0x5` | [SubCmdHandler/0xd3/HiiStringGet](#cmd-2-42) | M | live ✓ |  |  |  | X |
| [`2.43`](#cmd-2-43) | [2](#sec-1) | `0x30` | `0xd3` | `0x6` | [SubCmdHandler/0xd3/HiiEnumSet](#cmd-2-43) | M | live ✓ |  |  |  | X |
| [`2.44`](#cmd-2-44) | [2](#sec-1) | `0x30` | `0xd3` | `0x7` | [SubCmdHandler/0xd3/HiiEnumGet](#cmd-2-44) | M | live ✓ |  |  |  | X |
| [`2.45`](#cmd-2-45) | [2](#sec-1) | `0x30` | `0xd3` | `0x8` | [SubCmdHandler/0xd3/HiiOrdListSet](#cmd-2-45) | M | live ✓ |  |  |  | X |
| [`2.46`](#cmd-2-46) | [2](#sec-1) | `0x30` | `0xd3` | `0x9` | [SubCmdHandler/0xd3/HiiOrdListGet](#cmd-2-46) | M | live ✓ |  |  |  | X |
| [`2.47`](#cmd-2-47) | [2](#sec-1) | `0x30` | `0xd3` | `0xa` | [SubCmdHandler/0xd3/HiiJobStatusGet](#cmd-2-47) | M | live ✓ |  |  |  | X |
| [`2.48`](#cmd-2-48) | [2](#sec-1) | `0x30` | `0xd3` | `0xb` | [SubCmdHandler/0xd3/HiiVerifyPassword](#cmd-2-48) | ! | live ✓ |  |  |  | X |
| [`2.49`](#cmd-2-49) | [2](#sec-1) | `0x30` | `0xd3` | `0xc` | [SubCmdHandler/0xd3/HiiListPending](#cmd-2-49) | M | live ✓ |  |  |  | X |
| [`15.22`](#cmd-15-22) | [15](#sec-14) | `0x30` | `0xd4` |  | [DellCmdiDracPOSTCode](#cmd-15-22) | M | live ✓ |  |  |  | X |
| [`2.50`](#cmd-2-50) | [2](#sec-1) | `0x30` | `0xd5` | `0x30` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-50) | M | live ✓ |  |  |  | X |
| [`2.51`](#cmd-2-51) | [2](#sec-1) | `0x30` | `0xd5` | `0x31` | [SubCmdHandler/DellBpFwUpdateInterface](#cmd-2-51) | M | live ✓ |  |  |  | X |
| [`2.52`](#cmd-2-52) | [2](#sec-1) | `0x30` | `0xd5` | `0x32` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-52) | M | live ✓ |  |  |  | X |
| [`2.53`](#cmd-2-53) | [2](#sec-1) | `0x30` | `0xd5` | `0x33` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-53) | M | live ✓ |  |  |  | X |
| [`2.54`](#cmd-2-54) | [2](#sec-1) | `0x30` | `0xd5` | `0x34` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-54) | M | live ✓ |  |  |  | X |
| [`2.55`](#cmd-2-55) | [2](#sec-1) | `0x30` | `0xd5` | `0x35` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-55) | M | live ✓ |  |  |  | X |
| [`2.56`](#cmd-2-56) | [2](#sec-1) | `0x30` | `0xd5` | `0x36` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-56) | M | live ✓ |  |  |  | X |
| [`2.57`](#cmd-2-57) | [2](#sec-1) | `0x30` | `0xd5` | `0x37` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-57) | M | live ✓ |  |  |  | X |
| [`2.58`](#cmd-2-58) | [2](#sec-1) | `0x30` | `0xd5` | `0x38` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-58) | M | live ✓ |  |  |  | X |
| [`2.59`](#cmd-2-59) | [2](#sec-1) | `0x30` | `0xd5` | `0x39` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-59) | M | live ✓ |  |  |  | X |
| [`2.60`](#cmd-2-60) | [2](#sec-1) | `0x30` | `0xd5` | `0x3a` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-60) | M | live ✓ |  |  |  | X |
| [`2.61`](#cmd-2-61) | [2](#sec-1) | `0x30` | `0xd5` | `0x3b` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-61) | M | live ✓ |  |  |  | X |
| [`2.62`](#cmd-2-62) | [2](#sec-1) | `0x30` | `0xd5` | `0x3c` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-62) | M | live ✓ |  |  |  | X |
| [`2.63`](#cmd-2-63) | [2](#sec-1) | `0x30` | `0xd5` | `0x3d` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-63) | M | live ✓ |  |  |  | X |
| [`2.64`](#cmd-2-64) | [2](#sec-1) | `0x30` | `0xd5` | `0x3e` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-64) | M | live ✓ |  |  |  | X |
| [`2.65`](#cmd-2-65) | [2](#sec-1) | `0x30` | `0xd5` | `0x3f` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-65) | M | live ✓ |  |  |  | X |
| [`2.66`](#cmd-2-66) | [2](#sec-1) | `0x30` | `0xd5` | `0x40` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-66) | M | live ✓ |  |  |  | X |
| [`2.67`](#cmd-2-67) | [2](#sec-1) | `0x30` | `0xd5` | `0x50` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-67) | M | live ✓ |  |  |  | X |
| [`2.68`](#cmd-2-68) | [2](#sec-1) | `0x30` | `0xd5` | `0x54` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-68) | M | live ✓ |  |  |  | X |
| [`2.69`](#cmd-2-69) | [2](#sec-1) | `0x30` | `0xd5` | `0x55` | [SubCmdHandler/DellBpLocalIpmiInterface](#cmd-2-69) | M | live ✓ |  |  |  | X |
| [`2.70`](#cmd-2-70) | [2](#sec-1) | `0x30` | `0xd6` | `0x00` | [SubCmdHandler/InBandGetIpPort](#cmd-2-70) | M | live ✓ |  |  |  | X |
| [`2.71`](#cmd-2-71) | [2](#sec-1) | `0x30` | `0xd6` | `0x01` | [SubCmdHandler/InBandGenerateAliteCert](#cmd-2-71) | ! | live ✓ |  |  |  | X |
| [`2.72`](#cmd-2-72) | [2](#sec-1) | `0x30` | `0xd6` | `0x02` | [SubCmdHandler/InBandRetrieveAliteCert](#cmd-2-72) | ! | live ✓ |  |  |  | X |
| [`2.73`](#cmd-2-73) | [2](#sec-1) | `0x30` | `0xd6` | `0x03` | [SubCmdHandler/InBandGetLastRceError](#cmd-2-73) | M | live ✓ |  |  |  | X |
| [`2.74`](#cmd-2-74) | [2](#sec-1) | `0x30` | `0xd6` | `0x04` | [SubCmdHandler/InBandISMVersionCmdHandler](#cmd-2-74) | H | live ✓ |  |  |  | X |
| [`2.75`](#cmd-2-75) | [2](#sec-1) | `0x30` | `0xd6` | `0x05` | [SubCmdHandler/InBandGetISMLCDUPVersion](#cmd-2-75) | M | live ✓ |  |  |  | X |
| [`2.76`](#cmd-2-76) | [2](#sec-1) | `0x30` | `0xd6` | `0x06` | [SubCmdHandler/InBandGetOauthToken](#cmd-2-76) | ! | live ✓ |  |  |  | X |
| [`2.77`](#cmd-2-77) | [2](#sec-1) | `0x30` | `0xd6` | `0x07` | [SubCmdHandler/InBandLcLogWithArgument](#cmd-2-77) | H | live ✓ |  |  |  | X |
| [`2.78`](#cmd-2-78) | [2](#sec-1) | `0x30` | `0xd6` | `0x08` | [SubCmdHandler/InBandMultiPlatformEventCmd](#cmd-2-78) | H | live ✓ |  |  |  | X |
| [`2.79`](#cmd-2-79) | [2](#sec-1) | `0x30` | `0xd6` | `0x0a` | [SubCmdHandler/InBandSendMemoryHealthEventCmd](#cmd-2-79) | ! | live ✓ |  |  |  | X |
| [`2.80`](#cmd-2-80) | [2](#sec-1) | `0x30` | `0xd6` | `0x0b` | [SubCmdHandler/InBandIsmStateHandler](#cmd-2-80) | M | live ✓ |  |  |  | X |
| [`5.36`](#cmd-5-36) | [5](#sec-4) | `0x30` | `0xd7` |  | [DellDCSSCBMCWrapper](#cmd-5-36) | M | live ✓ |  |  |  | X |
| [`5.37`](#cmd-5-37) | [5](#sec-4) | `0x30` | `0xd8` |  | [DellDCSSCBMCWrapper](#cmd-5-37) | M | live ✓ |  |  |  | X |
| [`5.38`](#cmd-5-38) | [5](#sec-4) | `0x30` | `0xda` |  | [DellDCSSCBMCWrapper](#cmd-5-38) | M | live ✓ |  |  |  | X |
| [`15.23`](#cmd-15-23) | [15](#sec-14) | `0x30` | `0xdb` |  | [FileObjCmdHandler](#cmd-15-23) | M | live ✓ |  |  |  | X |
| [`5.39`](#cmd-5-39) | [5](#sec-4) | `0x30` | `0xdc` |  | [DellDCSSCBMCWrapper](#cmd-5-39) | ! | live ✓ |  | X | • | • |
| [`12.5`](#cmd-12-5) | [12](#sec-11) | `0x30` | `0xdd` | `0x00` | [ConfigValDDCmdHndlr/0x00](#cmd-12-5) | M | live ✓ |  |  |  | X |
| [`12.6`](#cmd-12-6) | [12](#sec-11) | `0x30` | `0xdd` | `0x01` | [ConfigValDDCmdHndlr/0x01](#cmd-12-6) | M | live ✓ |  |  |  | X |
| [`12.7`](#cmd-12-7) | [12](#sec-11) | `0x30` | `0xdd` | `0x02` | [ConfigValDDCmdHndlr/0x02](#cmd-12-7) | M | live ✓ |  |  |  | X |
| [`12.8`](#cmd-12-8) | [12](#sec-11) | `0x30` | `0xdd` | `0x03` | [ConfigValDDCmdHndlr/0x03](#cmd-12-8) | ! | live ✓ |  |  |  | X |
| [`12.9`](#cmd-12-9) | [12](#sec-11) | `0x30` | `0xdd` | `0x04` | [ConfigValDDCmdHndlr/0x04](#cmd-12-9) | M | live ✓ |  |  |  | X |
| [`12.10`](#cmd-12-10) | [12](#sec-11) | `0x30` | `0xdd` | `0x05` | [ConfigValDDCmdHndlr/0x05](#cmd-12-10) | M | live ✓ |  |  |  | X |
| [`13.2`](#cmd-13-2) | [13](#sec-12) | `0x30` | `0xde` |  | [DellBpAckDriveRemoval](#cmd-13-2) | ! | live ✓ |  |  |  | X |
| [`5.40`](#cmd-5-40) | [5](#sec-4) | `0x30` | `0xdf` |  | [DellDCSSCBMCWrapper](#cmd-5-40) | M | gated |  |  |  | X |
| [`15.24`](#cmd-15-24) | [15](#sec-14) | `0x30` | `0xfa` |  | [DellCmdSmaMbxFlag](#cmd-15-24) | M | live ✓ |  |  |  | X |
| [`5.41`](#cmd-5-41) | [5](#sec-4) | `0x32` | `0x01` |  | [CmdDcmiGetPowerReading](#cmd-5-41) | M | live ✓ |  |  |  | X |
| [`5.42`](#cmd-5-42) | [5](#sec-4) | `0x32` | `0x02` |  | [DellDCSSCBMCWrapper](#cmd-5-42) | M | live ✓ |  |  |  | X |
| [`5.43`](#cmd-5-43) | [5](#sec-4) | `0x32` | `0x03` |  | [DellDCSSCBMCWrapper](#cmd-5-43) | M | live ✓ |  |  |  | X |
| [`5.44`](#cmd-5-44) | [5](#sec-4) | `0x32` | `0x73` |  | [DellDCSSCBMCWrapper](#cmd-5-44) | M | live ✓ |  |  |  | X |
| [`5.45`](#cmd-5-45) | [5](#sec-4) | `0x36` | `0xf5` |  | [DellDCSSCBMCWrapper](#cmd-5-45) | M | live ✓ |  |  |  | X |

## 1. Bootstrap Credentials & Attestation (17)

Commands that hand host-side agents iDRAC credentials, cert fingerprints, or provisioning control — the credential-disclosure surface.

### 1.1CmdDcmiGetDcmiCapabilityInfo Medium

NetFn 0x2c · Cmd 0x01Priv  · · · ·libdcmiconfidence: highabsent

DCMI Get Capability Info (DCMI spec section 6.1). Returns DCMI conformance version and platform capability data for one of five capability selectors (data\[1\] = 1..5). Requires the DCMI group extension identifier (0xDC) as data\[0\]. All selectors prepend a fixed 4-byte header (0xDC, 0x01, 0x05, 0x02 in little-endian = group ID + DCMI spec version 1.5 rev 2) to the selector-specific payload. No privilege required.

Request

Minimum 2 data bytes (req+8 and req+9). byte\[0\] (req+8): DCMI Group Extension Identifier, must be 0xDC (=0xdc = -0x24 in signed byte); any other value → CC=0xcc (invalid data field). byte\[1\] (req+9): Capability selector, must be in range 1..5; value 0 or \>5 → CC=0xcc. No further bytes used for the request.

Response

All responses begin with a 4-byte fixed header at param_3\[0..3\]: bytes \[0xDC, 0x01, 0x05, 0x02\] (DCMI group ext ID + conformance version 1.5 rev 2). resp_len (\*param_2) and the remaining bytes are selector-dependent: Selector 1 (General Platform Parameters): resp_len=7; param_3\[4-5\]=0x0100 (LE16, supported DCMI capabilities bitmap); param_3\[6\]=number of LAN+serial channels (1 if serial not configured, 3 if serial configured). Selector 2 (Mandatory Platform Attributes): resp_len=9; param_3\[4\]=(GetSELMaxEntryCount()&0xFF) (SEL max entries low byte); param_3\[5\]=((GetSELMaxEntryCount()\>\>8)&0xFF)\|0xA0 (SEL max entries high nibble, with bits 7:5=101 set indicating optional platform attrs); param_3\[6-7\]=0x0000 (reserved); param_3\[8\]=0x01 (platform characteristic flags). Selector 3 (Optional Platform Attributes): resp_len=6; param_3\[4\]=GetControllerAddress() (BMC I2C/IPMB address); param_3\[5-7\]=undetermined (zero-initialized region); param_3\[8 equiv index\]=0xFF (no power management device). Selector 4 (Manageability Access Attributes): resp_len=7; param_3\[4\]=primary LAN channel number from G_LANChannelNumInfo (0xFF if no LAN configured); param_3\[5-8\] includes reserved 0xFF then primary serial channel number from G_SerialChannelNumInfo (0xFF if not configured). Selector 5 (Enhanced System Power Statistics Attributes): resp_len=9; param_3\[4\]=0x04 (number of rolling average time periods supported); param_3\[5-8\]=time period data from global capability array (decompiler artifact prevents precise byte-level decoding — treat as undetermined). CC=0x00 on success; CC=0xcc on invalid selector or missing 0xDC group byte.

Backends `GetSELMaxEntryCount() (SEL record count from IPMI SEL subsystem); GetControllerAddress() (BMC IPMB address); G_LANChannelNumInfo and G_SerialChannelNumInfo (global channel configuration structures populated at init by DcmiInit); global capability array for selector-5 time periods (address not resolved by decompiler)`

**Security** — No privilege required — unauthenticated callers can enumerate DCMI capability information including BMC IPMB address, SEL capacity, and LAN/serial channel numbers. This is standard DCMI behaviour but provides useful reconnaissance: the BMC I2C address and channel numbers narrow subsequent attack vectors. The selector-5 capability bitmap may reveal the set of supported rolling-average windows before any authenticated session is established.

### 1.2DellCmdGetMgrCertFingerprint Medium

NetFn 0x2c · Cmd 0x01Priv  · · · **A**libmisccmdconfidence: highabsent

Returns the SHA-256 fingerprint of the iDRAC TLS certificate as 32 binary bytes. Allows an in-band BIOS/OS agent to pin-validate the iDRAC TLS channel. Only available when Bootstrap Credential Provisioning is enabled.

Request

| Offset | Request field                  |
|--------|--------------------------------|
| 7      | 0x02 (data length              |
| 8      | 0x52 ('R', required magic      |
| 9      | 0x01 (version/subtype selector |

Response

| Offset | Response field |
|----|----|
| 8 | != 'R'; 0xcb if |
| 9 | != 0x01; 0x80 if provisioning disabled or CfgGet fails; 0xff on fingerprint-length mismatch (len != 0x41) or StringToHex error |

Backends `CfgGetAttributeInt (iDRAC.Embedded.1#Security.1#IPMIBootstrapCredentialProvisioning), CfgGetAttribute (iDRAC.Embedded.1#Security.1#TLSCertificateFingerPrint), StringToHex`

**Security** — Exposes TLS cert fingerprint over in-band IPMI; gated on Bootstrap Provisioning being enabled. Allows BIOS/OS agent to authenticate iDRAC TLS channel without a trust anchor.

### 1.3CmdDcmiGetPowerReading Medium

NetFn 0x2c · Cmd 0x02Priv  · **U** O Alibdcmiconfidence: highabsent

DCMI Get Power Reading (DCMI spec section 6.6.1). Returns current, minimum, maximum, and average power consumption in watts, plus a timestamp and measurement period. Reads data from Dell shared memory segment 6 (Dell_shm_memread). Supports two modes: mode 1 = system power (instantaneous statistics window), mode 2 = rolling average over a caller-specified time window. Requires DCMI group extension identifier 0xDC as data\[0\] and platform support (FUN_00104500 feature check). User privilege sufficient.

Request

| Offset | Request field |
|----|----|
| 8 | DCMI Group Extension Identifier, must be 0xDC; any other value → CC=0xcc. byte\[1\] |
| 9 | Mode — 0x01=system power (instantaneous/cumulative window), 0x02=rolling average. byte\[2\] |
| 10 | Rolling average time duration (mode 2 only; ignored for mode 1, must be 0x00). Valid durations for mode 2: 0x00 (same as mode 1 window), 0x81 (1-hour window), 0xC1 (1-day window), 0xC7 (7-day / weekly window); other values → CC=0xcc. byte\[3\] |
| 11 | Reserved, must be 0x00; non-zero → CC=0xcc. |

Response

| Offset | Response field |
|----|----|
| 0 | 0xDC (DCMI group extension ID); param_3\[1-2\]=current power (LE16, watts) from SHM; param_3\[3-4\]=minimum power (LE16, watts) from SHM; param_3\[5-6\]=maximum power (LE16, watts) from SHM; param_3\[7-8\]=average power (LE16, watts) from SHM; param_3\[9-12\]=timestamp (LE32) from SHM; param_3\[13-16\]=measurement time duration (LE32): value 1000 for mode 1, or the low 6 bits of the duration byte cast to uint32 for mode 2 non-zero durations |
| 17 | 0x40 (power measurement active flag). SHM offsets differ by duration: mode-1/0x00: base offsets 0x58D (current), 0x58F (min), 0x591 (max), 0x58B (avg), 0x587 (timestamp); 0x81 (1 hr): 0x1E/0x24/0x26/0x28; 0xC1 (1 day): 0x2C/0x2E/0x38/0x34; 0xC7 (7 day): 0x3A/0x40/0x42/0x44. Error CCs: 0xd5 if platform support check (FUN_00104500) returns 0; 0xcc for invalid data fields. |

Backends `Dell_shm_memread(segment=6, offset, size) — reads power statistics from Dell shared memory segment 6; FUN_00104500() — undetermined platform capability check function (returns 0 if unsupported)`

**Security** — User privilege required. Read-only power telemetry, no configuration path. The four rolling-average windows (0x81/0xC1/0xC7/mode-1) each read distinct SHM offsets; sending an unexpected duration byte that passes the validity check (none do — all other values hit CC=0xcc) is not possible per the current gate logic. Low residual risk: the SHM read could expose stale or inconsistent readings if the producer (power monitoring daemon) crashes.

### 1.4DellCmdGetBootstrapCredentials Critical

NetFn 0x2c · Cmd 0x02Priv  · · · **A**libmisccmdconfidence: highabsent

Returns the IPMI Bootstrap Credentials (32-byte username+password blob) provisioned via iDRAC's Bootstrap Credential Provisioning feature. Unless req+9 equals the keep-enabled sentinel 0xa5, the provisioning flag is auto-cleared after delivery (one-shot semantic).

Request

| Offset | Request field |
|----|----|
| 7 | 0x02 (data length |
| 8 | 0x52 ('R', required magic |
| 9 | 0xa5 keeps provisioning enabled after read, any other value triggers CfgSetAttributeInt to disable IPMIBootstrapCredentialProvisioning |

Response

| Offset | Response field |
|----|----|
| 0 | 0x52 ('R' marker |
| 1 | ..32\]=32-byte bootstrap credential blob from GenerateBootstrapCredentials_IPCClient (username+password). CC=0x00 success; 0xd4 if not in-band; 0xc7 if req len != 2; 0xcc if req+8 != 'R'; 0x80 if provisioning disabled or CfgGet fails; 0xff on IPC or invalid-credential-string error |

Backends `CfgGetAttributeInt/CfgSetAttributeInt (iDRAC.Embedded.1#Security.1#IPMIBootstrapCredentialProvisioning), GenerateBootstrapCredentials_IPCClient (IPC)`

**Security** — Delivers plaintext bootstrap credentials (new IPMI username+password pair) to in-band caller; one-shot by default—provisioning auto-disabled after first read unless sentinel 0xa5 supplied. High-value target: allows OS/BIOS agent to harvest a fresh Admin IPMI credential.

### 1.5CmdDcmiGetPowerLimit Medium

NetFn 0x2c · Cmd 0x03Priv  · **U** O Alibdcmiconfidence: highabsent

DCMI Get Power Limit (DCMI spec section 6.6.2). Returns the currently configured system power cap limit and whether it is active. Reads the power cap value and enabled/disabled state from cfgdb attributes System.Embedded.1#ServerPwr.1#PowerCapValue and System.Embedded.1#ServerPwr.1#PowerCapSetting. Returns CC=0x80 (power limit not active) when the cap is disabled, CC=0x00 when active. Also gates on an LC (Lifecycle Controller) feature license check for power-cap capability (feature bit 0xb) and a secondary platform support check.

Request

| Offset | Request field |
|----|----|
| 8 | must be 0xDC (DCMI group extension ID); any other value → CC=0xcc. byte\[1\] |
| 9 | must be 0x00 (reserved); non-zero → CC=0xcc. byte\[2\] |
| 10 | must be 0x00 (reserved); non-zero → CC=0xcc. |

Response

| Offset | Response field |
|----|----|
| 0 | 0xDC (DCMI group extension ID); param_3\[1-2\]=0x0000 (reserved/exception actions, always zero |
| 3 | 0x00 (exception action for power limit exceeded, always zero in this implementation); param_3\[4-5\]=PowerCapValue (LE16, watts, from cfgdb System.Embedded.1#ServerPwr.1#PowerCapValue); param_3\[6-9\]=1000 (LE32, correction time in milliseconds, hardcoded); param_3\[10-11\]=0x0000 (reserved); param_3\[12-13\]=0x0001 (LE16, statistics sampling period in seconds, hardcoded). CC=0x00 if PowerCapSetting != 0 (power limit active); CC=0x80 if PowerCapSetting == 0 (power limit not active, per DCMI spec); CC=0x6F if LC feature license check for power-cap (lmCheckLcFeature(0xb)) fails; CC=0xd5 if FUN_00104500 platform support check fails; CC=0xd5 if FUN_001045a0 secondary platform check fails; CC=0xFF if CfgGetAttributeInt fails for either cfgdb key. |

Backends `CfgGetAttributeInt("System.Embedded.1#ServerPwr.1#PowerCapValue") — cfgdb power cap wattage; CfgGetAttributeInt("System.Embedded.1#ServerPwr.1#PowerCapSetting") — cfgdb power cap enable flag (0=disabled); lmCheckLcFeature(0xb) — LC license check for power cap feature; FUN_00104500() and FUN_001045a0() — undetermined platform support check functions`

**Security** — User privilege sufficient to read the configured power cap limit and its activation state. CC=0x80 (not active) vs CC=0x00 (active) leaks the power-cap enforcement state without Admin access. The correction time (1000 ms) and sampling period (1 s) are hardcoded — a caller cannot distinguish them from configurable values without probing Set Power Limit. CC=0x6f leaks whether the power-cap license is present, enabling license-state fingerprinting without Admin rights.

### 1.6CmdDcmiSetPowerLimit Medium

NetFn 0x2c · Cmd 0x04Priv  · · **O** Alibdcmiconfidence: highabsent

Set the DCMI power cap value in watts. On IPMB-style channels (channel 3 or 5, i.e., Chassis Manager / CM path) the cap is written directly to shared memory (Dell_shm SHM at offsets 0x7c8 and 0x7c7); on all other channels it is written to cfgdb PowerCapValue. If the cap is already active (PowerCapSetting==1) and the channel is not IPMB, also updates ActivePolicyName to 'DCMI-USER'. Requires lmCheckLcFeature(0xb) to be enabled (returns 0x6f if not licensed). Platform availability is checked via two undetermined functions (FUN_00104500, FUN_001045a0); returns 0xD5 if platform check fails.

Request

| Offset | Request field |
|----|----|
| 7 | 1B): CmdDataLen — number of data bytes (must cover at least 13 data bytes, indices 0-12). |
| 8 | /data\[0\] (1B): Group Extension Identifier = 0xDC; any other value returns 0xCC. |
| 9 | /data\[1\] (1B): Reserved, must be 0x00. |
| 10 | /data\[2\] (1B): Reserved, must be 0x00. |
| 11 | /data\[3\] (1B): Reserved, must be 0x00. |
| 12 | /data\[4\] (1B): Exception Action (0x00..0x11); values above 0x11 return 0xCC. |
| 13 | 14/data\[5-6\] (2B LE): Power Cap in Watts (uint16, stored to PowerCapValue / SHM). |
| 15 | 18/data\[7-10\] (4B): Correction Time Limit in ms (uint32 LE, not validated by this handler). |
| 19 | /data\[11\] (1B): Reserved, must be 0x00. |
| 20 | /data\[12\] (1B): Reserved, must be 0x00; any non-zero value returns 0xCC. Minimum effective data length: 13 bytes. |

Response

CC=0x00 on success. resp_data\[0\] (1B) = 0xDC (Group Extension Identifier). Total resp_data bytes = 1 (\*param_2=1). Error codes: 0xCC = invalid data field (bad magic / reserved field / exception action out of range); 0x6F = feature not licensed; 0xD5 = platform support unavailable; 0xFF = SHM or cfgdb write failure.

Backends `cfgdb keys: System.Embedded.1#ServerPwr.1#PowerCapValue (int write), System.Embedded.1#ServerPwr.1#PowerCapSetting (int read), System.Embedded.1#ServerPwr.1#ActivePolicyName (string write). Dell_shm: type 0x39, offset 0x7c8 (4B, power cap watts) and offset 0x7c7 (1B, flag). lmCheckLcFeature feature 0xB. FUN_00104500 / FUN_001045a0 (platform support checks, undetermined deps).`

**Security** — Operator-level config write to power management policy. Two distinct write paths (cfgdb vs SHM) depending on channel number — attacker controlling channel-handle field could force SHM write path bypassing cfgdb audit trail. Exception action field is validated for range (0x00-0x11) but semantic effect of each value is in the platform firmware, not this handler. License check is the only access gate beyond IPMI privilege level.

### 1.7CmdDcmiActDeactPowerLimit Medium

NetFn 0x2c · Cmd 0x05Priv  · · **O** Alibdcmiconfidence: highabsent

Activate (1) or deactivate (0) the DCMI power cap. Writes the action byte to cfgdb PowerCapSetting. On deactivation: sets ActivePolicyName to empty string. On activation via non-IPMB channels (channel != 3 and != 5): sets ActivePolicyName to 'DCMI-USER'; IPMB/CM channels skip the policy-name update. Requires lmCheckLcFeature(0xb) and platform support checks (same as SetPowerLimit); returns 0xD5 if either fails.

Request

| Offset | Request field |
|----|----|
| 8 | /data\[0\] (1B): Group Extension = 0xDC; else 0xCC. |
| 9 | /data\[1\] (1B): Action — 0x00 = deactivate, 0x01 = activate; any value \> 0x01 returns 0xCC. |
| 10 | /data\[2\] (1B): Reserved, must be 0x00. |
| 11 | /data\[3\] (1B): Reserved, must be 0x00. Minimum data length: 4 bytes. |

Response

CC=0x00 on success. resp_data\[0\] (1B) = 0xDC. Total resp_data bytes = 1 (\*param_2=1). Error codes: 0xCC = invalid data (bad magic, bad action value, non-zero reserved); 0x6F = not licensed; 0xD5 = platform unavailable; 0xFF = cfgdb write failure.

Backends `cfgdb keys: System.Embedded.1#ServerPwr.1#PowerCapSetting (int write, 0 or 1), System.Embedded.1#ServerPwr.1#ActivePolicyName (string write: '' or 'DCMI-USER'). lmCheckLcFeature feature 0xB. FUN_00104500 / FUN_001045a0.`

**Security** — Operator-level toggle of power cap enforcement. Deactivating the cap by writing action=0x00 clears the policy name in cfgdb and disables power limiting with no further confirmation. Channel-number distinction (IPMB vs LAN) affects whether the policy name is updated but not whether the setting takes effect.

### 1.8CmdDcmiGetAssetTag Medium

NetFn 0x2c · Cmd 0x06Priv  · **U** O Alibdcmiconfidence: highabsent

Read a slice of the system asset tag string from cfgdb (key ServerInfo.1#AssetTag), with chunked access controlled by byte offset and count. Maximum tag length is 0x3F bytes; maximum bytes per call is 0x10. If a DcmiCmdHookFuncEntry hook is registered, the hook is dispatched first (hook code 1); if the hook returns DCMI_HOOK_COMMAND_NOT_SUPPORT (2) the built-in cfgdb path runs; if DCMI_HOOK_COMMAND_STATUS_OK (0) the hook provides the response; if DCMI_HOOK_COMMAND_STATUS_FAIL (1) returns 0xCA.

Request

| Offset | Request field |
|----|----|
| 8 | /data\[0\] (1B): Group Extension = 0xDC; else 0xCC. |
| 9 | /data\[1\] (1B): Byte offset into asset tag to start reading (0..0x3E; value \>= 0x3F or the combination offset+count \> 0x3F returns 0xC9). |
| 10 | /data\[2\] (1B): Number of bytes to return (0..0x10; \> 0x10 returns 0xC9). Constraint: offset + count \<= 0x3F. Minimum data length: 3 bytes. |

Response

| Offset | Response field |
|----|----|
| 0 | 1B) = 0xDC (Group Extension). |
| 1 | 1B) = total asset tag length (0..0x3F). |
| 2 | ..2+N-1\] (N bytes) = the requested slice of the tag string starting at the given offset, where N = min(requested_count, available_bytes). \*param_2 = N + 2. Special: if tag is empty, \*param_2=2, resp_data has only 0xDC and length byte (=0). Special: if count=0 in request, only 0xDC + total_length returned. Error codes: 0xCC = bad group magic; 0xC9 = offset or count out of range; 0xCA = hook returned failure. |

Backends `cfgdb key System.Embedded.1#ServerInfo.1#AssetTag (string read, max 0x40 chars). DcmiCmdHookFuncEntry function pointer (optional OEM hook, registered via DCMIRegisterHookFunction).`

**Security** — User-level read. The offset+count bounds are validated before the cfgdb read so there is no read-beyond-buffer risk in this handler. The hook dispatch path calls a function pointer from a global (DcmiCmdHookFuncEntry_00119e48); if this pointer were corrupted (e.g., via a memory-corruption bug elsewhere), an attacker with User-level IPMI access could redirect execution.

### 1.9CmdDcmiGetDcmiSensorInfo Medium

NetFn 0x2c · Cmd 0x07Priv  · · **O** Alibdcmiconfidence: medabsent

Return DCMI sensor record information for inlet-temperature sensors. Validates the entity type (must be 0x01 = inlet temperature) and entity instance against a hard-coded bitmask; allowed instances (3-based) are: 3, 7, 63, 64, 65, 66. Also requires that at least one of the two start-record-handle bytes is zero. Iterates the SDR to count sensor records via GetSDRCount but the decompiled code does not clearly propagate the count into the response; returns a fixed 3-byte stub response. The SDR loop result appears to be optimised out or is a decompiler artifact.

Request

req+8/data\[0\] (1B): Group Extension = 0xDC; else 0xCC. req+9/data\[1\] (1B): Entity Type — must be 0x01 (inlet temperature); other values fail the bitmask check. req+10/data\[2\] (1B): Entity Instance; (instance - 3) must be in {0,4,60,61,62,63}, i.e., instance ∈ {3,7,63,64,65,66}. req+11/data\[3\] (1B): Start Record Handle low byte — at least one of data\[3\] or data\[4\] must be 0x00. req+12/data\[4\] (1B): Start Record Handle high byte. Minimum data length: 5 bytes.

Response

| Offset | Response field |
|----|----|
| 0 | 1B) = 0xDC. |
| 1 | 1B) = undetermined (decompiler shows 0x00 hardcoded after SDR loop; likely total sensor instance count in correct implementation). |
| 2 | 1B) = 0x00 (undetermined). \*param_2 = 3. Error: 0xCC returned if any validation fails (implicit — function returns without setting \*param_2 on failure path, leaving it at 0). |

Backends `SDR subsystem via GetSDRCount and GetSDRAreaHeaderSize (runtime IPMI sensor data repository).`

**Security** — Read-only sensor metadata. Low risk. The decompiled loop appears broken — static analysis cannot confirm the actual response payload beyond the first byte; runtime testing required to verify sensor count and record handles are correctly reported.

### 1.10CmdDcmiSetAssetTag Medium

NetFn 0x2c · Cmd 0x08Priv  · · **O** Alibdcmiconfidence: highabsent

Write a slice of the system asset tag. If offset is 0 the tag is fully replaced (cleared first, then the new bytes are strlcpy'd into a 0x40-byte buffer before writing). If offset \> 0, the current tag is read from cfgdb, the supplied bytes are patched in at the given offset, and the modified full string is written back. After writing the tag, sets AssetTagSetByDCMI flag to 1 in cfgdb. Optionally dispatches to DcmiCmdHookFuncEntry (hook code 2); on hook failure returns 0xC9. If hook returns DCMI_HOOK_COMMAND_NOT_SUPPORT the built-in cfgdb path runs.

Request

req+7 (1B): CmdDataLen; must satisfy CmdDataLen - 3 == data\[2\] (count of bytes to write). req+8/data\[0\] (1B): Group Extension = 0xDC; else 0xCC. req+9/data\[1\] (1B): Byte offset to write at (0..0x3E; \>= 0x3F returns 0xC9). req+10/data\[2\] (1B): Number of bytes to write (0..0x10; \> 0x10 returns 0xC9). Constraint: offset + count \<= 0x3F; else 0xC9. req+11..req+10+count/data\[3..3+N-1\] (N bytes): Tag data to write. Minimum data length: 3 bytes (N=0 allowed — sets empty tag at offset 0, or no-op write at offset\>0 if current tag is shorter).

Response

| Offset | Response field |
|----|----|
| 0 | 1B) = 0xDC. |
| 1 | 1B) = new total asset tag length (= offset + count, as a char sum). \*param_2 = 2. Error codes: 0xC9 (0xC9) = offset/count out of range or offset+count \> 0x3F; 0xCC = bad group magic; 0xC9 also returned via hook failure path; 0xC7 = data length mismatch (count != CmdDataLen-3). |

Backends `cfgdb keys: System.Embedded.1#ServerInfo.1#AssetTag (string read+write, max 0x40), System.Embedded.1#ServerInfo.1#AssetTagSetByDCMI (int write, set to 1). DcmiCmdHookFuncEntry optional hook.`

**Security** — Operator-level write to a system identity field. The tag is validated for length (max 0x3F chars) and the write-count is cross-checked against CmdDataLen to prevent header/data mismatch. However, the asset tag is a free-form string stored in cfgdb and rendered in management interfaces; if the UI does not escape it, this is a stored-XSS or injection vector accessible at Operator privilege. Also sets AssetTagSetByDCMI=1 permanently — no way to clear this flag via DCMI.

### 1.11CmdDcmiGetManagementControllerIdStr Critical

NetFn 0x2c · Cmd 0x09Priv  · **U** O Alibdcmiconfidence: medabsent

Read a slice of the DCMI Management Controller ID string in chunks. Validates offset and count bounds identically to GetAssetTag (max string 0x3F bytes, max per call 0x10 bytes). Delegates retrieval to internal function FUN_00104840 (backend undetermined from static analysis — likely cfgdb or Get Device ID string).

Request

| Offset | Request field |
|----|----|
| 8 | /data\[0\] (1B): Group Extension = 0xDC; else 0xCC. |
| 9 | /data\[1\] (1B): Byte offset (0..0x3E; \>= 0x3F returns 0xC9). |
| 10 | /data\[2\] (1B): Number of bytes to read (0..0x10; offset + count must be \< 0x40). Minimum data length: 3 bytes. |

Response

| Offset | Response field |
|----|----|
| 0 | 1B) = 0xDC. |
| 1 | 1B) = total MC ID string length. |
| 2 | ..2+N-1\] (N bytes) = requested slice of the ID string (N = requested count, or 0 if count is 0). \*param_2 = count + 2. Error codes: 0xCC = bad group magic or offset/count validation failed; 0xC9 = FUN_00104840 returned non-zero completion code. |

Backends `FUN_00104840 (undetermined — internal DCMI helper; backend cfgdb key or IPMI Get Device ID string not determinable from static analysis alone).`

**Security** — User-level read. Risk depends on what FUN_00104840 reads; if it touches credentials or config strings, any LAN-accessible user could call this. Bounds validation is correct.

### 1.12CmdDcmiSetManagementControllerIdStr High

NetFn 0x2c · Cmd 0x0aPriv  · · · **A**libdcmiconfidence: medabsent

Write a slice of the DCMI Management Controller ID string (up to 0x10 bytes per call, max total string 0x3F bytes). Cross-checks that the supplied byte count equals CmdDataLen - 3. Delegates the actual write to internal function FUN_00104670 (backend undetermined). On success, returns the new total string length in the response.

Request

| Offset | Request field |
|----|----|
| 7 | 1B): CmdDataLen; must satisfy CmdDataLen - 3 == data\[2\] (returns 0xC9 if mismatch). |
| 8 | /data\[0\] (1B): Group Extension = 0xDC; else 0xCC. |
| 9 | /data\[1\] (1B): Byte offset (0..0x3E; \>= 0x3F returns 0xC7). |
| 10 | /data\[2\] (1B): Number of bytes to write (0..0x10; \> 0x10 returns 0xC7). Constraint: offset + count \< 0x40. |
| 11 | ..data\[3..3+N-1\] (N bytes): String bytes to write. Minimum data length: 3 bytes. |

Response

| Offset | Response field |
|----|----|
| 0 | 1B) = 0xDC. |
| 1 | 1B) = new total MC ID string length (from local_40.\_1_1\_ returned by FUN_00104670). \*param_2 = 2. Error codes: 0xCC = bad group magic; 0xC7 = offset out of range (\>= 0x3F) or count \> 0x10; 0xC9 = length mismatch (count != CmdDataLen-3) or offset+count \>= 0x40; 0xC7 also from general constraint failure inside FUN_00104670. |

Backends `FUN_00104670 (undetermined — writes MC ID string; likely cfgdb or NVRAM; backend and key name not recoverable from static analysis of this handler).`

**Security** — Admin-only write to the BMC identity string. If FUN_00104670 writes to cfgdb without escaping, the MC ID string (which may be rendered in the WebUI or returned in Get Device ID responses) could carry injected content. The length cap (0x3F) limits buffer overflow risk but does not prevent injection payloads of that size.

### 1.13CmdDcmiSetThermalLimit Medium

NetFn 0x2c · Cmd 0x0bPriv  · · **O** Alibdcmiconfidence: highabsent

Set a Dell-extended DCMI inlet temperature limit. Validates entity ID (must be 0x37=inlet or 0x40), entity instance (signed byte \>= 0), flag byte (bits 7,4,3 must be 0), exact data length (must be exactly 7 bytes), and a non-zero uint16 limit value. In the current build, pInletTempSensorInfo is always NULL so the function unconditionally logs 'pInletTempSensorInfo is NULL' and returns CC=0xCB — no success path is reachable. This is a non-standard Dell extension; not part of the DCMI 1.5 specification.

Request

| Offset | Request field |
|----|----|
| 7 | 1B): CmdDataLen — must be exactly 7 (0x07); returns 0xC7 (=199 decimal) if not. |
| 8 | /data\[0\] (1B): Group Extension = 0xDC; else 0xCC. |
| 9 | /data\[1\] (1B): Entity ID — 0x37 (0x37='7', inlet temperature) or 0x40 ('@'); other values return 0xCC. |
| 10 | /data\[2\] (1B): Entity instance, treated as signed; must be \>= 0 (0..127); negative value returns 0xCC. |
| 11 | /data\[3\] (1B): Flags/configuration byte; bits 7, 4, 3 must be 0 (mask 0x9F); else 0xCC. |
| 12 | /data\[4\] (1B): Unknown field (not range-validated in this handler). |
| 13 | 14/data\[5-6\] (2B LE): Temperature limit as uint16 (via MakeUINT16(data\[6\], data\[5\])); must be non-zero, else returns 0x85. Minimum and maximum data length: exactly 7 bytes. |

Response

No success response reachable in current build. CC=0xCB (Command Not Supported in Present State / Destination Unavailable) always returned when all inputs are valid but sensor info pointer is NULL. Intermediate validation failures return: 0xCC = bad magic / entity ID / instance / flag bits; 0xC7 = wrong data length; 0x85 = zero thermal limit value.

Backends `pInletTempSensorInfo (runtime global pointer, NULL in current build — sensor table not populated). MakeUINT16 (byte-swap helper). GetInletTemperatureInstBySensorNum (likely called by the code path after sensor lookup, unreachable).`

**Security** — Dead code in current firmware build — always returns 0xCB. If sensor info is populated in a future build or different configuration, an Operator could set inlet temperature shutdown thresholds, potentially triggering false thermal events or preventing legitimate thermal protection. The 0x9F flag-byte mask leaves bits 6,5,2,1,0 available for undocumented control that is not inspected further in this handler.

### 1.14CmdDcmiGetThermalLimit Medium

NetFn 0x2c · Cmd 0x0cPriv  · **U** O Alibdcmiconfidence: highabsent

Returns the configured DCMI thermal limit for a specified entity (inlet or outlet temperature sensor). Reads exception actions and sampling period from in-memory globals populated by CmdDcmiSetThermalLimit; does not read cfgdb. The temperature limit field in the response is always written as 0x00 in this code path — it is undetermined whether a separate path populates it or whether the implementation is incomplete.

Request

| Offset | Request field |
|----|----|
| 7 | data_length (not validated). |
| 8 | data\[0\]: Group Extension ID, must be 0xDC (required). |
| 9 | data\[1\]: Entity ID; must be 0x37 (system board/inlet) or 0x40 (processor/outlet) — any other value causes silent no-op return with CC=0xCC. |
| 10 | data\[2\]: Entity Instance Number \[6:0\]; bit7 must be clear (\>=0); values with bit7 set are rejected (CC=0xCC). |

Response

| Offset | Response field |
|----|----|
| 0 | 0xDC (DCMI group extension ID). |
| 1 | Exception Actions byte (from global DAT_0011a1d2; clamped to 0x00 if the global is -1/unset). |
| 2 | 0x00 (Temperature Limit — hard-coded to zero in this path; undetermined if set by another code path). |
| 3 | ..4\]=Sampling Period in seconds as 16-bit LE (from global DAT_0011a1d0, byte-swapped via HtoLSB16). Response data length field (\*param_2) set to 5. |

Backends `In-memory globals DAT_0011a1d0 (16-bit sampling period, undefined2) and DAT_0011a1d2 (exception actions byte) — populated by CmdDcmiSetThermalLimit at runtime; no cfgdb or dbus reads.`

**Security** — Read-only. Exposes thermal limit configuration (exception actions, sampling period). Low risk. Temperature limit always returned as 0 regardless of entity/instance arguments, which may indicate partial implementation. No data is written.

### 1.15CmdDcmiGetTemperatureReadings Medium

NetFn 0x2c · Cmd 0x10Priv  · **U** O Alibdcmiconfidence: highabsent

Returns current temperature sensor readings from one of three in-memory sensor tables (inlet, baseboard, or CPU), selected by a sensor-type code. For each matching sensor, calls SenMgrGetSensorReading() and converts the raw reading to Celsius using the SDR linear formula (ESSDScaleSensorValue). Supports filtering by entity instance or returning all instances. Returns at most 8 readings per call. Both total instance count and matched readings count are reported in the response.

Request

Minimum 5 data bytes (data\[3\] and data\[4\] are read unconditionally; no explicit length check). req+8=data\[0\]: Group Extension ID=0xDC (required). req+9=data\[1\]: Sensor Type=0x01 (Temperature); must be exactly 0x01. req+10=data\[2\]: Entity/sensor-table selector — valid values: 0x37 or 0x40 -\> inlet temp table; 0x42 or 0x07 -\> baseboard temp table; 0x41 or 0x03 -\> CPU temp table. (Validated against bitmask 0xe010000000000011 shifted by (data\[2\]-3); other values cause CC=0xCC with no-op return.) req+11=data\[3\]: Entity Instance filter; 0=return all matching instances, non-zero=filter to exact instance. req+12=data\[4\]: Starting instance offset (pagination); must be 0 when data\[3\] is non-zero — if both data\[3\] and data\[4\] are non-zero, the request is rejected (CC=0xCC).

Response

| Offset | Response field |
|----|----|
| 0 | 0xDC (DCMI group extension). |
| 1 | Total number of sensor instances iterated in the selected table range. |
| 2 | Number of valid temperature readings returned (N, max 8). For i in 0..N-1 |
| 3 | +2\*i\]=temperature in Celsius with bit7 cleared (raw SDR reading scaled by formula |
| 4 | +2\*i\]=entity instance number of that sensor. Response data length (\*param_2) = 3 + N\*2 (initial value 3; updated per reading appended). |

Backends `In-memory sensor tables: G_sInletTempSensorTable, G_sBaseboardTempSensorTable, G_sCPUTempSensorTable (linked lists populated at DCMI init). SenMgrGetSensorReading() for live IPMI sensor readings. ESSDScaleSensorValue() for SDR Type 1 linear formula conversion using SDR calibration coefficients (M, B, Rexp, Bexp from lVar10+0x18..+0x1d offsets).`

**Security** — Read-only. Exposes system temperature data. Iterating all instances via data\[3\]=0 enumerates the full sensor topology (count, instance numbers). Max 8 readings per call limits response size. No write path. Low risk.

### 1.16CmdDcmiSetDMCIConfigParam Critical

NetFn 0x2c · Cmd 0x12Priv  · · · **A**libdcmiconfidence: highabsent

Sets DCMI configuration parameters for DHCP-based management discovery and optionally resets the Management Controller ID string. Writes to cfgdb iDRAC.Embedded.1#NIC.1# keys (iDRAC gen\<6) or iDRAC.Embedded.1#Network.1# keys (gen\>=6). Supports five parameter selectors: MC ID string reset (0x01), DHCP option flags (0x02), DHCP packet timeout (0x03), DHCP retry timeout (0x04), DHCP wait interval (0x05). Param 0x02 encodes three DHCP flags in a single bitmask byte; params 0x04 and 0x05 carry 16-bit values in big-endian order.

Request

req+8=data\[0\]: Group Extension ID=0xDC (required). req+9=data\[1\]: Parameter Selector 0x01..0x05; values outside this range return CC=0xC7. req+10=data\[2\]: Parameter Set Selector; must be 0x00 — any non-zero value returns CC=0xCC. req+7=data_length (used as sub-selector): must be 4 for params 0x01/0x02/0x03, must be 5 for params 0x04/0x05 (wrong length for those params causes silent fall-through to CC=0xC7). req+11=data\[3\]: Param value byte (all params) or MSB-adjacent of 16-bit value. req+12=data\[4\]: 2nd byte of 16-bit value (params 0x04 and 0x05 only). Parameter details — Param 0x01 (data_len=4): data\[3\]=0x01 triggers MC ID string global clear (sMgCtrIdStrOut zeroed, FUN_00104840 called); any other data\[3\] is a no-op but still returns success. Param 0x02 (data_len=4): data\[3\] bitmask — bit0=DCMIDHCPopt12 (Option 12 hostname), bit1=DCMIDHCPopt60opt43 (Option 60/43 vendor class), bit7=DCMIDHCPrandombackoff (random backoff enable); bits\[6:2\] must be zero else CC=0xCC. Param 0x03 (data_len=4): data\[3\]=DCMIDHCPpkttimeout (u8 seconds). Param 0x04 (data_len=5): data\[3..4\] big-endian u16=DCMIDHCPretrytimeout (seconds). Param 0x05 (data_len=5): data\[3..4\] big-endian u16=DCMIDHCPwaitinterval (seconds). The u16 is byte-swapped before passing to CfgSetAttributeInt.

Response

Return value (completion code): 0x00 on success, 0xFF on cfgdb write failure (dlog_printf logged), 0xC7 on invalid parameter selector or data length mismatch. resp_data\[0\]=0xDC (DCMI group extension). Response data length (\*param_2) = 1 on success.

Backends `CfgSetAttributeInt() writes to cfgdb keys: iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPretrytimeout, iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPwaitinterval, iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPrandombackoff, iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPopt60opt43, iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPopt12, iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPpkttimeout. NIC.1 vs Network.1 key prefix selected by Dell_get_generation() at runtime. In-memory global sMgCtrIdStrOut (MC ID string struct, 0x40 bytes zeroed on param 0x01 reset).`

**Security** — Admin-gated network/DHCP config write. Incorrect timeout values could disrupt DCMI DHCP-based management discovery. Param 0x01 reset clears MC ID string only in RAM (no cfgdb persistence observed); effect survives until daemon restart. The DHCP option flags (opt12, opt60opt43) affect what the BMC advertises in DHCP requests — relevant to network fingerprinting and DHCP server targeting. No credential or firmware write path.

### 1.17CmdDcmiGetDMCIConfigParam High

NetFn 0x2c · Cmd 0x13Priv  · **U** O Alibdcmiconfidence: highabsent

Reads DCMI configuration parameters from cfgdb. Counterpart to CmdDcmiSetDMCIConfigParam. Every response includes DCMI spec conformance (1.5) and parameter revision (1) in bytes resp\[1..3\]. Supports the same five parameter selectors as the Set command. Parameter 0x01 (MC ID string) always returns 0x00 in the data byte — no cfgdb read is performed for it; this appears to be an incomplete or stub implementation.

Request

| Offset | Request field |
|----|----|
| 7 | data_length) must equal 3 — any other length for a valid param selector returns CC=0xC7. |
| 8 | data\[0\]: Group Extension ID=0xDC (required). |
| 9 | data\[1\]: Parameter Selector 0x01..0x05; out-of-range with data_len=3 returns CC=0xCC; out-of-range with other data_len returns CC=0xC7. |
| 10 | data\[2\]: Parameter Set Selector; must be 0x00, else CC=0xCC. |

Response

Return value (completion code): 0x00 on success, 0xFF on cfgdb read failure (dlog_printf logged), 0xC7 on invalid selector or wrong data_length, 0xCC on set-selector!=0 or out-of-range param with correct length. resp_data\[0\]=0xDC (DCMI group extension, written as part of 4-byte literal 0x010501dc LE). resp_data\[1\]=0x01 (DCMI major spec conformance). resp_data\[2\]=0x05 (DCMI minor spec conformance). resp_data\[3\]=0x01 (parameter revision). resp_data\[4\] or resp_data\[4..5\] per parameter: Param 0x01: resp_data\[4\]=0x00 (stub, no cfgdb read); \*param_2=5. Param 0x02: resp_data\[4\]=DHCP option bitmask (bit7=randombackoff, bit1=opt60opt43, bit0=opt12 — same encoding as Set); \*param_2=5. Param 0x03: resp_data\[4\]=DCMIDHCPpkttimeout (u8); \*param_2=5. Param 0x04: resp_data\[4..5\]=DCMIDHCPretrytimeout as u16 big-endian (byte-swapped from cfgdb native); \*param_2=6. Param 0x05: resp_data\[4..5\]=DCMIDHCPwaitinterval as u16 big-endian; \*param_2=6.

Backends `CfgGetAttributeInt() reads from cfgdb keys: iDRAC.Embedded.1#{NIC|Network}.1#DCMIDHCPretrytimeout, DCMIDHCPwaitinterval, DCMIDHCPrandombackoff, DCMIDHCPopt60opt43, DCMIDHCPopt12, DCMIDHCPpkttimeout. NIC.1 vs Network.1 prefix selected by Dell_get_generation(). No cfgdb read for param 0x01 (MC ID string).`

**Security** — User-gated read. Exposes DHCP timing parameters and DHCP option flag configuration. Reveals network discovery settings useful for targeted DHCP spoofing against the BMC. Param 0x01 always returns 0 regardless of stored MC ID string state — read asymmetry with the Set command. Low direct risk.

## 2. In-Band iSM Bridge (KCS/host) (80)

Host-interface (KCS) commands bridging the OS to iDRAC: iSM channel, OAuth token, mTLS cert, racadm passthrough. Reachable from the host with no BMC credentials.

### 2.1SubCmdHandler/0xce/SystemPowerCapacity Medium

NetFn 0x30 · Cmd 0xce · Sub 0x0Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get/set system power capacity limits. Leaf handler: SystemPowerCapacity() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `SystemPowerCapacity() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.2SubCmdHandler/0xce/PhysicalTopology Medium

NetFn 0x30 · Cmd 0xce · Sub 0x1Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get physical chassis topology information. Leaf handler: PhysicalTopology() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `PhysicalTopology() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.3SubCmdHandler/0xce/getActivePowerPolicy Low

NetFn 0x30 · Cmd 0xce · Sub 0x3Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get active power management policy. Leaf handler: getActivePowerPolicy() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `getActivePowerPolicy() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.4SubCmdHandler/0xce/PSURapidON Medium

NetFn 0x30 · Cmd 0xce · Sub 0x4Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

PSU rapid power-on control. Leaf handler: PSURapidON() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `PSURapidON() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.5SubCmdHandler/0xce/getPSUSysCapability Low

NetFn 0x30 · Cmd 0xce · Sub 0x5Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get PSU system capability data. Leaf handler: getPSUSysCapability() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `getPSUSysCapability() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.6SubCmdHandler/0xce/PSUPFC Medium

NetFn 0x30 · Cmd 0xce · Sub 0x6Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

PSU power factor correction control. Leaf handler: PSUPFC() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `PSUPFC() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.7SubCmdHandler/0xce/ThermalSetting Medium

NetFn 0x30 · Cmd 0xce · Sub 0x9Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get/set thermal configuration settings. Leaf handler: ThermalSetting() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `ThermalSetting() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.8SubCmdHandler/0xce/getTempSensorNumber Low

NetFn 0x30 · Cmd 0xce · Sub 0xaPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get temperature sensor count. Leaf handler: getTempSensorNumber() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `getTempSensorNumber() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.9SubCmdHandler/0xce/DellOEMCmdPwrSimulationMngmnt Medium

NetFn 0x30 · Cmd 0xce · Sub 0xbPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Power simulation management. Leaf handler: DellOEMCmdPwrSimulationMngmnt() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `DellOEMCmdPwrSimulationMngmnt() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.10SubCmdHandler/0xce/VRConfiguration Medium

NetFn 0x30 · Cmd 0xce · Sub 0xdPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Voltage regulator configuration. Leaf handler: VRConfiguration() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `VRConfiguration() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.11SubCmdHandler/0xce/TempReadings Medium

NetFn 0x30 · Cmd 0xce · Sub 0xePriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get temperature sensor readings. Leaf handler: TempReadings() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `TempReadings() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.12SubCmdHandler/0xce/getPowerReading Low

NetFn 0x30 · Cmd 0xce · Sub 0xfPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get current power consumption reading. Leaf handler: getPowerReading() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `getPowerReading() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.13SubCmdHandler/0xce/pwrBudgetCheck Medium

NetFn 0x30 · Cmd 0xce · Sub 0x10Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Check power budget allocation. Leaf handler: pwrBudgetCheck() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `pwrBudgetCheck() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.14SubCmdHandler/0xce/psuHotSpareThreshold Medium

NetFn 0x30 · Cmd 0xce · Sub 0x11Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

PSU hot-spare activation threshold. Leaf handler: psuHotSpareThreshold() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `psuHotSpareThreshold() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.15SubCmdHandler/0xce/slbOverRide Medium

NetFn 0x30 · Cmd 0xce · Sub 0x12Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

System-level budget override. Leaf handler: slbOverRide() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `slbOverRide() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.16SubCmdHandler/0xce/clstOverRide Medium

NetFn 0x30 · Cmd 0xce · Sub 0x13Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Cluster-level budget override. Leaf handler: clstOverRide() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `clstOverRide() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.17SubCmdHandler/0xce/psuMismatchOverRide Medium

NetFn 0x30 · Cmd 0xce · Sub 0x14Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

PSU mismatch override setting. Leaf handler: psuMismatchOverRide() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `psuMismatchOverRide() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.18SubCmdHandler/0xce/updateGpGPUPBT Medium

NetFn 0x30 · Cmd 0xce · Sub 0x15Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Update GPU power budget table. Leaf handler: updateGpGPUPBT() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `updateGpGPUPBT() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.19SubCmdHandler/0xce/ThermalOverride Medium

NetFn 0x30 · Cmd 0xce · Sub 0x16Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Thermal override control. Leaf handler: ThermalOverride() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `ThermalOverride() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.20SubCmdHandler/0xce/PowerThermalTableInfo Medium

NetFn 0x30 · Cmd 0xce · Sub 0x17Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get power-thermal lookup table info. Leaf handler: PowerThermalTableInfo() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `PowerThermalTableInfo() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.21SubCmdHandler/0xce/ThermalEBInfo Medium

NetFn 0x30 · Cmd 0xce · Sub 0x18Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get thermal energy balance info. Leaf handler: ThermalEBInfo() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `ThermalEBInfo() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.22SubCmdHandler/0xce/psuDisableACDiscHandler Medium

NetFn 0x30 · Cmd 0xce · Sub 0x19Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

PSU AC disconnect disable handler. Leaf handler: psuDisableACDiscHandler() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `psuDisableACDiscHandler() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.23SubCmdHandler/0xce/PSUFixedInputBulkVoltage Medium

NetFn 0x30 · Cmd 0xce · Sub 0x1aPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get/set PSU fixed bulk voltage. Leaf handler: PSUFixedInputBulkVoltage() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `PSUFixedInputBulkVoltage() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.24SubCmdHandler/0xce/LiquidCoolingSensorConfig Medium

NetFn 0x30 · Cmd 0xce · Sub 0x1bPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Liquid cooling sensor configuration. Leaf handler: LiquidCoolingSensorConfig() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `LiquidCoolingSensorConfig() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.25SubCmdHandler/0xce/powerExtendedCmds Medium

NetFn 0x30 · Cmd 0xce · Sub 0x1cPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Extended power management commands. Leaf handler: powerExtendedCmds() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable. Supports multi-chunk GET/SET via offset/length fields.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout for GET/SET undetermined (leaf handler in external library).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response payload layout undetermined (leaf handler in libmisccmd.so.9.9.9, not decompiled). CC values: 0=success; 0xc7=bad direction (not 0 or 1); 0xc8=data too large; 0xc6=len+offset exceeds 0x800; 0xc9=requested len exceeds max IPMI msg size; 0xc1=subcmd not found in table. |

Backends `powerExtendedCmds() in libmisccmd.so.9.9.9; likely power/thermal dbus services and cfgdb power keys.`

**Security** — Admin-only. Power/thermal SET subcmds can alter power caps and thermal thresholds (potential DoS via thermal runaway or power exhaustion). Specific impact undetermined without libmisccmd.so decompilation.

### 2.26SubCmdHandler/0xcf/OSBmcPtAttributes Critical

NetFn 0x30 · Cmd 0xcf · Sub 0x00Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Get or set OS-to-BMC USB passthrough network attributes: USB NIC P2P enable state, IP address (IPv4 or IPv6), and MAC address. GET reads iDRAC.Embedded.1#OS-BMC.1#{UsbP2PEnable,UsbNicIpAddress,UsbNicIpV6Address,UsbNicMacAddress} from cfgdb. SET enables USB P2P and writes UsbNicIpAddress to cfgdb (IPv6 writes are silently ignored with CC=0 on 16G hardware).

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET: outer data_len=7; inner_param\[0\]=IP stack mode (0=IPv4, 1=IPv6; CC=0xc9 if \>1). SET: outer SET payload (40 bytes): byte\[0\]=IP stack mode (0/1); byte\[1\]=USB PT value (must be 0x15 or 0x25; CC=0xc9 if invalid); bytes\[2..17\]=IP address (text string for IPv4, or binary IPv6 16 bytes); bytes\[18..21\]=IPv4 netmask (binary 4 bytes; must be zero for IPv6 mode, CC=0xce if not); bytes\[22..39\]=unused.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc9 if IP stack mode \> 1 or USB PT value out of range. CC=0xce if cfgdb read/write fails. CC=0xc7 (199) if data_len wrong for direction. GET CC=0 → 46-byte payload: leaf\[0\]=USB P2P enable (0x15=enabled, 0x00=disabled); leaf\[1\]=0x02 (constant); leaf\[2..16\]=USB NIC IPv4 address text (up to 15 chars, null-padded); leaf\[18..23\]=USB NIC MAC address (6 bytes binary, present only if P2P enabled); leaf\[24..29\]=zeros; leaf\[30..37\]=zeros; leaf\[38..45\]=zeros. SET CC=0 → no additional payload beyond 5-byte SubCmdHandler header. |

Backends `cfgdb keys: iDRAC.Embedded.1#OS-BMC.1#UsbP2PEnable (int), iDRAC.Embedded.1#OS-BMC.1#UsbNicIpAddress (str), iDRAC.Embedded.1#OS-BMC.1#UsbNicIpV6Address (str), iDRAC.Embedded.1#OS-BMC.1#UsbNicMacAddress (str). CfgGetAttribute / CfgSetAttribute / CfgSetAttributeInt.`

**Security** — Admin-only write path can configure USB NIC IP address used by OS-BMC passthrough channel. An attacker with Admin credentials can redirect the OS-BMC passthrough to an arbitrary IP, potentially facilitating MITM on in-band host communications. READ exposes NIC MAC address and USB NIC IP.

### 2.27SubCmdHandler/0xcf/OSBmcPtUSB Medium

NetFn 0x30 · Cmd 0xcf · Sub 0x02Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Get or set the USB NIC passthrough network configuration (P2P enable, IP address, IPv6 address, MAC address, and IPv4 netmask). GET reads all USB NIC configuration from cfgdb and returns binary network parameters. SET validates and writes new IP/IPv6 address, netmask, and P2P enable flag to cfgdb.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET: outer data_len=7; inner_param\[0\]=IP stack mode (0=IPv4, 1=IPv6; CC=0xc9 if \>1). SET: 22-byte payload: byte\[0\]=IP stack mode (0=IPv4, 1=IPv6; CC=0xc9 if \>1); byte\[1\]=USB PT enable (0/1; CC=0xc9 if \>1); bytes\[2..5\]=IPv4 address (binary 4 bytes, mode=0) OR bytes\[2..17\]=IPv6 address (16 bytes, mode=1); bytes\[18..21\]=IPv4 netmask (binary, mode=0; CC=0xce if non-zero for mode=1).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc9 if stack mode or PT value out of range. CC=0xce if cfgdb read/write fails or invalid IP format. CC=0xc7 if data_len wrong. GET CC=0 → 28-byte payload: leaf\[0\]=UsbP2PEnable (0/1); leaf\[1\]=0x02 (constant); leaf\[2..5\]=IPv4 addr (binary) OR leaf\[2..17\]=IPv6 addr (binary); leaf\[18..23\]=MAC address (6 bytes binary, present if P2P enabled); leaf\[24..27\]=IPv4 netmask (binary, or 0 for IPv6 mode). |

Backends `cfgdb: iDRAC.Embedded.1#OS-BMC.1#{UsbP2PEnable, UsbNicIpAddress, UsbNicIpV6Address, UsbNicMacAddress, UsbNicIPNetmask}. Uses inet_pton/inet_ntop for address validation.`

**Security** — Admin write path can change USB NIC IP/IPv6/netmask used for OS-BMC USB passthrough. Setting a hostile IP could redirect passthrough traffic. Read path exposes MAC address and current IP configuration.

### 2.28SubCmdHandler/0xcf/OSBmcPtLOM Medium

NetFn 0x30 · Cmd 0xcf · Sub 0x03Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Get or set the LOM (LAN on Motherboard) NIC passthrough configuration: LOM P2P enable, PT capability, MAC address, and IPv4 netmask. GET reads PTCapability, LomP2PEnable, UsbNicMacAddress, and UsbNicIPNetmask from cfgdb. SET enables/disables LOM passthrough; only allowed if PT hardware capability is present.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET: outer data_len=7; inner_param\[0\]=IP stack mode (0=IPv4, 1=IPv6; CC=0xc9 if \>1). SET: 22-byte payload: byte\[0\]=IP stack mode (0=IPv4, 1=IPv6; CC=0xc9 if \>1); byte\[1\]=LOM PT enable (0/1; CC=0xc9 if \>1); bytes\[2..17\]=IP address (16 bytes; must be all-zero for PT capable mode, CC=0xce if not); bytes\[18..21\]=IPv4 netmask (must be all-zero, CC=0xce if not).

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xce if cfgdb read/write fails or if PT capability is absent (set blocked). CC=0xc9 if IP stack mode or LOM PT out of range. CC=0xc7 if data_len wrong. GET CC=0 → 28-byte payload: leaf\[0..1\]=LE16 PT+P2P state (0x0201 if PT capable AND LOM P2P enabled; else 0x0002); leaf\[2..17\]=zeros; leaf\[18..23\]=USB NIC MAC address (6 bytes binary, if LOM P2P enabled); leaf\[24..27\]=IPv4 netmask (binary) or 0x00000000 for IPv6 mode. |

Backends `cfgdb: iDRAC.Embedded.1#OS-BMC.1#{PTCapability, LomP2PEnable, UsbNicMacAddress, UsbNicIPNetmask}. Uses inet_pton for netmask format validation.`

**Security** — Admin write path can enable/disable LOM NIC passthrough. PT capability must be present in hardware (hardware-enforced gate). Read exposes NIC MAC address. SET validates IP/netmask are zero (cannot set LOM IP via this cmd). Enabling LOM P2P on a hardware-capable system could open a new network path.

### 2.29SubCmdHandler/0xd1/LicensingResetFlag Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x00Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that resets iDRAC license management flags and returns a 4-byte zero-filled response (likely a reset-confirmation payload). Not available via SET direction.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner_param data_len (req\[7\]-6) must be 4. inner_params\[0..3\]: content undetermined (4 bytes required but not checked individually). CC=0xc1 if SET direction. CC=0xc7 if inner data_len != 4.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc1 if direction is SET. CC=0xc7 if inner data_len != 4. GET CC=0 → 4-byte leaf payload (all 0x00). Total response: 9 bytes (5-byte SubCmdHandler header + 4-byte payload). |

Backends `None visible in decompile (writes only to response buffer; no cfgdb/dbus calls).`

**Security** — Admin-only. Clears/resets license flags (exact flag semantics undetermined). Could be used to manipulate licensing state or clear license enforcement markers.

### 2.30SubCmdHandler/0xd1/LicensingEntireBitmap Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x01Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that retrieves the entire Dell Feature Entitlement Bitmap (FEB) from the License Manager (LM). Returns 48 bytes of license feature flags. If the high nibble of the first response byte is 0x7, also clears IMC previous status bit 0x10000000.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 4. inner_params\[0..3\]: passed to DellAbsDMGetLMiDracFEB() (undetermined semantics). CC=0xc1 if SET direction. CC=0xc7 if inner data_len != 4.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc1 if SET direction. CC=0xc7 if inner data_len != 4. CC=0x7e if DellAbsDMGetLMiDracFEB() fails. GET CC=0 → 48-byte (0x30) FEB payload written by DellAbsDMGetLMiDracFEB() into response buffer. Payload layout is specific to the LM ABI (undetermined without libdellabsdm.so decompilation). Total response: 53 bytes (5-byte header + 48-byte FEB). |

Backends `DellAbsDMGetLMiDracFEB() in libdellabsdm.so.9. DellClearIMCPrevStatusBit() (conditionally called if FEB[0] high nibble == 7).`

**Security** — Admin-only. Returns the full license feature bitmap, revealing which iDRAC features are licensed. This could inform attackers about the presence/absence of security features (e.g., iDRAC Enterprise, Remote Console, OpenManage). Side effect: may clear an IMC status bit.

### 2.31SubCmdHandler/0xd1/LicensingSingleStatus Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x02Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that queries the license status for a single iDRAC licensable feature. The feature ID (1..256) is passed in the inner payload; the result from DellAbsDMCheckLcFeature() is returned as a 1-byte status.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 2. inner_params\[0..1\]: LE16 feature ID (1..256 valid; CC=0xcc if 0 or \>256). CC=0xc1 if SET. CC=0xc7 if inner data_len != 2.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc1 if SET direction. CC=0xc7 if inner data_len != 2. CC=0xcc if feature ID out of range (0 or \>256). CC=0x7e if DellAbsDMCheckLcFeature() fails. GET CC=0 → 1-byte leaf payload: feature license status byte. Total response: 6 bytes (5-byte header + 1-byte status). |

Backends `DellAbsDMCheckLcFeature(feature_id) in libdellabsdm.so.9.`

**Security** — Admin-only. Allows enumeration of individual feature license states (up to 256 features). An attacker can iterate feature IDs to map the iDRAC license configuration, identifying which security/management features are present.

### 2.32SubCmdHandler/0xd1/LicensableDeviceList Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x05Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that retrieves the list of licensable devices managed by iDRAC. Calls DellAbsDMGetLicensableDeviceList() and returns the list in the response buffer.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 4. inner_params\[0..3\]: passed to DellAbsDMGetLicensableDeviceList() (semantics undetermined). CC=0xc1 if SET. CC=0xc7 if inner data_len != 4.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc1 if SET direction. CC=0xc7 if inner data_len != 4. CC=0x7e if DellAbsDMGetLicensableDeviceList() fails. GET CC=0 → device list payload from DellAbsDMGetLicensableDeviceList() (layout undetermined without libdellabsdm.so decompilation). |

Backends `DellAbsDMGetLicensableDeviceList() in libdellabsdm.so.9.`

**Security** — Admin-only. Returns enumeration of licensable devices (NICs, storage controllers, etc.). Reveals device inventory information.

### 2.33SubCmdHandler/0xd1/LicensableDeviceCurrentClass Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x06Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that returns the current license class for a specific licensable device. Device is selected by a 1-byte device index passed in the inner payload. Calls DellAbsDMGetLicensableDeviceCurrentClass(device_idx).

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 4. inner_params\[0\]=device index (byte). inner_params\[1..3\]: unused. CC=0xc1 if SET. CC=0xc7 if inner data_len != 4.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc1 if SET. CC=0xc7 if inner data_len != 4. CC=0xcc if device not found (DellAbsDM returns 7). CC=0x7e if DellAbsDM returns non-zero and non-7 and non-(-1). CC=0xff if DellAbsDM returns -1. GET CC=0 → device current license class payload (layout undetermined). |

Backends `DellAbsDMGetLicensableDeviceCurrentClass(device_idx) in libdellabsdm.so.9.`

**Security** — Admin-only. License class reveals entitlement tier for each device (e.g., Basic/Enterprise).

### 2.34SubCmdHandler/0xd1/LicensableDeviceInformation High

NetFn 0x30 · Cmd 0xd1 · Sub 0x07Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that returns detailed information about a specific licensable device. Device selected by 1-byte index. Calls DellAbsDMGetLicensableDeviceInformation(device_idx).

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 4. inner_params\[0\]=device index. inner_params\[1..3\]: unused.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xcc (device not found), 0x7e (other error), 0xff (unknown error), or 0 (success). GET CC=0 → device information payload from DellAbsDMGetLicensableDeviceInformation() (layout undetermined). |

Backends `DellAbsDMGetLicensableDeviceInformation(device_idx) in libdellabsdm.so.9.`

**Security** — Admin-only. Reveals device model/firmware/configuration details.

### 2.35SubCmdHandler/0xd1/LicensableDeviceLicenseList Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x08Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that returns the list of installed licenses for a specific device. Device selected by 1-byte index. Calls DellAbsDMGetLicensableDeviceLicenseList(device_idx).

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 4. inner_params\[0\]=device index. inner_params\[1..3\]: unused.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xcc/0x7e/0xff per DellAbsDM error, or 0 on success. GET CC=0 → list of license identifiers for the device (layout undetermined). |

Backends `DellAbsDMGetLicensableDeviceLicenseList(device_idx) in libdellabsdm.so.9.`

**Security** — Admin-only. Lists all license keys/IDs on a device.

### 2.36SubCmdHandler/0xd1/LicensableDeviceLicenseInfo Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0x09Priv  · · · **A**liboemcmdsconfidence: highlive ✓

GET-direction-only command that returns detailed information for a specific device's license entry. Device selected by 1-byte index. Calls DellAbsDMGetLicensableDeviceLicenseInfo(device_idx).

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); inner data_len must be 4. inner_params\[0\]=device index. inner_params\[1..3\]: unused.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xcc/0x7e/0xff per DellAbsDM error, or 0 on success. GET CC=0 → license detail payload (layout undetermined). |

Backends `DellAbsDMGetLicensableDeviceLicenseInfo(device_idx) in libdellabsdm.so.9.`

**Security** — Admin-only. May reveal license entitlement dates, expiry, and feature codes.

### 2.37SubCmdHandler/0xd1/LicensingPCBAtest Medium

NetFn 0x30 · Cmd 0xd1 · Sub 0xffPriv  · · · **A**liboemcmdsconfidence: highlive ✓

Manufacturing-mode-only command that runs a PCBA (Printed Circuit Board Assembly) licensing test via DellAbsDM_LM_PCBA(). Gated by both a hardware manufacturing jumper check (IsManufacturingModeJumperOn) AND a software manufacturing-mode test (IsInManufacturingTestMode). GET direction triggers the test; SET direction is rejected with CC=0xc1. A 1-byte mode selector (0/1) and a 1-byte test command byte are required.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. GET direction only (req+8=1); SET direction returns CC=0xc1. inner data_len must be 3 (CC=0xc7 if not). inner_params\[0\]=mode selector (0 or 1; CC=0xcc if \>1). inner_params\[1\]=PCBA test command byte (passed to DellAbsDM_LM_PCBA()). inner_params\[2\]: unused.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. CC=0xc1 if direction is SET. CC=0xc7 if inner data_len != 3. CC=0xcc if mode selector \> 1. CC=0xc1 if manufacturing jumper is not on AND manufacturing test mode is not active. CC=0x7e if DellAbsDM_LM_PCBA() fails. CC=0 on success → response payload from DellAbsDM_LM_PCBA() (layout undetermined). |

Backends `IsManufacturingModeJumperOn() (hardware jumper check), IsInManufacturingTestMode() (software mode check), DellAbsDM_LM_PCBA(cmd_byte) in libdellabsdm.so.9.`

**Security** — Admin-only with manufacturing gate. Hardware jumper or manufacturing-test-mode activation required. If manufacturing mode is left enabled in production firmware (which has been observed in other vendors), this command could allow license manipulation. The subcmd byte 0xff (non-standard/sentinel value) suggests intentional hidden status.

### 2.38RacMw_TransferData Critical

NetFn 0x30 · Cmd 0xd2Priv  · **U** O Alibkcspassthruconfidence: highlive ✓

KCS passthrough multiplexer for the racadm middleware daemon. Provides eight distinct sub-operations selected by the first request data byte: (0) submit a racadm command string to the BMC in one or more chunks, (1) poll and retrieve the racadm response in chunks, (2) upload or download BMC files (SSL certs, CSR, Kerberos keytab, SSH public key, license XML, SCP XML, dat.ini) in chunks with 16-bit offsets, (3) query or toggle the racadm middleware enable flag and LocalConfigDisabled setting, (4) upload or download larger BMC files (LC log, RAID config, HW inventory, SCP config XML) with 32-bit offsets, (5) poll the proxy execution status flag, (6) submit a racadm proxy command string to a separate proxy worker thread in chunks, (7) retrieve the proxy worker response in chunks, (8) read the last racadm execution status code. All eight sub-operations are gated by IsMsgFromSystemInterface() and are unreachable over LAN/RMCP.

Request

Minimum length: 1 data byte (op-types 0x05, 0x08); 2 bytes (0x03); 6 bytes (0x00, 0x01, 0x06, 0x07); 7 bytes (0x02); 8 bytes (0x04). All offsets are from the start of the IPMI request data body (byte 0 = first data byte after the Command byte). byte 0 \[op_type, 1 B\]: selects sub-operation: 0x00 = KCS Passthrough Receive (host→BMC command delivery) 0x01 = KCS Passthrough Send (host←BMC response retrieval) 0x02 = File Transfer (16-bit offsets) 0x03 = Middleware Enable/Disable/Query 0x04 = Large File Transfer (32-bit offsets) 0x05 = Proxy Status Poll 0x06 = Proxy Receive (host→BMC proxy command delivery) 0x07 = Proxy Send (host←BMC proxy response retrieval) 0x08 = Racadm Status Query --- op_type 0x00 (KCS Passthrough Receive) --- byte 1..2 \[total_or_chunk_len, uint16 LE\]: on first packet (cmd_id=0) this is the total command string length; on continuation packets it is the number of bytes in this chunk. byte 3..4 \[chunk_offset, uint16 LE\]: byte offset within cmd_buffer at which to write this chunk; 0 on first packet. byte 5 \[cmd_id, 1 B\]: 0 on first packet (BMC assigns a unique ID); echoed value on continuation packets. byte 6..N \[data, variable\]: command string bytes for this chunk, copied to cmd_buffer\[chunk_offset\]. --- op_type 0x01 (KCS Passthrough Send) --- byte 1..2 \[chunk_len, uint16 LE\]: 0 for a probe/length request; number of bytes to retrieve on continuation. byte 3..4 \[chunk_offset, uint16 LE\]: byte offset within resp_buffer to start reading; 0 on probe. byte 5 \[cmd_id, 1 B\]: transaction ID returned by prior Receive response. --- op_type 0x02 (File Transfer, 16-bit offsets) --- byte 1 \[cmd_id, 1 B\]: 0 on first packet; echoed value from prior response on continuation. byte 2 \[file_info, 1 B\]: bit 0: direction — 1=download (BMC→host), 0=upload (host→BMC) bits 2:1: stage — 0=init/first, 2=continue, 3=finalize/last bits 6:3: file_type for upload direction: 0/2 = /var/run/racadm/sslcertupload.tmp 3 = /var/run/racadm/krbkeytabupload.tmp 5 = /var/run/racadm/sshpkauthupload.tmp (requires license 0x16) 7 = /var/tmp/upload/licensetrans.xml 9 = /var/run/racadm/dat.ini 0xf = /var/run/scp/\_xmlimport 0x10= /tmp/\_proxyImport bits 6:3: file_type for download direction: 0 = /var/run/racadm/sslcertdownload 6 = /var/run/racadm/sslcsrgen.tmp 7 = /var/tmp/upload/licenseexport.xml 9 = /var/run/racadm/dat.ini byte 3..4 \[length, uint16 LE\]: on init: total file size (download) or first-chunk size (upload); on continue: chunk size. byte 5..6 \[file_offset, uint16 LE\]: offset within file for this chunk (download reads fseek here; upload appends so this is informational). byte 7..N \[data, variable\]: upload payload bytes (upload ops, continue/finalize stages only); appended to the target file. --- op_type 0x03 (Middleware Enable/Disable/Query) --- byte 1 \[sub_cmd, 1 B\]: 0=set racmw_enabled=0, 1=set racmw_enabled=1, other=query only. --- op_type 0x04 (Large File Transfer, 32-bit offsets) --- byte 1 \[cmd_id, 1 B\]: 0 on first packet. byte 2 \[file_info, 1 B\]: bit 0: direction — 1=download, 0=upload (upload path not observed in code for this mode) bits 2:1: stage — 0=init, 2=continue, 3=finalize bits 6:3: file_type (download): 7 = /var/tmp/upload/licenseexport.xml 8 = /var/run/racadm/remoteviewlclog 0xa = /var/run/racadm/raidconfig 0xb = /var/run/racadm/rsellog 0xc = /var/run/racadm/dm/localtemphist 0xd = /var/run/racadm/L/hw_inventory.xml 0xe = /var/run/scp/\_xmlconfig byte 3 \[num_bytes, 1 B\]: chunk size in bytes for this transfer step. byte 4..7 \[file_offset, uint32 LE\]: absolute byte offset within file for fseek (download); not used for upload continue stage. --- op_type 0x05 (Proxy Status Poll) --- No additional bytes required. --- op_type 0x06 (Proxy Receive) --- byte 1..2 \[chunk_len, uint16 LE\]: 0 on first packet (total_length); chunk size on continuation. byte 3..4 \[chunk_offset, uint16 LE\]: 0 on first packet. byte 5 \[cmd_id, 1 B\]: 0 on first packet. byte 6..N \[data, variable\]: proxy command string bytes. --- op_type 0x07 (Proxy Send) --- byte 1..2 \[chunk_len, uint16 LE\]: 0 on probe; bytes to retrieve on continuation. byte 3..4 \[chunk_offset, uint16 LE\]: offset into proxy resp_buffer. byte 5 \[cmd_id, 1 B\]: from prior Proxy Receive response. --- op_type 0x08 (Racadm Status) --- No additional bytes required.

Response

byte 0 \[cc, 1 B\]: completion code. 0x00 = success 0x7E = command in progress (worker thread not yet done; caller should retry) 0xC0 = handler busy with another transaction (caller should retry) 0xC1 = invalid state — no pending transaction or cmd_id mismatch 0xFF = internal error (file I/O failure, thread spawn failure, state machine violation) Additional response bytes vary by op_type: --- op_type 0x00 (Passthrough Receive), resp_len=6 --- byte 1..4 \[echo, 4 B\]: verbatim copy of req bytes 1..4 (total_or_chunk_len + chunk_offset as received). byte 5 \[cmd_id, 1 B\]: BMC-assigned transaction ID (non-zero); use in all continuation packets and in the subsequent Passthrough Send call. --- op_type 0x01 (Passthrough Send) --- Probe response (resp_len=6): byte 1..2 \[total_len, uint16 LE\]: total response string length including NUL. byte 3..4 \[offset, uint16 LE\]: 0. byte 5 \[cmd_id, 1 B\]: echoed transaction ID. Data-chunk response (resp_len = 6 + chunk_len): byte 1..2 \[chunk_len, uint16 LE\]. byte 3..4 \[chunk_offset, uint16 LE\]. byte 5 \[cmd_id, 1 B\]. byte 6..N \[data\]: racadm response string fragment from resp_buffer\[chunk_offset .. chunk_offset+chunk_len\]. --- op_type 0x02 (File Transfer), resp_len=7 (control) or 7+chunk_len (download data) --- byte 1 \[cmd_id, 1 B\]: newly assigned ID on init, echoed on continuation. byte 2 \[file_info, 1 B\]: echoed from request. byte 3..4 \[size_or_len, uint16 LE\]: on download init = total file size; on continuation = chunk_len. byte 5..6 \[offset, uint16 LE\]: file_offset echoed. byte 7..N \[data\]: file bytes (download continue stage only). --- op_type 0x03 (Middleware Enable/Disable/Query), resp_len=6 --- byte 1 \[racmw_enabled, 1 B\]: 0=middleware disabled, 1=enabled. byte 2 \[localconfigdisable, 1 B\]: 0=local config writes allowed, 1=disabled (from AIM ipmi_local_config_disable key). byte 3..4 \[reserved, 2 B\]: 0x0000. byte 5 \[magic, 1 B\]: always 0x01. --- op_type 0x04 (Large File Transfer), resp_len=8 (init) or 8+num_bytes (download data) --- byte 1 \[cmd_id, 1 B\]. byte 2 \[file_info, 1 B\]: echoed. byte 3 \[num_bytes, 1 B\]: echoed chunk size. byte 4..7 \[size_or_offset, 4 B\]: on init = total file size (uint32 LE); on continue = current offset (bytes scattered across resp\[4..7\] as individual shifted bytes). byte 8..N \[data\]: file bytes (download continue stage only). --- op_type 0x05 (Proxy Status), resp_len=2 --- byte 1 \[proxy_status, 1 B\]: current value of g_proxy_status global (0=not ready, 1=response available). --- op_type 0x06 (Proxy Receive), resp_len=6 --- byte 1..2 \[chunk_len, uint16 LE\]: echoed. byte 3..4 \[chunk_offset, uint16 LE\]: echoed. byte 5 \[cmd_id, 1 B\]: BMC-assigned proxy transaction ID. --- op_type 0x07 (Proxy Send) --- Probe response (resp_len=6): byte 1..2 \[total_len, uint16 LE\], byte 3..4 \[offset=0, uint16 LE\], byte 5 \[cmd_id\]. Data response (resp_len = 6 + chunk_len): byte 1..2 \[chunk_len\], byte 3..4 \[chunk_offset\], byte 5 \[cmd_id\], byte 6..N \[data from proxy_resp_buffer\]. --- op_type 0x08 (Racadm Status), resp_len=2 --- byte 1 \[status, 1 B\]: g_status — return code of last racadm execution (0=success, non-zero=failure).

Backends `IsMsgFromSystemInterface() — KCS channel guard; racmw_enabled/racmw_cmd_id/racmw_dat_avail/racmw_resp_buffer global state (in-process); aim_config_get_int('ipmi_local_config_disable') — AIM config DB; POSIX shared memory via shmget/shmat keyed on ftok('/tmp/proxy_lock.txt', 1) size 0x119a4 — shared with racadm CGI/shim process; worker thread spawned via PTR_RacMw_Wrapper (calls ExecuteCmd → racadm binary with RACADM_ACCESS=kcspt env var); proxy worker thread via PTR_RacMw_Wrapper_proxy (calls ExecuteCmd_Shm → vfork+execve of /usr/local/cgi-bin/exec or login/logout/putfile); files written/read under /var/run/racadm/, /var/run/scp/, /var/tmp/upload/, /tmp/; d_licenseCheck(0x16) — license gate for SSH public key upload (file_type=5, op_type=0x02 upload); RacMwProcessConfig — intermediate config file processor writing /tmp/config_racmw.tmp for 'set -f' and 'config -f' commands.`

**Security** — 1. Arbitrary racadm command execution (op_type=0x00/0x01): any process on the host OS with KCS access can submit a full racadm command string to the BMC and read back the response. This is the designed host-to-BMC management channel but constitutes arbitrary BMC configuration from a compromised host OS. RACADM_ACCESS=kcspt is set so racadm treats the caller as a KCS passthrough client. 2. Sensitive file download without explicit auth check (op_type=0x02/0x04): the file_type enum grants direct read access to /var/run/racadm/dat.ini (config dump), /var/run/racadm/sslcertdownload (SSL private certificate), /var/run/racadm/sslcsrgen.tmp (CSR), /var/tmp/upload/licenseexport.xml, and large files including /var/run/racadm/L/hw_inventory.xml and /var/run/scp/\_xmlconfig. No additional credential check beyond IsMsgFromSystemInterface. 3. Sensitive file upload (op_type=0x02/0x04): upload file_types include SSL cert replacement, Kerberos keytab replacement, SSH public key injection (/var/run/racadm/sshpkauthupload.tmp — though a license check gates this), SCP XML import (/var/run/scp/\_xmlimport which can batch-configure the BMC), and /tmp/\_proxyImport. A host-OS attacker can replace BMC TLS certificates or inject SSH keys. 4. d_licenseCheck bypass surface: file_type=5 (SSH pubkey upload) calls d_licenseCheck(0x16). If a license check bypass exists, SSH key injection becomes unconditional. 5. LocalConfigDisabled bypass scope: op_type=0x03 reads the LocalConfigDisabled flag but the racadm command channel (op_type=0x00) is not observed to check it before executing commands. The flag is only surfaced to the host for informational use; enforcement is inside the racadm binary. 6. Shared memory channel to racadm CGI (ExecuteCmd_Shm): proxy ops (0x06/0x07) write commands into a shared memory segment and vfork+execve /usr/local/cgi-bin/exec (or login/logout/putfile) — an attacker who can manipulate the SHM key or race the vfork window may interfere with BMC CGI operations. 7. No rate-limiting or transaction timeout visible in this handler; the 'busy' (0xC0) response is purely state-machine based, not time-bounded.

### 2.39SubCmdHandler/0xd3/HiiIntegerSet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x2Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Set a BIOS HII integer attribute by handle. Leaf handler: HiiIntegerSet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiIntegerSet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.40SubCmdHandler/0xd3/HiiIntegerGet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x3Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get a BIOS HII integer attribute by handle. Leaf handler: HiiIntegerGet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiIntegerGet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.41SubCmdHandler/0xd3/HiiStringSet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x4Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Set a BIOS HII string attribute by handle. Leaf handler: HiiStringSet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiStringSet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.42SubCmdHandler/0xd3/HiiStringGet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x5Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get a BIOS HII string attribute by handle. Leaf handler: HiiStringGet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiStringGet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.43SubCmdHandler/0xd3/HiiEnumSet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x6Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Set a BIOS HII enumeration attribute by handle. Leaf handler: HiiEnumSet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiEnumSet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.44SubCmdHandler/0xd3/HiiEnumGet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x7Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get a BIOS HII enumeration attribute by handle. Leaf handler: HiiEnumGet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiEnumGet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.45SubCmdHandler/0xd3/HiiOrdListSet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x8Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Set a BIOS HII ordered list attribute by handle. Leaf handler: HiiOrdListSet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiOrdListSet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.46SubCmdHandler/0xd3/HiiOrdListGet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0x9Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get a BIOS HII ordered list attribute by handle. Leaf handler: HiiOrdListGet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiOrdListGet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.47SubCmdHandler/0xd3/HiiJobStatusGet Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0xaPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Get status of a pending BIOS HII job. Leaf handler: HiiJobStatusGet() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiJobStatusGet() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.48SubCmdHandler/0xd3/HiiVerifyPassword Critical

NetFn 0x30 · Cmd 0xd3 · Sub 0xbPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Verify BIOS setup password via HII. Leaf handler: HiiVerifyPassword() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiVerifyPassword() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.49SubCmdHandler/0xd3/HiiListPending Medium

NetFn 0x30 · Cmd 0xd3 · Sub 0xcPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

List pending BIOS HII configuration jobs. Leaf handler: HiiListPending() in libmisccmd.so.9.9.9 (external symbol, not decompiled). Dispatched by SubCmdHandler via G_asOEMSubCmdTable.

Request

Outer IPMI request (netfn=0x30): req+7=data_len; req+8=direction(0=SET/1=GET); req+9=subcmd; req+10..11=LE16 chunk_req_len; req+12..13=LE16 chunk_offset. For GET: req+14+N=inner_param\[N\], min outer data_len=7 (6 overhead + 1 inner byte). For SET single-chunk: req+14..15=LE16 inner_total_len (must equal req+10..11); req+16+N=set_payload\[N\]; inner_total_len = set_payload_len + 2; min outer data_len=8+set_payload_len. Inner payload layout undetermined (leaf handler in libmisccmd.so.9.9.9). Typically requires a BIOS HII handle/key and, for Set operations, a value.

Response

| Offset | Response field |
|----|----|
| 0 | ..3\]=req+9..12 (subcmd + chunk_req_len + offset_lo |
| 4 | req+13 (offset_hi). Leaf payload follows at |
| 5 | +\]. Leaf response layout undetermined. SubCmdHandler wrapper CC values: 0=success; 0xc4=direction invalid; 0xc8=data too large; 0xc6=len+offset overflow; 0xc9=max IPMI size exceeded; 0xc1=subcmd not in table. |

Backends `HiiListPending() in libmisccmd.so.9.9.9; BIOS HII database (likely accessed via libhapi.so or libipmid BIOS interface).`

**Security** — Admin-only. HII Get/Set subcmds can read and write BIOS configuration attributes including security settings (Secure Boot, boot order, password policy). HiiVerifyPassword (0x0b) could be used for offline password brute-force via IPMI. HiiJobStatusGet and HiiListPending reveal pending BIOS configuration state.

### 2.50SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x30Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x30: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc over DBus. Operates on the backplane subsystem (bay management, drive status, sensor data, LEDs, etc.). Exact semantics of this subcmd are handled by the backplane library and are not determinable from liboemcmds alone.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | subcmd(0x30); data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE; for SET: data\[6..7\]=payload-length uint16_LE, data\[8+\]=payload (max total chunk 200 bytes). Min data: 6 bytes (GET). Payload format is subcmd-specific and forwarded verbatim to the backplane library. |

Response

Response is produced by DellBpIpmiLibSubFunc; length and format are subcmd-specific (undetermined from liboemcmds/libbackplane static analysis alone). CC=0x00 on success; CC=0xff on resource allocation failure or DBus error; CC=0xce if backplane inventory for the specified bay is unavailable.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), DellBpMsgAlloc/Free(), BpMsgThreadInfoAlloc(), backplane DBus service`

**Security** — Allows querying and configuring backplane hardware (drive bays, indicators, sensors). No KCS gate — accessible from LAN with Admin priv. IsInManufacturingTestMode flag is queried and embedded in the backplane request.

### 2.51SubCmdHandler/DellBpFwUpdateInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x31Priv  · · · **A**liboemcmdsconfidence: medlive ✓

Backplane firmware update command. GET returns the current FW update status for a specified backplane bay. SET initiates a FW update for a specified bay using a pre-staged SEP image at /var/run/backplane/sepimg.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x31; data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE. GET additional |
| 6 | bay-ID (uint8). SET additional: data\[6..7\]=payload-length uint16_LE |
| 8 | bay-ID (uint8). Min data: 7 bytes GET (header+bay-id), 9 bytes SET. |

Response

GET CC=0x00: 4 bytes FW update status from BP_GET_FW_UPDATE_STATUS_DBUS (format: DBus-defined, undetermined). SET CC=0x00: success, 0 data bytes (firmware update initiated asynchronously). CC=0xce: invalid bay ID / inventory lookup failed. CC=0xff: BpMsgThreadInfoAlloc or DBus call failed.

Backends `BpMsgThreadInfoAlloc(), GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibBayInventory(), BP_GET_FW_UPDATE_STATUS_DBUS(), BP_SET_FW_UPDATE_DBUS(), FUN_00105df0() (image staging), /var/run/backplane/sepimg (staged firmware image)`

**Security** — SET triggers backplane firmware reflash; firmware source is /var/run/backplane/sepimg. If an attacker can write to that path (e.g. via a compromised BMC process) and send this IPMI command, they can flash arbitrary backplane firmware. No cryptographic verification of the image is visible at this level. No KCS gate — LAN-reachable.

### 2.52SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x32Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x32: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics handled by backplane library (undetermined from static analysis of liboemcmds/libbackplane).

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x32; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.53SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x33Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x33: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x33; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.54SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x34Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x34: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x34; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.55SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x35Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x35: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x35; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.56SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x36Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x36: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x36; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.57SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x37Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x37: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x37; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.58SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x38Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x38: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x38; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.59SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x39Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x39: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x39; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.60SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x3aPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x3a: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x3a; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.61SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x3bPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x3b: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x3b; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.62SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x3cPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x3c: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x3c; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.63SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x3dPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x3d: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x3d; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.64SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x3ePriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x3e: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x3e; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.65SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x3fPriv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x3f: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x3f; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.66SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x40Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x40: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x40; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.67SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x50Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x50 ('P'): forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Special-cased in \_cmdHandler: if baycount==0, the backplane API is treated as valid anyway (possibly a probe/presence-check command that works with no bays installed). Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x50; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane presence/probe command reachable even when no bays are installed (baycount==0 forced-valid path). LAN-reachable with Admin priv.

### 2.68SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x54Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x54: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x54; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.69SubCmdHandler/DellBpLocalIpmiInterface Medium

NetFn 0x30 · Cmd 0xd5 · Sub 0x55Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

Backplane subcommand 0x55: forwarded to DellBpLocalIpmiInterface → \_cmdHandler → DellBpIpmiLibSubFunc. Exact semantics undetermined.

Request

| Offset | Request field |
|----|----|
| 0 | set(0)/get(1 |
| 1 | 0x55; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; SET: data\[6..7\]=payload-len, data\[8+\]=payload. Min: 6 bytes GET. |

Response

Subcmd-specific (undetermined). CC=0x00 success; CC=0xff resource/DBus error.

Backends `GetBPApiDataOverDBus_CAPI(), DellBpIpmiLibSubFunc(), backplane DBus service`

**Security** — Backplane hardware access; LAN-reachable with Admin priv.

### 2.70SubCmdHandler/InBandGetIpPort Medium

NetFn 0x30 · Cmd 0xd6 · Sub 0x00Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

KCS-only (in-band): returns the IP port number used by the iDRAC Service Module (iSM) agent for its local communication channel. Allows the host-side iSM process to discover the iDRAC endpoint port via IPMI.

Request

| Offset | Request field |
|----|----|
| 0 | 1 (GET only expected; SET path undetermined |
| 1 | 0x00; data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE. Min: 6 bytes. Handler body not available in current decomp (libmisccmd.so.9.9.9); request/response layout undetermined beyond the envelope. |

Response

CC=0xc1 if not KCS. On success (CC=0x00): response bytes contain IP port value — exact layout undetermined from available decomp.

Backends `libmisccmd.so.9.9.9:InBandGetIpPort (VA 0x2a060); IsInBandCommand(); port source undetermined (likely cfgdb or socket query)`

**Security** — KCS-gated. Returns iSM communication port — informational only, but could assist an attacker on the host OS in targeting the iSM-to-iDRAC channel.

### 2.71SubCmdHandler/InBandGenerateAliteCert Critical

NetFn 0x30 · Cmd 0xd6 · Sub 0x01Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

KCS-only (in-band): triggers generation of an 'alite' mTLS certificate used by the iSM agent for its authenticated channel to iDRAC. Allows the host-side iSM process to request a fresh client certificate via IPMI.

Request

| Offset | Request field |
|----|----|
| 0 | 0 (SET, triggers generation |
| 1 | 0x01; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; additional payload undetermined. Min: 6 bytes. Handler body (libmisccmd.so.9.9.9 VA 0x2a500) not available in current decomp. |

Response

CC=0xc1 if not KCS. On success: exact layout undetermined.

Backends `libmisccmd.so.9.9.9:InBandGenerateAliteCert (VA 0x2a500); IsInBandCommand(); certificate storage undetermined`

**Security** — KCS-gated. Generates an iSM-to-iDRAC mTLS client certificate. A compromised host-OS process with IPMI KCS access could request a fresh cert, potentially bootstrapping the authenticated iSM channel without legitimate iSM credentials.

### 2.72SubCmdHandler/InBandRetrieveAliteCert Critical

NetFn 0x30 · Cmd 0xd6 · Sub 0x02Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

KCS-only (in-band): retrieves the previously generated 'alite' mTLS certificate (iSM-to-iDRAC client cert). Allows the host-side iSM process to fetch its certificate material via IPMI.

Request

| Offset | Request field |
|----|----|
| 0 | 1 (GET |
| 1 | 0x02; data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE. Min: 6 bytes. Handler body (libmisccmd.so.9.9.9 VA 0x2a664) not available in current decomp. |

Response

CC=0xc1 if not KCS. On success (CC=0x00): response bytes contain certificate material — exact layout and max size undetermined.

Backends `libmisccmd.so.9.9.9:InBandRetrieveAliteCert (VA 0x2a664); IsInBandCommand(); certificate store undetermined`

**Security** — KCS-gated. Exposes the iSM mTLS client certificate. A compromised host-OS process could exfiltrate the cert used to authenticate to iDRAC's iSM mTLS endpoint, enabling impersonation of the iSM agent.

### 2.73SubCmdHandler/InBandGetLastRceError Medium

NetFn 0x30 · Cmd 0xd6 · Sub 0x03Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

KCS-only (in-band): returns the last RCE (Remote Connect Error) or connection error code recorded for the iSM channel. Allows the host-side iSM process to query iDRAC's most recent connection error state.

Request

| Offset | Request field |
|----|----|
| 0 | 1 (GET |
| 1 | 0x03; data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE. Min: 6 bytes. Handler body (libmisccmd.so.9.9.9 VA 0x2a390) not available in current decomp. |

Response

CC=0xc1 if not KCS. On success: error code bytes — exact layout undetermined.

Backends `libmisccmd.so.9.9.9:InBandGetLastRceError (VA 0x2a390); IsInBandCommand()`

**Security** — KCS-gated; informational error code leakage.

### 2.74SubCmdHandler/InBandISMVersionCmdHandler High

NetFn 0x30 · Cmd 0xd6 · Sub 0x04Priv  · · · **A**liboemcmdsconfidence: medlive ✓

KCS-only (in-band): GET returns the iDRAC Service Module (iSM) version string; SET writes a new iSM version. Used by the host-side iSM agent to register its software version with iDRAC over the KCS channel.

Request

| Offset | Request field |
|----|----|
| 0 | 0(SET)/1(GET |
| 1 | 0x04; data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE. SET: data\[6..7\]=payload-len, data\[8+\]=version-string payload (format undetermined; delegated to InBandSetISMVersion in libmisccmd). GET: no extra bytes. Min: 6 bytes GET. |

Response

CC=0xc1 if not KCS. GET CC=0x00: response bytes contain iSM version string (format/length undetermined; delegated to InBandGetISMVersion). SET CC=0x00: success, 0 data bytes.

Backends `libmisccmd.so.9.9.9:InBandSetISMVersion (VA 0x2a9a0), InBandGetISMVersion (VA 0x2a820); IsInBandCommand()`

**Security** — KCS-gated. SET allows host OS to write arbitrary iSM version string to iDRAC — could be used to spoof the installed iSM version in inventory/management interfaces.

### 2.75SubCmdHandler/InBandGetISMLCDUPVersion Medium

NetFn 0x30 · Cmd 0xd6 · Sub 0x05Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

KCS-only (in-band): returns the iSM LCDUP (Lifecycle Controller DUP update package) version. Allows the host-side iSM to query the LC DUP version currently known to iDRAC.

Request

| Offset | Request field |
|----|----|
| 0 | 1 (GET |
| 1 | 0x05; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE. Min: 6 bytes. Handler body (libmisccmd.so.9.9.9 VA 0x2acf0) not available in current decomp. |

Response

CC=0xc1 if not KCS. On success: LCDUP version bytes — exact layout undetermined.

Backends `libmisccmd.so.9.9.9:InBandGetISMLCDUPVersion (VA 0x2acf0); IsInBandCommand()`

**Security** — KCS-gated; informational version leakage.

### 2.76SubCmdHandler/InBandGetOauthToken Critical

NetFn 0x30 · Cmd 0xd6 · Sub 0x06Priv  · · · **A**liboemcmdsconfidence: medlive ✓

KCS-only (in-band): returns an OAuth bearer token scoped to the iSM channel. Allows the host-side iSM agent to obtain a token for authenticating to iDRAC Redfish / WS-Man APIs. This is the primary mechanism by which iSM bootstraps API access to iDRAC.

Request

| Offset | Request field |
|----|----|
| 0 | 1 (GET |
| 1 | 0x06; data\[2..3\]=requested-length uint16_LE; data\[4..5\]=offset uint16_LE. Min: 6 bytes. Handler body (libmisccmd.so.9.9.9 VA 0x2aee0) not available in current decomp; may support multi-packet GET given token size. |

Response

CC=0xc1 if not KCS. On success (CC=0x00): response bytes contain OAuth bearer token — exact format and max length undetermined.

Backends `libmisccmd.so.9.9.9:InBandGetOauthToken (VA 0x2aee0); IsInBandCommand(); OAuth token store (likely cfgdb or shared.key-derived)`

**Security** — CRITICAL: KCS-gated, but any host-OS process that can open /dev/ipmi0 and send KCS IPMI can obtain the OAuth token. Token grants Redfish/WS-Man API access to iDRAC. On a compromised host OS, this provides a direct escalation path to iDRAC API-level control (sensor reads, firmware updates, user management) without iDRAC credentials. The token's lifetime and scope are undetermined — if it is long-lived or grants broad Admin scope, a single KCS transaction compromises the full iDRAC management plane.

### 2.77SubCmdHandler/InBandLcLogWithArgument High

NetFn 0x30 · Cmd 0xd6 · Sub 0x07Priv  · · · **A**liboemcmdsconfidence: lowlive ✓

KCS-only (in-band): writes a log entry to the iDRAC Lifecycle Controller (LC) log with caller-supplied arguments. Allows the host-side iSM agent to inject log messages into the iDRAC LC log.

Request

| Offset | Request field |
|----|----|
| 0 | 0 (SET |
| 1 | 0x07; data\[2..3\]=len uint16_LE; data\[4..5\]=offset uint16_LE; data\[6..7\]=payload-len; data\[8+\]=log message/arguments payload. Handler body (libmisccmd.so.9.9.9 VA 0x2b4e0) not available in current decomp; payload format undetermined. |

Response

CC=0xc1 if not KCS. On success: 0 data bytes (write operation).

Backends `libmisccmd.so.9.9.9:InBandLcLogWithArgument (VA 0x2b4e0); IsInBandCommand(); LC log (iDRAC event journal)`

**Security** — KCS-gated. Host OS can inject arbitrary entries into the iDRAC LC log — enables log tampering / spoofing of events for forensic evasion. If arguments are passed to a format-string or command builder inside the handler (not visible without further decomp), there may be an injection risk.

### 2.78SubCmdHandler/InBandMultiPlatformEventCmd High

NetFn 0x30 · Cmd 0xd6 · Sub 0x08Priv  · · · **A**liboemcmdsconfidence: highlive ✓

KCS-only (in-band), SET only: sends a batch of platform events to the iDRAC event log in a single IPMI transaction. The handler spawns a detached thread (MultiEventLoggingThread) to process all events asynchronously and returns immediately.

Request

| Offset | Request field |
|----|----|
| 0 | 0 (SET only; GET returns CC=0xcc |
| 1 | 0x08; data\[2..3\]=payload-total-length uint16_LE; data\[4..5\]=offset (0 for first/only packet); data\[6..7\]=payload-data-length uint16_LE |
| 8 | event count N (uint8); data\[9..9+6N-1\]=N platform events, 6 bytes each (format: standard IPMI Platform Event fields — sensor type, event direction/type, event data 1-3). Total payload length must equal N\*6+1 exactly. Max N limited by IPMI message size. Min: 10 bytes (1 event: N=1, payload=7, total=15 data bytes). |

Response

CC=0x00: events accepted (async thread started), 0 response data bytes. CC=0xcc: GET attempted or payload length != N\*6+1. CC=0xff: semaphore creation failed, calloc failed, or pthread_create failed. CC=0xc1: not KCS. CC=0xc7 (199): payload length mismatch.

Backends `libmisccmd.so.9.9.9:InBandMultiPlatformEventCmd (VA 0x2b890); IsInBandCommand(); pthread_create(MultiEventLoggingThread); lx_SemaphoreCreate('MultiEventSem'); iDRAC event logging subsystem`

**Security** — KCS-gated. Host OS can inject up to N platform events (arbitrary sensor type, event type, event data) into the iDRAC event log in a single call. This enables: (1) flooding the SEL (DoS), (2) injecting false alarms to mask real events, (3) spoofing hardware events (e.g. fake drive failure, fake power fault) that trigger automated iDRAC actions. Payload is copied to heap and handed to a detached thread with no visible validation of event field semantics.

### 2.79SubCmdHandler/InBandSendMemoryHealthEventCmd Critical

NetFn 0x30 · Cmd 0xd6 · Sub 0x0aPriv  · · · **A**liboemcmdsconfidence: highlive ✓

KCS-only (or xRev-platform), SET only: sends memory health / BIOS refcode error events to iDRAC. Spawns a detached thread (SendMemoryHealthEventsThread) to process the event asynchronously. On platforms where isXRev() returns true the KCS gate is skipped.

Request

| Offset | Request field |
|----|----|
| 0 | 0 (SET only; GET returns CC=0xcc |
| 1 | 0x0a; data\[2..3\]=payload-total-length uint16_LE; data\[4..5\]=offset uint16_LE; data\[6..7\]=payload-data-length uint16_LE |
| 8 | event subtype (uint8). Subtype constraints: if subtype==0x05 then payload-length must be exactly 0x59 (89) or 0x69 (105) bytes; otherwise subtype must be in {0,1,2,3,4,0x10} and payload must be \< 0xc1 (193) bytes. For subtype 0x05: handler allocates 193-byte buffer and records length at offset \[192\]. For other subtypes: payload copied verbatim to heap buffer of payload-length bytes. Min: 10 bytes (8-byte envelope + 2 bytes payload). |

Response

CC=0x00: event accepted (async thread started), 0 response data bytes. CC=0xcc: GET attempted or invalid subtype. CC=0xc7 (199): invalid payload length. CC=0xff: semaphore/calloc/pthread failure. CC=0xc1: not KCS (unless isXRev() platform).

Backends `libmisccmd.so.9.9.9:InBandSendMemoryHealthEventCmd (VA 0x2bba0); IsInBandCommand(); isXRev(); pthread_create(SendMemoryHealthEventsThread); lx_SemaphoreCreate('SendMemoryHealthEventSem')`

**Security** — Nearly KCS-only except isXRev() bypass on specific platform variants — if isXRev() is true the channel check is skipped entirely. Host OS can inject arbitrary memory-health / BIOS refcode events into iDRAC. The subtype-5 fixed-size path allocates a 193-byte buffer and only writes length at position 192, leaving the rest from the memcpy of caller-controlled data — content fully attacker-controlled. Async thread processes unchecked event content.

### 2.80SubCmdHandler/InBandIsmStateHandler Medium

NetFn 0x30 · Cmd 0xd6 · Sub 0x0bPriv  · · · **A**liboemcmdsconfidence: highlive ✓

KCS-only (in-band): GET/SET the iDRAC Service Module (iSM) operational state in the configuration database. State values: 0=disabled, 1=enabled, 2=not-running, 3=running (exact semantics per iDRAC documentation). Allows the host-side iSM agent to register its current state with iDRAC.

Request

| Offset | Request field |
|----|----|
| 0 | 0(SET)/1(GET |
| 1 | 0x0b; data\[2..3\]=0(GET) or payload-total-length uint16_LE(SET); data\[4..5\]=0 uint16_LE. GET: no further bytes (leaf param_2 must be 0). SET: data\[6..7\]=1 (payload-data-length=1 uint16_LE |
| 8 | new state (uint8, must be 0-3). Min: 6 bytes GET, 9 bytes SET. |

Response

GET CC=0x00: 1 byte response data = current state value (uint8, 0-3). SET CC=0x00: 0 data bytes (write committed to cfgdb). CC=0xc7 (199): invalid data length (GET with extra bytes, or SET with length != 1). CC=0xcc: state value \> 3. CC=0xff: CfgSetAttributeInt/CfgGetAttributeInt failed. CC=0xc1: not KCS.

Backends `libmisccmd.so.9.9.9:InBandIsmStateHandler (VA 0x2bf50); CfgSetAttributeInt('iDRAC.Embedded.1#ServiceModule.1#ServiceModuleState'); CfgGetAttributeInt same key; IsInBandCommand()`

**Security** — KCS-gated. Host OS can set iSM state to 0 (disabled) via this command, suppressing iSM-based monitoring. Could be used by a compromised host to blind iDRAC's iSM-mediated telemetry without touching host-side iSM processes.

## 3. Lifecycle Controller / MASER (131)

MASER (LC storage) partition access, backup/restore, POST-time provisioning, factory inventory, secure firmware update staging.

### 3.1CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERGetProvOptions Medium

NetFn 0x30 · Cmd 0xa1 · Sub 0x00Priv  · **U** O Alibmaserconfidence: highlive ✓

Called by BIOS/UEFI at POST start to determine what the BMC wants LC to do this boot. Evaluates LC disabled/enabled/recovery/lock state, UEFI flag (cfgdb LaunchSSM, CSIOR), BnR job in progress, and Boot-to-MASER active state. Returns a provisioning options code and SSM unoptimized flag. Side-effects: touches /tmp/system_in_post, removes /tmp/prov_system_power_off and /tmp/offline_db_sync_requested, may run /bin/osdinst UpdateConfigurableBootToNetworkISOStatus, may set wipe-system UEFI flag if /flash/data0/oem_ps/wipe_system exists.

Request

| Offset | Request field |
|----|----|
| 8 | 0x00 (subcmd). No additional validated data fields (length not explicitly checked). |
| 7 | data_len): minimum 1. |

Response

CC: 0x00. resp_data length=4. resp_data\[0\]: 0x00. resp_data\[1\]: provisioning options code (G_u8ProvOptions: 0=normal/no-action, 1=launch GUI, 2=MASER locked, 3=LC disabled or BnR in progress, 4=MASER in recovery, 5=launch SSM, 6=AutoSync ON, 7=Boot-to-MASER active). resp_data\[2\]: 1=SSM unoptimized flag set in cfgdb. resp_data\[3\]: 0x00.

Backends `IsMASERDisabled(), IsMASERInRecovery(), IsBootToMASERActive(), BnR_JobInProgress(), IsMaserCmdsMaserLocked(), GetLCSupport(), getiDRACImageType(); cfgdb keys: LCAttributes.1#LaunchSSM, LCAttributes.1#CollectSystemInventoryOnRestart, LCAttributes.1#SSMUnoptimized; MaserCmdsGetUEFIFlag(), MaserCmdsSetUEFIFlag(); utl_is_file_exist('/flash/data0/oem_ps/wipe_system'); utl_execmd('/bin/osdinst ...'); utl_touch_file('/tmp/system_in_post'); unlink('/tmp/prov_system_power_off'), unlink('/tmp/offline_db_sync_requested')`

**Security** — Called by BIOS over KCS/BT during POST. Can trigger osdinst execution if Boot-to-MASER is active. Returns the boot disposition code — if an attacker can influence cfgdb keys (e.g., LaunchSSM), they can redirect BIOS boot into SSM or recovery mode. User priv over in-band interface.

### 3.2CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERSetSystemReq Medium

NetFn 0x30 · Cmd 0xa1 · Sub 0x01Priv  · **U** O Alibmaserconfidence: lowlive ✓

BIOS reports system requirements and capabilities to the BMC during POST.

Request

req+8=0x01. Remaining fields: undetermined (CmdOEMPOSTMASERSetSystemReq.c not read).

Response

undetermined.

Backends `undetermined.`

**Security** — Data written from BIOS to BMC. User+inBand.

### 3.3CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERAttachPartition Medium

NetFn 0x30 · Cmd 0xa1 · Sub 0x02Priv  · **U** O Alibmaserconfidence: lowlive ✓

BIOS requests attachment of a MASER partition during POST. Also triggered when cVar3==0x03 (subcmd=0x02 with data\[1\]=0x03 triggers DetachPartition via shared code path in the dispatcher).

Request

req+8=0x02. Remaining fields: undetermined (CmdOEMPOSTMASERAttachPartition.c not read). Note: dispatcher also routes to CmdOEMPOSTMASERDetachPartition when req+8=0x02 and req+9=0x03.

Response

undetermined.

Backends `undetermined.`

**Security** — POST-time partition attach from BIOS. User+inBand.

### 3.4CmdOEMPOSTMASERAccess/CmdOEMPOSTMASERDetachPartition Medium

NetFn 0x30 · Cmd 0xa1 · Sub 0x03Priv  · **U** O Alibmaserconfidence: lowlive ✓

BIOS requests detachment of a MASER partition during POST.

Request

req+8=0x03. Remaining fields: undetermined (CmdOEMPOSTMASERDetachPartition.c not read).

Response

undetermined.

Backends `undetermined.`

**Security** — POST-time partition detach from BIOS. User+inBand.

### 3.5CmdOEMPOSTMASERAccess/CmdOEMPOSTLogLCLEvent High

NetFn 0x30 · Cmd 0xa1 · Sub 0x04Priv  · **U** O Alibmaserconfidence: lowlive ✓

BIOS logs a Lifecycle Controller event to the LC log during POST.

Request

req+8=0x04. Remaining fields: undetermined (CmdOEMPOSTLogLCLEvent.c not read).

Response

undetermined.

Backends `LC event log.`

**Security** — Log write from BIOS. User+inBand. Potential log injection if event content is not sanitized.

### 3.6CmdOEMPOSTMASERAccess/CmdOEMPOSTGetBootVolLabel Medium

NetFn 0x30 · Cmd 0xa1 · Sub 0x05Priv  · **U** O Alibmaserconfidence: lowlive ✓

BIOS queries the boot volume label during POST.

Request

req+8=0x05. Remaining fields: undetermined (CmdOEMPOSTGetBootVolLabel.c not read).

Response

undetermined.

Backends `undetermined.`

**Security** — Read-only label query. User+inBand.

### 3.7CmdOEMPOSTMASERAccess/CmdOEMPOSTSetBIOSPassword Critical

NetFn 0x30 · Cmd 0xa1 · Sub 0x06Priv  · **U** O Alibmaserconfidence: highlive ✓

Transfer a BIOS system or setup password from the BIOS to the BMC during POST. Password data is chunked (max 32B per transfer) and reassembled. When all chunks received (offset+chunk_len == total_len), writes an XML file (/tmp/biossystempassword or /tmp/biossetuppassword) and calls aim_exec_systemcmd_DDS('aimexec_fullfw_bios_system_pwd' or 'aimexec_fullfw_bios_setup_pwd') to process it. Also clears /var/run/osd/skipisoimageboot if MASER is in use and boot_to_maser sentinel exists.

Request

| Offset | Request field                                                   |
|--------|-----------------------------------------------------------------|
| 7      | 0x26 (38 bytes, fixed).                                         |
| 8      | 0x06 (subcmd).                                                  |
| 9      | password type (0=system, 1=setup).                              |
| 10     | encoding type byte (written as hex string to XML EncodingType). |
| 11     | total password length.                                          |
| 12     | current chunk length (must be ≤ 32).                            |
| 13     | chunk byte offset within total password.                        |
| 14     | ..(14+chunk_len-1): chunk data bytes. Minimum length: 38.       |

Response

CC: 0x00 success (chunk accepted or full transfer processed). resp_data length=2. resp_data\[0..1\]: 0x00. CC errors: 0xC7 if data_len != 38 or current_chunk_len \> 32.

Backends `Global BIOS password buffers (DAT_0018c8c0 system, DAT_0018c9c0 setup); fopen64/fwrite to /tmp/biossystempassword or /tmp/biossetuppassword; aim_exec_systemcmd_DDS('aimexec_fullfw_bios_system_pwd' / 'aimexec_fullfw_bios_setup_pwd'); lstat64('/var/run/osd/boot_to_maser'); unlink('/var/run/osd/skipisoimageboot')`

**Security** — HIGH: BIOS passwords are transferred to BMC in plaintext over in-band IPMI and written as XML to /tmp files. The aim_exec_systemcmd_DDS call executes a named command with the password as side data. If the DDS command name or password buffer can be manipulated, this is a persistence/credential-theft primitive. User priv over in-band; BIOS is the intended caller. Encoding type byte is copied from req into the XML without filtering — potential XML injection.

### 3.8CmdOEMPOSTMASERAccess/CmdOEMPOSTSetBIOSSHAPassword Critical

NetFn 0x30 · Cmd 0xa1 · Sub 0x07Priv  · **U** O Alibmaserconfidence: lowlive ✓

Transfer a BIOS SHA-hashed password from BIOS to BMC during POST. Similar chunked transfer as subcmd 0x06 but for SHA-encoded passwords.

Request

req+8=0x07. Remaining fields: undetermined (CmdOEMPOSTSetBIOSSHAPassword.c not read, ~24KB).

Response

undetermined.

Backends `Similar to subcmd 0x06. File writes in /tmp/, aim_exec_systemcmd_DDS.`

**Security** — HIGH: Same password transfer channel as subcmd 0x06 but for SHA-hashed passwords. User+inBand.

### 3.9CmdOEMMASERPartitionAccess/CmdOEMLockMASER Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x00Priv  · · · **A**libmaserconfidence: highlive ✓

Begin a MASER (Lifecycle Controller) exclusive session. Generates a random 2-byte session handle via IPMISessionCtrlGenerateRandomNum, stores it in global DAT_0018bf70, sets DAT_0018bf6b=1 (session active). Optionally arms an ACK watchdog timer (5-60 s) and the main MASER watchdog timer (60-64800 s). Optionally registers for power-off events to auto-close the session on host power-off.

Request

| Offset | Request field |
|----|----|
| 7 | 0x06 (6 data bytes required). |
| 8 | 0x00 (subcmd=LockMASER). |
| 9 | flags byte (bit0=ACK timeout requested, bit1=auto-close session on host power-off). |
| 10 | ..11: LE uint16 main watchdog timeout in seconds (0→64800 s default, \<60→clamped to 60). |
| 12 | reserved (must be 0x00). |
| 13 | ACK timeout in seconds (valid only when flags bit0=1; clamped 5-60). Minimum length: 6. |

Response

| Offset | Response field |
|----|----|
| 0 | ..1\]: 2B random session handle (LE, used in all subsequent session-locked subcmds). |
| 2 | ..3\]: 0 (reserved). |

Backends `IPMISessionCtrlGenerateRandomNum (random session handle); _lx_TimerCreate/_lx_TimerActivate/_lx_TimerChange (ACK timer and main watchdog timer); DellAbsRegCallback(9, MASERLPCCallBack) for power-off events; UpdateLCStatusInShm()`

**Security** — Session initiation gate for all MASER partition operations. Admin-only but inBandOnly — only reachable via host KCS/BT, not LAN. Generates a 2-byte random session handle; short handle space (65536 values) allows brute-force guessing if an attacker has in-band IPMI access at Admin privilege. Watchdog ensures session cannot be held open indefinitely.

### 3.10CmdOEMMASERPartitionAccess/CmdOEMUnLockMASER Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x01Priv  · · · **A**libmaserconfidence: highlive ✓

Terminate the active MASER session. Validates the supplied session handle against the globally stored one, deactivates the main watchdog timer, clears session state (DAT_0018bf6b=0, handle=0), resets power-off flag and on-reset flag, and calls UpdateLCStatusInShm(0).

Request

req+7=0x05 (5 data bytes required). req+8=0x01 (subcmd). req+9..10: 2B session handle (must match active session handle exactly; bytes req+8+3 and req+8+4 i.e. req+11..12 must both be 0x00 else CC=0xCC). req+11..12: reserved (must be 0x00). Minimum length: 5.

Response

| Offset | Response field |
|----|----|
| 11 | ..12 or |
| 13 | ..14 non-zero). On success: resp_data length=2. resp_data\[0..1\]: 0,0. |

Backends `_lx_TimerDeactivate (main watchdog); UpdateLCStatusInShm(0)`

**Security** — Session termination. Handle validation protects against unauthorized session teardown. Bypassing this (guessing the handle) would allow an attacker to abort a legitimate LC session mid-operation.

### 3.11CmdOEMMASERPartitionAccess/CmdOEMMASERLockWDreset Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x02Priv  · · · **A**libmaserconfidence: lowlive ✓

Reset the MASER session watchdog timer (keep-alive ping). Prevents the watchdog from expiring and forcibly closing the session.

Request

req+8=0x02 (subcmd). Remaining fields: undetermined (leaf handler CmdOEMMASERLockWDreset.c not read). Minimum length: undetermined.

Response

undetermined (leaf handler not read).

Backends `MASER_WD_Reset() or equivalent watchdog reset mechanism.`

**Security** — Heartbeat command for session liveness. Reachable only in-band at Admin priv.

### 3.12CmdOEMMASERPartitionAccess/CmdOEMGetPartitionIndexInfo Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x03Priv  · · · **A**libmaserconfidence: highlive ✓

Return the total number of MASER partitions from the global partition index count (DAT_0018bef0). Requires an active session with a matching handle.

Request

| Offset | Request field                                     |
|--------|---------------------------------------------------|
| 7      | 0x05.                                             |
| 8      | 0x03 (subcmd).                                    |
| 9      | ..10: 2B session handle.                          |
| 11     | ..12: reserved (must be 0x00). Minimum length: 5. |

Response

| Offset | Response field                                                |
|--------|---------------------------------------------------------------|
| 0      | ..1\]: session handle echo.                                   |
| 2      | ..5\]: 0x00.                                                  |
| 6      | ..7\]: LE uint16 partition index count (global DAT_0018bef0). |
| 8      | ..9\]: 0x00. Resets watchdog on success.                      |

Backends `Global in-memory partition index DAT_0018bef0; MASER_WD_Reset()`

**Security** — Read-only partition metadata. Discloses partition count. Admin+inBand only.

### 3.13CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfo Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x04Priv  · · · **A**libmaserconfidence: highlive ✓

Return info about a specific MASER partition (dynamic partitions only in this code path). Reads partition name from global G_char8DynPartNameMap, computes size from image file stat at /var/run/maser/images/\<name\>.img, encodes name as digit bytes. Static partitions return an error outside POST. SECUPD partitions are hidden when /mnt/scratchpad/hide_SECUPD exists.

Request

| Offset | Request field |
|----|----|
| 7 | 0x07. |
| 8 | 0x04 (subcmd). |
| 9 | ..10: 2B session handle. |
| 11 | partition type byte (bit7=1 for dynamic, bits6:0 must be 0; 0x80=dynamic, 0x00=static unsupported outside manuf mode). |
| 12 | dynamic partition index (0-based). |
| 13 | ..14: reserved (must be 0x00 bits in upper bits). Minimum length: 7. |

Response

| Offset | Response field                                           |
|--------|----------------------------------------------------------|
| 0      | session handle low.                                      |
| 1      | ..2\]: LE uint16 partition size in 64KB units minus 1.   |
| 3      | size high byte.                                          |
| 4      | ..8\]: 5 bytes of digit-encoded partition name from map. |
| 9      | status flags (0x58=hidden SECUPD).                       |
| 10     | type flags (0x49=dynamic). Resets watchdog on success.   |

Backends `G_char8DynPartNameMap (global partition name array); stat64 on /var/run/maser/images/<name>.img; utl_file_exists('/mnt/scratchpad/hide_SECUPD'); IsBIOSDonePOST()`

**Security** — Read-only partition metadata. SECUPD partition can be hidden from query via sentinel file. Discloses dynamic partition names and sizes. Admin+inBand only.

### 3.14CmdOEMMASERPartitionAccess/CmdOEMAttachPartitions Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x05Priv  · · · **A**libmaserconfidence: highlive ✓

Request async attach of one or more MASER partitions to the host. Validates session, checks no prior attach is pending, stores partition bitmap in S_pAttachMap, fires a GP task event. Partition selection is via a bitmask across multiple bytes.

Request

req+7=0x0b (11 bytes). req+8=0x05 (subcmd). req+9..10: 2B session handle. req+11..12: 2B partition attach bitmap (which partitions; must not be all-zero with req+15..16 also zero). req+13..14: reserved (must be 0x00; bits req+8..9's upper bits also checked). req+15..16: 2B partition access flags/type bitmap. req+17..18: reserved (must be 0x00). Minimum length: 11.

Response

| Offset | Response field                |
|--------|-------------------------------|
| 0      | ..1\]: session handle echo.   |
| 2      | ..3\]: 0x00. Resets watchdog. |

Backends `S_pAttachMap (global), S_u32MASERAttachEventID (global), SetGPTaskEvent(), MASER_WD_Reset()`

**Security** — Partition attach is async. A successful response means the task was queued, not completed; use CmdOEMCheckMASER_IPMIcmdStatus (subcmd 0x0a) to poll status. Admin+inBand only.

### 3.15CmdOEMMASERPartitionAccess/CmdOEMDetachPartitions Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x06Priv  · · · **A**libmaserconfidence: highlive ✓

Request async detach of one or more MASER partitions from the host. Same structure as AttachPartitions (subcmd 0x05) but stores into S_pDetachMap and fires the detach GP task event.

Request

req+7=0x0b (11 bytes). req+8=0x06 (subcmd). req+9..10: 2B session handle. req+11..12: 2B partition bitmap (must not be all-zero with req+15..16). req+13..14: reserved (must be 0x00). req+15..16: 2B detach flags. req+17..18: reserved. Minimum length: 11.

Response

| Offset | Response field                |
|--------|-------------------------------|
| 0      | ..1\]: session handle echo.   |
| 2      | ..3\]: 0x00. Resets watchdog. |

Backends `S_pDetachMap (global), DAT_0018bf24 (detach event ID), SetGPTaskEvent(), MASER_WD_Reset()`

**Security** — Async operation, poll with subcmd 0x0a. Admin+inBand only.

### 3.16CmdOEMMASERPartitionAccess/CmdOEMCreateDynamicPartition Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x07Priv  · · · **A**libmaserconfidence: medlive ✓

Request async creation of a new dynamic MASER partition with a given size and volume label. Stores size (in 64KB blocks) and 6-byte label into globals, sets status pending, fires a GP task event.

Request

| Offset | Request field |
|----|----|
| 7 | 0x0c (12 bytes). |
| 8 | 0x07 (subcmd). |
| 9 | ..10: 2B session handle. |
| 11 | ..12: LE uint16 volume size request (actual_bytes=(value+1)\*64). |
| 13 | ..18: 6B ASCII volume label. |
| 19 | device type flags (bits7:5 = device type — must be 0x00 (default) or 0x02; bits4:0 must be 0). Minimum length: 12. |

Response

CC: undetermined on success path (response length not explicitly set in decompile); likely 0x00 with resp_data length=0 or 4. CC: 0x01 session inactive, 0x03 invalid handle, 0x02 previous create still pending, 0xC7 bad length (expected 12), 0xCC invalid device type or reserved bits set. Resets watchdog on success.

Backends `DAT_0018bf00..0x06 (volume label globals), DAT_0018bf0c (volume size global), DAT_0018bf28 (create task event ID), SetGPTaskEvent(), MASER_WD_Reset()`

**Security** — Creates new storage partition. Admin+inBand. Async — poll with subcmd 0x0a cmd_id=7.

### 3.17CmdOEMMASERPartitionAccess/CmdOEMDeleteDynamicPartition High

NetFn 0x30 · Cmd 0xa2 · Sub 0x08Priv  · · · **A**libmaserconfidence: highlive ✓

Request async deletion of one or more dynamic MASER partitions identified by bitmap. Refuses if partition is currently attached in POST (IsBIOSDonePOST check). Stores delete bitmap in globals and fires the delete GP task event.

Request

| Offset | Request field |
|----|----|
| 7 | 0x09 (9 bytes). |
| 8 | 0x08 (subcmd). |
| 9 | ..10: 2B session handle. |
| 11 | ..12: 2B delete bitmap (S_u8DeleteDynamicBitMap\[0..1\]; both bytes must not both be zero; checked against MountedMaserMap). |
| 13 | ..14: reserved (must be 0x00). |
| 15 | ..16: reserved (must be 0x00). Minimum length: 9. |

Response

| Offset | Response field |
|----|----|
| 0 | ..1\]: session handle echo. |
| 2 | ..3\]: 0x00. CC errors: 0x01 no session, 0x03 invalid handle, 0x06 partition currently attached, 0xC7 bad length, 0xCC reserved non-zero or bitmap all-zero. Resets watchdog. |

Backends `DAT_0018bf20 (delete bitmap global), S_pMountedMaserMap, DAT_0018bf2c (delete task event ID), SetGPTaskEvent(), IsBIOSDonePOST(), MASER_WD_Reset()`

**Security** — Destructive partition delete. Admin+inBand. CC=6 guard prevents deleting attached partitions while in POST.

### 3.18CmdOEMMASERPartitionAccess/CmdOEMSecureUpdatePartition Critical

NetFn 0x30 · Cmd 0xa2 · Sub 0x09Priv  · · · **A**libmaserconfidence: highlive ✓

Transfer hash data for a secure partition update. Two packet types: header (data\[3\]=0x00, data_len=11) initializes SecureUpdateInit with partition params; data packet (data\[3\]=0x01, data_len=15) appends 10 hash bytes to the hash file via SecUpdGetData. When all expected hash chunks received, fires the SECUPD task event.

Request

Header packet: req+7=0x0b (11), req+8=0x09, req+9..10=session handle, req+11=0x00 (header), req+12..13=reserved, req+14=partition index, req+15=total hash chunks, req+16=chunk size. Data packet: req+7=0x0f (15), req+8=0x09, req+9..10=session handle, req+11=0x01 (data), req+12..21=10B hash data. Minimum length: 11 (header) or 15 (data).

Response

CC: 0x00 success, 0x01 session inactive or out-of-range hash count, 0x03 invalid handle, 0xCC SecUpdGetData failed, 0xC7 bad length. On success: resp_data length=4. resp_data\[0\]: session handle low. resp_data\[1\]: 0x00. resp_data\[2..3\]: 0x00. Resets watchdog.

Backends `SecureUpdateInit(), SecUpdGetData(), fopen64/fwrite to hash file (path from DAT_0018bf80), DAT_0018bf34 (SECUPD task event ID), SetGPTaskEvent(), MASER_WD_Reset()`

**Security** — Firmware/partition update gate. Hash data is written to a file then a task is triggered. A session handle is required (Admin+inBand). File path for hash data comes from SecUpdGetData return — if that path is attacker-influenced it could be a write primitive, but derivation of the path is undetermined from static analysis alone.

### 3.19CmdOEMMASERPartitionAccess/CmdOEMCheckMASER_IPMIcmdStatus Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x0aPriv  · · · **A**libmaserconfidence: highlive ✓

Poll the completion status of a previously issued async MASER command. The caller specifies which prior command to query (by its subcmd ID) and receives back a per-command status byte from global state. Supported query IDs: 2 (WD_RESET), 3 (GET_INDEX_INFO), 4 (GET_INFO), 5 (ATTACH), 6 (DETACH), 7 (CREATE), 8 (DELETE), 9 (SECUPD), 0x14 (WIPE), 0x20 (BEGIN_SECUPD), 0x21 (START_SECUPD_PM), 0x22 (PROCESS_SECUPD), 0x23 (END_SECUPD), 0x24 (AD_BY_NAME), 0x26 (SINGLE_IPMI).

Request

req+7=0x06 (6 bytes). req+8=0x0a (subcmd). req+9..10: 2B session handle. req+11: 1B command ID to query (see purpose for valid values). req+12..13: reserved (upper bits of req+8..12 must be 0x00). Minimum length: 6.

Response

| Offset | Response field |
|----|----|
| 0 | ..1\]: session handle (LE uint16). |
| 2 | status byte for the queried command (0=success/complete, 1=failure, 2=pending, 3=invalid handle, other=command-specific error). |
| 3 | 0x00. Resets watchdog. |

Backends `Global per-command status variables (DAT_0018bf08, DAT_0018bf22, DAT_0018bf68, DAT_0018bf6a, DAT_0018bf75, DAT_0018bf76, DAT_0018bfe5, DAT_0018bfe7, DAT_0018bfe8, DAT_0018bfe9, PTR_S_u8PrevMaserAttachStatus, PTR_G_u8Status_DetachPartition); MASER_WD_Reset()`

**Security** — Read-only status polling. Exposes internal command completion state. Admin+inBand only.

### 3.20CmdOEMMASERPartitionAccess/CmdOEMChangePartitionAccessType High

NetFn 0x30 · Cmd 0xa2 · Sub 0x0bPriv  · · · **A**libmaserconfidence: highlive ✓

Change partition access type (RO→RW or vice versa) for one or more MASER partitions. Validates session, checks manufacturing/UEFI mode restrictions (RW not allowed on static partitions 001/002/021 in POST or after POST for static ones). For OEMDRV partitions, calls ProcessAvctMapForRFSaction to perform the vmedia re-attach with new access type.

Request

| Offset | Request field                                 |
|--------|-----------------------------------------------|
| 7      | 0x0e (14 bytes).                              |
| 8      | 0x0b (subcmd).                                |
| 9      | ..10: 2B session handle.                      |
| 11     | ..12: 2B partition bitmap (which partitions). |
| 13     | ..14: 2B source flags.                        |
| 15     | ..16: 2B target partition bitmap.             |
| 17     | ..18: reserved.                               |
| 19     | access type (0=read-only, 1=read-write).      |
| 20     | ..21: reserved. Minimum length: 14.           |

Response

| Offset | Response field                |
|--------|-------------------------------|
| 0      | ..1\]: session handle echo.   |
| 2      | ..3\]: 0x00. Resets watchdog. |

Backends `IsInManufacturingTestMode(), IsBIOSDonePOST(), G_char8DynPartNameMap, ProcessAvctMapForRFSaction(), Dell_shm_memread(), MASER_WD_Reset()`

**Security** — Allows escalating partition from RO to RW. Restricted to specific partition types and modes. Admin+inBand.

### 3.21CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfoByName Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x0cPriv  · · · **A**libmaserconfidence: lowlive ✓

Return MASER partition info by partition name string instead of by index. Equivalent to CmdOEMGetPartitioninfo but with name-based lookup.

Request

req+8=0x0c (subcmd). Remaining fields: undetermined (CmdOEMGetPartitioninfoByName.c not read). Minimum length: undetermined.

Response

undetermined (leaf handler not read).

Backends `Partition name map, partition image files. Similar to subcmd 0x04.`

**Security** — Read-only partition info. Admin+inBand.

### 3.22CmdOEMMASERPartitionAccess/CmdOEMGetUEFIFlag High

NetFn 0x30 · Cmd 0xa2 · Sub 0x10Priv  · · · **A**libmaserconfidence: lowlive ✓

Read the current UEFI boot flag/state from the MASER session context. Controls what the UEFI/BIOS does on next boot (GUI, SSM, recovery, normal, etc.).

Request

req+8=0x10 (subcmd). Remaining fields: undetermined (CmdOEMGetUEFIFlag.c not read).

Response

undetermined (leaf handler not read).

Backends `MaserCmdsGetUEFIFlag() global/cfgdb state.`

**Security** — Read-only boot flag. Admin+inBand.

### 3.23CmdOEMMASERPartitionAccess/CmdOEMSetUEFIFlag High

NetFn 0x30 · Cmd 0xa2 · Sub 0x11Priv  · · · **A**libmaserconfidence: lowlive ✓

Write the UEFI boot flag/state to control what happens on next boot (normal, GUI, SSM, recovery, wipe, etc.).

Request

req+8=0x11 (subcmd). Remaining fields: undetermined (CmdOEMSetUEFIFlag.c not read).

Response

undetermined (leaf handler not read).

Backends `MaserCmdsSetUEFIFlag() global/cfgdb state.`

**Security** — Can redirect host to recovery or wipe mode on next boot. Admin+inBand is the only guard.

### 3.24CmdOEMMASERPartitionAccess/CmdOEMLockMASER_LockACK Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x12Priv  · · · **A**libmaserconfidence: highlive ✓

Identical handler to subcmd 0x00 (CmdOEMLockMASER). IPMICMD_MASER_LOCK_ACK — same code path, same behavior: begins a MASER session with optional ACK timer.

Request

Identical to subcmd 0x00. req+7=0x06; req+8=0x12; req+9..13 as per subcmd 0x00.

Response

Identical to subcmd 0x00.

Backends `Same as subcmd 0x00.`

**Security** — Same as subcmd 0x00. Having two subcmd values map to the same handler may indicate a version-compatibility alias.

### 3.25CmdOEMMASERPartitionAccess/CmdOEMAck Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x13Priv  · · · **A**libmaserconfidence: lowlive ✓

Acknowledge a pending MASER lock ACK request (IPMICMD_MASER_ACK). Resets or deactivates the ACK watchdog timer.

Request

req+8=0x13 (subcmd). Remaining fields: undetermined (CmdOEMAck.c not read).

Response

undetermined (leaf handler not read).

Backends `ACK timer (DAT_0018c1a0), session state globals.`

**Security** — ACK mechanism. Admin+inBand.

### 3.26CmdOEMMASERPartitionAccess/CmdOEMLCLWipe Critical

NetFn 0x30 · Cmd 0xa2 · Sub 0x14Priv  · · · **A**libmaserconfidence: highlive ✓

Initiate an async Lifecycle Controller wipe operation. First checks that SEKM (Secure Enterprise Key Management) is not present (returns CC=0x14 if SEKM enabled). Validates session handle. Refuses if /mmc1/SPI_shadow.bin exists (CC=-0x2b). Fires the LC wipe GP task event. Manufacturing test mode bypasses the session check.

Request

| Offset | Request field                                                     |
|--------|-------------------------------------------------------------------|
| 7      | 0x05 (5 bytes).                                                   |
| 8      | 0x14 (subcmd).                                                    |
| 9      | ..10: 2B session handle (bypass-able in manufacturing test mode). |
| 11     | 1B wipe mode flags.                                               |
| 12     | reserved (must be 0x00). Minimum length: 5.                       |

Response

| Offset | Response field |
|----|----|
| 0 | ..1\]: session handle echo. |
| 2 | ..3\]: 0x00. CC errors: 0xC7 bad length, 0xCC reserved non-zero, 0x14 SEKM present (wipe blocked), -0x2b (0xD5) SPI shadow bin present, 0x01 session inactive, 0x03 invalid handle, 0x02 previous wipe still pending. Resets watchdog on success. |

Backends `CfgGetAttributeInt('iDRAC.Embedded.1#SEKM.1#SEKMStatus'); stat64('/mmc1/SPI_shadow.bin'); IsInManufacturingTestMode(1); DAT_0018bf38 (wipe task event ID); SetGPTaskEvent(); MASER_WD_Reset()`

**Security** — DESTRUCTIVE: wipes the Lifecycle Controller storage. SEKM presence blocks the wipe — if SEKM check can be bypassed (e.g., cfgdb manipulation), wipe runs. Manufacturing test mode bypasses session handle validation. Admin+inBand.

### 3.27CmdOEMMASERPartitionAccess/CmdOEMUtility_Request Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x15Priv  · · · **A**libmaserconfidence: lowlive ✓

Utility request sub-operation (IPMICMD_MASER_UTILITY_REQUEST). Same handler (CmdOEMUtility) as subcmd 0x16.

Request

req+8=0x15. Remaining fields: undetermined (CmdOEMUtility.c not read).

Response

undetermined.

Backends `undetermined.`

**Security** — Admin+inBand.

### 3.28CmdOEMMASERPartitionAccess/CmdOEMUtility_Status Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x16Priv  · · · **A**libmaserconfidence: lowlive ✓

Utility status sub-operation (IPMICMD_MASER_UTILITY_STATUS). Same handler (CmdOEMUtility) as subcmd 0x15.

Request

req+8=0x16. Remaining fields: undetermined (CmdOEMUtility.c not read).

Response

undetermined.

Backends `undetermined.`

**Security** — Admin+inBand.

### 3.29CmdOEMMASERPartitionAccess/CmdOEMBeginSECUPD High

NetFn 0x30 · Cmd 0xa2 · Sub 0x20Priv  · · · **A**libmaserconfidence: lowlive ✓

Begin a secure update (SECUPD) operation. Sets up the SECUPD state machine. Called before CmdOEMProcessSECUPD and CmdOEMEndSECUPD.

Request

req+8=0x20. Remaining fields: undetermined (CmdOEMBeginSECUPD.c not read).

Response

undetermined.

Backends `SECUPD state globals (DAT_0018bfe7); MASERBeginSECUPD().`

**Security** — Firmware/partition update initiation. Requires Admin+inBand session.

### 3.30CmdOEMMASERPartitionAccess/CmdOEMStartSECUPD_PM High

NetFn 0x30 · Cmd 0xa2 · Sub 0x21Priv  · · · **A**libmaserconfidence: lowlive ✓

Start or retrieve SECUPD data (IPMICMD_PM_GET_SECUPD_DATA). Platform Manager variant of the SECUPD data retrieval command.

Request

req+8=0x21. Remaining fields: undetermined (CmdOEMStartSECUPD_PM.c not read).

Response

undetermined.

Backends `SECUPD state globals.`

**Security** — Firmware/partition update data transfer. Admin+inBand.

### 3.31CmdOEMMASERPartitionAccess/CmdOEMProcessSECUPD High

NetFn 0x30 · Cmd 0xa2 · Sub 0x22Priv  · · · **A**libmaserconfidence: lowlive ✓

Process a secure update block (IPMICMD_MASER_PROCESS_SECUPD). Transfers firmware/partition update data after BeginSECUPD.

Request

req+8=0x22. Remaining fields: undetermined (CmdOEMProcessSECUPD.c not read).

Response

undetermined.

Backends `SECUPD state globals (DAT_0018bfe8); MASERProcessSECUPD().`

**Security** — Firmware update data path. Admin+inBand.

### 3.32CmdOEMMASERPartitionAccess/CmdOEMEndSECUPD High

NetFn 0x30 · Cmd 0xa2 · Sub 0x23Priv  · · · **A**libmaserconfidence: lowlive ✓

Finalize a secure update operation (IPMICMD_MASER_END_SECURE_UPDATE). Commits the update after all data has been transferred.

Request

req+8=0x23. Remaining fields: undetermined (CmdOEMEndSECUPD.c not read).

Response

undetermined.

Backends `SECUPD state globals (DAT_0018bfe9); MASEREndSECUPD().`

**Security** — Firmware update commit. Admin+inBand.

### 3.33CmdOEMMASERPartitionAccess/CmdOEMADByName Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x24Priv  · · · **A**libmaserconfidence: lowlive ✓

Attach or detach a MASER partition by name (IPMICMD_MASER_ATTACH_DETACH_BY_NAME). Identifies the partition by ASCII name string rather than bitmap index.

Request

req+8=0x24. Remaining fields: undetermined (CmdOEMADByName.c not read).

Response

undetermined.

Backends `MASERADByNameTask; partition name map.`

**Security** — Admin+inBand. If partition name lookup is not properly sanitized, potential path for name-based partition selection attacks.

### 3.34CmdOEMMASERPartitionAccess/CmdOEMSingleIPMI Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x26Priv  · · · **A**libmaserconfidence: lowlive ✓

Single-packet secure update (IPMICMD_SECUPD_SINGLE). A combined begin/process/end SECUPD in one IPMI message.

Request

req+8=0x26. Remaining fields: undetermined (CmdOEMSingleIPMI.c not read, ~28KB decompile).

Response

undetermined.

Backends `SECUPD state; firmware write path.`

**Security** — Single-shot firmware/partition update. Admin+inBand. The large function size (~28KB) warrants deeper analysis.

### 3.35CmdOEMMASERPartitionAccess/CmdOEMGetPkgCacheUpdateFlag Medium

NetFn 0x30 · Cmd 0xa2 · Sub 0x27Priv  · · · **A**libmaserconfidence: lowlive ✓

Read the package cache update flag, used to track whether cached update packages need refreshing.

Request

req+8=0x27. Remaining fields: undetermined (CmdOEMGetPkgCacheUpdateFlag.c not read).

Response

undetermined.

Backends `undetermined.`

**Security** — Read-only flag. Admin+inBand.

### 3.36CmdOEMRemoteEnablement/GetAutoDiscovery Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x00Priv  · **U** O Alibmaserconfidence: highlive ✓

Return whether auto-discovery is currently enabled (1) or disabled (0) by querying the internal getAutoDiscovery() function.

Request

req+8=0x00; no further data

Response

resp_len=1; resp\[0\]=0 or 1

Backends `getAutoDiscovery()`

### 3.37CmdOEMRemoteEnablement/SetAutoDiscovery Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x01Priv  · **U** O Alibmaserconfidence: highlive ✓

Set the auto-discovery mode. Mode 0=disable, 1=enable+restart service, 2=enable+run /usr/bin/auto_disc_setup.sh (manufacturing mode only), 3=enable+FUN_00140ed0, 4=enable+FUN_00140ed0+restart service.

Request

req+8=0x01; req+9=mode (0..4)

Response

resp_len=0; CC 0x00 on success; CC 0x09 if mode 2 requested outside manufacturing mode

Backends `setAutoDiscoveryEnabled/Disabled, run_systemctl_as_root(0x15 idrac_discovery.service), utl_execmd(/usr/bin/auto_disc_setup.sh), IsInManufacturingTestMode`

**Security** — Mode 2 executes /usr/bin/auto_disc_setup.sh as root. Mode 1/4 restart idrac_discovery.service. All modes are available to any User-level IPMI caller without channel restriction.

### 3.38CmdOEMRemoteEnablement/SignCertificate Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x02Priv  · **U** O Alibmaserconfidence: highlive ✓

Initiate a certificate signing/generation operation (op 0=factory/manufacturing, 1=iDRAC, 2=server, 3=client) by spawning a detached pthread PthreadCertOperations. Returns pending (CC 2) immediately; uses /tmp/cert_script_pending_flag as a lock.

Request

req+8=0x02; req+9=op (0..3; \>3 returns CC 1); op 0 requires manufacturing mode

Response

resp_len=2; resp\[0\]=0; resp\[1\]=0; CC 0x02 while pending; CC 0x01 on invalid op or thread failure; CC 0x09 if op=0 outside manufacturing mode

Backends `PthreadCertOperations (pthread), /tmp/cert_script_pending_flag, /flash/data0/cv/ cert files`

**Security** — PKI material is generated or replaced. op=1 generates a new iDRAC TLS identity; op=3 replaces the remote-enablement client cert. No out-of-band authorization required beyond User-level IPMI.

### 3.39CmdOEMRemoteEnablement/GetCertificateStatus Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x03Priv  · **U** O Alibmaserconfidence: highlive ✓

Check whether a certificate file exists on flash for the given cert type. cert_type 0=STAG_client/factory, 1=CUSCLNT.PEM, 2=CUSSRVPB.PEM, 3=STAG_client. Also reads fault code from /tmp/STAG_client_error if absent.

Request

req+8=0x03; req+9=cert_type (0..3)

Response

resp_len=3; return-CC = 2 if a cert-signing operation is in progress (/tmp/cert_script_pending_flag exists), else 0. resp\[0\]=present flag: 1 if the cert file for the requested type exists, 0 if absent. resp\[1\]=fault_code (byte from /tmp/STAG_client_error via fscanf) when the cert is absent, else 0. resp\[2\]=0.

Backends `stat64 on /flash/data0/cv/STAG_client.pem, CUSCLNT.PEM, CUSSRVPB.PEM, STAG_client_factory.pem; /tmp/STAG_client_error (read)`

### 3.40CmdOEMRemoteEnablement/GetRECapabilitiesBitmap Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x04Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the 8-byte RE (Remote Enablement) capability bitmap for a given component (1=iDRAC from /etc/CAPIDRAC, 2=BIOS from /var/run/osd/CAPBIOS or /flash/data0/oem_ps/CAPBIOS, 3=USC from /flash/data0/oem_ps/CAPUSC).

Request

req+8=0x04; req+9=component (1=iDRAC, 2=BIOS, 3=USC; other returns CC 1)

Response

| Offset | Response field                                                 |
|--------|----------------------------------------------------------------|
| 0      | ..7\]=capability_bitmap_8bytes (fscanf %2hhx x8, byte-reversed |
| 8      | ..9\]=0. CC 0x01 if file not found or fscanf fails.            |

Backends `/etc/CAPIDRAC, /var/run/osd/CAPBIOS, /flash/data0/oem_ps/CAPBIOS, /flash/data0/oem_ps/CAPUSC (read)`

### 3.41CmdOEMRemoteEnablement/SetRECapabilitiesBitmap Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x05Priv  · **U** O Alibmaserconfidence: highlive ✓

Deprecated set-capabilities call. Regardless of component, always resets the CSIORLaunched CfgDB attribute to 0. Component 1 (iDRAC) logs 'may not be set'; components 2-3 log 'deprecated'. Always returns CC 0x01.

Request

req+8=0x05; req+9=component (1..3)

Response

CC 0x01 always. Side effect: CfgSetAttributeInt(CSIORLaunched, 0) is always called.

Backends `CfgSetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#CSIORLaunched)`

**Security** — Unconditionally resets CSIOR launched state — any User-level IPMI caller can prevent CSIOR from being recognized as already launched.

### 3.42CmdOEMRemoteEnablement/GetProvisioningServerInfo Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x06Priv  · **U** O Alibmaserconfidence: highlive ✓

Return a substring of the provisioning server URL from CfgDB. Caller specifies a byte offset and maximum bytes to return (capped at 30). Allows chunked read-out of the full URL.

Request

req+8=0x06; req+9=offset (byte offset into URL string); req+10=max_bytes (capped to 30)

Response

| Offset | Response field                                    |
|--------|---------------------------------------------------|
| 0      | actual_bytes_returned                             |
| 1      | ..\]=URL_substring. CC 0x01 if offset \>= strlen. |

Backends `getProvisioningServerInfoConfigDB (CfgDB read)`

**Security** — Exposes provisioning server URL to any User-level IPMI caller on any channel.

### 3.43CmdOEMRemoteEnablement/SetProvisioningServerInfo Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x07Priv  · **U** O Alibmaserconfidence: highlive ✓

Write one chunk of the provisioning server URL into a 256-byte global buffer (DAT_0018c370) at caller-specified offset; when offset+length-1 == total_len, the complete URL is committed to CfgDB and syslog.

Request

| Offset | Request field |
|----|----|
| 8 | 0x07 |
| 9 | offset |
| 10 | chunk_length |
| 11 | ..=url_bytes. Writes are accepted only if offset+chunk_length \< 0x101 (i.e. \<= 256, the size of the 256-byte DAT_0018c370 buffer); otherwise CC 0xcc. The URL is committed to CfgDB when offset+chunk_length-1 == the total-length byte stored at buffer\[0\]. |

Response

resp_len=1; resp\[0\]=chunk_length (echo); CC 0x00. CC 0xcc if offset+length exceeds buffer.

Backends `DAT_0018c370 global buffer, setProvisioningServerInfoConfigDB (CfgDB write), syslog, openlog/closelog`

**Security** — Allows any User-level IPMI caller to overwrite the provisioning server URL — enabling a redirect to an attacker-controlled provisioning server, leading to device takeover on next factory-reset/re-provisioning.

### 3.44CmdOEMRemoteEnablement/GetDiscoveryRestartOptions Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x08Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the current auto-discovery restart option flags by reading /flash/data0/oem_ps/auto_discovery_conf. Flags: bit0=disable_users, bit1=delete_users, bit2=DH_factory_default.

Request

req+8=0x08; no further data

Response

resp_len=2; resp\[0\]=flags_byte; resp\[1\]=0

Backends `/flash/data0/oem_ps/auto_discovery_conf (read), getDHFactoryDefault()`

### 3.45CmdOEMRemoteEnablement/SetDiscoveryRestartOptions Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x09Priv  · **U** O Alibmaserconfidence: highlive ✓

Set auto-discovery restart options by writing directives to /flash/data0/oem_ps/auto_discovery_conf. bit0=disable_users, bit1=delete_users (writes to conf), bit2=setDHFactoryDefault. Existing non-matching lines are preserved via copy.

Request

req+8=0x09; req+9=flags_byte (bits 0..2 as above)

Response

resp_len=0; returns bool (false=success, true=error)

Backends `/flash/data0/oem_ps/auto_discovery_conf (read/write), setDHFactoryDefault()`

**Security** — Setting delete_users flag causes all user accounts to be deleted on the next auto-discovery restart. Any User-level IPMI caller on any channel can set this.

### 3.46CmdOEMRemoteEnablement/GetCCRFeatureState Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x0aPriv  · **U** O Alibmaserconfidence: highlive ✓

Return whether the Cloud Configuration Reset (CCR) feature is enabled, indicated by the existence of /flash/data0/oem_ps/ccr_enabled.

Request

req+8=0x0a; no further data

Response

| Offset | Response field                            |
|--------|-------------------------------------------|
| 0      | 1 if ccr_enabled file exists, 0 otherwise |
| 1      | ..2\]=0                                   |

Backends `utl_is_file_exist(/flash/data0/oem_ps/ccr_enabled)`

### 3.47CmdOEMRemoteEnablement/SetCCRFeatureState Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x0bPriv  · **U** O Alibmaserconfidence: highlive ✓

Enable or disable the Cloud Configuration Reset feature by creating or removing /flash/data0/oem_ps/ccr_enabled.

Request

req+8=0x0b; req+9=state (0=disable/unlink, non-zero=enable/touch)

Response

resp_len=2; resp\[0..1\]=0; CC 0x00

Backends `unlink or utl_touch_file(/flash/data0/oem_ps/ccr_enabled)`

**Security** — Enabling CCR causes the iDRAC to be reconfigured from a cloud provisioning server on next restart. Can be toggled by any User-level IPMI caller.

### 3.48CmdOEMRemoteEnablement/GetCCRUpdateFWMode Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x0cPriv  · **U** O Alibmaserconfidence: highlive ✓

Return the current partial-firmware-update mode (0..2) from CfgDB attribute PartFirmwareUpdate.

Request

req+8=0x0c; no further data

Response

| Offset | Response field                        |
|--------|---------------------------------------|
| 0      | mode (0..2                            |
| 1      | ..2\]=0. CC 0x01 if CfgDB read fails. |

Backends `CfgGetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#PartFirmwareUpdate)`

### 3.49CmdOEMRemoteEnablement/SetCCRUpdateFWMode Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x0dPriv  · **U** O Alibmaserconfidence: highlive ✓

Set the partial-firmware-update mode (0=none, 1=partial, 2=full) in CfgDB.

Request

req+8=0x0d; req+9=mode (0..2; \>=3 returns CC 1)

Response

resp_len=2; resp\[0..1\]=0; CC 0x00 on success, CC 0x01 on CfgDB failure or invalid mode

Backends `CfgSetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#PartFirmwareUpdate)`

### 3.50CmdOEMRemoteEnablement/GetCCRConfigurationState Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x0ePriv  · **U** O Alibmaserconfidence: highlive ✓

Return the current partial-configuration-update state (0..2) from CfgDB attribute PartConfigurationUpdate.

Request

req+8=0x0e; no further data

Response

| Offset | Response field                        |
|--------|---------------------------------------|
| 0      | state (0..2                           |
| 1      | ..2\]=0. CC 0x01 if CfgDB read fails. |

Backends `CfgGetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#PartConfigurationUpdate)`

### 3.51CmdOEMRemoteEnablement/SetCCRConfigurationState Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x0fPriv  · **U** O Alibmaserconfidence: highlive ✓

Set the partial-configuration-update state (0..2) in CfgDB.

Request

req+8=0x0f; req+9=state (0..2; \>=3 returns CC 1)

Response

resp_len=2; resp\[0..1\]=0; CC 0x00 on success, CC 0x01 on failure

Backends `CfgSetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#PartConfigurationUpdate)`

### 3.52CmdOEMRemoteEnablement/GetCCRAutoSyncState Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x10Priv  · **U** O Alibmaserconfidence: highlive ✓

Return whether CSIOR (Collect System Inventory On Restart) is enabled, from CfgDB.

Request

req+8=0x10; no further data

Response

resp_len=3; resp\[0\]=state; resp\[1..2\]=0. CC 0x01 if CfgDB fails.

Backends `CfgGetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#CollectSystemInventoryOnRestart)`

### 3.53CmdOEMRemoteEnablement/SetCCRAutoSyncState Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x11Priv  · **U** O Alibmaserconfidence: highlive ✓

Set the CSIOR (Collect System Inventory On Restart) state in CfgDB. Side effect: if setting to 0 and the UEFI flag currently equals 7, also resets the UEFI flag to 0 via MaserCmdsSetUEFIFlag.

Request

req+8=0x11; req+9=state

Response

resp_len=2; resp\[0..1\]=0; CC 0x00 on success, CC 0x01 on CfgDB failure

Backends `CfgSetAttributeInt (CollectSystemInventoryOnRestart), MaserCmdsGetUEFIFlag, MaserCmdsSetUEFIFlag`

**Security** — Disabling CSIOR prevents inventory collection on reboot, potentially hiding hardware tampering from the LC log.

### 3.54CmdOEMRemoteEnablement/GetDHStatus Low

NetFn 0x30 · Cmd 0xa3 · Sub 0x12Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the Dynamic Host (auto-discovery) status: 0=not running, 1=running (from /tmp/auto_dh_status_file), 2=enabled/configured (/flash/data0/oem_ps/auto_discovery_enabled exists), 3=complete (/flash/data0/oem_ps/auto_dh_complete_file). Includes time-remaining when running.

Request

req+8=0x12; no further data

Response

| Offset | Response field                               |
|--------|----------------------------------------------|
| 0      | dh_status (0..3                              |
| 1      | sub_status                                   |
| 3      | ..6\]=time_or_ipaddr_u32 (big-endian swapped |

Backends `getAutoDiscoveryRunning, stat64 on /flash/data0/oem_ps/auto_discovery_enabled, /flash/data0/oem_ps/auto_dh_complete_file, GetAutoDhStatus, GetTimeLeft`

### 3.55CmdOEMRemoteEnablement/RemoveCertificate Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x13Priv  · **U** O Alibmaserconfidence: highlive ✓

Delete PKI certificate file(s) from /flash/data0/cv/. bit0=delete iDRAC client cert (STAG_client.pem + CUSTRTCA.PEM), bit1=delete server cert (CUSSRVPB.PEM). Both bits can be set simultaneously.

Request

req+8=0x13; req+9=cert_bitmap (bits 0..1; value 0 returns CC 1)

Response

resp_len=2; resp\[0..1\]=0; CC 0x02 on success (syslog written). CC 0x01 if bitmap==0.

Backends `utl_rm_force_filelike(/flash/data0/cv/STAG_client.pem, CUSTRTCA.PEM, CUSSRVPB.PEM), syslog`

**Security** — Destroys iDRAC or server PKI material. Any User-level IPMI caller on any channel can revoke the device's certificates, triggering re-provisioning on next restart.

### 3.56CmdOEMRemoteEnablement/SkipISOBoot Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x14Priv  · **U** O Alibmaserconfidence: highlive ✓

If a network ISO is attached (/tmp/osd_connect_network_isoimg_attached exists), execute /bin/osdinst SkipISOImageBoot & to skip it on the next boot.

Request

req+8=0x14; no further data

Response

resp_len=2; resp\[0..1\]=0; CC 0x00 if ISO attached (even if osdinst fails), CC 0x01 if no ISO attached

Backends `lstat64(/tmp/osd_connect_network_isoimg_attached), utl_execmd(/bin/osdinst SkipISOImageBoot)`

### 3.57CmdOEMRemoteEnablement/DisconnectNetworkISO Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x15Priv  · **U** O Alibmaserconfidence: highlive ✓

If a network ISO is attached, execute /bin/osdinst DisconnectNetworkISOImage & to unmount it.

Request

req+8=0x15; no further data

Response

resp_len=2; resp\[0..1\]=0; CC 0x00 if ISO was attached and command issued, CC 0x01 if no ISO

Backends `lstat64(/tmp/osd_connect_network_isoimg_attached), utl_execmd(/bin/osdinst DisconnectNetworkISOImage)`

### 3.58CmdOEMRemoteEnablement/ChangeRFSToAttachMode Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x16Priv  · **U** O Alibmaserconfidence: highlive ✓

Flip the Remote File Share (RFS) internal mode from streaming (RFS) to attach mode by setting the AIM config key pm_int_rfs_attach_mode. No-op if already set.

Request

req+8=0x16; no further data

Response

resp_len=2; resp\[0..1\]=0; CC 0x00

Backends `aim_config_get_bool/aim_config_set_bool (pm_int_rfs_attach_mode)`

### 3.59CmdOEMRemoteEnablement/ReCapabilityForDup Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0x17Priv  · **U** O Alibmaserconfidence: highlive ✓

Return DUP (Dell Update Package) capability flags for the current server generation. resp\[5\]=1 if server generation \> 3 (i.e. 14G+), else 0. The component ID in the request is ignored for the capability logic but is echoed back into the response.

Request

req+8=0x17; req+9..12=component_id_u32 (ignored for logic, logged and echoed into resp\[1..4\])

Response

| Offset | Response field                                               |
|--------|--------------------------------------------------------------|
| 0      | 0                                                            |
| 1      | ..4\]=component_id echo (the u32 from req+9..12              |
| 5      | dup_capable (1 if Dell_get_generation()\>3, else 0           |
| 6      | ..10\]=0. CC 0xc2 if the resp_len pointer (param_2) is NULL. |

Backends `Dell_get_generation()`

### 3.60CmdOEMRemoteEnablement/UEFILOGService Medium

NetFn 0x30 · Cmd 0xa3 · Sub 0xfffffff0Priv  · **U** O Alibmaserconfidence: highlive ✓

UEFI debug-log service. Subcmd (req+9): 0x01=get current dlog level and source-enabled state; 0x02=write data bytes into a 255-byte circular UEFI log buffer (optionally flushing via dlog_printf at the caller-specified severity level).

Request

req+8=0xfffffff0; req+7 must be \>= 2 (else CC 0xc7); req+9=op (0x01 or 0x02). For op=0x02: req+7 must be \>=5 (else CC 0xc7); req+10 (bVar5)=flags (bit0=reset ring buffer, bit1=flush via dlog_printf); req+11 (bVar4)=log_level (0-\>1, values \>9 clamped to 9); req+12 (uVar11)=max_byte_count (values \>=0xc4 clamp to sentinel 0xc3); req+13..=log_data bytes. (Previously req+10/req+11/req+12 were documented as log_level/max_byte_count/flags respectively, which is wrong; the correct order is flags/log_level/max_byte_count.)

Response

resp_len=4; resp\[0..3\]=0xff424200 initial; For op=0x01: resp\[0\]=1, resp\[1\]=dlog_level, resp\[2\]=source_enabled, resp\[3\]=0xc3; For op=0x02: resp\[0\]=2, resp\[1\]=dlog_level, resp\[2\]=source_enabled if flushed. CC 0xc7 if reqlen \< 2 or \< 5 for op=0x02

Backends `dlog_getlevel, dlog_issource, dlog_printf, PTR_UEFILOGGlobalState (255-byte ring buffer)`

**Security** — Any User-level IPMI caller on any channel can inject arbitrary data into the iDRAC's UEFI debug log stream and trigger dlog_printf at any severity level.

### 3.61CmdOEMvFlash/GetCardInfo Low

NetFn 0x30 · Cmd 0xa4 · Sub 0x00Priv  · **U** O Alibmaserconfidence: highlive ✓

Return vFlash SD-card info: total size, available space, health state, boot partition index, and status flags (enabled, attached, write-protected, partitions-attached).

Request

req+8=0x00; no further data required

Response

| Offset | Response field |
|----|----|
| 0 | result (0 on success; VFL error code on VFL_List_SD_Card_Info failure |
| 1 | status_flags. Bits confirmed from code: bit0(0x01)=health_warn, bit1(0x02)=health_crit, bits0+1 both set (value 0x03)=health_undefined, bit3(0x08)=write_protected (local_2f, per debug log), bit4(0x10)=enabled (local_33), bit5(0x20)=partitions_attached. Bits bit2(0x04, local_32), bit6(0x40, local_31), bit7(0x80, local_30) are set from card flags that are unlabeled in the decompilation (undetermined meaning). |
| 2 | ..5\]=total_size_u32_LE |
| 6 | ..9\]=available_space_u32_LE |
| 10 | boot_partition_index |
| 11 | 0 |

Backends `VFL_List_SD_Card_Info, VFL_Get_Partition_Index_Info_Attached`

### 3.62CmdOEMvFlash/CardControl Medium

NetFn 0x30 · Cmd 0xa4 · Sub 0x01Priv  · **U** O Alibmaserconfidence: highlive ✓

Enable, disable, or initialize the vFlash SD card. Action 0=disable, 1=enable, 2=initialize (triggers async format job).

Request

req+8=0x01; req+9=action (0=disable, 1=enable, 2=initialize); no further data

Response

| Offset | Response field                       |
|--------|--------------------------------------|
| 0      | result_code (0=ok, 99=invalid action |
| 1      | ..4\]=jobID (only set for action=2   |
| 5      | ..6\]=0                              |

Backends `VFL_Disable_vFlash, VFL_Enable_vFlash, VFL_Initialize_SD_Card`

**Security** — In-band caller can disable or wipe the vFlash partition. No additional authentication beyond IPMI user privilege.

### 3.63CmdOEMvFlash/GetPartitionIndexInfo Low

NetFn 0x30 · Cmd 0xa4 · Sub 0x10Priv  · **U** O Alibmaserconfidence: highlive ✓

Return a 16-bit bitmap of existing vFlash partition indices (byte-swapped).

Request

req+8=0x10; no further data

Response

| Offset | Response field                                                   |
|--------|------------------------------------------------------------------|
| 0      | result                                                           |
| 1      | ..2\]=partition_bitmap (big-endian, byte-swapped from VFL output |
| 3      | ..4\]=0                                                          |

Backends `VFL_Get_Partition_Index_Info`

### 3.64CmdOEMvFlash/GetPartitionInfo Low

NetFn 0x30 · Cmd 0xa4 · Sub 0x11Priv  · **U** O Alibmaserconfidence: highlive ✓

Return detailed info for a single vFlash partition: size, label, format type, emulation type, access type, attached flag.

Request

req+8=0x11; req+9=partition_index

Response

resp_len=14; resp\[0\]=result; resp\[1..4\]=partition_size_u32; resp\[5..6\]=label_u16; resp\[7\]=flags (bit6=attached, bit3=read-write, bit0=emulation floppy, bit1=emulation CD; no write_protected bit is written into resp\[7\] by this handler); resp\[8..11\]=size2_u32; resp\[12..13\]=format_type_flags (0x20=ext2,0x40=ext3,0x60=fat16,0x80=fat32)

Backends `VFL_Get_Partition_Info`

### 3.65CmdOEMvFlash/AttachPartitions Medium

NetFn 0x30 · Cmd 0xa4 · Sub 0x12Priv  · **U** O Alibmaserconfidence: highlive ✓

Attach one or more vFlash partitions to the host by bitmap. The 16-bit bitmap is byte-swapped from the request.

Request

req+8=0x12; req+9..10=partition_bitmap (big-endian, byte-swapped before use)

Response

| Offset | Response field  |
|--------|-----------------|
| 0      | result          |
| 1      | ..4\]=jobID_u32 |
| 5      | ..6\]=0         |

Backends `VFL_Attach_Partitions`

**Security** — Attaching partitions exposes vFlash storage to the host OS; in-band host can trigger this autonomously.

### 3.66CmdOEMvFlash/DetachPartitions Medium

NetFn 0x30 · Cmd 0xa4 · Sub 0x13Priv  · **U** O Alibmaserconfidence: highlive ✓

Detach one or more vFlash partitions from the host by bitmap.

Request

req+8=0x13; req+9..10=partition_bitmap (big-endian, byte-swapped)

Response

| Offset | Response field  |
|--------|-----------------|
| 0      | result          |
| 1      | ..4\]=jobID_u32 |
| 5      | ..6\]=0         |

Backends `VFL_Detach_Partitions`

### 3.67CmdOEMvFlash/SetBootPartition High

NetFn 0x30 · Cmd 0xa4 · Sub 0x14Priv  · **U** O Alibmaserconfidence: highlive ✓

Set which vFlash partition is the boot partition, either by index (mode=0) or by label string (mode!=0, label taken from req+0xf).

Request

| Offset | Request field               |
|--------|-----------------------------|
| 8      | 0x14                        |
| 9      | mode; if mode==0            |
| 10     | partition_index; if mode!=0 |
| 0xb    | ..0xf=label_4bytes          |
| 0xf    | ..0x10=label_2bytes         |

Response

| Offset | Response field                                       |
|--------|------------------------------------------------------|
| 0      | result (0=ok, 0x08=fail-by-index, 0x16=fail-by-label |
| 1      | ..2\]=0                                              |

Backends `VFL_Boot_VFlash_Partition, VFL_Boot_VFlash_Label`

**Security** — Host can redirect its own boot path to an arbitrary vFlash label via this in-band command.

### 3.68CmdOEMvFlash/GetBootPartition High

NetFn 0x30 · Cmd 0xa4 · Sub 0x15Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the currently configured boot partition index and its label string.

Request

req+8=0x15; no further data

Response

| Offset | Response field                   |
|--------|----------------------------------|
| 0      | result ('0x23'=no boot partition |
| 1      | boot_partition_index             |
| 2      | ..5\]=label_4bytes               |
| 6      | ..7\]=label_2bytes               |
| 8      | ..9\]=0                          |

Backends `VFL_List_SD_Card_Info, VFL_Get_Partition_Info`

### 3.69CmdOEMvFlash/CreateEmptyPartition High

NetFn 0x30 · Cmd 0xa4 · Sub 0x20Priv  · **U** O Alibmaserconfidence: highlive ✓

Create and optionally format a new empty vFlash partition with caller-specified index, label, size, format type (RAW/EXT2/EXT3/FAT16/FAT32), and emulation type (none/floppy/CD). Returns a job ID.

Request

| Offset | Request field |
|----|----|
| 8 | 0x20 |
| 9 | partition_index |
| 10 | ..13=label_4bytes |
| 14 | ..15=label_2bytes |
| 16 | flags_byte (bits\[6:3\]=format_type: 0=RAW,8=EXT2,0x10=EXT3,0x18=FAT16,0x20=FAT32; bits\[2:0\]=emul_type: 0=none,1=floppy,2=CD |
| 17 | ..20=partition_size_u32 |

Response

| Offset | Response field  |
|--------|-----------------|
| 0      | result          |
| 1      | ..4\]=jobID_u32 |
| 5      | ..6\]=0         |

Backends `VFL_Create_Format_Partition`

**Security** — Host can create arbitrary-sized partitions limited only by SD card capacity. No label length validation visible in decompilation.

### 3.70CmdOEMvFlash/FormatPartition High

NetFn 0x30 · Cmd 0xa4 · Sub 0x21Priv  · **U** O Alibmaserconfidence: highlive ✓

Format a vFlash partition. Decompiled function body is a stub — the function returns 0 immediately with no side effects. Likely not yet implemented.

Request

req+8=0x21; any further data ignored

Response

CC 0x00; resp_len=0

Backends `none (stub)`

### 3.71CmdOEMvFlash/ChangePartitionAccessType Medium

NetFn 0x30 · Cmd 0xa4 · Sub 0x22Priv  · **U** O Alibmaserconfidence: highlive ✓

Change one or more vFlash partitions to read-write (access=0) or read-only (access=1) mode. Partition set selected by 16-bit bitmap.

Request

req+8=0x22; req+9..10=partition_bitmap (big-endian, byte-swapped); req+0xb (req+11)=access_type (0 -\> VFL arg 1, 1 -\> VFL arg 0; any other value returns result 0x19). No padding byte before the access_type field.

Response

| Offset | Response field                         |
|--------|----------------------------------------|
| 0      | result (0=ok, 0x19=invalid access type |
| 1      | ..2\]=0                                |

Backends `VFL_Change_Partitions_Access_Type`

### 3.72CmdOEMvFlash/DeletePartition High

NetFn 0x30 · Cmd 0xa4 · Sub 0x23Priv  · **U** O Alibmaserconfidence: highlive ✓

Delete one or more vFlash partitions by bitmap.

Request

req+8=0x23; req+9..10=partition_bitmap (big-endian, byte-swapped)

Response

| Offset | Response field |
|--------|----------------|
| 0      | result         |
| 1      | ..2\]=0        |

Backends `VFL_Delete_Partitions`

**Security** — Destructive: permanently deletes partition data. Host process can self-trigger partition deletion.

### 3.73CmdOEMvFlash/GetJobStatus Low

NetFn 0x30 · Cmd 0xa4 · Sub 0x24Priv  · **U** O Alibmaserconfidence: highlive ✓

Poll the status of an asynchronous vFlash job (attach/create/format/initialize) by job ID.

Request

req+8=0x24; req+9..12=jobID_u32

Response

| Offset | Response field |
|----|----|
| 0 | completion_code |
| 1 | percent_complete |
| 2 | ..5\]=jobID_u32 |
| 6 | job_type_encoded (job_type: 1→0x0201, 2→0x21, 3→0x20, 4→0x23, 7→0x12, 8→0x13, other→0xff |
| 8 | partition_id |

Backends `VFL_Get_Job_Status`

### 3.74CmdOEMvFlash/GetPartitionStatus Low

NetFn 0x30 · Cmd 0xa4 · Sub 0x25Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the current operational status of a specific vFlash partition (e.g. idle, formatting, attaching) by partition index.

Request

req+8=0x25; req+9=partition_index

Response

| Offset | Response field                  |
|--------|---------------------------------|
| 0      | completion_code                 |
| 1      | percent_complete_or_100_if_done |
| 2      | ..5\]=jobID_u32                 |
| 6      | job_type_encoded                |
| 8      | partition_id                    |

Backends `VFL_Get_Partition_Status`

### 3.75CmdOEMDellFactory/CreateFactoryHWInventory High

NetFn 0x30 · Cmd 0xa5 · Sub 0x00Priv  · **U** O Alibmaserconfidence: highlive ✓

Spawn an asynchronous thread to generate a factory hardware-inventory XML snapshot. Only available when iDRAC is in Manufacturing Test Mode. Returns CC 0x02 (pending) immediately. If a prior call is still pending, DAT_0018c480 is 2 and the command returns CC 0x02 without re-spawning.

Request

| Offset | Request field                                       |
|--------|-----------------------------------------------------|
| 8      | 0x00 (subcmd                                        |
| 7      | must equal 0x06 (reqlen==6); no further data fields |

Response

CC 0x02 returned in all spawn cases (both freshly-spawned and already-pending set uVar5=2); CC 0x01 if pthread_create fails; CC 0x09 if not in Manufacturing mode; CC 0x05 if MASER disabled/not initialized; CC 0xc7 if reqlen(req+7)!=6. No CC 0x00 path exists for this subcmd.

Backends `threadCreateFactoryHWInventory (pthread), DAT_0018c480 global state, IsInManufacturingTestMode(2), IsMASERInit, IsMASERDisabled`

**Security** — Manufacturing-mode gate (IsInManufacturingTestMode) required. No user-supplied data written to disk.

### 3.76CmdOEMDellFactory/RecreateMASERDeprecated High

NetFn 0x30 · Cmd 0xa5 · Sub 0x01Priv  · **U** O Alibmaserconfidence: highlive ✓

Formerly 'Recreate MASER images'. Now deprecated — returns CC 0xcc immediately with no side effects.

Request

req+8=0x01; req+7 must equal 0x06

Response

CC 0xcc (invalid command)

Backends `none`

### 3.77CmdOEMDellFactory/GetFactoryStatus High

NetFn 0x30 · Cmd 0xa5 · Sub 0x02Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the current factory HW-inventory job status for a given status index. Reads from a global byte array DAT_0018c480 indexed by the caller-supplied index byte. Returns a 4-byte response with the index and status byte.

Request

req+8=0x02 (subcmd); req+7==0x06; req+9=index (0..4, inclusive; \>4 returns CC 0xcc)

Response

resp_len=4; resp\[0\]=index; resp\[1\]=DAT_0018c480\[index\]; resp\[2..3\]=0x00

Backends `DAT_0018c480 global status array (set by threadCreateFactoryHWInventory), IsInManufacturingTestMode`

**Security** — Index is bounds-checked (\>4 returns CC 0xcc). Read-only; no write side-effects.

### 3.78CmdOEMDellFactory/PlatformCacheCleanup Medium

NetFn 0x30 · Cmd 0xa5 · Sub 0x03Priv  · **U** O Alibmaserconfidence: highlive ✓

Trigger a platform-feature-cache cleanup by writing a sentinel string to /flash/data0/features/system-id. A background process monitors this file to perform the cleanup.

Request

req+8=0x03; req+7==0x06; no further data

Response

CC 0x00 on success (file opened and written); CC 0x01 if fopen64 fails

Backends `/flash/data0/features/system-id (write), IsInManufacturingTestMode`

**Security** — Writes fixed string 'features/platform cache cleanup request' to flash. Gated by manufacturing mode.

### 3.79CmdOEMDellFactory/SecureDefaultPassword Critical

NetFn 0x30 · Cmd 0xa5 · Sub 0x04Priv  · **U** O Alibmaserconfidence: highlive ✓

Set or verify the secure default password for the root iDRAC user via CfgDB attribute 'idrac.embedded.1#securedefaultpassword.1#password'. Op=0 sets the password, op=1 verifies it.

Request

| Offset | Request field                                |
|--------|----------------------------------------------|
| 8      | 0x04                                         |
| 9      | op (0=set, 1=verify                          |
| 10     | pwlen (max 20                                |
| 11     | ..11+pwlen=password bytes. When              |
| 7      | !=0x06 only op=0x04 is valid (else CC 0xc7). |

Response

CC 0x00 on success; CC 0x01 on failure (e.g. CfgSetAttribute error, pw too long); return value is the char cVar2 passed to the parent

Backends `CfgSetAttribute / CfgGetAttribute (idrac.embedded.1#securedefaultpassword.1#password), IsInManufacturingTestMode`

**Security** — Writes or compares a plaintext root password into CfgDB while in manufacturing mode. Combined with no IPMI-layer encryption requirement, exposes the factory root credential over unencrypted in-band IPMI.

### 3.80CmdOEMBackupRestore/PopulateBackupCmd High

NetFn 0x30 · Cmd 0xa6 · Sub 0x00Priv  · **U** O Alibmaserconfidence: highlive ✓

Receive one chunk of the Backup&Restore passphrase/parameters structure and write it into a 264-byte global buffer at the caller-specified offset. When the buffer is fully populated it is flushed to /flash/data0/cv/BNR/backup_parameters. Uses lmCheckLcFeature(0x24) gate.

Request

| Offset | Request field                               |
|--------|---------------------------------------------|
| 8      | 0x00 (subcmd                                |
| 9      | ..10=offset_u16_BE (big-endian byte-swapped |
| 11     | chunk_length                                |
| 12     | ..(12+chunk_length-1)=data                  |

Response

| Offset | Response field                           |
|--------|------------------------------------------|
| 0      | result (0=ok, 1=fopen/fwrite error       |
| 1      | 0\. CC 0x6f if BnR feature not licensed. |

Backends `DAT_0018c4b0 global buffer (264 bytes), /flash/data0/cv/BNR/backup_parameters (write), lmCheckLcFeature(0x24)`

**Security** — No bounds check on (offset + chunk_length) against the 0x108-byte buffer — a large offset+length sum overflows adjacent BSS globals. The backup passphrase file on /flash/cv/ is consumed by the AIM backup process.

### 3.81CmdOEMBackupRestore/SendBackupCmd Medium

NetFn 0x30 · Cmd 0xa6 · Sub 0x01Priv  · **U** O Alibmaserconfidence: highlive ✓

Kick off an asynchronous backup by calling aim_exec_systemcmd_DDS with a hardcoded backup command string. Returns pending (CC 2) while the job runs, then returns the job ID read from /flash/data0/oem_ps/idrac_br_job_id. Timeout is 5 seconds.

Request

req+8=0x01; no additional data

Response

resp_len=18; resp\[0..15\]=job_id_string when complete; CC 0x02 while pending (just-spawned or still running); CC 0x03 if a BnR job is already in progress (BnR_JobInProgress()!=0, so no new job is spawned); CC 0x01 on timeout (\>5s) or error. CC 0x6f if BnR feature not licensed (lmCheckLcFeature(0x24)).

Backends `aim_exec_systemcmd_DDS (hardcoded backup command), /flash/data0/oem_ps/idrac_br_job_id, sysinfo(2)`

**Security** — Triggers the AIM backup pipeline which reads passphrase from /flash/data0/cv/BNR/backup_parameters written by subcmd 0x00.

### 3.82CmdOEMBackupRestore/PopulateRestoreCmd High

NetFn 0x30 · Cmd 0xa6 · Sub 0x02Priv  · **U** O Alibmaserconfidence: highlive ✓

Receive one chunk of the restore parameters structure (520 bytes: flags, passphrase, LKM passphrase) and write it into a global buffer at the caller-specified offset. When complete, flushed to /flash/data0/cv/BNR/restore_parameters.

Request

| Offset | Request field |
|----|----|
| 8 | 0x02 |
| 9 | ..10=offset_u16_BE |
| 11 | chunk_length |
| 12 | ..=data. Buffer layout: \[0\]=flags, \[1\]=rsvd, \[2..3\]=passphrase_len_u16, \[4..5\]=LKM_passphrase_len_u16, \[6..7\]=rsvd, \[8..263\]=passphrase(256 bytes), \[264..519\]=LKM_passphrase(256 bytes |

Response

resp_len=2; resp\[0\]=result (0=ok, 1=fopen/fwrite error)

Backends `DAT_0018c5c0 global buffer (520 bytes), /flash/data0/cv/BNR/restore_parameters (write)`

**Security** — Same offset+length overflow risk as subcmd 0x00 (no bounds check on sum against 0x208). Passphrase data written to flash cv/ partition.

### 3.83CmdOEMBackupRestore/SendRestoreCmd Medium

NetFn 0x30 · Cmd 0xa6 · Sub 0x03Priv  · **U** O Alibmaserconfidence: highlive ✓

Kick off an asynchronous restore from the parameters previously written by subcmd 0x02. Mirrors SendBackupCmd. After completion checks if restore-validation flag in the buffer is set; if not, clears the 0x208-byte restore buffer.

Request

req+8=0x03; no additional data

Response

resp_len=18; resp\[0..15\]=job_id_string when complete; CC 0x02 while pending; CC 0x03 if a BnR job already in progress; CC 0x01 on timeout (\>5s). NOTE: this handler has NO lmCheckLcFeature gate, so there is no CC 0x6f path (unlike SendBackupCmd).

Backends `aim_exec_systemcmd_DDS (restore command), /flash/data0/oem_ps/idrac_br_job_id, /flash/data0/cv/BNR/restore_parameters; DAT_0018c5c0 buffer bit2 = restore-validation flag`

**Security** — Restoring from an attacker-crafted parameter file can overwrite iDRAC configuration. Combined with PopulateRestoreCmd, this is a complete configuration-replacement primitive.

### 3.84CmdOEMBackupRestore/QueryJobStatus Low

NetFn 0x30 · Cmd 0xa6 · Sub 0x04Priv  · **U** O Alibmaserconfidence: highlive ✓

Query the lifecycle-controller job status for a given job ID by forking /bin/jcstore and reading its output from /tmp/idrac_br_job_status. Returns parsed fields: status, MsgID, MsgArgsList, PercentComplete.

Request

req+8=0x04; req+9..24=jobID_string (16 bytes, NUL-terminated)

Response

| Offset | Response field             |
|--------|----------------------------|
| 0      | status_code                |
| 1      | ..5\]=MsgID_5bytes         |
| 7      | ..26\]=MsgArgsList_20bytes |
| 27     | PercentComplete            |

Backends `/bin/jcstore (execl, no shell), /tmp/idrac_br_job_status`

**Security** — Job ID string passes directly to execl — no shell injection possible. Forks a child process per call.

### 3.85CmdOEMBackupRestore/QueryJobID Low

NetFn 0x30 · Cmd 0xa6 · Sub 0x05Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the current BnR job ID by reading it from /flash/data0/oem_ps/idrac_br_job_id.

Request

req+8=0x05; no further data

Response

resp_len=18; resp\[0..15\]=job_id_string (up to 256 chars, fgets). Returns bool true on error.

Backends `/flash/data0/oem_ps/idrac_br_job_id (read)`

### 3.86CmdOEMBackupRestore/CancelCmd Medium

NetFn 0x30 · Cmd 0xa6 · Sub 0x06Priv  · **U** O Alibmaserconfidence: highlive ✓

Cancel a running BnR job by calling aim_exec_systemcmd_DDS with the cancel command string (aimexec_fullfw_bnr_cancel_cmd).

Request

req+8=0x06; no further data

Response

resp_len=2; resp\[0\]=0 (always); CC 0x00

Backends `aim_exec_systemcmd_DDS (hardcoded cancel command)`

### 3.87CmdOEMBackupRestore/SetJobStatusCmd High

NetFn 0x30 · Cmd 0xa6 · Sub 0x07Priv  · **U** O Alibmaserconfidence: highlive ✓

Update a lifecycle-controller job's status record via /bin/jcstore by forking a child. Takes job ID, a status byte (mapped to string via (&PTR_DAT_0018a010)\[status_byte\]), a message ID, and a percent-complete value.

Request

req+8=0x07; req+9..24 (req+0x9..0x18)=jobID_string (16 bytes); req+0x19 (req+25)=status_byte; req+0x1a..0x1d=msg_id_u32 (local_168); req+0x1e..0x1f=msg_id_u16 (local_164); req+0x20 (req+32)=percent_complete. (There is no msg_id_null request byte; local_162=0 is set in-code. percent_complete is at req+0x20, not req+33.)

Response

resp_len=2; resp\[0\]=result (0=ok, 1=error, 2=pending); CC 0x00

Backends `/bin/jcstore (execl), PTR_DAT_0018a010 status-string table`

**Security** — status_byte is used as an unchecked index into PTR_DAT_0018a010 pointer array before calling snprintf — out-of-range status_byte causes OOB pointer dereference (potential crash or info leak).

### 3.88CmdOEMBackupRestore/GetAutoFeatureStatus Low

NetFn 0x30 · Cmd 0xa6 · Sub 0x0aPriv  · **U** O Alibmaserconfidence: highlive ✓

Return the current state of three LC auto-features (AutoUpdate, AutoBackup, AutoRestore) from CfgDB.

Request

req+8=0x0a; no further data

Response

| Offset | Response field                             |
|--------|--------------------------------------------|
| 0      | 0x0a (reserved constant, from \*param_3=10 |
| 1      | 0                                          |
| 2      | AutoUpdate(0=off,1=on,0xff=error           |
| 3      | AutoBackup                                 |
| 4      | AutoRestore                                |
| 5      | ..6\]=0. CC 0x00.                          |

Backends `CfgGetAttributeInt (LifecycleController.Embedded.1#LCAttributes.1#AutoUpdate / AutoBackup / AutoRestore)`

### 3.89CmdOEMBackupRestore/GetAutoRestoreVflCap Low

NetFn 0x30 · Cmd 0xa6 · Sub 0x0bPriv  · **U** O Alibmaserconfidence: highlive ✓

Asynchronously query whether vFlash auto-restore is capable. First call triggers GetAutoRestoreCap(); subsequent calls poll DAT_0018c4a1 for completion (state 2=pending, 5=done). Returns capability byte in resp\[0\] when done.

Request

req+8=0x0b; no further data

Response

resp_len=1; resp\[0\]=capability_byte when done (DAT_0018c4a0). Returns 0x02 while pending, 0x00 when complete.

Backends `GetAutoRestoreCap (async), DAT_0018c4a0/DAT_0018c4a1 global state`

### 3.90CmdOEMSupportAssist/NativeOSCollection Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x00Priv  · **U** O Alibmaserconfidence: highlive ✓

Enable or configure native OS-level SupportAssist data collection. Sets the collection mode in CfgDB and writes the mode to shared memory slot 0xe9. reqlen must be 5.

Request

| Offset | Request field |
|----|----|
| 8 | 0x00 (subcmd |
| 7 | must equal 5 |
| 9 | collection_mode (1..3, else error |
| 10 | report_type (FR/PR flag, passed to CfgSetAttributeInt(nativeOSEnableKey, ... |

Response

| Offset | Response field                                 |
|--------|------------------------------------------------|
| 0      | result (0=ok, 6=shm write failed or cfg failed |
| 1      | ..2\]=0; CC 0x00 on success, 0x01 on error     |

Backends `CfgSetAttributeInt (nativeOSEnableKey), Dell_shm_memwrite(0x2a, ..., 0xe9, 1)`

**Security** — collection_mode (req+9, range-checked 1..3) is written to shared memory offset 0xe9. report_type (req+10) is NOT range-checked and is passed straight to CfgSetAttributeInt(nativeOSEnableKey, ...).

### 3.91CmdOEMSupportAssist/NativeOSCollectionStarted Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x01Priv  · **U** O Alibmaserconfidence: highlive ✓

Signal iDRAC that the host OS has started a native SupportAssist collection. Checks the nativeOSEnableKey CfgDB attribute is enabled; if so, writes 0x11 to shm\[0xea\] and 0x00 to shm\[0xeb\]. reqlen must be 3.

Request

req+8=0x01; req+7 must equal 3; no further data

Response

| Offset | Response field                                  |
|--------|-------------------------------------------------|
| 0      | result (0=ok, 1=not enabled, 6=shm write failed |
| 1      | ..2\]=0                                         |

Backends `CfgGetAttributeInt (nativeOSEnableKey), Dell_shm_memwrite(0x2a, 0x11, 0xea, 1), Dell_shm_memwrite(0x2a, 0x00, 0xeb, 1)`

### 3.92CmdOEMSupportAssist/NativeOSCollectionEnded Critical

NetFn 0x30 · Cmd 0xa8 · Sub 0x02Priv  · **U** O Alibmaserconfidence: highlive ✓

Signal iDRAC that native OS collection has ended. Includes file-type and hash/size information for the collected file. Writes file-type, completion status, and optionally a 4-byte (CRC32), 16-byte (MD5) or 32-byte (SHA256) file hash to shared memory.

Request

req+8=0x02; req+7\>=3 (else CC ret 1, resp\[0\]=3). req+9 (bVar2, must be \<4 else 'invalid File Type') selects the shm write path: value 2 -\> write status 0x11 to shm offset 0xeb and finish; value 3 -\> write 0x22 to shm 0xeb and finish; values 0 and 1 -\> file-hash report path with distinct shm offsets (bVar2==0 uses sec-type 0xec / hash 0xed; bVar2==1 uses sec-type 0x10d / hash 0x10e). req+10 (local_4d) is the file/hash type: 0=none, 1=filesize(4B), 2=MD5(16B), 3=SHA256(32B), written to the sec-type shm offset. req+0xb..=hash bytes. reqlen(req+7) must exactly match the file/hash type: none=3, filesize=7, MD5=0x13, SHA256=0x23 (mismatch -\> resp\[0\]=3). NOTE: req+9 and req+10 semantics were previously documented reversed.

Response

| Offset | Response field |
|----|----|
| 0 | result (0=ok, 1=invalid file_type, 3=invalid length, 6=shm write failed |
| 1 | ..2\]=0 |

Backends `Dell_shm_memwrite(0x2a, ..., 0xec/0xed/0xeb/0xea, N)`

**Security** — Up to 32 bytes of caller-supplied hash data is written directly to shared memory (Dell_shm) without cryptographic verification of the hash itself.

### 3.93CmdOEMSupportAssist/ExposeiSMInstaller Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x03Priv  · **U** O Alibmaserconfidence: highlive ✓

Expose the iSM (iDRAC Service Module) installer to the host OS by creating a MASER session, allocating a random 2-byte nonce, arming a 35-minute watchdog timer, and signalling SetGPTaskEvent. reqlen must be 3.

Request

req+8=0x03; req+7 must equal 3; no further data

Response

resp_len=3; resp\[0\]=result. Reachable values in this handler: 0 (SetGPTaskEvent succeeded, function returns CC 0); 1 (DAT_0018c12a==2 'another operation pending', OR SetGPTaskEvent failed); 2 (session created, request pending); 3 (invalid length); 5 (session already exists). The 'tool set session already in progress' branch leaves resp\[0\]=0 and returns CC 1. Values 4 and 8 are NOT produced here (they belong to the Hide handlers). resp\[1..2\]=0

Backends `IPMISessionCtrlGenerateRandomNum, _lx_TimerCreate/_lx_TimerChange/_lx_TimerActivate, SetGPTaskEvent, UpdateLCStatusInShm, DAT_0018bf6b/DAT_0018bf70 session state`

**Security** — The iSM installer partition (vFlash) is exposed to the host OS. Session is identified by a 2-byte random nonce, giving only 65536 possible session IDs.

### 3.94CmdOEMSupportAssist/HideiSMInstaller Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x04Priv  · **U** O Alibmaserconfidence: highlive ✓

Hide the iSM installer partition from the host OS by signalling SetGPTaskEvent to tear down the session created by subcmd 0x03. reqlen must be 3.

Request

req+8=0x04; req+7 must equal 3; no further data

Response

| Offset | Response field |
|----|----|
| 0 | result (0=ok, 1=SetGPTaskEvent failed, 2=pending, 4=another op pending, 8=session does not exist |
| 1 | ..2\]=0 |

Backends `SetGPTaskEvent, DAT_0018bf6b session state`

### 3.95CmdOEMSupportAssist/GetStatus Low

NetFn 0x30 · Cmd 0xa8 · Sub 0x05Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the last SupportAssist command status (DAT_0018c191), or 2 (pending) if an operation is currently in progress (DAT_0018c190 != 0). reqlen must be 3.

Request

req+8=0x05; req+7 must equal 3; no further data

Response

| Offset | Response field                                 |
|--------|------------------------------------------------|
| 0      | status (DAT_0018c191 if idle, 2 if in-progress |
| 1      | ..2\]=0                                        |

Backends `DAT_0018c191, DAT_0018c190 global state`

### 3.96CmdOEMSupportAssist/CollectData Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x06Priv  · **U** O Alibmaserconfidence: highlive ✓

Initiate a SupportAssist data collection by creating a MASER session and signalling SetGPTaskEvent with the collect-data task handle. Equivalent flow to ExposeiSMInstaller but for the diagnostic collection task.

Request

req+8=0x06; req+7 must equal 3; no further data

Response

| Offset | Response field                   |
|--------|----------------------------------|
| 0      | result (0=ok, 1=error, 2=pending |
| 1      | ..2\]=0                          |

Backends `IPMISessionCtrlGenerateRandomNum, _lx_TimerCreate, SetGPTaskEvent, DAT_0018b879/DAT_0018c194/DAT_0018c195 state`

### 3.97CmdOEMSupportAssist/GetCollectDataStatus Low

NetFn 0x30 · Cmd 0xa8 · Sub 0x07Priv  · **U** O Alibmaserconfidence: highlive ✓

Return the current SupportAssist data-collection status (DAT_0018c193), or 2 (pending) if a collection is running (DAT_0018c194 != 0). reqlen must be 3.

Request

req+8=0x07; req+7 must equal 3; no further data

Response

| Offset | Response field                    |
|--------|-----------------------------------|
| 0      | status (DAT_0018c193 or 2=pending |
| 1      | ..2\]=0                           |

Backends `DAT_0018c193, DAT_0018c194 global state`

### 3.98CmdOEMSupportAssist/HideCollectDataResult Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x08Priv  · **U** O Alibmaserconfidence: highlive ✓

Hide the vFlash dynamic partition containing SupportAssist-collected data by tearing down the collect-data MASER session via SetGPTaskEvent. reqlen must be 3.

Request

req+8=0x08; req+7 must equal 3; no further data

Response

| Offset | Response field |
|----|----|
| 0 | result (0=ok, 1=error, 2=pending, 4=another op pending, 8=partition not exposed or session missing |
| 1 | ..2\]=0 |

Backends `SetGPTaskEvent, DAT_0018bf6b/DAT_0018bf18/DAT_0018c192/DAT_0018c193 state`

### 3.99CmdOEMSupportAssist/CollectDataCancel Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x09Priv  · **U** O Alibmaserconfidence: highlive ✓

Cancel a running SupportAssist data collection by setting the cancel flag (DAT_0018c195). Only works if a collection is actively running (DAT_0018c194 == 1). reqlen must be 3.

Request

req+8=0x09; req+7 must equal 3; no further data

Response

| Offset | Response field |
|----|----|
| 0 | result: 2 = cancel signaled (only when DAT_0018c194==1, i.e. a collection is actively running; function returns CC 0), 1 = not running (returns CC 1), 3 = bad length (returns CC 1 |
| 1 | ..2\]=0 |

Backends `DAT_0018c194, DAT_0018c195, DAT_0018c193 global state`

### 3.100CmdOEMSupportAssist/JobInProgressPendingSignal Medium

NetFn 0x30 · Cmd 0xa8 · Sub 0x10Priv  · **U** O Alibmaserconfidence: highlive ✓

Check whether a SupportAssist job is currently in progress via SA_PreReqCheck. Returns 0 (none), 1 (failed precheck), or 2 (job in progress). Used for polling before initiating a new operation. reqlen must be 3.

Request

req+8=0x10; req+7 must equal 3; no further data

Response

| Offset | Response field |
|----|----|
| 0 | status (0=no job, 1=precheck failed, 2=job in progress, 3=bad length |
| 1 | ..2\]=0 |

Backends `SA_PreReqCheck`

### 3.101CmdOEMMASER_PM/CmdOEMGetPMUpdateFlag Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x10Priv  · · · **A**libmaserconfidence: lowlive ✓

Read the Platform Manager (PM) update flag status from cfgdb or global state.

Request

| Offset | Request field |
|----|----|
| 8 | 0x10. Must come from system interface or CMC channel (channel nibble of |
| 0 | 7). Remaining fields: undetermined (CmdOEMGetPMUpdateFlag.c not read). |

Response

undetermined.

Backends `undetermined (PM update flag cfgdb key).`

**Security** — Read-only PM flag. Admin+inBand or CMC channel.

### 3.102CmdOEMMASER_PM/CmdOEMClrPMUpdateFlag Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x11Priv  · · · **A**libmaserconfidence: lowlive ✓

Clear the Platform Manager update flag.

Request

req+8=0x11. Must come from system interface or CMC channel. Remaining fields: undetermined (CmdOEMClrPMUpdateFlag.c not read).

Response

undetermined.

Backends `PM update flag cfgdb key.`

**Security** — Write to PM update flag. Admin+inBand or CMC.

### 3.103CmdOEMMASER_PM/CmdOEMGetPMStatus Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x12Priv  · · · **A**libmaserconfidence: highlive ✓

Return Platform Manager status. Opens /mnt/pm/pm/pm_info (64 bytes), reads PM version and info. Also queries system info via SMILGetObjByKey('91\|\|System.Embedded.1') for a system type byte at offset 0x7BD. Checks /flash/data0/oem_ps/pm_disabled and /flash/data0/oem_ps/pm_unpop sentinels.

Request

req+8=0x12. Must come from system interface or CMC channel. No additional validated data fields visible.

Response

| Offset | Response field                                        |
|--------|-------------------------------------------------------|
| 0      | 0x12 (subcmd echo).                                   |
| 1      | status (0=ok, 1=file read error, 2=file open failed). |
| 2      | PM version byte (from pm_info\[2\]).                  |
| 3      | ..4\]: LE uint16 from pm_info\[0..1\].                |
| 5      | 0 if pm_disabled file exists (PM disabled), else 1.   |
| 6      | 0 if pm_unpop exists (unpopulated), else 1.           |
| 7      | system type byte (from SMIL object at 0x7BD).         |
| 8      | ..28\]: zeroed/undetermined.                          |

Backends `SMILGetObjByKey('91||System.Embedded.1'); open64/read('/mnt/pm/pm/pm_info'); stat64('/flash/data0/oem_ps/pm_disabled'), stat64('/flash/data0/oem_ps/pm_unpop')`

**Security** — Discloses PM version, system type, and PM state. Admin+inBand or CMC.

### 3.104CmdOEMMASER_PM/CmdOEMGetPMDefaultBrand Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x13Priv  · · · **A**libmaserconfidence: lowlive ✓

Read the default Platform Manager brand identifier.

Request

req+8=0x13. Must come from system interface or CMC channel. Remaining fields: undetermined.

Response

undetermined.

Backends `undetermined.`

**Security** — Read-only. Admin+inBand or CMC.

### 3.105CmdOEMMASER_PM/CmdOEMGetPMRebrand Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x14Priv  · · · **A**libmaserconfidence: lowlive ✓

Read the Platform Manager rebrand status.

Request

req+8=0x14. Must come from system interface or CMC channel. Remaining fields: undetermined.

Response

undetermined.

Backends `undetermined.`

**Security** — Read-only. Admin+inBand or CMC.

### 3.106CmdOEMMASER_PM/CmdOEMSetPMInstall Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x15Priv  · · · **A**libmaserconfidence: lowlive ✓

Trigger Platform Manager installation.

Request

req+8=0x15. Must come from system interface or CMC channel. Remaining fields: undetermined.

Response

undetermined.

Backends `undetermined.`

**Security** — Triggers PM install. Admin+inBand or CMC.

### 3.107CmdOEMMASER_PM/GetBIOSRTDFlag Low

NetFn 0x30 · Cmd 0xa9 · Sub 0x17Priv  · · · **A**libmaserconfidence: highlive ✓

Read the BIOS Runtime Data (RTD) requested flag from cfgdb key LifecycleController.Embedded.1#LCAttributes.1#BIOSRTDRequested.

Request

req+8=0x17. No additional required data bytes validated. Does NOT require system interface — accessible from any channel at Admin priv.

Response

| Offset | Response field                                              |
|--------|-------------------------------------------------------------|
| 0      | 0x17 (subcmd echo).                                         |
| 1      | CfgGetAttributeInt return code (0=success, non-zero=error). |
| 2      | BIOSRTDRequested value (0=not requested, 1=requested).      |
| 3      | ..6\]: 0x00.                                                |

Backends `cfgdb key: LifecycleController.Embedded.1#LCAttributes.1#BIOSRTDRequested (CfgGetAttributeInt)`

**Security** — Read-only cfgdb flag. Not gated by inBand check — reachable via LAN at Admin priv. Low risk.

### 3.108CmdOEMMASER_PM/ClearBIOSRTDFlag Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x18Priv  · · · **A**libmaserconfidence: highlive ✓

Clear (set to 0) the BIOS RTD requested flag in cfgdb, then reads it back to confirm. Not gated by system interface check.

Request

req+8=0x18. No additional validated data bytes. Does NOT require system interface.

Response

| Offset | Response field                             |
|--------|--------------------------------------------|
| 0      | 0x18 (subcmd echo).                        |
| 1      | CfgSetAttributeInt return code.            |
| 2      | value read back after clear (should be 0). |
| 3      | ..5\]: 0x00.                               |

Backends `cfgdb key: LifecycleController.Embedded.1#LCAttributes.1#BIOSRTDRequested (CfgSetAttributeInt+CfgGetAttributeInt)`

**Security** — Writes to cfgdb RTD flag. Not inBand-gated — reachable via LAN at Admin priv.

### 3.109CmdOEMMASER_PM/SetBIOSRTDFlag Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x19Priv  · · · **A**libmaserconfidence: highlive ✓

Set the BIOS RTD requested flag to a caller-supplied value (0-2) in cfgdb. Value \> 2 is rejected. Does not require system interface.

Request

req+8=0x19. req+9: 1B desired RTD flag value (0-2; values \> 2 → CC=0x01). Does NOT require system interface.

Response

| Offset | Response field                                 |
|--------|------------------------------------------------|
| 0      | 0x19 (subcmd echo).                            |
| 1      | value written (from cfgdb read-back or req+9). |
| 2      | ..5\]: 0x00.                                   |

Backends `cfgdb key: LifecycleController.Embedded.1#LCAttributes.1#BIOSRTDRequested (CfgSetAttributeInt+CfgGetAttributeInt)`

**Security** — Writes to cfgdb RTD requested flag. Not inBand-gated — reachable via LAN at Admin priv. Controlling BIOS RTD request may influence boot behavior.

### 3.110CmdOEMMASER_PM/CmdOEMCmplntUpdValidate Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x1aPriv  · · · **A**libmaserconfidence: lowlive ✓

Compellent (storage controller) firmware update: validate the DUP update package.

Request

req+8=0x1a. Not gated by system interface check. Remaining fields: undetermined (CmdOEMCmplntUpdValidate.c not read).

Response

undetermined.

Backends `undetermined (DUP validation logic).`

**Security** — Firmware validation step. Not inBand-gated — LAN-reachable at Admin priv.

### 3.111CmdOEMMASER_PM/CmdOEMCmplntUpdValidateStatus Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x1bPriv  · · · **A**libmaserconfidence: lowlive ✓

Compellent firmware update: query validation status.

Request

req+8=0x1b. Not gated by inBand check. Remaining fields: undetermined.

Response

undetermined.

Backends `undetermined.`

**Security** — Read-only status. Not inBand-gated.

### 3.112CmdOEMMASER_PM/CmdOEMCmplntUpdUpdate Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x1cPriv  · · · **A**libmaserconfidence: lowlive ✓

Compellent firmware update: apply the validated DUP update package.

Request

req+8=0x1c. Not gated by inBand check. Remaining fields: undetermined (CmdOEMCmplntUpdUpdate.c not read).

Response

undetermined.

Backends `undetermined (DUP apply logic).`

**Security** — Firmware update write. Not inBand-gated — reachable via LAN at Admin priv. HIGH risk if DUP validation is bypassed.

### 3.113CmdOEMMASER_PM/CmdOEMCmplntUpdQueryStatus Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x1dPriv  · · · **A**libmaserconfidence: lowlive ✓

Compellent firmware update: query overall update status.

Request

req+8=0x1d. Not gated by inBand check. Remaining fields: undetermined.

Response

undetermined.

Backends `undetermined.`

**Security** — Read-only status. Not inBand-gated.

### 3.114CmdOEMMASER_PM/CmdOemGetLCStatus Medium

NetFn 0x30 · Cmd 0xa9 · Sub 0x1ePriv  · · · **A**libmaserconfidence: highlive ✓

Return Lifecycle Controller status by calling CmdOemGetLCStatus() (wraps MAPI_GetLCStatus). Not gated by system interface check.

Request

req+8=0x1e. Not gated by system interface check. No additional data fields validated.

Response

| Offset | Response field                           |
|--------|------------------------------------------|
| 0      | 0x1e (subcmd echo).                      |
| 1      | LC status byte from CmdOemGetLCStatus(). |
| 2      | ..3\]: 0x00.                             |

Backends `CmdOemGetLCStatus() → MAPI_GetLCStatus()`

**Security** — Read-only LC status. Not inBand-gated — LAN-reachable at Admin priv.

### 3.115CmdOEMMASER_PM/CmdOEMGetBIOSPasswordInfo Critical

NetFn 0x30 · Cmd 0xa9 · Sub 0x2fPriv  · · · **A**libmaserconfidence: lowlive ✓

Return information about BIOS password configuration (length, encoding type, etc.).

Request

req+8=0x2f. Not gated by inBand check. Remaining fields: undetermined (CmdOEMGetBIOSPasswordInfo.c not read).

Response

undetermined.

Backends `undetermined (BIOS password state/cfgdb).`

**Security** — HIGH: discloses BIOS password configuration info (presence, encoding). Not inBand-gated — reachable via LAN at Admin priv. Combined with the SetBIOSPassword subcmd of 0xa1, enables a full BIOS credential attack chain.

### 3.116CmdOEMMASERLCLAccess/CmdOEMLCLMASERUpdateInventoryOrXML Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x01Priv  · **U** O Alibmaserconfidence: lowlive ✓

Update MASER/LC inventory records. Routes to CmdOEMLCLMASERUpdateInventoryRecords if data\[3\]==0x02, otherwise routes to CmdOEMLCLMASERUpdateXMLRecords (called with no args in this path — likely uses global state).

Request

| Offset | Request field |
|----|----|
| 8 | 0x01 (subcmd). |
| 11 | data\[3\]): 0x02 routes to UpdateInventoryRecords; other values route to UpdateXMLRecords. Remaining fields for each: undetermined. |

Response

undetermined.

Backends `LC inventory database; XML record store.`

**Security** — Write path to inventory records. User+inBand. Inventory injection potential if input is not sanitized.

### 3.117CmdOEMMASERLCLAccess/CmdOEMLCLMASERLogEntry High

NetFn 0x30 · Cmd 0xaa · Sub 0x03Priv  · **U** O Alibmaserconfidence: lowlive ✓

Write a Lifecycle Controller log entry.

Request

req+8=0x03. Remaining fields: undetermined (CmdOEMLCLMASERLogEntry.c not read).

Response

undetermined.

Backends `LC log database.`

**Security** — Log write. User+inBand. Log injection risk if entry content is not sanitized.

### 3.118CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryCurrentRecords Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x0bPriv  · **U** O Alibmaserconfidence: lowlive ✓

Query current Lifecycle Controller inventory records.

Request

req+8=0x0b. Remaining fields: undetermined (CmdOEMLCLMASERQueryCurrentRecords.c not read).

Response

undetermined.

Backends `LC inventory records.`

**Security** — Read-only LC data. User+inBand.

### 3.119CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryRecordHistory Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x0cPriv  · **U** O Alibmaserconfidence: lowlive ✓

Query the historical record set for a given LC entry.

Request

req+8=0x0c. Remaining fields: undetermined (CmdOEMLCLMASERQueryRecordHistory.c not read).

Response

undetermined.

Backends `LC record history store.`

**Security** — Read-only LC history. User+inBand.

### 3.120CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryEventRecord Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x0dPriv  · **U** O Alibmaserconfidence: lowlive ✓

Query a specific event record from the Lifecycle Controller log.

Request

req+8=0x0d. Remaining fields: undetermined (CmdOEMLCLMASERQueryEventRecord.c not read).

Response

undetermined.

Backends `LC event log.`

**Security** — Read-only event query. User+inBand.

### 3.121CmdOEMMASERLCLAccess/CmdOEMLCLMASERQueryDependency Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x0ePriv  · **U** O Alibmaserconfidence: lowlive ✓

Query dependency information for a given Lifecycle Controller record.

Request

req+8=0x0e. Remaining fields: undetermined (CmdOEMLCLMASERQueryDependency.c not read).

Response

undetermined.

Backends `LC dependency records.`

**Security** — Read-only. User+inBand.

### 3.122CmdOEMMASERLCLAccess/CmdOEMLCLMASERHistory Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x0fPriv  · **U** O Alibmaserconfidence: medlive ✓

Return LC job/change history. Gated by lmCheckLcFeature(0x22) — if that LC feature is not licensed/enabled, returns CC=0x6F with resp_data_len=0.

Request

req+8=0x0f. Feature check: lmCheckLcFeature(0x22) must return 0x01. Remaining fields: undetermined (CmdOEMLCLMASERHistory.c not read).

Response

CC: 0x6F (feature unavailable) with resp_data_len=0 if feature check fails. Success: undetermined.

Backends `lmCheckLcFeature(0x22) (LC feature license check); LC history store.`

**Security** — Feature-gated read-only history. User+inBand.

### 3.123CmdOEMMASERLCLAccess/CmdOEMLCLMASERHWInventory Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x10Priv  · **U** O Alibmaserconfidence: lowlive ✓

Return hardware inventory from the Lifecycle Controller. Gated by lmCheckLcFeature(0x22).

Request

req+8=0x10. Feature check: lmCheckLcFeature(0x22) must return 0x01. Remaining fields: undetermined (CmdOEMLCLMASERHWInventory.c not read).

Response

CC: 0x6F if feature unavailable. Success: undetermined.

Backends `lmCheckLcFeature(0x22); LC hardware inventory data.`

**Security** — Discloses hardware inventory. Feature-gated. User+inBand.

### 3.124CmdOEMMASERLCLAccess/CmdOEMLCLMASERFactoryHWInventoryGet High

NetFn 0x30 · Cmd 0xaa · Sub 0x11Priv  · **U** O Alibmaserconfidence: lowlive ✓

Return factory hardware inventory. Gated by lmCheckLcFeature(0x22). May return factory-provisioned hardware fingerprint data.

Request

req+8=0x11. Feature check: lmCheckLcFeature(0x22) must return 0x01. Remaining fields: undetermined (CmdOEMLCLMASERFactoryHWInventoryGet.c not read, ~28KB).

Response

CC: 0x6F if feature unavailable. Success: undetermined.

Backends `lmCheckLcFeature(0x22); factory HW inventory store.`

**Security** — Discloses factory hardware fingerprints. Feature-gated. User+inBand.

### 3.125CmdOEMMASERLCLAccess/CmdOEMLCLMASERGetLCLStatus Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x15Priv  · **U** O Alibmaserconfidence: medlive ✓

Return the status of the last LCL (Lifecycle Controller Local) request (G_u8Status_LastLCLReq global). Always succeeds with CC=0x00.

Request

req+8=0x15. No additional data bytes required (no length check visible). Minimum length: 1.

Response

CC: 0x00. resp_data length=2. resp_data\[0..1\]: 0x0000 (LE uint16 zero — status byte is logged but its placement in the response buffer is ambiguous from the decompile; resp_data\[0\] may be the status and resp_data\[1\] reserved, or both zeroed).

Backends `DAT_0018c122 (G_u8Status_LastLCLReq global in-memory)`

**Security** — Read-only last LCL request status. User+inBand.

### 3.126CmdOEMMASERLCLAccess/CmdOEMLCLGetUSCVer Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x16Priv  · **U** O Alibmaserconfidence: lowlive ✓

Return the USC (Unified Server Configurator) version from the Lifecycle Controller.

Request

req+8=0x16. Remaining fields: undetermined (CmdOEMLCLGetUSCVer.c not read).

Response

undetermined.

Backends `USC version data (cfgdb or SMIL).`

**Security** — Read-only version info. Useful for fingerprinting LC version. User+inBand.

### 3.127CmdOEMMASERLCLAccess/CmdOEMLCLCopyMUTData Medium

NetFn 0x30 · Cmd 0xaa · Sub 0x17Priv  · **U** O Alibmaserconfidence: lowlive ✓

Copy Manufacturing/Update/Test (MUT) data within the LC subsystem.

Request

req+8=0x17. Remaining fields: undetermined (CmdOEMLCLCopyMUTData.c not read).

Response

undetermined.

Backends `MUT data store in LC.`

**Security** — Data copy operation. User+inBand. Manufacturing-test context.

### 3.128CmdOEMGetMASERInfo Medium

NetFn 0x30 · Cmd 0xabPriv  · **U** O Alibmaserconfidence: medlive ✓

Return detailed info about a specific MASER media device. Type 0 = internal eMMC (reads /var/tmp/maser0.info). Type 1 = SD card (queries aim_config for ameastatus_bool_amea_sd_present; reads SD card info via VFL_List_SD_Card_Info; reads /var/tmp/maser1.info). Response includes media type, capacity fields, and a flags byte indicating write-protection and VFlash-in-use status.

Request

| Offset | Request field |
|----|----|
| 7 | 1B data length, must equal 0x03 |
| 8 | 1B MASER device type (0=internal eMMC, 1=SD card; other values → CC=0xCB |
| 9 | ..10: 2B undetermined (not visibly used in leaf). Minimum data length: 3. |

Response

| Offset | Response field |
|----|----|
| 0 | MASER type echo (0 or 1). |
| 1 | media vendor/type byte (0x00=MMC, 0x01=SD-full, 0x02=SD-partial — derived from maser\*.info local_e4 field). |
| 2 | ..3\]: capacity fields from maser\*.info local_a8. |
| 4 | ..5\]: undetermined fields. |
| 6 | flags byte (bit1=VFlash in use, bit0=SD card write-protected, for type 1). |
| 7 | ..9\]: undetermined. |

Backends `files: /var/tmp/maser0.info, /var/tmp/maser1.info (internal helper FUN_0010e1d0 reads these); aim_config key: ameastatus_bool_amea_sd_present; VFL_List_SD_Card_Info(); VFlash_in_use()`

**Security** — Discloses storage device presence, capacity, and VFlash status at User privilege over LAN. SD write-protection state and VFlash-in-use exposed. Useful for attacker reconnaissance.

### 3.129CmdOEMGetMASERType Medium

NetFn 0x30 · Cmd 0xadPriv  · **U** O Alibmaserconfidence: highlive ✓

Return the MASER (Lifecycle Controller storage) hardware type. In this build the type is hardcoded to 0x0000 (two bytes), indicating no differentiated type information is exposed.

Request

| Offset | Request field                                        |
|--------|------------------------------------------------------|
| 7      | 1B data length, must equal 0x02                      |
| 8      | ..9: 2B reserved (not read). Minimum data length: 2. |

Response

| Offset | Response field |
|----|----|
| 0 | 1B): 0x00 (MASER type, hardcoded). |
| 1 | 1B): 0x00 (sub-type, hardcoded). resp_data length = 3 (includes one trailing zero byte written as undefined2 zero pair). Two bytes of type info are always 0. |

Backends `None (hardcoded response; no cfgdb, file, or hardware access).`

**Security** — Returns a constant zero response. Low risk. LAN-reachable at User privilege.

### 3.130CmdOEMGetMASERAccessState Medium

NetFn 0x30 · Cmd 0xaePriv  · · · **A**libmaserconfidence: highlive ✓

Read the current Lifecycle Controller (LC / MASER) enabled/disabled state from cfgdb. Returns the inverted sense of LifecycleControllerState: cfgdb=0 (disabled) → resp byte=1; cfgdb=1 (enabled) → resp byte=0; other values returned raw.

Request

| Offset | Request field |
|----|----|
| 7 | 1B data length, must equal 0x02 |
| 8 | ..9: 2B reserved (values not checked beyond length). Minimum data length: 2. |

Response

| Offset | Response field |
|----|----|
| 0 | 1B): LC access state (0=LC enabled, 1=LC disabled, raw cfgdb value for other states). |
| 1 | ..2\] (2B): zeroed reserved. resp_data length = 3 on success. |

Backends `cfgdb key: LifecycleController.Embedded.1#LCAttributes.1#LifecycleControllerState (read via CfgGetAttributeInt)`

**Security** — Read-only state disclosure. Reachable over LAN at Admin privilege. Value inversion mapping (0→1, 1→0) may confuse callers but is not exploitable standalone.

### 3.131CmdOEMSetMASERAccessState Medium

NetFn 0x30 · Cmd 0xafPriv  · **U** O Alibmaserconfidence: highlive ✓

Enable or disable the Lifecycle Controller. On disable: terminates any active MASER session, stops the watchdog timer, clears session state, and logs UEFI0021 event. On enable from recovery state (cfgdb was 2): touches /tmp/force_create_begin, runs run_verify_maser_as_root('force_mas001...') to sync the mas001 partition, clears recovery flag, and logs UEFI0020 event. Persists the new state to cfgdb LifecycleControllerState (1=enabled, 0=disabled).

Request

| Offset | Request field |
|----|----|
| 7 | 1B data length, must equal 0x03 |
| 8 | 1B desired state (0=enable, non-zero=disable |
| 9 | ..10: 2B not used by visible code (reserved). Minimum data length: 3. |

Response

CC (return value): 0x00 success, 0x01 cfgdb read or write error, 0xC7 invalid data length. resp_data\[0..1\] (2B): zeroed. resp_data length = 2.

Backends `cfgdb key: LifecycleController.Embedded.1#LCAttributes.1#LifecycleControllerState (read+write via CfgGetAttributeInt/CfgSetAttributeInt); files: /tmp/force_create_begin, /tmp/force_create_end; function run_verify_maser_as_root; ClearMASERInRecovery(); ClearUEFIOOBRecovery(); DCLCLWRAPSubmitEvent (LC event log); UpdateLCStatusInShm; _lx_TimerDeactivate (watchdog)`

**Security** — CRITICAL: priv=User (low privilege) can disable the Lifecycle Controller, terminating any active MASER session and blocking all LC-gated operations. On enable from recovery, executes run_verify_maser_as_root with a fixed string path pattern. LAN-reachable at User privilege — any authenticated user can disable LC on the BMC.

## 4. vFlash / SD Storage (0)

vFlash SD-card partition lifecycle: create/format/attach/detach/delete, boot-partition selection.

*No commands in this generation.*

## 5. DCMI (45)

DCMI (Data Center Manageability Interface) power/thermal/asset-tag/sensor commands and the SCBMC proxy.

### 5.1DellDCSSCBMCWrapper/0x11 Medium

NetFn 0x30 · Cmd 0x11Priv  · · · **A**libdcmiconfidence: medlive ✓

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x11 to the Sub-Controller BMC (SCBMC) via D-Bus (dbusScbmc_IpmiHandler). Only active when Dell_get_idrac_type() == 2, indicating a modular/blade chassis platform with a physical SCBMC (e.g. PowerEdge MX IO module or chassis management controller). The full IPMI message including all data bytes is forwarded verbatim to the SCBMC over a ZMQ IPC channel; the SCBMC response is returned verbatim. Specific command semantics are implemented in the SCBMC firmware and are not derivable from static analysis of libdcmi.so alone.

Request

req+7: u8DataLen (1 B) = number of data bytes following; no minimum enforced by this proxy — all data forwarded to SCBMC. req+8..req+8+DataLen-1: opaque payload forwarded to SCBMC (structure and minimum length determined by SCBMC implementation, undetermined from this code).

Response

Completion code (1 B): 0x00 on success; 0xd5 if Dell_get_idrac_type() != 2 (command not supported on non-modular platform); 0xc3 if dbusScbmc_IpmiHandler returns -2 (SCBMC response timeout); 0xd3 if D-Bus call fails (SCBMC communication error); 0xff if SCBMC returned no response buffer; SCBMC CC (any of 0xc0-0xc2, 0xc4-0xcf, 0xd0-0xd2, 0xd4, 0xd6, 0xdf) passed through verbatim. Response body (0..N bytes): SCBMC response payload, length set from SCBMC-returned length (memcpy'd verbatim into resp_data). Structure undetermined.

Backends `Dell_get_idrac_type() (platform type check, likely /flash/data0 or cfgdb); dbusScbmc_IpmiHandler (D-Bus → libscbmc.so.9 → ZMQ IPC at ipc:///var/run/scbmcipc/N → SCBMC firmware service); SCBMC physical hardware (Sub-Controller BMC on blade/modular chassis).`

**Security** — Admin-gated. Only reachable on modular chassis (iDRAC type 2). Acts as a full Admin-privilege IPMI bridge to a physically separate BMC on the chassis fabric; any Admin iDRAC session can send arbitrary netfn 0x30 cmd 0x11 commands to the SCBMC, potentially exploiting SCBMC-side vulnerabilities without direct SCBMC network access. The SCBMC service is only reachable via this bridge from external IPMI callers. No input validation performed before forwarding.

### 5.2DellDCSSCBMCWrapper/0x12 Medium

NetFn 0x30 · Cmd 0x12Priv  · · · **A**libdcmiconfidence: medgated

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x12 to the Sub-Controller BMC (SCBMC) via D-Bus. Identical gating and proxy mechanism to cmd=0x11: requires iDRAC type == 2 (modular platform), forwards full IPMI message to SCBMC, returns SCBMC response verbatim. Per-command semantics determined by SCBMC firmware; undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular platform; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs (0xc0-0xc2, 0xc4-0xcf, 0xd0-0xd2, 0xd4, 0xd6, 0xdf) passed through. Response body: SCBMC payload, length and structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC ipc:///var/run/scbmcipc/N → SCBMC hardware.`

**Security** — Admin-gated SCBMC bridge. Same attack surface as cmd=0x11: no validation before forwarding to SCBMC. Potential for Admin-to-SCBMC pivot.

### 5.3DellDCSSCBMCWrapper/0x13 Medium

NetFn 0x30 · Cmd 0x13Priv  · · · **A**libdcmiconfidence: medlive ✓

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x13 to the Sub-Controller BMC (SCBMC) via D-Bus. Same gating and proxy logic as cmd=0x11/0x12. Per-command semantics undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs passed through. Response body: SCBMC payload, structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC → SCBMC hardware.`

**Security** — Admin-gated SCBMC bridge. No input validation before SCBMC forwarding.

### 5.4DellDCSSCBMCWrapper/0x14 Medium

NetFn 0x30 · Cmd 0x14Priv  · · · **A**libdcmiconfidence: medgated

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x14 to the Sub-Controller BMC (SCBMC) via D-Bus. Same gating and proxy logic as cmd=0x11. Per-command semantics undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs passed through. Response body: SCBMC payload, structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC → SCBMC hardware.`

**Security** — Admin-gated SCBMC bridge. No input validation before SCBMC forwarding.

### 5.5DellDCSSCBMCWrapper/0x15 Medium

NetFn 0x30 · Cmd 0x15Priv  · · · **A**libdcmiconfidence: medlive ✓

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x15 to the Sub-Controller BMC (SCBMC) via D-Bus. Same gating and proxy logic as cmd=0x11. Per-command semantics undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs passed through. Response body: SCBMC payload, structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC → SCBMC hardware.`

**Security** — Admin-gated SCBMC bridge. No input validation before SCBMC forwarding.

### 5.6DellDCSSCBMCWrapper/0x16 Medium

NetFn 0x30 · Cmd 0x16Priv  · · · **A**libdcmiconfidence: medgated

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x16 to the Sub-Controller BMC (SCBMC) via D-Bus. Same gating and proxy logic as cmd=0x11. Per-command semantics undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs passed through. Response body: SCBMC payload, structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC → SCBMC hardware.`

**Security** — Admin-gated SCBMC bridge. No input validation before SCBMC forwarding.

### 5.7DellDCSSCBMCWrapper/0x17 Medium

NetFn 0x30 · Cmd 0x17Priv  · · · **A**libdcmiconfidence: medlive ✓

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x17 to the Sub-Controller BMC (SCBMC) via D-Bus. Same gating and proxy logic as cmd=0x11. Per-command semantics undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs passed through. Response body: SCBMC payload, structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC → SCBMC hardware.`

**Security** — Admin-gated SCBMC bridge. No input validation before SCBMC forwarding.

### 5.8DellDCSSCBMCWrapper/0x19 Critical

NetFn 0x30 · Cmd 0x19Priv  · · · **A**libdcmiconfidence: medlive ✓

Transparent proxy of Dell OEM IPMI command netfn=0x30 cmd=0x19 to the Sub-Controller BMC (SCBMC) via D-Bus. Same gating and proxy logic as cmd=0x11. Note: cmd=0x18 is absent from the registration set (gap between 0x17 and 0x19), suggesting 0x18 is either reserved or handled elsewhere. Per-command semantics undetermined from libdcmi.so static analysis.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B); no minimum enforced by proxy. |
| 8 | ..end: opaque payload forwarded to SCBMC. Structure and minimum length undetermined. |

Response

Completion code (1 B): 0x00 success; 0xd5 non-modular; 0xc3 SCBMC timeout; 0xd3 D-Bus failure; 0xff no response buffer; SCBMC CCs passed through. Response body: SCBMC payload, structure undetermined.

Backends `Dell_get_idrac_type(); dbusScbmc_IpmiHandler → libscbmc.so.9 → ZMQ IPC at ipc:///var/run/scbmcipc/ → SCBMC hardware (IO module or chassis management controller on Dell PowerEdge MX / modular chassis).`

**Security** — Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. Gap at cmd=0x18 is notable. All 8 proxy commands (0x11-0x17, 0x19) share identical handler code and present the same attack surface: an Admin iDRAC credential grants full netfn=0x30 command access to the physically separate SCBMC, which may have independent vulnerabilities not exposed on the iDRAC network interface.

### 5.9DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x1aPriv  · · · **A**libdcmiconfidence: high for wrapper logic and error codes; low for per-command request/response payload layout (SCBMC service not decompiled)gated

Blade-chassis SCBMC (Sub-Controller / Chassis Management Controller) IPMI proxy, cmd slot 0x1a. Gates on Dell_get_idrac_type()==2 (blade server iDRAC only; returns CC=0xd5 on tower/rack). Forwards the raw IPMI request verbatim to the dbusScbmc_IpmiHandler D-Bus method on the scbmc service, copies the response payload and completion code back to the IPMI caller. The specific operation performed is determined by the SCBMC D-Bus service for this cmd byte; the libdcmi layer performs no independent parsing of request data.

Request

No bytes are parsed by this handler; the entire IPMI request buffer (param_1 pointer, which includes netfn, cmd, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0x1a is defined by the SCBMC service (undetermined from static analysis of this library). Min request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if Dell_get_idrac_type()!=2 (not a blade iDRAC). CC=0xc3 if D-Bus call times out. CC=0xd3 if D-Bus call fails (non-timeout error). CC=0xff if SCBMC returns null/empty response. On success: CC=byte from scbmc response (local_49); resp_data\[0..N-1\]=memcpy of SCBMC response payload; \*param_2 (resp_len)=local_40 (SCBMC-reported payload length). SCBMC completion codes 0xc0-0xcf (except 0xc3) and 0xd0-0xdf (except 0xd3/0xd5) are passed through to the caller. Response payload layout for cmd 0x1a determined by SCBMC service (undetermined).

Backends `dbusScbmc_IpmiHandler D-Bus method (service/interface undetermined from this code; connects to scbmc subsystem); Dell_get_idrac_type() — reads iDRAC hardware platform type`

**Security** — Admin-privilege required. Blind proxy: all request bytes from an Admin IPMI session are forwarded verbatim to the SCBMC D-Bus service without any validation in this layer. Security enforcement and input validation is entirely inside the SCBMC service. Only available on blade-chassis iDRACs (type==2); functionally dead on rack/tower. D-Bus timeout and failure paths expose CC=0xc3/0xd3 error distinguishability to callers, which can fingerprint SCBMC availability. Actual attack surface depends on SCBMC service implementation (not decompiled here).

### 5.10DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x1bPriv  · · · **A**libdcmiconfidence: high for wrapper logic; low for SCBMC per-command payloadlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x1b. Identical wrapper logic to cmd 0x1a: gates on Dell_get_idrac_type()==2, forwards raw request to dbusScbmc_IpmiHandler, copies response back. Specific operation for 0x1b determined by the SCBMC D-Bus service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0x1b defined by SCBMC service (undetermined). Min request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data = SCBMC payload; resp_len = SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Same proxy-without-validation concern as 0x1a. Blade-only. SCBMC service is the sole enforcement point for this cmd slot.

### 5.11DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x1dPriv  · · · **A**libdcmiconfidence: high for wrapper; low for per-command semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x1d (cmd 0x1c is absent from this library's registration table, indicating it is handled elsewhere or unimplemented). Same wrapper: blade-type gate plus D-Bus forwarding to dbusScbmc_IpmiHandler. Specific operation for 0x1d determined by SCBMC.

Request

No bytes parsed here; raw request forwarded. Layout for 0x1d undetermined. Min length: undetermined.

Response

CC=0xd5 (not blade), CC=0xc3 (timeout), CC=0xd3 (D-Bus error), CC=0xff (empty response), or SCBMC-provided CC+payload. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method; Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy to SCBMC. Blade-only. Cmd 0x1c gap suggests 0x1d is a distinct SCBMC function not adjacent to 0x1c in the protocol.

### 5.12DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x1ePriv  · · · **A**libdcmiconfidence: high for wrapper; low for per-command semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x1e. Same wrapper logic: blade-type gate, D-Bus forwarding. Operation determined by SCBMC service.

Request

No bytes parsed here; raw request forwarded. Layout undetermined. Min length: undetermined.

Response

CC=0xd5/0xc3/0xd3/0xff on error paths; SCBMC CC+payload on success. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method; Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only.

### 5.13DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x1fPriv  · · · **A**libdcmiconfidence: high for wrapper; low for per-command semanticsgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x1f. Same wrapper logic: blade-type gate, D-Bus forwarding. Operation determined by SCBMC service.

Request

No bytes parsed here; raw request forwarded. Layout undetermined. Min length: undetermined.

Response

CC=0xd5/0xc3/0xd3/0xff on error paths; SCBMC CC+payload on success. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method; Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only.

### 5.14DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x20Priv  · · · **A**libdcmiconfidence: high for wrapper; low for per-command semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x20. Same wrapper logic: blade-type gate, D-Bus forwarding. Operation determined by SCBMC service.

Request

No bytes parsed here; raw request forwarded. Layout undetermined. Min length: undetermined.

Response

CC=0xd5/0xc3/0xd3/0xff on error paths; SCBMC CC+payload on success. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method; Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only.

### 5.15DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x22Priv  · · · **A**libdcmiconfidence: high for wrapper; low for per-command semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x22 (cmd 0x21 absent from this library's table). Same wrapper: blade-type gate, D-Bus forwarding to dbusScbmc_IpmiHandler. Operation determined by SCBMC service.

Request

No bytes parsed here; raw request forwarded. Layout undetermined. Min length: undetermined.

Response

CC=0xd5/0xc3/0xd3/0xff on error paths; SCBMC CC+payload on success. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method; Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. Cmd 0x21 gap mirrors the 0x1c gap; both suggest the SCBMC protocol has reserved or separately-handled slots in this range.

### 5.16DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x23Priv  · · · **A**libdcmiconfidence: high for wrapper; low for per-command semanticsgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x23. Same wrapper: blade-type gate, D-Bus forwarding. Operation determined by SCBMC service. This is the last command in the contiguous block registered to this handler (0x1a-0x23 with gaps at 0x1c and 0x21).

Request

No bytes parsed here; raw request forwarded. Layout undetermined. Min length: undetermined.

Response

CC=0xd5/0xc3/0xd3/0xff on error paths; SCBMC CC+payload on success. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method; Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy to SCBMC service. All 8 commands in this block (0x1a, 0x1b, 0x1d-0x20, 0x22-0x23) share the same absence of input validation in libdcmi; an Admin IPMI session can send arbitrary data bytes that the SCBMC service receives without any libdcmi-level sanitisation. Blade-only (CC=0xd5 on rack/tower prevents exploitation on non-blade targets).

### 5.17DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x25Priv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC (Sub-Controller / Chassis Management Controller) IPMI proxy, cmd slot 0x25 (cmd 0x24 is absent from this library's registration table, indicating a gap or separate handler). Gates on Dell_get_idrac_type()==2 (blade-server iDRAC only; returns CC=0xd5 on rack/tower). Forwards the raw IPMI request verbatim to the dbusScbmc_IpmiHandler D-Bus method on the scbmc service, then copies the response payload and completion code back to the IPMI caller. The specific operation for cmd 0x25 is determined entirely by the SCBMC D-Bus service; libdcmi performs no independent parsing of request data bytes.

Request

No bytes are parsed by this handler; the entire IPMI request buffer (param_1, including netfn, cmd, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0x25 is defined by the SCBMC service (undetermined from static analysis of this library). Minimum request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if Dell_get_idrac_type()!=2 (not a blade iDRAC). CC=0xc3 if D-Bus call times out (dbusScbmc_IpmiHandler returns -2). CC=0xd3 if D-Bus call fails with other error (\<0). CC=0xff if SCBMC returns null or zero-length response. On success: CC=byte from SCBMC response (local_49, passed through); \*param_2 (resp_len) = local_40 (SCBMC-reported payload byte count); param_3 = memcpy of SCBMC payload. SCBMC completion codes in range 0xc0-0xcf (except 0xc3) and 0xd0-0xdf (except 0xd3 and 0xd5) are passed through unmodified to the caller. Per-command response payload layout is determined by the SCBMC service (undetermined).

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem service; interface/object path not visible in this code); Dell_get_idrac_type() (reads iDRAC hardware platform type from libmodular)`

**Security** — Admin-privilege required. Blind proxy: all request bytes from an Admin IPMI session are forwarded verbatim to the SCBMC D-Bus service without any validation in this layer. Security enforcement and input validation are entirely the responsibility of the SCBMC service (not decompiled here). Blade-chassis-only (CC=0xd5 on rack/tower prevents exploitation on non-blade targets). D-Bus timeout (CC=0xc3) vs general failure (CC=0xd3) are distinguishable by callers, enabling fingerprinting of SCBMC availability. The 0x24 gap before this command suggests this is a distinct SCBMC functional block.

### 5.18DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x26Priv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x26. Identical wrapper logic to cmd 0x25: blade-type gate (Dell_get_idrac_type()==2), then forwards raw request to dbusScbmc_IpmiHandler and copies response back. The specific operation for 0x26 is determined by the SCBMC D-Bus service. Cmd slots 0x27, 0x28, 0x29 are absent from this library's table, leaving a 3-slot gap before the next registered block at 0x2a.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0x26 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC-reported length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy, no libdcmi-level input validation. Blade-only. Gap at 0x27-0x29 indicates 0x26 ends one SCBMC sub-block and 0x2a starts another.

### 5.19DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x2aPriv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x2a (first of a contiguous block 0x2a-0x2f registered to this handler; slots 0x27-0x29 are absent, creating a 3-slot gap after 0x26). Same wrapper logic: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x2a defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. Start of the 0x2a-0x2f block, which together with 0x25-0x26 and the earlier 0x1a-0x23 block suggests the SCBMC protocol allocates netfn 0x30 commands in distinct functional groups separated by reserved/external gaps.

### 5.20DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x2bPriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x2b (second command in the contiguous 0x2a-0x2f block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x2b defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation; SCBMC service is sole enforcement point.

### 5.21DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x2cPriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x2c (third command in the 0x2a-0x2f block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x2c defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation.

### 5.22DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x2dPriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x2d (fourth command in the 0x2a-0x2f block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x2d defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation.

### 5.23DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x2ePriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x2e (fifth command in the 0x2a-0x2f block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x2e defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation.

### 5.24DellDCSSCBMCWrapper High

NetFn 0x30 · Cmd 0x2fPriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x2f (last of the 0x2a-0x2f block and last command in this batch). Same wrapper: blade-type gate (Dell_get_idrac_type()==2), verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service. Across all registered libdcmi SCBMC slots (0x1a-0x23, 0x25-0x26, 0x2a-0x2f), libdcmi provides no independent request validation; the SCBMC D-Bus service is the sole enforcement and parsing layer for all these command bytes.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x2f defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy, no libdcmi-level input validation across any SCBMC cmd slot. Blade-only (CC=0xd5 on rack/tower). An Admin IPMI session on a blade iDRAC can send arbitrary payloads to all 18 registered SCBMC command slots (0x1a-0x2f with gaps); the SCBMC D-Bus service receives these bytes without any sanitisation by this library. If the SCBMC service has vulnerabilities (e.g. buffer overflows, command injection), they are directly reachable from an authenticated LAN session. The timeout/failure CC distinction (0xc3 vs 0xd3) allows callers to map SCBMC service availability.

### 5.25DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x44Priv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC (Sub-Controller / Chassis Management Controller) IPMI proxy, cmd slot 0x44. There is a gap of 20 cmd slots (0x30-0x43) between this and the previous registered block ending at 0x2f, and a gap of 3 slots (0x45-0x47) between this and the next registered command at 0x48; 0x44 is therefore isolated on both sides, suggesting it is a distinct SCBMC functional operation. Same wrapper logic as all prior batches: gates on Dell_get_idrac_type()==2 (blade-server iDRAC only; returns CC=0xd5 on rack/tower), then forwards the raw IPMI request verbatim to the dbusScbmc_IpmiHandler D-Bus method on the SCBMC service and copies the response payload and completion code back to the IPMI caller. The specific operation performed is determined entirely by the SCBMC D-Bus service; libdcmi performs no independent parsing.

Request

No bytes are parsed by this handler; the entire IPMI request buffer (including netfn, cmd, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0x44 is defined by the SCBMC service (undetermined from static analysis of this library). Minimum request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if Dell_get_idrac_type()!=2 (not a blade iDRAC). CC=0xc3 if D-Bus call times out (dbusScbmc_IpmiHandler returns -2). CC=0xd3 if D-Bus call fails with other error (\<0). CC=0xff if SCBMC returns null or zero-length response. On success: CC=byte from SCBMC response (local_49); resp_data\[0..N-1\]=memcpy of SCBMC response payload; resp_len=local_40 (SCBMC-reported payload byte count). SCBMC completion codes 0xc0-0xcf (except 0xc3) and 0xd0-0xdf (except 0xd3 and 0xd5) are passed through unmodified. Per-command response payload layout determined by SCBMC service (undetermined).

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem service; interface/object path not visible in this code); Dell_get_idrac_type() (reads iDRAC hardware platform type from libmodular)`

**Security** — Admin-privilege required. Blind proxy: all request bytes from an Admin IPMI session are forwarded verbatim to the SCBMC D-Bus service without any validation in this layer. Security enforcement and input validation are entirely the responsibility of the SCBMC service. Blade-chassis-only (CC=0xd5 on rack/tower prevents exploitation on non-blade targets). D-Bus timeout (CC=0xc3) vs general failure (CC=0xd3) are distinguishable by callers, enabling fingerprinting of SCBMC availability. The double-sided isolation of cmd 0x44 (gaps at 0x30-0x43 and 0x45-0x47) suggests a distinct SCBMC subsystem function that may have different semantics from the 0x2a-0x2f block.

### 5.26DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x48Priv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x48. Isolated between gaps 0x45-0x47 (before) and 0x49 (which begins a contiguous block); however 0x48 is only one slot before the 0x49-0x4d block so the gap is minimal. Same wrapper logic: blade-type gate (Dell_get_idrac_type()==2), then forwards raw IPMI request verbatim to dbusScbmc_IpmiHandler and copies response back. The specific operation for 0x48 is determined by the SCBMC D-Bus service; libdcmi performs no parsing.

Request

No bytes are parsed by this handler; the entire IPMI request buffer is forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0x48 is defined by the SCBMC service (undetermined). Minimum request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC-reported length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy, no libdcmi-level input validation. Blade-only. The 3-slot gap at 0x45-0x47 before this command suggests 0x48 is the first command of a new SCBMC functional group (0x48-0x4d), with 0x48 possibly serving as a group header or initiator operation within the SCBMC protocol.

### 5.27DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x49Priv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x49 (first of the contiguous 0x49-0x4d block; 0x48 may be a related but separate entry point as it is immediately adjacent). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x49 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation; SCBMC service is sole enforcement point.

### 5.28DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x4aPriv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x4a (second command in the contiguous 0x49-0x4d block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x4a defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation.

### 5.29DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x4bPriv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x4b (third command in the contiguous 0x49-0x4d block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x4b defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation.

### 5.30DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x4cPriv  · · · **A**libdcmiconfidence: highlive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0x4c (fourth command in the contiguous 0x49-0x4d block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x4c defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level input validation.

### 5.31DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0x4dPriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0x4d (last of the contiguous 0x49-0x4d block). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. Specific operation determined by SCBMC service. After this block there is a gap of 145 cmd slots (0x4e-0xde) before the final registered SCBMC command at 0xdf.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0x4d defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_len=SCBMC length; resp_data=SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. The very large gap (0x4e-0xde) after this block and before the outlier 0xdf entry suggests the SCBMC protocol allocates netfn 0x30 in distinct non-contiguous clusters; 0xdf may be a special-purpose or legacy SCBMC command separate from the main functional blocks.

### 5.32DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xc5Priv  · · · **A**libdcmiconfidence: high for wrapper logic and error codes; low for per-command request/response payload layout (SCBMC service not decompiled)gated

Blade-chassis SCBMC (Sub-Controller / Chassis Management Controller) IPMI proxy, cmd slot 0xc5. First of a contiguous block 0xc5-0xc8 registered to this handler; preceded by a large gap from 0x2f (the last previously documented block ends there). Gates on Dell_get_idrac_type()==2 (blade-server iDRAC only; returns CC=0xd5 on rack/tower). Forwards the raw IPMI request verbatim to the dbusScbmc_IpmiHandler D-Bus method on the scbmc service, then copies the response payload and completion code back to the IPMI caller. The specific operation is determined entirely by the SCBMC D-Bus service; libdcmi performs no independent parsing of request data bytes for this command.

Request

No bytes are parsed by this handler; the entire IPMI request buffer (param_1, which includes netfn, cmd, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0xc5 is defined by the SCBMC service (undetermined from static analysis of this library). Minimum request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if Dell_get_idrac_type()!=2 (not a blade iDRAC). CC=0xc3 if D-Bus call times out (dbusScbmc_IpmiHandler returns -2). CC=0xd3 if D-Bus call fails with other error (return \<0). CC=0xff if SCBMC returns null or zero-length response. On success: CC=byte from SCBMC response (local_49, passed through); \*param_2 (resp_len)=local_40 (SCBMC-reported payload byte count); param_3=memcpy of SCBMC payload. SCBMC completion codes in range 0xc0-0xcf (except 0xc3) and 0xd0-0xdf (except 0xd3 and 0xd5) are passed through unmodified to the caller. Per-command response payload layout is determined by the SCBMC service (undetermined).

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem service; interface/object path not visible in this code); Dell_get_idrac_type() (reads iDRAC hardware platform type from libmodular)`

**Security** — Admin-privilege required. Blind proxy: all request bytes from an Admin IPMI session are forwarded verbatim to the SCBMC D-Bus service without any validation in this layer. Security enforcement and input validation are entirely the responsibility of the SCBMC service (not decompiled here). Blade-chassis-only (CC=0xd5 on rack/tower prevents exploitation on non-blade targets). D-Bus timeout (CC=0xc3) vs general failure (CC=0xd3) are distinguishable by callers, enabling fingerprinting of SCBMC availability.

### 5.33DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xc6Priv  · · · **A**libdcmiconfidence: high for wrapper logic; low for per-command SCBMC payload semanticsgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0xc6 (second in the contiguous 0xc5-0xc8 block). Identical wrapper logic to 0xc5: blade-type gate (Dell_get_idrac_type()==2), verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. The specific operation for 0xc6 is determined by the SCBMC D-Bus service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0xc6 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload (memcpy); resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy, no libdcmi-level input validation. Blade-only. SCBMC service is sole enforcement point.

### 5.34DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xc7Priv  · · · **A**libdcmiconfidence: high for wrapper logic; low for per-command SCBMC payload semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0xc7 (third in the 0xc5-0xc8 block). Same wrapper: blade-type gate, verbatim D-Bus forwarding. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0xc7 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload; resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level validation.

### 5.35DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xc8Priv  · · · **A**libdcmiconfidence: high for wrapper logic; low for per-command SCBMC payload semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0xc8 (last of the contiguous 0xc5-0xc8 block; slots 0xc9-0xd6 are absent from this library's registration table, indicating a large gap before the next SCBMC block at 0xd7). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0xc8 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload; resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level validation. The 14-slot gap (0xc9-0xd6) after this block suggests the 0xc5-0xc8 group is a distinct SCBMC functional sub-block.

### 5.36DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xd7Priv  · · · **A**libdcmiconfidence: high for wrapper logic; low for per-command SCBMC payload semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0xd7 (first of a pair 0xd7-0xd8; separated from the prior block 0xc5-0xc8 by a 14-slot gap at 0xc9-0xd6). Same wrapper: blade-type gate (Dell_get_idrac_type()==2), verbatim D-Bus forwarding to dbusScbmc_IpmiHandler. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0xd7 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload; resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level validation. Large gap before 0xd7 indicates this pair is a distinct SCBMC functional block.

### 5.37DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xd8Priv  · · · **A**libdcmiconfidence: high for wrapper logic; low for per-command SCBMC payload semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0xd8 (second and last of the 0xd7-0xd8 pair; slot 0xd9 is absent, creating a 1-slot gap before 0xda). Same wrapper: blade-type gate, verbatim D-Bus forwarding. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0xd8 defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload; resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level validation. Gap at 0xd9 separates this pair from the following isolated 0xda slot.

### 5.38DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xdaPriv  · · · **A**libdcmiconfidence: high for wrapper logic; low for per-command SCBMC payload semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0xda (isolated single slot; 0xd9 is absent before it and 0xdb is absent after it, placing 0xda between the 0xd7-0xd8 pair and the 0xdc User-priv slot). Same wrapper: blade-type gate, verbatim D-Bus forwarding to dbusScbmc_IpmiHandler. Specific operation determined by SCBMC service.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0xda defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload; resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — Admin-privilege. Blind proxy. Blade-only. No libdcmi-level validation. Isolated placement with gaps on both sides suggests this command is a distinct, standalone SCBMC function.

### 5.39DellDCSSCBMCWrapper Critical

NetFn 0x30 · Cmd 0xdcPriv  · **U** O Alibdcmiconfidence: high for wrapper logic and privilege level; low for per-command SCBMC payload semanticslive ✓

Blade-chassis SCBMC IPMI proxy, cmd slot 0xdc (isolated; 0xdb absent before it). Notable: this is the only command in this batch registered at User privilege instead of Admin. Same DellDCSSCBMCWrapper handler: blade-type gate (Dell_get_idrac_type()==2), verbatim D-Bus forwarding to dbusScbmc_IpmiHandler, response passthrough. The specific SCBMC operation behind 0xdc is determined by the SCBMC service; whatever it exposes here is accessible to any authenticated IPMI User-level session on a blade iDRAC.

Request

No bytes parsed by this handler; entire IPMI request forwarded verbatim. Request data layout for cmd 0xdc defined by SCBMC service (undetermined). Minimum request data length: undetermined.

Response

CC=0xd5 if not blade iDRAC. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response; resp_data=SCBMC payload; resp_len=SCBMC-reported length. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem); Dell_get_idrac_type()`

**Security** — User-privilege — significantly lower bar than the Admin-only sibling commands. Any authenticated IPMI User session on a blade iDRAC can reach whatever SCBMC functionality is behind 0xdc. Blind proxy: request bytes forwarded verbatim with no libdcmi-level validation; SCBMC service is the sole enforcement layer. If the SCBMC's 0xdc handler has an exploitable flaw (buffer overflow, info leak, state corruption), it is reachable from a User-level IPMI credential, not only Admin. Blade-only gate (CC=0xd5 on rack/tower) limits exposure to blade deployments.

### 5.40DellDCSSCBMCWrapper Medium

NetFn 0x30 · Cmd 0xdfPriv  · · · **A**libdcmiconfidence: highgated

Blade-chassis SCBMC IPMI proxy, cmd slot 0xdf. This is an outlier command separated from the previous registered SCBMC block (0x48-0x4d) by 145 unregistered cmd slots (0x4e-0xde); it is the last and most distant SCBMC command registered by libdcmi in netfn 0x30. Same wrapper logic: gates on Dell_get_idrac_type()==2 (blade iDRAC only; CC=0xd5 otherwise), then forwards the entire raw IPMI request verbatim to dbusScbmc_IpmiHandler via D-Bus and proxies the response back. The specific operation for 0xdf is determined by the SCBMC D-Bus service; libdcmi performs no independent parsing. The numerical distance (0xdf=223) and isolation suggest this may be a special-purpose SCBMC command (e.g. diagnostics, reset, or a catch-all handler) distinct from the functional clusters at lower cmd offsets.

Request

No bytes are parsed by this handler; the entire IPMI request buffer (including netfn, cmd, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Request data layout for cmd 0xdf is defined by the SCBMC service (undetermined from static analysis of this library). Minimum request data length: undetermined.

Response

Byte 0: completion code. CC=0xd5 if Dell_get_idrac_type()!=2. CC=0xc3 on D-Bus timeout. CC=0xd3 on D-Bus failure. CC=0xff on null/empty SCBMC response. On success: CC from SCBMC response (local_49); resp_len=local_40; resp_data=memcpy of SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Per-command payload layout undetermined. Note: the SCBMC completion-code pass-through table in DellDCSSCBMCWrapper includes 0xdf itself as a transparent pass-through (case 0xdf in the switch on local_49); this means if the SCBMC returns CC=0xdf, it is not reinterpreted as an error — it is forwarded to the caller as-is.

Backends `dbusScbmc_IpmiHandler D-Bus method (scbmc subsystem service; interface/object path not visible in this code); Dell_get_idrac_type() (reads iDRAC hardware platform type)`

**Security** — Admin-privilege required. Blind proxy: request bytes forwarded verbatim to SCBMC D-Bus service without any libdcmi-level validation. Blade-chassis-only (CC=0xd5 on rack/tower). The cmd byte 0xdf coincides with the IPMI Group Extension Command byte used in some OEM contexts; on blade chassis this slot is claimed by the SCBMC proxy. Its isolation (largest gap in the entire libdcmi SCBMC registration table) and the fact that the DellDCSSCBMCWrapper completion-code switch explicitly lists 0xdf as a transparent pass-through are notable: a SCBMC service bug at this cmd could return CC=0xdf which is passed back uninterpreted. The full attack surface across all 25 libdcmi SCBMC cmd slots (0x1a-0x23 with gaps, 0x25-0x26, 0x2a-0x2f, 0x44, 0x48-0x4d, 0xdf) depends entirely on the SCBMC D-Bus service implementation; none of these slots have any input sanitisation in the IPMI proxy layer.

### 5.41CmdDcmiGetPowerReading Medium

NetFn 0x32 · Cmd 0x01Priv  · · · **A**libdcmiconfidence: highlive ✓

Dead/stub registration of CmdDcmiGetPowerReading for Dell OEM netfn 0x32 / cmd 0x01. The handler immediately detects that the incoming netfn matches NetFnLUNCoupleConstruct(0x32,0,0) (the OEM group) and unconditionally returns completion code 0xd5 (command not supported in present state / invalid command for given network function). No request data is read, no response data is written. The actual DCMI power reading implementation is only active when registered under DCMI netfn 0x2c / cmd 0x02 (see separate CMDDOC). This OEM registration appears to be a stub or a forward-compatibility placeholder.

Request

No request data bytes are read or validated. Minimum length: 0 (all paths return 0xd5 before any data access for this netfn).

Response

Byte 0 (completion code): always 0xd5 (command not supported / invalid for this network function). No response data bytes written. resp_len (\*param_2) left at 0.

Backends `None (no backend calls are made; the function exits immediately upon detecting netfn 0x32)`

**Security** — Admin privilege required but request is always rejected (CC=0xd5). No exploitable surface. Confirmed dead path via static analysis: all callers reaching via netfn 0x32 exit before any processing.

### 5.42DellDCSSCBMCWrapper Medium

NetFn 0x32 · Cmd 0x02Priv  · · · **A**libdcmiconfidence: highlive ✓

Dell OEM netfn 0x32 SCBMC proxy, cmd 0x02. Same DellDCSSCBMCWrapper handler as cmd 0x73: gates on Dell_get_idrac_type()==2 (blade-only), then forwards the raw IPMI request verbatim to dbusScbmc_IpmiHandler and returns the SCBMC response. No local subcommand dispatch. Cmd 0x02 in netfn 0x32 sits adjacent to CmdDcmiGetPowerReading (cmd 0x01) but is an SCBMC proxy, not a DCMI command.

Request

No bytes are parsed by this handler; the full IPMI request buffer is forwarded verbatim to dbusScbmc_IpmiHandler. Data layout for cmd 0x02 is defined by the SCBMC service (undetermined). Minimum request data length: undetermined.

Response

Byte 0 (completion code): 0xd5 if not blade iDRAC; 0xc3 on D-Bus timeout; 0xd3 on D-Bus failure; 0xff on null/empty SCBMC response. On success: CC from SCBMC; resp_len = SCBMC-reported payload length; resp_data = SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (SCBMC subsystem); Dell_get_idrac_type()`

**Security** — Admin privilege required. Blade-only gate. Blind proxy with no libdcmi-level input validation. Proximity to DCMI cmd 0x01 may cause confusion in tooling that assumes cmd 0x02 in netfn 0x32 is a DCMI Set Power Reading variant; it is not — it is an opaque SCBMC forward.

### 5.43DellDCSSCBMCWrapper Medium

NetFn 0x32 · Cmd 0x03Priv  · · · **A**libdcmiconfidence: highlive ✓

Dell OEM netfn 0x32 SCBMC proxy, cmd 0x03. Same DellDCSSCBMCWrapper handler: blade-only gate (Dell_get_idrac_type()==2), verbatim forwarding to dbusScbmc_IpmiHandler, SCBMC response passthrough. No local subcommand dispatch. Cmd 0x03 in netfn 0x32 sits adjacent to CmdDcmiGetPowerLimit (DCMI 0x2c/0x03) but is an SCBMC proxy, not a DCMI command.

Request

No bytes are parsed by this handler; the full IPMI request buffer is forwarded verbatim to dbusScbmc_IpmiHandler. Data layout for cmd 0x03 is defined by the SCBMC service (undetermined). Minimum request data length: undetermined.

Response

Byte 0 (completion code): 0xd5 if not blade iDRAC; 0xc3 on D-Bus timeout; 0xd3 on D-Bus failure; 0xff on null/empty SCBMC response. On success: CC from SCBMC; resp_len = SCBMC-reported payload length; resp_data = SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (SCBMC subsystem); Dell_get_idrac_type()`

**Security** — Admin privilege required. Blade-only gate. Blind proxy; no libdcmi-level input validation. Like cmd 0x02, the proximity to DCMI power-limit cmd 0x03 may cause confusion in tooling; it is an opaque SCBMC forward. SCBMC service is the sole enforcement point.

### 5.44DellDCSSCBMCWrapper Medium

NetFn 0x32 · Cmd 0x73Priv  · · · **A**libdcmiconfidence: highlive ✓

Dell OEM netfn 0x32 SCBMC proxy, cmd 0x73. Gates on Dell_get_idrac_type()==2 (blade-chassis iDRAC only; returns CC=0xd5 on rack/tower). Forwards the entire IPMI request verbatim to the dbusScbmc_IpmiHandler D-Bus method on the SCBMC service and copies the response payload and completion code back to the IPMI caller. No local subcommand dispatch; the SCBMC D-Bus service determines the operation. Cmd 0x73 is outside the dense 0x01-0x0x range of OEM DCMI commands and within the block of higher-numbered Dell SCBMC extensions registered in this netfn.

Request

No bytes are parsed by this handler; the full IPMI request buffer (including netfn 0x32, cmd 0x73, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Data layout for cmd 0x73 is defined by the SCBMC service (undetermined from static analysis of this library). Minimum request data length: undetermined.

Response

Byte 0 (completion code): 0xd5 if Dell_get_idrac_type()!=2 (not a blade iDRAC); 0xc3 if D-Bus call times out (dbusScbmc_IpmiHandler returns -2); 0xd3 if D-Bus call fails with any other negative return; 0xff if SCBMC returns null pointer or zero-length payload. On success: CC = byte returned by SCBMC service (local_49); resp_len (\*param_2) = SCBMC-reported payload byte count; resp_data (param_3) = memcpy of SCBMC payload. SCBMC CCs in ranges 0xc0-0xcf (excluding 0xc3) and 0xd0-0xdf (excluding 0xd3 and 0xd5) are passed through unmodified. Payload layout is determined by the SCBMC service (undetermined).

Backends `dbusScbmc_IpmiHandler D-Bus method (SCBMC chassis management subsystem; interface/object path not visible in this library); Dell_get_idrac_type() (reads iDRAC platform type)`

**Security** — Admin privilege required. Blade-only gate (CC=0xd5 on rack/tower). Blind proxy: all request bytes from an Admin IPMI session are forwarded to SCBMC without any validation in this layer; SCBMC is the sole enforcement and parsing point. D-Bus timeout (CC=0xc3) vs general failure (CC=0xd3) are distinguishable by callers, enabling SCBMC availability fingerprinting. Cmd 0x73 is well outside the dense low-numbered block and may correspond to an infrequently audited SCBMC subsystem.

### 5.45DellDCSSCBMCWrapper Medium

NetFn 0x36 · Cmd 0xf5Priv  · · · **A**libdcmiconfidence: highlive ✓

Dell OEM netfn 0x36 SCBMC proxy, cmd 0xf5. Same DellDCSSCBMCWrapper handler: gates on Dell_get_idrac_type()==2 (blade-only), forwards the entire IPMI request verbatim to dbusScbmc_IpmiHandler, returns SCBMC response. No local subcommand dispatch. Netfn 0x36 is a distinct Dell OEM group separate from the 0x32 group used for most DCMI/SCBMC commands in this library; cmd 0xf5 is at the high end of that group's range.

Request

No bytes are parsed by this handler; the full IPMI request buffer (netfn 0x36, cmd 0xf5, and all data bytes) is forwarded verbatim to dbusScbmc_IpmiHandler. Data layout for this command is defined by the SCBMC service (undetermined). Minimum request data length: undetermined.

Response

Byte 0 (completion code): 0xd5 if not blade iDRAC; 0xc3 on D-Bus timeout; 0xd3 on D-Bus failure; 0xff on null/empty SCBMC response. On success: CC from SCBMC; resp_len = SCBMC-reported payload length; resp_data = SCBMC payload. SCBMC CCs 0xc0-0xcf (exc. 0xc3) and 0xd0-0xdf (exc. 0xd3/0xd5) passed through. Payload layout undetermined.

Backends `dbusScbmc_IpmiHandler D-Bus method (SCBMC subsystem); Dell_get_idrac_type()`

**Security** — Admin privilege required. Blade-only gate. Blind proxy; no libdcmi-level input validation. Netfn 0x36 / cmd 0xf5 is an unusual combination (high cmd byte in a separate OEM group) and likely exposes a rarely-exercised SCBMC subsystem path. SCBMC is the sole validation point.

## 6. Node Manager & Power / Thermal (84)

Intel Node Manager passthrough, power capping/budget, PSU, fan/thermal, airflow, fresh-air.

### 6.1DellNMCommand/0x40 Medium

NetFn 0x2e · Cmd 0x40 · Sub 0x40Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0x40 pass-through gate. After the global AllowIpmiI2cCommands and generation pre-check, the handler performs no further validation (no license check, no data parsing) and returns 0x00. Request bytes are forwarded to the PCH Node Manager over I2C; the specific NM semantic (Intel NM spec cmd 0x40) is opaque to this iDRAC code.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload (IANA prefix + NM-specific fields) forwarded to PCH without inspection. Min length: 0 data bytes for the gate; NM spec may impose more. |

Response

byte 0: completion code. 0x00=pass (global gate cleared); 0xd4=NM commands blocked (AllowIpmiI2cCommands cfgdb key=0 on a non-gen-3 system). No additional response bytes written by this handler; actual NM response comes from PCH if forwarded.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; PCH Node Manager over I2C`

**Security** — No license gate and no payload validation beyond the global AllowIpmiI2cCommands check. Any Admin-privileged caller on a gen-3 or AllowI2C-enabled system can push arbitrary bytes to the PCH Node Manager over I2C through this command. Potential for NM policy manipulation if PCH NM firmware has exploitable commands.

### 6.2DellNMCommand/0x41 Medium

NetFn 0x2e · Cmd 0x41 · Sub 0x41Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0x41 pass-through gate. Identical to 0x40: passes after the global AllowIpmiI2cCommands/generation gate with no further license check or payload inspection. Request forwarded to PCH Node Manager over I2C.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload forwarded to PCH without inspection. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=pass; 0xd4=NM commands blocked (AllowIpmiI2cCommands=0 on non-gen-3). No additional response bytes from this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; PCH Node Manager over I2C`

**Security** — Same as 0x40: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control.

### 6.3DellNMCommand/0x42 Medium

NetFn 0x2e · Cmd 0x42 · Sub 0x42Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0x42 pass-through gate. Identical to 0x40/0x41: passes after the global AllowIpmiI2cCommands/generation gate with no further license check or payload inspection. Request forwarded to PCH Node Manager over I2C.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload forwarded to PCH without inspection. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=pass; 0xd4=NM commands blocked (AllowIpmiI2cCommands=0 on non-gen-3). No additional response bytes from this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; PCH Node Manager over I2C`

**Security** — Same as 0x40: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control.

### 6.4DellNMCommand/0x43 Medium

NetFn 0x2e · Cmd 0x43 · Sub 0x43Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0x43 pass-through gate. Identical to 0x40/0x41/0x42: passes after the global AllowIpmiI2cCommands/generation gate with no further license check or payload inspection. Request forwarded to PCH Node Manager over I2C.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload forwarded to PCH without inspection. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=pass; 0xd4=NM commands blocked (AllowIpmiI2cCommands=0 on non-gen-3). No additional response bytes from this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; PCH Node Manager over I2C`

**Security** — Same as 0x40: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control.

### 6.5DellNMCommand/0x44 Medium

NetFn 0x2e · Cmd 0x44 · Sub 0x44Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get Alert Thresholds' pass-through gate. DellNMCommand is registered as the IPMI handler for this NetFn/cmd and dispatches internally on the cmd byte (param_1\[6\]). For cmd 0x44, the code falls through the cmd-byte dispatch tree to a single global gate check: if AllowIpmiI2cCommands cfgdb key is 0 AND the system generation is not 3, the command is blocked with CC 0xD4. Otherwise the function returns CC 0x00 (success) without reading any request data bytes or writing any response data. In a real deployment the iDRAC framework would relay the request to the Intel NM processor over the SMBus/I2C channel after this gate returns success; in this virtual build the relay does not occur and callers receive an empty success response.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked by this handler). |
| 8 | +: data bytes are NOT parsed; the handler reads only param_1\[6\] (cmd=0x44) and performs the AllowI2C/generation gate check. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed (NM relay expected); 0xD4=AllowIpmiI2cCommands key is 0 AND system generation is not 3 (NM commands globally blocked). No additional response bytes are written by this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only; no config writes, no data returned. CC 0x00 is returned even if the underlying NM relay does not execute (stub behavior in virtual build). An Admin can determine whether NM commands are enabled by sending this cmd and observing CC 0xD4 vs 0x00. The AllowIpmiI2cCommands attribute is the sole enforcement point for all NM commands in this library; a misconfigured or missing attribute defaults to blocked on non-gen-3.

### 6.6DellNMCommand/0x45 Medium

NetFn 0x2e · Cmd 0x45 · Sub 0x45Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Set Policy Suspension Periods' pass-through gate. DellNMCommand handles this cmd byte via the same global gate logic as 0x44: validates AllowIpmiI2cCommands and system generation, returns CC 0xD4 if blocked or CC 0x00 if allowed. No request data bytes are parsed and no response data bytes are written. In a full NM implementation the request would be forwarded to the NM processor over I2C after the gate passes; in this build that relay is absent.

Request

| Offset | Request field                                           |
|--------|---------------------------------------------------------|
| 7      | data length (not checked).                              |
| 8      | +: data bytes are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked (AllowIpmiI2cCommands=0 and gen!=3). No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only; no writes, no data leak. Identical gate to 0x44. The stub CC 0x00 response can mislead NM management tools into believing suspension periods were set when no NM hardware interaction occurred.

### 6.7DellNMCommand/0x46 Medium

NetFn 0x2e · Cmd 0x46 · Sub 0x46Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get Policy Suspension Periods' pass-through gate. Same AllowIpmiI2cCommands/generation gate logic as 0x44 and 0x45. Returns CC 0x00 or CC 0xD4 with no request parsing and no response data written.

Request

| Offset | Request field                                           |
|--------|---------------------------------------------------------|
| 7      | data length (not checked).                              |
| 8      | +: data bytes are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only. Stub CC 0x00 returns no suspension-period data; a caller expecting NM response payload will receive an empty response body, which may cause management software to misparse or crash if it assumes a non-empty payload on success.

### 6.8DellNMCommand/0x4b Medium

NetFn 0x2e · Cmd 0x4b · Sub 0x4bPriv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get Turbo Synchronization Ratio' pass-through gate. Same AllowIpmiI2cCommands/generation gate logic as the other NM commands in this range. Returns CC 0x00 or CC 0xD4 with no request parsing and no response data written. Intel NM spec identifies this cmd as retrieving the turbo ratio limit from the processor power management engine; none of that logic is implemented here.

Request

| Offset | Request field                                           |
|--------|---------------------------------------------------------|
| 7      | data length (not checked).                              |
| 8      | +: data bytes are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only. No turbo-ratio data is exposed. Identical gate surface to other NM pass-through stubs.

### 6.9DellNMCommand/0x60 Medium

NetFn 0x2e · Cmd 0x60 · Sub 0x60Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS (Compute, Memory, and IO Utilization Reporting) - 'Get CUPS Capabilities' or 'CUPS Configuration' pass-through gate (exact NM sub-function is determined by request data not parsed here). DellNMCommand applies the AllowIpmiI2cCommands/generation gate and returns CC 0x00 or CC 0xD4 with no request parsing and no response data written.

Request

| Offset | Request field                                           |
|--------|---------------------------------------------------------|
| 7      | data length (not checked).                              |
| 8      | +: data bytes are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only. Stub CC 0x00 with empty body could cause CUPS-capable management stacks (e.g. Intel Data Center Manager) to misinterpret NM CUPS availability.

### 6.10DellNMCommand/0x61 Medium

NetFn 0x2e · Cmd 0x61 · Sub 0x61Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Get CUPS Policies' pass-through gate. DellNMCommand applies the AllowIpmiI2cCommands/generation gate and returns CC 0x00 or CC 0xD4 with no request parsing and no response data written.

Request

| Offset | Request field                                           |
|--------|---------------------------------------------------------|
| 7      | data length (not checked).                              |
| 8      | +: data bytes are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only. Identical stub behavior to 0x60.

### 6.11DellNMCommand/0x64 Medium

NetFn 0x2e · Cmd 0x64 · Sub 0x64Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Enable/Disable CUPS' pass-through gate. DellNMCommand applies the AllowIpmiI2cCommands/generation gate and returns CC 0x00 or CC 0xD4 with no request parsing and no response data written. No actual CUPS enable/disable operation is performed by this handler; the command would normally toggle CUPS reporting on the NM processor.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +: data bytes (including enable/disable flag) are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only. An Admin calling this to enable/disable CUPS will receive CC 0x00 with no effect — the silent no-op could mask a failure to disable CUPS telemetry in a security hardening context.

### 6.12DellNMCommand/0x65 Medium

NetFn 0x2e · Cmd 0x65 · Sub 0x65Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Get CUPS Configuration' pass-through gate. DellNMCommand applies the AllowIpmiI2cCommands/generation gate and returns CC 0x00 or CC 0xD4 with no request parsing and no response data written.

Request

| Offset | Request field                                           |
|--------|---------------------------------------------------------|
| 7      | data length (not checked).                              |
| 8      | +: data bytes are NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation()`

**Security** — Gate-only. No CUPS configuration data is returned; stub CC 0x00 with empty payload is indistinguishable from a legitimate 'no CUPS data' response without further NM-layer context.

### 6.13DellNMCommand/0x66 Medium

NetFn 0x2e · Cmd 0x66 · Sub 0x66Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Set CUPS Policies' pass-through gate. DellNMCommand is registered as the IPMI handler for this NetFn/cmd and dispatches internally on the cmd byte (param_1\[6\]=0x66). For this cmd byte the code falls in the 0x00-0x7F range (positive signed byte), taking the branch: bVar3 \< 0x83 AND (char)bVar3 \>= 0, which falls through directly to the success path (lVar7=0). The sole gate is the global AllowIpmiI2cCommands/generation pre-check applied to all NM commands: if AllowIpmiI2cCommands cfgdb key is 0 AND system generation is not 3, the command is blocked with CC 0xD4; otherwise CC 0x00 is returned. No license check, no request bytes inspected beyond param_1\[6\]. In a full NM build, the request would be relayed to the PCH Node Manager over I2C; in this virtual environment no relay occurs.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked by this handler). |
| 8 | +N (data\[N\]): NM protocol payload (IANA prefix + NM-specific fields) are NOT parsed; the handler reads only param_1\[6\] (cmd=0x66) for the dispatch decision. Min length: 0 data bytes for the gate; Intel NM spec may impose more. |

Response

byte 0: completion code. 0x00=gate passed (NM relay expected downstream); 0xD4=AllowIpmiI2cCommands cfgdb key is 0 AND system generation is not 3 (NM commands globally blocked). No additional response bytes are written by this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C (relay, not implemented in virtual build)`

**Security** — Gate-only; no config writes, no data returned from iDRAC side. The AllowIpmiI2cCommands attribute is the sole enforcement point. Any Admin-privileged caller on a gen-3 system or one with AllowIpmiI2cCommands=1 can relay arbitrary NM payload to the PCH. Follows the same pass-through code path as 0x60-0x65 (CUPS range).

### 6.14DellNMCommand/0x67 Medium

NetFn 0x2e · Cmd 0x67 · Sub 0x67Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Get CUPS Data' pass-through gate. Identical code path to 0x66: cmd byte 0x67 falls in the 0x00-0x7F range, takes the (char)bVar3 \>= 0 branch, falls through to lVar7=0 after the global AllowIpmiI2cCommands/generation gate. No license check, no request parsing, no response bytes written. In a full NM build, request is relayed to PCH NM over I2C to retrieve CUPS utilization data.

Request

| Offset | Request field                                                    |
|--------|------------------------------------------------------------------|
| 7      | data length (not checked).                                       |
| 8      | +N (data\[N\]): NM payload NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked (AllowIpmiI2cCommands=0 and gen!=3). No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C`

**Security** — Gate-only. Identical to 0x66. Stub CC 0x00 with empty body is returned on success; management stacks expecting CUPS data payload on success will receive nothing, potentially causing incorrect capacity planning decisions.

### 6.15DellNMCommand/0x68 Medium

NetFn 0x2e · Cmd 0x68 · Sub 0x68Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Set CUPS Configuration' pass-through gate. Identical code path to 0x66/0x67: cmd byte 0x68 is in the 0x00-0x7F range, (char)0x68 \> 0, falls through to lVar7=0 after the global AllowIpmiI2cCommands/generation gate. No license check, no request parsing. In a full NM build, the request is forwarded to PCH NM to configure CUPS thresholds and reporting parameters.

Request

| Offset | Request field                                                    |
|--------|------------------------------------------------------------------|
| 7      | data length (not checked).                                       |
| 8      | +N (data\[N\]): NM payload NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C`

**Security** — Gate-only. No CUPS configuration changes are performed by iDRAC itself; stub CC 0x00 may mislead a caller into believing CUPS was reconfigured when no PCH interaction occurred. Same gate surface as 0x64 (Enable/Disable CUPS).

### 6.16DellNMCommand/0x69 Medium

NetFn 0x2e · Cmd 0x69 · Sub 0x69Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager CUPS - 'Reset CUPS Statistics' pass-through gate. Identical code path to 0x66-0x68: cmd byte 0x69 is in the 0x00-0x7F range, (char)0x69 \> 0, falls through to lVar7=0 after the global AllowIpmiI2cCommands/generation gate. No license check, no request parsing. In a full NM build, the request is forwarded to PCH NM to reset accumulated CUPS utilization statistics.

Request

| Offset | Request field                                                    |
|--------|------------------------------------------------------------------|
| 7      | data length (not checked).                                       |
| 8      | +N (data\[N\]): NM payload NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=gate passed; 0xD4=NM commands blocked. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C`

**Security** — Gate-only. An Admin can send this to reset CUPS statistics with no additional authorization beyond the AllowIpmiI2cCommands gate, potentially erasing historical utilization data used for capacity planning without audit trail from iDRAC.

### 6.17DellNMCommand/0x80 Medium

NetFn 0x2e · Cmd 0x80 · Sub 0x80Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager manufacturing command 0x80 - pass-through gate gated by physical manufacturing mode jumper. DellNMCommand dispatches on param_1\[6\]=0x80. Cmd byte 0x80 is in the 0x80-0x82 range: the condition (uVar6 \< 0x83) is true AND (char)0x80 = -128 \< 0, triggering a goto to LAB_0011a6a4 which calls IsManufacturingModeJumperOn(). If the jumper is NOT installed, the handler returns CC 0xD6 immediately without forwarding. If the jumper IS installed, it falls through to lVar7=0 (pass). The global AllowIpmiI2cCommands/generation gate applies first. Intel NM spec identifies cmd 0x80 in this range as a manufacturing-test command (likely 'Get Limiting Band' or a vendor-specific hardware characterization operation); no payload is inspected by this handler.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed by this handler; the request is forwarded verbatim to PCH NM only if both the AllowIpmiI2cCommands gate AND the manufacturing mode jumper check pass. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=both gates passed (manufacturing mode active and AllowI2C gate cleared); 0xD4=NM commands globally blocked (AllowIpmiI2cCommands=0 and gen!=3); 0xD6=manufacturing mode jumper not installed. No additional response bytes written by this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); IsManufacturingModeJumperOn() (physical GPIO/CPLD check); PCH Node Manager over I2C`

**Security** — Physical manufacturing mode jumper is the primary additional gate beyond Admin privilege and AllowIpmiI2cCommands. When the jumper is installed (factory floor or lab setting), any Admin IPMI session can relay arbitrary manufacturing NM payloads to the PCH. The CC 0xD6 response leaks the fact that the manufacturing jumper is absent, allowing attackers to fingerprint board state.

### 6.18DellNMCommand/0x81 Medium

NetFn 0x2e · Cmd 0x81 · Sub 0x81Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager manufacturing command 0x81 - manufacturing jumper gated pass-through. Identical code path and gate logic to cmd 0x80: (char)0x81 \< 0 triggers IsManufacturingModeJumperOn() check; returns CC 0xD6 if jumper absent, CC 0x00 if present (after the global AllowIpmiI2cCommands gate). Intel NM manufacturing commands in the 0x80-0x82 range typically cover platform characterization operations (e.g., 'Set Turbo Synchronization Ratio' or 'Reset NM Settings'). No payload inspection by this handler.

Request

| Offset | Request field                                                    |
|--------|------------------------------------------------------------------|
| 7      | data length (not checked).                                       |
| 8      | +N (data\[N\]): NM payload NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=both gates passed; 0xD4=NM globally blocked; 0xD6=manufacturing jumper absent. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); IsManufacturingModeJumperOn(); PCH Node Manager over I2C`

**Security** — Same as 0x80: physical manufacturing jumper gate. CC 0xD6 distinguishes missing jumper from other errors and leaks hardware configuration state. When jumper is present, NM manufacturing payload reaches PCH with no content validation by iDRAC.

### 6.19DellNMCommand/0x82 High

NetFn 0x2e · Cmd 0x82 · Sub 0x82Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager manufacturing command 0x82 - manufacturing jumper gated pass-through. Identical code path to 0x80 and 0x81: cmd byte 0x82 satisfies (uVar6 \< 0x83) AND (char)0x82 \< 0, triggering the IsManufacturingModeJumperOn() gate. Returns CC 0xD6 if jumper is absent, CC 0x00 if present. Intel NM 0x82 in the manufacturing range corresponds to commands such as 'Get Turbo Synchronization Ratio' or similar platform characterization operations not expected in production deployments. No payload inspection.

Request

| Offset | Request field                                                    |
|--------|------------------------------------------------------------------|
| 7      | data length (not checked).                                       |
| 8      | +N (data\[N\]): NM payload NOT parsed. Min length: 0 data bytes. |

Response

byte 0: completion code. 0x00=both gates passed; 0xD4=NM globally blocked; 0xD6=manufacturing jumper absent. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); IsManufacturingModeJumperOn(); PCH Node Manager over I2C`

**Security** — Same as 0x80 and 0x81. The three commands 0x80-0x82 share the same manufacturing gate and together expose a cluster of NM manufacturing-test operations. If a production unit erroneously has the manufacturing jumper installed (or if IsManufacturingModeJumperOn is spoofable via software), these commands become reachable by any Admin IPMI session.

### 6.20DellNMCommand/0xa8 Critical

NetFn 0x2e · Cmd 0xa8 · Sub 0xa8Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager / SMBus 'Master Write-Read' (I2C/SMBus arbitrary access) pass-through gate. DellNMCommand dispatches on param_1\[6\]=0xa8. Cmd byte 0xa8 falls in the 0x83-0xBF range (not 0xC0): condition (uVar6 \< 0x83) is false and (uVar6 != 0xc0) is true, so execution jumps directly to LAB_0011a4e0 (lVar7=0). The sole gate is the global AllowIpmiI2cCommands/generation pre-check. No license check, no payload inspection. Intel Group Extension cmd 0xa8 under netfn=0x2E corresponds to SMBus/I2C Master Write-Read, which provides raw SMBus bus master access to any device on the bus managed by the PCH ME. In a full build, the request bytes (bus address, read/write lengths, write data) are forwarded verbatim to the ME for execution.

Request

| Offset | Request field |
|----|----|
| 3 | bus-id/channel |
| 4 | slave-address\<\<1\|r/w |
| 5 | read-count, data\[6+\]=write-data bytes. Min length: 0 data bytes for the iDRAC gate. |

Response

byte 0: completion code. 0x00=gate passed (SMBus operation forwarded to PCH ME); 0xD4=NM commands globally blocked (AllowIpmiI2cCommands=0 and gen!=3). No additional response bytes from this iDRAC handler; actual read data (if any) comes from the PCH ME relay response.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH ME SMBus master (I2C bus access to arbitrary bus slaves)`

**Security** — High-value target: cmd 0xa8 maps to SMBus Master Write-Read, which gives an Admin IPMI caller arbitrary I2C/SMBus read/write access to any device reachable by the PCH ME (power controllers, voltage regulators, SPD EEPROMs, BMC-adjacent devices, potentially SSD controllers). The only gate on a gen-3 system with default AllowIpmiI2cCommands is Admin IPMI privilege. No license check, no bus-address whitelist visible in this code. Comparable attack surface to DCMI Master Write-Read (IPMI cmd 0x52 under netfn 0x2C) but relayed through PCH ME, potentially reaching a wider set of buses.

### 6.21DellNMCommand/0xb7 Medium

NetFn 0x2e · Cmd 0xb7 · Sub 0xb7Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0xb7 pass-through gate. Falls in the 0x83-0xBF range that is not specially handled: after the global AllowIpmiI2cCommands/generation gate the handler does no further validation and returns 0x00. No license check. Request forwarded to PCH Node Manager over I2C. Specific NM semantic is undetermined from this iDRAC code alone.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload forwarded to PCH without inspection. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=pass; 0xd4=NM commands blocked (AllowIpmiI2cCommands=0 on non-gen-3). No additional response bytes from this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; PCH Node Manager over I2C`

**Security** — No license gate. Any Admin caller that clears the global AllowIpmiI2c gate can push arbitrary bytes to the PCH Node Manager. Potentially covers NM extension commands whose PCH-side behavior is unknown.

### 6.22DellNMCommand/0xba Medium

NetFn 0x2e · Cmd 0xba · Sub 0xbaPriv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0xba pass-through gate. Identical code path to 0xb7: falls in the 0x83-0xBF range not specially handled. After the global gate the handler returns 0x00 with no license check or payload validation. Request forwarded to PCH Node Manager over I2C. Specific NM semantic is undetermined from this iDRAC code alone.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload forwarded to PCH without inspection. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=pass; 0xd4=NM commands blocked (AllowIpmiI2cCommands=0 on non-gen-3). No additional response bytes from this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; PCH Node Manager over I2C`

**Security** — Same as 0xb7: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control.

### 6.23DellNMCommand/0xc0 Medium

NetFn 0x2e · Cmd 0xc0 · Sub 0xc0Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager enable/disable platform power-cap policy. Validates policy domain, trigger-type, and aggression fields against allowed combinations. In manufacturing mode (IsManufacturingModeJumperOn()==0) AND when domain bits\[3:0\]\<4, the command is additionally restricted to monolithic iDRAC (type 3) and must arrive via the serial (in-band) interface; other configurations in that path receive 0xd6. Manufacturing mode may also write PowerCapSetting and ActivePolicyName config attributes. In non-manufacturing mode the handler returns 0x00 (success, no-op) without performing any trigger/aggression validation or config writes. Requires feature license 0xb. A global pre-check blocks all NM commands on non-gen-3 systems when AllowIpmiI2cCommands cfgdb key is 0.

Request

| Offset | Request field |
|----|----|
| 7 | data length (min 4). |
| 8 | .. |
| 10 | data\[0..2\]): IANA manufacturer ID, 3 bytes LE (not validated). |
| 11 | data\[3\]): policy-control byte — bits\[3:0\]=domain-ID (0=platform; 1=CPU; 2=memory; 3=HDD), bits\[7:4\]=action/enable flags. |
| 12 | data\[4\]): policy/trigger-type byte (validated against allowed set; 0x01=boot-time, 0x02=full). |
| 13 | data\[5\]): aggression/limit parameter byte. |

Response

byte 0: completion code. 0x00=success; 0x6f=license feature 0xb absent; 0x80=invalid policy-ID or domain/trigger combination; 0xd4=NM commands blocked (AllowIpmiI2cCommands=0 on non-gen-3); 0xd6=wrong interface or non-monolithic iDRAC. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; CfgSetAttributeInt System.Embedded.1#ServerPwr.1#PowerCapSetting; CfgSetAttribute System.Embedded.1#ServerPwr.1#ActivePolicyName; Dell_shm_memread area 0xc; Dell_get_generation; Dell_get_idrac_type; IsSerialInterface; IsManufacturingModeJumperOn; lmCheckLcFeature(0xb)`

**Security** — In manufacturing mode can disable power capping (set PowerCapSetting=0) and clear ActivePolicyName. An Admin on a manufacturing-jumpered unit can remove all power throttling. The serial/monolithic restriction applies only in manufacturing mode with domain\<4; in non-manufacturing mode any channel can reach this handler and it returns 0x00 (no-op).

### 6.24DellNMCommand/0xc1 Medium

NetFn 0x2e · Cmd 0xc1 · Sub 0xc1Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager set-policy command. Sets a power-cap policy: enables or disables server power capping, sets the active policy name to 'OpenManage Power Center', and writes a numeric power-cap wattage value to the config database. Also reads current NM state from shared memory. Feature license 0xb is required unless domain-ID bits\[3:0\]=0 and trigger-type=0x02, in which case an unlicensed path modifies the input domain byte (clears bit 4) before reaching the main flow. A global pre-check blocks NM commands on non-gen-3 systems with AllowIpmiI2cCommands=0.

Request

req+7: data length (min 9 when setting power cap value). req+8..req+10 (data\[0..2\]): IANA manufacturer ID, 3 bytes LE. req+11 (data\[3\]): policy-info byte — bits\[3:0\]=domain-ID (must be 0 for non-licensed path), bit\[4\]=enable-power-cap flag (1=enable and write cap value), bits\[7:5\]=reserved. req+12 (data\[4\]): trigger-type (0x01=enable power cap path; 0x02=NM policy type). req+13 (data\[5\]): sub-policy/action byte. req+15..req+16 (data\[7..8\]): power-cap value in watts, uint16 LE, used when req+11 bit\[4\]=1.

Response

byte 0: completion code. 0x00=success; 0x6f=domain/trigger invalid and no feature license 0xb. No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; CfgSetAttributeInt System.Embedded.1#ServerPwr.1#PowerCapSetting; CfgSetAttribute System.Embedded.1#ServerPwr.1#ActivePolicyName; CfgSetAttributeInt System.Embedded.1#ServerPwr.1#PowerCapValue; Dell_shm_memread area 0xc offset 0x363d; Dell_get_generation; IsManufacturingModeJumperOn; lmCheckLcFeature(0xb)`

**Security** — Authenticated Admin can set arbitrary power-cap wattage (uint16 from request bytes data\[7..8\]) into System.Embedded.1#ServerPwr.1#PowerCapValue with no range validation visible in this handler. Setting an abnormally low cap could degrade system performance or stability. On systems without feature license 0xb, the unlicensed path still modifies the input buffer's domain byte (bit-4 cleared) before returning 0x6f — a minor in-memory mutation, not a security boundary bypass.

### 6.25DellNMCommand/0xc2 Medium

NetFn 0x2e · Cmd 0xc2 · Sub 0xc2Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager get-policy stub: checks feature license 0xb and returns success if the license is present. No request data is parsed, no response data is written, and no back-end state is read or modified. Likely a placeholder for a get-policy reply path that was stripped or deferred.

Request

No data bytes are parsed. Min length: 0 data bytes.

Response

byte 0: completion code. 0x00=licensed/success; 0x6f=feature license 0xb absent. No additional response bytes.

Backends `iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (global gate); lmCheckLcFeature(0xb)`

**Security** — Read-only license probe; no writes, no data leak. Can be used to fingerprint whether the NM license is installed.

### 6.26DellNMCommand/0xc3 Medium

NetFn 0x2e · Cmd 0xc3 · Sub 0xc3Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel Node Manager 'Set NM Alert Thresholds' (inferred from Intel NM spec). DellNMCommand is registered as the single C-level handler for the full NM command range (0xc0-0xd9); it dispatches internally on param_1\[6\] (the IPMI cmd byte). For 0xc3, no sub-command dispatch occurs: the function checks the AllowIpmiI2cCommands cfgdb key and the server hardware generation (Dell_get_generation). If AllowI2C==0 AND gen!=3, the command is rejected with CC=0xd4. Otherwise it falls through with CC=0x00, signalling the IPMI framework to forward the unmodified request to the Intel ME/NM processor over I2C/SMBus. DellNMCommand applies no additional license or manufacturing-mode check for this cmd byte.

Request

req+0..req+5: IPMI session/channel header (6 bytes, framework-set). req+6: cmd byte 0xc3. req+7: data length (N). req+8+0: 0x57 (Intel IANA byte 0). req+8+1: 0x01 (Intel IANA byte 1). req+8+2: 0x00 (Intel IANA byte 2). req+8+3: domain_id \[bits 3:0\] \| policy_type \[bits 7:4\]. req+8+4: threshold_type / trigger. req+8+5..req+8+N-1: NM alert threshold parameters (command-specific, passed opaquely to Intel ME). Min data length: 3 (IANA only — checked by DellNMCommand pre-filter); Intel ME enforces full NM payload requirements.

Response

| Offset | Response field |
|----|----|
| 0 | completion code — 0x00=forwarded to NM (NM response follows), 0xd4=AllowIpmiI2cCommands not set on non-Gen3 system. If CC=0x00 |
| 1 | .. |
| 3 | Intel IANA echo (0x57 0x01 0x00, echoed by Intel ME). |
| 4 | ..resp+N: NM alert threshold response bytes (from Intel ME, format per Intel NM spec; content undetermined statically). |

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() hardware generation check; Intel ME/Node Manager subsystem over SMBus/I2C (command pass-through target)`

**Security** — Allows setting Intel NM power alert thresholds, which can suppress or raise warnings about power overdrawn conditions. Attacker with Admin IPMI access can disable alerts to mask anomalous power draw. Requires AllowIpmiI2cCommands=1 on non-Gen3 hardware (off by default). Command is NOT in-band only; accessible over LAN IPMI.

### 6.27DellNMCommand/0xc4 Medium

NetFn 0x2e · Cmd 0xc4 · Sub 0xc4Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel Node Manager 'Get NM Alert Thresholds' (inferred from Intel NM spec). Identical gating logic to cmd 0xc3: AllowIpmiI2cCommands check + generation check, no license or manufacturing checks. If allowed, passes request through to Intel ME/NM over I2C. Read-only query returning currently configured NM alert thresholds for a domain/policy.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xc4. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3: domain_id \[bits 3:0\]. req+8+4: policy_id. Min data length: 3 (IANA). Full NM payload enforced by Intel ME.

Response

| Offset | Response field |
|----|----|
| 0 | CC 0x00=NM response follows, 0xd4=access blocked by AllowI2C/gen gate. If CC=0x00 |
| 1 | .. |
| 3 | IANA echo (0x57 0x01 0x00). |
| 4 | ..resp+N: NM threshold response (undetermined statically; from Intel ME). |

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — Read-only — exposes current NM alert threshold configuration to any Admin IPMI caller over LAN. Information disclosure of power management policy parameters.

### 6.28DellNMCommand/0xc5 High

NetFn 0x2e · Cmd 0xc5 · Sub 0xc5Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel Node Manager 'Set NM Policy Suspend Periods' (inferred from Intel NM spec). DellNMCommand checks AllowIpmiI2cCommands and generation; falls through with CC=0x00 if allowed. No additional license or manufacturing checks for this cmd. Suspend periods let the caller disable NM enforcement during scheduled windows.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xc5. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3: domain_id \[bits 3:0\]. req+8+4: policy_id. req+8+5..: NM suspend period list (start_offset, duration, recurrence bitmask; per-entry format per Intel NM spec). Min data length: 3.

Response

| Offset | Response field                                             |
|--------|------------------------------------------------------------|
| 0      | CC 0x00=allowed/forwarded, 0xd4=access blocked. If CC=0x00 |
| 1      | ..                                                         |
| 3      | IANA echo.                                                 |
| 4      | +: NM response (undetermined statically).                  |

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — Writing suspend periods can disable Intel NM power policy enforcement during attacker-controlled windows, potentially allowing runaway power draw unchecked by the ME. Admin IPMI access over LAN is sufficient.

### 6.29DellNMCommand/0xc6 Medium

NetFn 0x2e · Cmd 0xc6 · Sub 0xc6Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel Node Manager 'Get NM Policy Suspend Periods' (inferred from Intel NM spec). Same AllowIpmiI2cCommands+generation gate as other NM cmds. Read-only; no side-effects in DellNMCommand itself.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xc6. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3: domain_id \[bits 3:0\]. req+8+4: policy_id. Min data length: 3.

Response

| Offset | Response field                                                |
|--------|---------------------------------------------------------------|
| 0      | CC 0x00=forwarded, 0xd4=blocked. If CC=0x00                   |
| 1      | ..                                                            |
| 3      | IANA echo.                                                    |
| 4      | +: NM suspend period list response (undetermined statically). |

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — Read-only. Exposes scheduled NM policy suspension windows to any Admin IPMI caller over LAN.

### 6.30DellNMCommand/0xc7 Medium

NetFn 0x2e · Cmd 0xc7 · Sub 0xc7Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager policy-type validation command. In manufacturing mode (IsManufacturingModeJumperOn()==0), validates the domain byte (must be 0x01, else 0xd6) and then checks trigger-type and aggression fields against allowed combinations, returning 0x80 for invalid values and 0x00 for valid ones. Requires feature license 0xc. In non-manufacturing mode the domain check is skipped entirely and the command returns 0x00 (no-op success) after passing the license check; no 0xd6 is issued. No config writes occur in either mode.

Request

| Offset | Request field |
|----|----|
| 7 | data length (min 5). |
| 8 | .. |
| 10 | data\[0..2\]): IANA manufacturer ID, 3 bytes LE. |
| 11 | data\[3\]): domain/action byte (must equal 0x01 in manufacturing mode, else 0xd6; not validated in non-manufacturing mode). |
| 12 | data\[4\]): policy-type byte (0x00, 0x01, or 0x02 validated in manufacturing mode; others fall through). |
| 13 | data\[5\]): trigger/aggression byte (validated against allowed set in manufacturing mode when policy-type=0x00: values 3-5 and 0x0d are invalid). |

Response

byte 0: completion code. 0x00=success/valid; 0x6f=feature license 0xc absent; 0x80=invalid trigger/aggression value for given policy-type (manufacturing mode only); 0xd6=domain byte not 0x01 in manufacturing mode. No additional response bytes.

Backends `iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (global gate); Dell_get_generation; IsManufacturingModeJumperOn; lmCheckLcFeature(0xc)`

**Security** — Validation-only; no writes. Exposes whether manufacturing mode is active (different rejection codes for mfg vs non-mfg paths) and whether license 0xc is present — useful for target reconnaissance.

### 6.31DellNMCommand/0xc8 Medium

NetFn 0x2e · Cmd 0xc8 · Sub 0xc8Priv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0xc8 license gate with a partial unlicensed allowance. After the global AllowIpmiI2cCommands/generation pre-check: if feature license 0xc (NM power statistics) is present, the command is allowed unconditionally (returns 0x00). If the license is absent, only the specific combination data\[4\]=0x00 AND data\[5\]=0x02 is allowed (returns 0x00); any other data\[4\]/data\[5\] combination is denied (returns 0x6f). Specific NM semantic is undetermined from this iDRAC code alone.

Request

| Offset | Request field |
|----|----|
| 7 | data length (min 6 for the unlicensed gating check). |
| 8 | .. |
| 10 | data\[0..2\]): IANA manufacturer ID, 3 bytes (not validated by this handler). |
| 11 | data\[3\]): NM-specific byte (not validated). |
| 12 | data\[4\]): inspected when unlicensed — must be 0x00 to pass. |
| 13 | data\[5\]): inspected when unlicensed — must be 0x02 to pass. Further bytes are not parsed. |

Response

byte 0: completion code. 0x00=success (either licensed, or unlicensed path with data\[4\]=0x00 and data\[5\]=0x02); 0x6f=feature license 0xc absent and data\[4\]/data\[5\] combination not whitelisted; 0xd4=NM commands blocked globally. No additional response bytes written by this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; lmCheckLcFeature(0xc); PCH Node Manager over I2C`

**Security** — The unlicensed whitelist (data\[4\]=0x00, data\[5\]=0x02) allows a specific NM query without license. An Admin without the NM license can issue this whitelisted form to reach the PCH. The licensed path imposes no payload restrictions at all. Can be used to fingerprint license 0xc presence by probing data\[4\]/data\[5\] combinations.

### 6.32DellNMCommand/0xc9 Medium

NetFn 0x2e · Cmd 0xc9 · Sub 0xc9Priv  · · · **A**libmisccmdconfidence: highlive ✓

Gate for Intel Node Manager 'Get Node Manager Statistics'. DellNMCommand applies the standard AllowIpmiI2cCommands+generation gate, then additionally calls isAMD(): if the platform is AMD-based, returns CC=0xd3 immediately (Intel NM does not exist on AMD). On Intel platforms, falls through with CC=0x00 and the framework passes the request to Intel ME/NM for per-domain/per-policy power and thermal statistics retrieval.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xc9. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3: statistics_mode (0=global, 1=per-policy, 2=per-inlet-temp, 3=per-throttle, 4=per-memory). req+8+4: domain_id \[bits 3:0\]. req+8+5: policy_id (used when mode=per-policy). Min data length: 3 (full NM requires 6).

Response

resp+0: CC 0x00=Intel platform, NM response follows; 0xd3=AMD platform (Intel NM not present); 0xd4=AllowI2C/gen blocked. If CC=0x00: resp+1..resp+3: IANA echo (0x57 0x01 0x00). resp+4..resp+7: current value (uint32 LE). resp+8..resp+11: minimum value (uint32 LE). resp+12..resp+15: maximum value (uint32 LE). resp+16..resp+19: average value (uint32 LE). resp+20..resp+23: timestamp (uint32 LE). resp+24..resp+27: statistics reporting period (uint32 LE). resp+28: domain_id \[bits 3:0\] \| policy_id_valid \[bit 7\]. NOTE: NM response layout undetermined from static analysis; fields reflect Intel NM spec v2-v3 knowledge.

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); isAMD() CPU platform check; Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — Read-only query returning server power/thermal statistics from Intel ME. Leaks real-time power draw, temperature measurements, and throttling state to any Admin IPMI caller over LAN. Can be used to monitor server workloads. AMD-specific CC=0xd3 return is a reliable platform-type oracle.

### 6.33DellNMCommand/0xca Medium

NetFn 0x2e · Cmd 0xca · Sub 0xcaPriv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command 0xca strict license gate. After the global AllowIpmiI2cCommands/generation pre-check: requires feature license 0xc. If licensed, returns 0x00 and the command is forwarded to the PCH Node Manager. If unlicensed, returns 0x6f immediately. No payload bytes are inspected. Specific NM semantic is undetermined from this iDRAC code alone.

Request

| Offset | Request field |
|----|----|
| 7 | data length (any). |
| 8 | +N (data\[N\]): NM protocol payload forwarded to PCH without inspection. Min length: 0 data bytes for the gate. |

Response

byte 0: completion code. 0x00=licensed and forwarded; 0x6f=feature license 0xc absent; 0xd4=NM commands blocked globally. No additional response bytes from this handler.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation; lmCheckLcFeature(0xc); PCH Node Manager over I2C`

**Security** — Stricter than 0xc8: no unlicensed allowance. Probing 0xca vs 0xc8 with different data\[4\]/data\[5\] values cleanly fingerprints license 0xc presence. Licensed path passes arbitrary payload to PCH with no iDRAC-side validation.

### 6.34DellNMCommand/0xcb Medium

NetFn 0x2e · Cmd 0xcb · Sub 0xcbPriv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command gated solely by feature license 0xb. Returns success if licensed, 0x6f otherwise. No request data is parsed and no back-end state is accessed beyond the license check. The command's intended semantic beyond the license gate is undetermined from static analysis.

Request

No data bytes are parsed beyond the global AllowIpmiI2cCommands and generation gate. Min length: 0 data bytes.

Response

byte 0: completion code. 0x00=licensed/success; 0x6f=feature license 0xb absent. No additional response bytes.

Backends `iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (global gate); Dell_get_generation; lmCheckLcFeature(0xb)`

**Security** — License probe only; no writes, no data exposed. Can fingerprint NM license presence.

### 6.35DellNMCommand/0xce Medium

NetFn 0x2e · Cmd 0xce · Sub 0xcePriv  · · · **A**libmisccmdconfidence: highlive ✓

Node Manager command gated solely by feature license 0xc (a different license tier from 0xcb). Returns success if licensed, 0x6f otherwise. No request data is parsed and no back-end state is accessed beyond the license check. Intended semantic beyond the license gate is undetermined from static analysis.

Request

No data bytes are parsed beyond the global AllowIpmiI2cCommands and generation gate. Min length: 0 data bytes.

Response

byte 0: completion code. 0x00=licensed/success; 0x6f=feature license 0xc absent. No additional response bytes.

Backends `iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (global gate); Dell_get_generation; lmCheckLcFeature(0xc)`

**Security** — License probe only; no writes, no data exposed. Can be used to fingerprint whether the higher NM license tier (0xc) is installed, independently from 0xcb which probes tier 0xb.

### 6.36DellNMCommand/0xcf Medium

NetFn 0x2e · Cmd 0xcf · Sub 0xcfPriv  · · · **A**libmisccmdconfidence: lowlive ✓

Gate for an Intel NM command at 0xcf (exact Intel NM spec function undetermined). DellNMCommand handles the 0xcb-0xd9 range with a bitmask table (0x50a0) that governs manufacturing-mode restrictions. For 0xcf: shift=(0xcf+0x35)&0x3f=4, uVar8=0x10; since bit 4 is not set in 0x50a0, the manufacturing-mode branch is NOT taken. Also 0xcf != 0xce so the lmCheckLcFeature(0xc) branch is not taken. Result: falls through to CC=0x00 after the standard AllowIpmiI2cCommands+generation gate. No license check, no manufacturing check.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xcf. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3+: NM command-specific parameters (undetermined; passed opaquely to Intel ME). Min data length: 3.

Response

| Offset | Response field                                           |
|--------|----------------------------------------------------------|
| 0      | CC 0x00=forwarded, 0xd4=AllowI2C/gen blocked. If CC=0x00 |
| 1      | ..                                                       |
| 3      | IANA echo.                                               |
| 4      | +: NM response (undetermined statically).                |

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — No additional access controls beyond Admin+AllowI2C gate. Exact NM operation undetermined. Lower risk than write commands but could expose ME state.

### 6.37DellNMCommand/0xd0 Medium

NetFn 0x2e · Cmd 0xd0 · Sub 0xd0Priv  · · · **A**libmisccmdconfidence: highlive ✓

Gate for a manufacturing-mode-restricted Intel NM command at 0xd0. In the 0xcb-0xd9 range bitmask logic: shift=(0xd0+0x35)&0x3f=5, uVar8=0x20; bit 5 IS set in the 0x50a0 mask, so execution goes to LAB_0011a6a4: IsManufacturingModeJumperOn() is called. If the physical manufacturing jumper is NOT asserted, returns CC=0xd6 immediately. If jumper IS on, falls through to CC=0x00 and the standard AllowI2C/gen gate is still effective. This command is inaccessible in production systems with no manufacturing jumper.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xd0. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3+: NM manufacturing/calibration parameters (undetermined; enforced by Intel ME). Min data length: 3.

Response

| Offset | Response field |
|----|----|
| 0 | CC 0xd6=manufacturing jumper not asserted (blocked in production); CC 0xd4=AllowI2C/gen gate failed; CC 0x00=allowed (manufacturing environment). If CC=0x00 |
| 1 | .. |
| 3 | IANA echo. |
| 4 | +: NM manufacturing response (undetermined statically). |

Backends `IsManufacturingModeJumperOn() hardware jumper state read (physical GPIO/CPLD); cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — Effectively unreachable in production (manufacturing jumper absent). If an attacker could assert manufacturing mode (e.g. via CPLD compromise), this would expose an undocumented NM command channel. The manufacturing gate is hardware-enforced, not software-configurable from this path.

### 6.38DellNMCommand/0xd1 Medium

NetFn 0x2e · Cmd 0xd1 · Sub 0xd1Priv  · · · **A**libmisccmdconfidence: lowlive ✓

Gate for an Intel NM command at 0xd1 (exact function undetermined; possibly 'Get Node Manager Power Supply Data' or similar read operation per Intel NM spec). In the 0xcb-0xd9 bitmask: shift=(0xd1+0x35)&0x3f=6, uVar8=0x40; bit 6 is NOT set in 0x50a0, manufacturing branch skipped. Not 0xce. Falls through to CC=0x00 after standard AllowIpmiI2cCommands+generation gate. No license check, no manufacturing check.

Request

req+0..req+5: IPMI header. req+6: cmd byte 0xd1. req+7: data length. req+8+0..req+8+2: Intel IANA 0x570100. req+8+3+: NM command-specific parameters (undetermined; passed to Intel ME). Min data length: 3.

Response

| Offset | Response field                                           |
|--------|----------------------------------------------------------|
| 0      | CC 0x00=forwarded, 0xd4=AllowI2C/gen blocked. If CC=0x00 |
| 1      | ..                                                       |
| 3      | IANA echo.                                               |
| 4      | +: NM response (undetermined statically).                |

Backends `cfgdb key iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (read); Dell_get_generation() check; Intel ME/NM over SMBus/I2C`

**Security** — No additional access controls beyond Admin+AllowI2C gate. Exact NM operation undetermined from static analysis alone.

### 6.39DellNMCommand/0xd2 Medium

NetFn 0x2e · Cmd 0xd2 · Sub 0xd2Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Set Turbo Synchronization Ratio' pass-through gate. DellNMCommand is registered as the IPMI handler for this NetFn/cmd and dispatches internally on the cmd byte (param_1\[6\]=0xD2). The global AllowIpmiI2cCommands/generation pre-check runs first for all NM commands: if CfgGetAttributeInt(iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands)==0 AND Dell_get_generation()!=3, the command is blocked with CC 0xD4. If that gate passes, 0xD2 falls into the 0xCB-0xD9 bit-mask block (uVar8=1\<\<7=0x0080; 0x0080 & 0x50a0 != 0) and triggers an additional manufacturing-mode guard: IsManufacturingModeJumperOn() is called; if the manufacturing jumper is NOT asserted, CC 0xD6 is returned. Only when both gates pass does the function reach lVar7=0 (CC 0x00). In a full NM build the request would then be relayed to the PCH Node Manager over I2C/SMBus to adjust per-core turbo ratio limits; in this virtual build no relay occurs.

Request

| Offset | Request field |
|----|----|
| 0 | Manufacturer ID LSB (0x57 |
| 1 | Mfr ID mid (0x01 |
| 2 | Mfr ID MSB (0x00 |
| 3 | domain_id\[7:0\] (CPU package, 0=global |
| 4 | enable_disable (0=disable, 1=enable), data\[5-N\]=turbo-ratio limit bytes per active-core count. Min length: 0 data bytes for the iDRAC gate; Intel NM relay requires at least 5 data bytes. |

Response

byte 0: completion code. 0xD4=AllowIpmiI2cCommands cfgdb key is 0 AND system generation is not 3 (NM I2C commands globally disabled). 0xD6=manufacturing mode jumper not asserted (turbo-ratio write requires manufacturing mode). 0x00=both gates passed (NM relay expected; no response data bytes written by this handler). No additional response bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); IsManufacturingModeJumperOn(); PCH Node Manager over I2C/SMBus (relay, not implemented in virtual build)`

**Security** — Double-gated: AllowIpmiI2cCommands AND manufacturing jumper. The manufacturing-mode requirement means this command is production-inaccessible on a fielded server regardless of Admin privilege or AllowIpmiI2cCommands setting. No config writes or data reads occur in iDRAC itself. If both gates could be bypassed, the relay would let an attacker manipulate per-core CPU turbo ratios via the PCH NM engine, affecting performance/thermals without OS visibility.

### 6.40DellNMCommand/0xd3 Medium

NetFn 0x2e · Cmd 0xd3 · Sub 0xd3Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get Turbo Synchronization Ratio' pass-through gate. DellNMCommand dispatches on cmd byte 0xD3: global AllowIpmiI2cCommands/generation gate runs first (CC 0xD4 if blocked). For 0xD3 the bit-mask check yields uVar8=1\<\<8=0x0100; 0x0100 & 0x50a0 == 0 and the byte is neither 0xCE nor has bit 0 set, so execution falls directly to LAB_0011a4e0 (lVar7=0, CC 0x00). No license check, no manufacturing-mode check. In a full NM build the request is relayed to the PCH NM to retrieve the currently configured per-core turbo ratio limits; in this virtual build no relay occurs and no data is returned.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would be: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00), data\[3\]=domain_id (0=global/CPU package). Min length: 0 for iDRAC gate; Intel NM relay requires at least 4 data bytes. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked (AllowIpmiI2cCommands=0 and gen!=3). 0x00=gate passed (NM relay expected; no response data bytes written by this handler). In a full relay build the NM response would include turbo-ratio data bytes; the iDRAC stub writes none.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Single gate: AllowIpmiI2cCommands only (no manufacturing-mode or license requirement). Any Admin with AllowIpmiI2cCommands=1 can relay this to the PCH NM to read per-core turbo ratio configuration. Stub CC 0x00 with empty body in the virtual build could mislead callers expecting ratio data.

### 6.41DellNMCommand/0xd4 Medium

NetFn 0x2e · Cmd 0xd4 · Sub 0xd4Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Set CUPS Policies' pass-through gate (CUPS = Compute, Memory and I/O Utilization Reporting Service). DellNMCommand dispatches on cmd byte 0xD4: global AllowIpmiI2cCommands/generation gate runs first (CC 0xD4 if blocked). For 0xD4 the bit-mask yields uVar8=1\<\<9=0x0200; 0x0200 & 0x50a0 == 0 and neither CE nor bit-0 condition applies, so execution falls to LAB_0011a4e0 (CC 0x00). No license check, no manufacturing-mode check. In a full NM build, the relay would configure CUPS utilization thresholds in the PCH NM; in this virtual build no relay occurs.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would include: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00), followed by domain_id and CUPS policy configuration fields (thresholds, action, policy type). Min length: 0 for iDRAC gate. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked. 0x00=gate passed (no response data bytes written). In a full relay, an empty successful response body indicates the policy was accepted by the NM engine.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Single gate: AllowIpmiI2cCommands only. No manufacturing-mode or license check despite this being a write operation to the PCH NM power policy engine. In a real NM deployment an Admin with AllowIpmiI2cCommands=1 can set arbitrary CUPS utilization policies, including those that could artificially throttle workloads or mask overloads.

### 6.42DellNMCommand/0xd7 Medium

NetFn 0x2e · Cmd 0xd7 · Sub 0xd7Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get CUPS Policies' pass-through gate. DellNMCommand dispatches on cmd byte 0xD7: global AllowIpmiI2cCommands/generation gate runs first (CC 0xD4 if blocked). For 0xD7 the bit-mask yields uVar8=1\<\<12=0x1000; 0x1000 & 0x50a0 != 0 (bit 12 is set in 0x50a0), triggering the manufacturing-mode guard: IsManufacturingModeJumperOn(); if NOT in manufacturing mode, CC 0xD6 is returned. Only when both gates pass does the function reach CC 0x00. Notably, this is a read-only query (Get Policies) yet requires manufacturing mode, which is more restrictive than the complementary Set CUPS Policies (0xD4) command. In a full NM build the request would be relayed to PCH NM to retrieve configured CUPS policies; in this virtual build no relay occurs.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would be: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00), data\[3\]=domain_id, data\[4\]=policy_id. Min length: 0 for iDRAC gate. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked. 0xD6=manufacturing mode jumper not asserted. 0x00=both gates passed (no response data bytes written by this handler). In a full relay, the NM would return policy threshold/action bytes.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); IsManufacturingModeJumperOn(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Double-gated: AllowIpmiI2cCommands AND manufacturing jumper, even though this is a read operation. The asymmetry with 0xD4 (Set CUPS Policies, single-gated) is notable: reading current policies requires manufacturing mode while writing them does not. This may indicate an internal debug/audit use case. Production-inaccessible on fielded servers.

### 6.43DellNMCommand/0xd8 Medium

NetFn 0x2e · Cmd 0xd8 · Sub 0xd8Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get CUPS Data' pass-through gate. Returns real-time CPU, memory, and I/O utilization counters from the PCH NM. DellNMCommand dispatches on cmd byte 0xD8: global AllowIpmiI2cCommands/generation gate first (CC 0xD4 if blocked). For 0xD8 the bit-mask yields uVar8=1\<\<13=0x2000; 0x2000 & 0x50a0 == 0, neither CE nor bit-0, execution falls to LAB_0011a4e0 (CC 0x00). No license check, no manufacturing-mode check. In a full NM build the relay would return CUPS utilization data from the PCH NM engine; in this virtual build no relay occurs and no data is returned.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would be: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00), data\[3\]=domain_id (0=all), data\[4\]=parameter_selector (which CUPS metric to retrieve). Min length: 0 for iDRAC gate. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked. 0x00=gate passed (no response data bytes written). In a full relay the NM response would include CUPS utilization percentage fields; the iDRAC stub returns an empty body.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Single gate: AllowIpmiI2cCommands only. No manufacturing-mode or license requirement. Any Admin can relay this to harvest real-time CPU/memory/IO utilization telemetry from the PCH NM, which could be used for side-channel workload inference. Stub CC 0x00 with empty body in the virtual build returns no data regardless.

### 6.44DellNMCommand/0xd9 High

NetFn 0x2e · Cmd 0xd9 · Sub 0xd9Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Reset CUPS Statistics' pass-through gate. Clears accumulated CUPS utilization counters in the PCH NM. DellNMCommand dispatches on cmd byte 0xD9: global AllowIpmiI2cCommands/generation gate runs first (CC 0xD4 if blocked). For 0xD9 the bit-mask yields uVar8=1\<\<14=0x4000; 0x4000 & 0x50a0 != 0 (bit 14 is set in 0x50a0), triggering the manufacturing-mode guard: IsManufacturingModeJumperOn(); if NOT in manufacturing mode, CC 0xD6 is returned. Only when both gates pass does the function reach CC 0x00. In a full NM build the relay would instruct the PCH NM to reset CUPS counters; in this virtual build no relay occurs.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would be: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00), data\[3\]=domain_id (0=all). Min length: 0 for iDRAC gate. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked. 0xD6=manufacturing mode jumper not asserted. 0x00=both gates passed (no response data bytes written by this handler).

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); IsManufacturingModeJumperOn(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Double-gated: AllowIpmiI2cCommands AND manufacturing jumper. Consistent with other destructive NM operations. Production-inaccessible on fielded servers. If both gates could be bypassed, an attacker could erase historical CUPS utilization data relied upon by capacity-planning and workload-optimization tools without OS-level audit trail.

### 6.45DellNMCommand/0xdc Medium

NetFn 0x2e · Cmd 0xdc · Sub 0xdcPriv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get Limiting Policy ID' pass-through gate. Returns the identifier of the NM policy currently enforcing a power or utilization limit on the server. DellNMCommand dispatches on cmd byte 0xDC: global AllowIpmiI2cCommands/generation gate runs first (CC 0xD4 if blocked). 0xDC is \>= 0xDA and falls entirely outside the 0xC8/0xC0-0xC7/0xC9-0xD9 dispatch branches, reaching LAB_0011a4e0 directly (lVar7=0, CC 0x00) with no license check, no manufacturing-mode check, and no per-cmd logic. In a full NM build the relay would query the PCH NM for the active limiting policy ID; in this virtual build no relay occurs.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would be: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00), data\[3\]=domain_id (0=global). Min length: 0 for iDRAC gate. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked. 0x00=gate passed (no response data bytes written by this handler). In a full relay the NM would return the limiting policy ID and domain; the iDRAC stub returns an empty body.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Lightest gate of the set: only AllowIpmiI2cCommands, no manufacturing-mode, no license. Any Admin can query which NM policy is currently throttling the server. In a real deployment, this discloses whether the server is power-constrained, which power policy is active, and by inference the server's load relative to configured power budgets. Stub CC 0x00 with empty body in the virtual build.

### 6.46DellNMCommand/0xdf Medium

NetFn 0x2e · Cmd 0xdf · Sub 0xdfPriv  · · · **A**libmisccmdconfidence: highlive ✓

Intel Node Manager 'Get NM Version' pass-through gate. Returns the firmware version of the Node Manager engine in the PCH. DellNMCommand dispatches on cmd byte 0xDF: global AllowIpmiI2cCommands/generation gate runs first (CC 0xD4 if blocked). 0xDF is \>= 0xDA and falls outside all dispatch branches, reaching LAB_0011a4e0 directly (CC 0x00) with no license check, no manufacturing-mode check, and no per-cmd logic. In a full NM build the relay would query the PCH NM for its version string; in this virtual build no relay occurs and no version data is returned.

Request

| Offset | Request field |
|----|----|
| 7 | data length (not checked). |
| 8 | +N (data\[N\]): NM payload NOT parsed. Per Intel NM 3.0 spec the relay payload would be: data\[0-2\]=Manufacturer ID (0x57,0x01,0x00). Min length: 0 for iDRAC gate; Intel NM relay requires at least 3 data bytes. |

Response

byte 0: completion code. 0xD4=NM commands globally blocked. 0x00=gate passed (no response data bytes written). In a full relay, the NM response would include NM major/minor version, patch, and build bytes; the iDRAC stub returns an empty body, which may cause version-negotiating NM clients to fail or fall back to a minimum assumed version.

Backends `CfgGetAttributeInt iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); PCH Node Manager over I2C/SMBus (relay, not in virtual build)`

**Security** — Lightest gate: AllowIpmiI2cCommands only, no other restrictions. Same surface as 0xDC. In a real deployment, NM version disclosure aids an attacker in targeting known NM firmware vulnerabilities. Stub CC 0x00 with empty body could cause Intel Data Center Manager or similar to misdetect NM firmware version and apply wrong policy schemas.

### 6.47DellNMCommand/PowerBudget Medium

NetFn 0x2e · Cmd 0xeaPriv  · · · **A**libmisccmdconfidence: highlive ✓

Get or Set the server power budget (power cap). DellNMCommand gates the command on AllowIpmiI2cCommands and server generation; cmd 0xea has no explicit switch case so falls through to return CC 0x00 after the gate. The GET leaf (DellPwrGetPwrBudget) requires power-management license lmCheckLcFeature(0xb) and hardware power-cap support GetUpcSupport(). It reads PowerCapValue, PowerCapMaxThres, PowerCapMinThres from cfgdb, available power and PSU count from SHM, and current consumption from SHM. The SET leaf (DellPwrSetPwrBudget) accepts a cap value with a units byte (absolute watts, percent of max, or percent of min-to-max range) and writes PowerCapValue; if power cap is already enabled it also updates ActivePolicyName to 'iDRAC'.

Request

GET: req\[7\]=4 (data_len); req\[8\]=0x00 (getset; bit7=1 returns revision only); req\[9\]=0xea (param_selector); req\[10\]=0x00 (set_selector); req\[11\]=0x00 (block_selector). Minimum data bytes: 4. SET: req\[7\]\>=0x0d (13); req\[8\]=0xea (param_selector); req\[9..10\]=PowerCapValue uint16-LE; req\[11\]=units (0x00=watts, 0x01=pct-of-max, 0x02=pct-of-range \[min..max\]); req\[12..\]=reserved 0x00. Minimum data bytes: 13.

Response

| Offset | Response field |
|----|----|
| 0 | 0x11 (param_rev |
| 1 | ..2\]=PowerCapValue uint16-LE (watts |
| 3 | 0x00 |
| 4 | ..5\]=PowerCapMaxThres uint16-LE |
| 6 | ..7\]=PowerCapMinThres uint16-LE |
| 8 | numPSUs |
| 9 | ..10\]=AvailablePower uint16-LE (watts |
| 11 | 1 if AvailPwr\<=consumption else 0 |
| 12 | 0x00; resp_len=13. Error CC: 0xd4=AllowI2C blocked or gen unsupported; 0x6f=license absent; 0xd5=no HW power cap; 0xff=cfgdb or SHM read failure. SET success (cc=0x00): no response data. SET errors: 0xd4=gate; 0x6f=license; 0xd5=no HW cap; 0xc7=data_len\<13; 0xcc=invalid units (\>2); 0xff=cfgdb write failure. |

Backends `cfgdb: iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands; Dell_get_generation(); lmCheckLcFeature(0xb); GetUpcSupport(); cfgdb System.Embedded.1#ServerPwr.1#{PowerCapValue,PowerCapMaxThres,PowerCapMinThres,PowerCapSetting,ActivePolicyName}; SHM 0x30/0xda64 (available power uint32), SHM 0x30/0x2fe3 (PSU count), SHM 6/0x8c (power consumption uint16)`

**Security** — Admin-only. SET writes PowerCapValue and ActivePolicyName to cfgdb, directly capping server power via iDRAC. An attacker with Admin IPMI and power-management license can set an arbitrarily low cap, degrading workload performance without OS-level visibility. GET leaks power cap thresholds, PSU count, available power, and current consumption, enabling accurate workload profiling.

### 6.48DellNMCommand/SNMPAlertTrapDest Medium

NetFn 0x2e · Cmd 0xf0Priv  · · · **A**libmisccmdconfidence: highlive ✓

Get or Set SNMP alert trap destination configuration (address, type, ack interval, retries) for trap slots 4-6 (set_selector 0..2 maps to iDRAC.Embedded.1#SNMPAlert.4/5/6). DellNMCommand gate: AllowIpmiI2cCommands check, cmd 0xf0 falls through to CC 0x00. Both GET and SET require license check d_licenseCheck(0x10) OR d_licenseCheck(4) (CC 0x6f if both absent). Destination strings up to 39 bytes use a 3-block transfer protocol: block_selector 0/1/2 indexes chunks of the address. The SET path accumulates blocks in static globals DAT_0015fdcc/fde0 and commits to cfgdb only when block 0 arrives with a string length matching the accumulated total.

Request

GET: req\[7\]=4; req\[8\]=0x00 (getset); req\[9\]=0xf0 (param_selector); req\[10\]=set_selector 0..2 (slot=set_sel+4); req\[11\]=block_selector 0..2. Minimum 4 bytes. SET block 0: req\[7\]\<=0x13; req\[8\]=0xf0; req\[9\]=set_selector; req\[10\]=block_selector 0; req\[11\]=dest_strlen; req\[12\]=DestinationType; req\[13\]=AlertAckInterval; req\[14\]=Retries; req\[15..21\]=first 7 bytes of destination string. SET block 1: req\[10\]=1; req\[11..23\]=next 13 bytes. SET block 2: req\[10\]=2; remainder. Minimum per block: 4 bytes.

Response

| Offset | Response field |
|----|----|
| 0 | set_sel |
| 1 | block_sel |
| 2 | 0x00; block 0 |
| 3 | addr_strlen+3 |
| 4 | DestinationType |
| 5 | AlertAckInterval |
| 6 | Retries |
| 7 | ..14\]=first 8 bytes of destination; resp_len=0x13 (19). Blocks 1/2: continuation address bytes; resp_len=min(remaining,19). Error CC: 0xd4=gate; 0x6f=license absent; 0xcc=invalid set_selector (\>=3) or block_selector (\>=3); 0xff=cfgdb read failure. SET success (cc=0x00): no response data. SET errors as GET plus 0xff=cfgdb write failure. |

Backends `d_licenseCheck(0x10), d_licenseCheck(4); cfgdb iDRAC.Embedded.1#SNMPAlert.{4..6}#{Destination,DestinationType,AlertAckInterval,Retries}; static accumulation globals DAT_0015fdcc/fde0/fdf0/fdf8/fe00 (not re-entrant, process-global); iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands`

**Security** — Admin + license required. SET rewrites SNMP alert destination IPs from IPMI without going through the web UI or REST API, enabling silent alert redirection to an attacker host. The static-global block accumulation state is not per-session: interleaved concurrent writes from two IPMI sessions can corrupt the assembled address before cfgdb commit. GET discloses current trap destination addresses, types, and retry policies.

### 6.49DellNMCommand/0xf1 Medium

NetFn 0x2e · Cmd 0xf1Priv  · · · **A**libmisccmdconfidence: lowlive ✓

Unimplemented / reserved Dell OEM command slot. DellNMCommand gate: AllowIpmiI2cCommands check; cmd 0xf1 (\>= 0xda) has no explicit switch case and falls through to lVar7=0, returning CC 0x00 with no response data. Neither DellCmdGetSysInfo nor DellCmdSetSysInfo contain an explicit case for parameter selector 0xf1; both fall to their default branches and return CC 0x80 (Invalid Command). No backend access or state modification is performed.

Request

DellNMCommand accepts any payload; no format enforced. Minimum data bytes: 0.

Response

DellNMCommand: cc=0x00 with 0 response data bytes (gate passes). cc=0xd4 if AllowIpmiI2cCommands=0 and generation!=3. Downstream GET/SET dispatcher (if reached): cc=0x80.

Backends `cfgdb: iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (gate only); Dell_get_generation()`

**Security** — No active functionality. The cmd byte is allocated in the dispatch table, accepted by the gate, and returns success — a silent no-op. Not an exploitable surface based on static analysis, but leaves a live cmd slot that could become exploitable if a future update adds a handler.

### 6.50DellNMCommand/CMCInfo Medium

NetFn 0x2e · Cmd 0xf2Priv  · · · **A**libmisccmdconfidence: medlive ✓

Get or Set CMC/chassis network info (SysInfo parameter 0xfffffff2, internal index 242). DellNMCommand gate: AllowIpmiI2cCommands check; cmd 0xf2 falls through to CC 0x00. SET (DellCmdSetSysInfo case 0xf2): calls FUN_0010a4d0(param_1) to write the raw blob; if the IMC-ready flag DAT_0015fdc0 is non-zero (modular chassis present), reads back param 0xf2 from SHM and writes an extracted IPv6 address sub-field to cfgdb System.Embedded.1#ChassisInfo.1#IPV6Address. GET (DellCmdGetSysInfo case 0xf2): calls FUN_0010b9c4(set_selector, resp, resp_len, 0xfffffff2, 1) to read the blob; internals of both helpers are not decompiled in this batch.

Request

GET: req\[7\]=4; req\[8\]=0x00 (getset); req\[9\]=0xf2 (param_selector); req\[10\]=set_selector; req\[11\]=block_selector. Minimum 4 bytes. SET: req\[7\]=variable; req\[8\]=0xf2 (param_selector); req\[9+\]=CMC/chassis info payload. Exact SET payload layout undetermined (handled inside FUN_0010a4d0).

Response

GET success (cc=0x00): resp_data\[0\]=0x11; resp_data\[1..N\]=param 242 blob; resp_len=N+1. Exact field layout undetermined. Error CC: 0xd4=gate; 0xff=read error. SET success (cc=0x00): no data. SET errors: 0xd4=gate; 0xff=FUN_0010a4d0 failure or ChassisInfo.IPV6Address write failure.

Backends `FUN_0010a4d0 (write, internals undetermined); FUN_0010b9c4 (read, internals undetermined); SHM/SysInfo store for param 0xfffffff2; cfgdb System.Embedded.1#ChassisInfo.1#IPV6Address; global DAT_0015fdc0 (IMC-ready/modular flag); iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands`

**Security** — Admin-only. SET writes an IPv6 address string to cfgdb ChassisInfo.IPV6Address when the modular chassis flag is set, without visible input validation in this handler. The full attack surface depends on FUN_0010a4d0 internals (not available in this batch); potential for address injection into chassis inventory.

### 6.51DellNMCommand/SysInfoParam243 Medium

NetFn 0x2e · Cmd 0xf3Priv  · · · **A**libmisccmdconfidence: medlive ✓

Get or Set SysInfo parameter 0xfffffff3 (internal index 243). DellNMCommand gate: AllowIpmiI2cCommands check; cmd 0xf3 falls through to CC 0x00. SET (DellCmdSetSysInfo case 0xf3): shares a fall-through group with parameter selectors 4, 5, 8, 9, 0xd1, 0xe4 and calls FUN_0010a4d0(param_1) to write the raw SysInfo blob. GET (DellCmdGetSysInfo case 0xf3): calls FUN_0010b9c4(set_selector, resp, resp_len, 0xfffffff3, 1). Both FUN_0010a4d0 and FUN_0010b9c4 are shared helpers whose internals are not decompiled in this batch. The exact semantic of parameter 243 is undetermined; its grouping with primary OS name and OS version selectors suggests a BIOS-to-iDRAC system identification parameter.

Request

GET: req\[7\]=4; req\[8\]=0x00; req\[9\]=0xf3; req\[10\]=set_selector; req\[11\]=block_selector. Minimum 4 bytes. SET: req\[7\]=variable; req\[8\]=0xf3; req\[9+\]=parameter data bytes. Minimum length undetermined.

Response

GET success (cc=0x00): resp_data\[0\]=0x11; resp_data\[1..N\]=param 243 data; resp_len=N+1. Error CC: 0xd4=gate; 0xff=read failure. SET success (cc=0x00): no data. Error CC: 0xd4=gate; 0xff=write failure.

Backends `FUN_0010a4d0 (write); FUN_0010b9c4 (read); SHM/SysInfo store for param 0xfffffff3; iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands`

**Security** — Admin-only. Arbitrary blob write to a SysInfo slot with no visible content validation beyond the AllowI2C gate. Risk depends on what downstream consumers read parameter 243; they are not identified in this decompiled batch.

### 6.52DellNMCommand/SystemRevision Medium

NetFn 0x2e · Cmd 0xf4Priv  · · · **A**libmisccmdconfidence: highlive ✓

Get or Set the system revision blob (SysInfo parameter 0xfffffff4, labeled SYS_INFO_PARAM_244_SYS_REV in DellSysInfoInit). DellNMCommand gate: AllowIpmiI2cCommands check; cmd 0xf4 falls through to CC 0x00. GET (DellCmdGetSysInfo case 0xf4, via LAB_00111a78): calls readSysInfo(resp+1, &len, 0xfffffff4, 1); sets resp_len=len+1, resp\[0\]=0x11. SET (DellCmdSetSysInfo case 0xf4): calls writeSysInfo(data+1, data_len-1, 0xfffffff4) to persist the revision blob, then fires SetGPTaskEvent(S_u32SysInfoEndEventID, 2) to trigger the DellSysInfoEndTask callback. If the GP event call fails a warning is printed but CC 0x00 is still returned.

Request

GET: req\[7\]=4; req\[8\]=0x00 (getset); req\[9\]=0xf4; req\[10\]=set_selector (0); req\[11\]=block_selector (0). Minimum 4 data bytes. SET: req\[7\]=N (data_len); req\[8\]=0xf4 (param_selector); req\[9..N+7\]=revision blob bytes; length passed to writeSysInfo as data_len-1. Minimum 2 bytes.

Response

GET success (cc=0x00): resp_data\[0\]=0x11; resp_data\[1..N\]=system revision blob; resp_len=N+1. Error CC: 0xd4=gate; 0xff=readSysInfo failure. SET success (cc=0x00): no response data. Error CC: 0xd4=gate; any writeSysInfo non-zero return.

Backends `readSysInfo/writeSysInfo (SHM key 0xfffffff4); SetGPTaskEvent(S_u32SysInfoEndEventID) -> DellSysInfoEndTask GP callback; iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands`

**Security** — Admin-only. SET writes arbitrary bytes into the SYS_REV SHM slot and immediately fires DellSysInfoEndTask, which signals LifecycleController and other subscribers. Injecting malformed data could affect any consumer of parameter 244 that parses it without bounds checking. Read path discloses the hardware revision string, aiding version-specific exploit targeting.

### 6.53DellNMCommand/0xf5 Medium

NetFn 0x2e · Cmd 0xf5Priv  · · · **A**libmisccmdconfidence: lowlive ✓

Unimplemented / reserved Dell OEM command slot. DellNMCommand gate: AllowIpmiI2cCommands check; cmd 0xf5 (\>= 0xda) has no explicit switch case and falls through to lVar7=0, returning CC 0x00 with no response data. Neither DellCmdGetSysInfo nor DellCmdSetSysInfo contain an explicit case for parameter selector 0xf5; both return CC 0x80 (Invalid Command) via their default branches. No backend access or state modification is performed.

Request

DellNMCommand accepts any payload; no format enforced. Minimum data bytes: 0.

Response

DellNMCommand: cc=0x00 with 0 response bytes (gate passes). cc=0xd4 if AllowIpmiI2cCommands=0 and generation!=3.

Backends `cfgdb: iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands (gate only); Dell_get_generation()`

**Security** — No active functionality. Same dead slot characteristics as 0xf1.

### 6.54DellNMCommand/NodeIDInfo Medium

NetFn 0x2e · Cmd 0xf6Priv  · · · **A**libmisccmdconfidence: highlive ✓

Get Node ID information (SysInfo parameter 0xfffffff6, labeled SYS_INFO_PARAM_246_NODE_ID_INFO). Read-only: SET returns CC 0x82. DellNMCommand gate: AllowIpmiI2cCommands check; cmd 0xf6 falls through to CC 0x00. GET (DellCmdGetSysInfo case 0xf6 / code_r0x00112b74): validates data_len must be 7 or 9 (bVar4-7 & 0xfd == 0; otherwise CC 0xcc). If data\[0\] bit7 is set, returns 1-byte revision-only response. Otherwise reads the Node ID blob from SHM via readSysInfo(local_1a68, &len, 0xfffffff6, 1) (max 0x7c=124 bytes). The caller supplies a start offset and count: for data_len=7, count=MakeUINT16(data\[3\], data\[2\]) and offset=MakeUINT16(data\[5\], data\[4\]); for data_len=9, fields are swapped. Copies min(count, len-offset) bytes starting at blob\[offset+1\] into resp\[4+\]. Node ID blob is populated at boot by DellSysInfoInit calling readInitSysInfo(0xfffffff6).

Request

GET, data_len=7: req\[7\]=7; req\[8\]=0x00 (getset, bit7=1 for revision only); req\[9\]=0xf6 (param_selector); req\[10\]=set_selector low (start offset - 1); req\[11..12\]=count uint16-LE (max bytes to return, up to 0x7c); req\[13..14\]=unused. GET, data_len=9: req\[7\]=9; req\[8\]=getset; req\[9\]=0xf6; req\[10\]=sel2; req\[11..12\]=offset uint16-LE; req\[13..14\]=count uint16-LE. SET (any payload): returns CC 0x82. Minimum data bytes: 7.

Response

GET success (cc=0x00): resp_data\[0\]=0x11; resp_data\[1\]=set_sel_echo; resp_data\[2\]=bytes_returned; resp_data\[3\]=0x00; resp_data\[4..4+N-1\]=Node ID blob bytes \[offset..offset+N-1\]; resp_len=N+4. If bit7 of data\[0\] set: resp_len=1, resp_data\[0\]=0x11 (revision only). Error CC: 0xd4=gate; 0xcc=invalid data_len (not 7 or 9). SET: cc=0x82 unconditionally.

Backends `readSysInfo (SHM key 0xfffffff6, max 0x7c bytes); cfgdb System.Embedded.1#ServerInfo.1#NodeID (source for boot-time init); iDRAC.Embedded.1#Security.1#AllowIpmiI2cCommands`

**Security** — Read-only (SET blocked at CC 0x82). Discloses the server Node ID string used in Dell blade/modular chassis management topology. The caller-controlled offset and count allow sub-string extraction across the 124-byte blob; bounds are checked (offset+count \< 0x7d before the copy), but this should be verified empirically. Leaks node identity data useful for chassis topology mapping.

### 6.55DellNMCommand/0xC0 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xc0Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel Node Manager 'Set Active Power Policy' (NM cmd 0xC0). Checks license (lmCheckLcFeature 0xb). In non-manufacturing mode validates domain ID bits and policy type from the inner NM payload, checks iDRAC type and serial interface. Manufacturing mode jumper relaxes domain/type restrictions.

Request

| Offset | Request field |
|----|----|
| 6 | 0xC0 (NM subcommand, data\[0\]). |
| 11 | param_1\[0xb\])=domain/policy byte (bits 0-3 = domain, must be 0 for non-mfg; bit 4 = unused here). |
| 12 | param_1\[0xc\])=policy type. |
| 13 | param_1\[0xd\])=policy#. Min length from subcommand byte: undetermined (inner NM packet not fully decoded statically). |

Response

Completion code only, no response data bytes. CC=0x00 pass; CC=0x6F insufficient privilege (not licensed); CC=0xD6 command not supported in current configuration (serial/iDRAC type restriction); CC=0x80 invalid policy ID.

Backends `lmCheckLcFeature(0xb); IsManufacturingModeJumperOn(); Dell_get_idrac_type(); IsSerialInterface(); Dell_get_generation()`

**Security** — License gate with manufacturing-mode bypass. AllowIpmiI2cCommands cfgdb key and server generation gate at top of parent handler. Not channel-restricted so reachable from LAN IPMI as Admin.

### 6.56DellNMCommand/0xC1 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xc1Priv  · · · **A**libmisccmdconfidence: medlive ✓

Intel NM 'Set Power Policy' with active cfgdb side-effects. Validates license (lmCheckLcFeature 0xb). If bit 4 of the domain byte (req+11) is set (enable power cap): writes PowerCapSetting=1, ActivePolicyName='OpenManage Power Center', and PowerCapValue (16-bit watt value from req+15) to cfgdb. If disable: clears PowerCapSetting=0 and ActivePolicyName=''. Also clears bit 4 (enable bit) in the domain byte in-place in the request buffer, then reads Intel NM shared memory region (Dell_shm_memread 0xC, offset 0x363D).

Request

| Offset | Request field |
|----|----|
| 6 | 0xC1 (NM subcommand, data\[0\]). |
| 11 | domain+flags byte (bits 0-3=domain, must be 0 for non-licensed non-mfg; bit 4=power-cap enable flag). |
| 12 | policy type (0x01=power limit trigger, 0x02=another valid type; others rejected). |
| 13 | policy#. |
| 15 | ..16=power cap watt value (uint16 LE). Min length from subcommand: ~10 bytes. |

Response

Completion code only, no response data. CC=0x00 success; CC=0x6F not licensed; CC=0xD6 manufacturing/domain restriction not met; CC=0x80 invalid policy ID or wrong policy type combination.

Backends `lmCheckLcFeature(0xb); IsManufacturingModeJumperOn(); Dell_shm_memread(0xC, 0x363D); cfgdb: System.Embedded.1#ServerPwr.1#PowerCapSetting, System.Embedded.1#ServerPwr.1#ActivePolicyName, System.Embedded.1#ServerPwr.1#PowerCapValue`

**Security** — Config write: caller-supplied uint16 watt value written directly to PowerCapValue with no visible range check beyond policy type validation. Caller can set arbitrary power cap watt value. Licensed Admin or manufacturing-mode jumper required. Reachable from LAN IPMI as Admin.

### 6.57DellNMCommand/0xC2 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xc2Priv  · · · **A**libmisccmdconfidence: highlive ✓

License gate for Intel NM 'Delete Policy' (NM cmd 0xC2). Returns 0x6F if lmCheckLcFeature(0xb) is not licensed; otherwise returns CC=0 (pass-through to NM subsystem). No cfgdb writes in this handler.

Request

req+6=0xC2. Inner NM payload bytes not examined in this handler.

Response

CC=0x00 (licensed, pass); CC=0x6F (not licensed).

Backends `lmCheckLcFeature(0xb)`

**Security** — License gate only. Underlying NM Delete Policy executed by NM subsystem if gate passes.

### 6.58DellNMCommand/0xC7 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xc7Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel NM 'Get Statistics' (NM cmd 0xC7). Checks manufacturing jumper and lmCheckLcFeature(0xc). In non-manufacturing mode, validates domain (req+12) and policy type (req+13) combination: domain 0 allows specific non-standard types; domains 1 and 2 require policy types 0x0E and 0x0F respectively.

Request

req+6=0xC7. req+12 (param_1\[0xc\])=domain. req+13 (param_1\[0xd\])=policy type. Min length undetermined.

Response

CC=0x00 (pass); CC=0x6F (not licensed); CC=0x80 (invalid domain/policy type combination).

Backends `lmCheckLcFeature(0xc); IsManufacturingModeJumperOn()`

**Security** — Read-only gate; validates policy type range before forwarding NM statistics request. Manufacturing mode bypasses domain/type validation.

### 6.59DellNMCommand/0xC8 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xc8Priv  · · · **A**libmisccmdconfidence: medlive ✓

Gate for Intel NM 'Get Capabilities' (NM cmd 0xC8). If licensed (lmCheckLcFeature 0xc), passes through (CC=0). If not licensed but req+12=0x00 (domain 0) AND req+13=0x02 (type 2), also passes (CC=0) — a partial bypass for baseline capability discovery. All other unlicensed combinations return CC=0x6F.

Request

req+6=0xC8. req+12=domain. req+13=type. Min length undetermined.

Response

CC=0x00 (licensed pass, or unlicensed domain=0/type=2 baseline); CC=0x6F (not licensed for other combinations).

Backends `lmCheckLcFeature(0xc)`

**Security** — Partial license bypass for specific domain/type combination — an unlicensed Admin can still query NM baseline capabilities.

### 6.60DellNMCommand/0xC9 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xc9Priv  · · · **A**libmisccmdconfidence: highlive ✓

Intel NM 'Get Version' platform check. On AMD systems, immediately rejects with CC=0xD3 (parameter out of range / unsupported). On Intel platforms, falls through to CC=0 (pass). No license check.

Request

req+6=0xC9. No further bytes examined in this handler.

Response

CC=0xD3 (AMD platform); CC=0x00 (Intel platform, pass).

Backends `isAMD()`

**Security** — Read-only version query gate. Low risk.

### 6.61DellNMCommand/0xCA Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xcaPriv  · · · **A**libmisccmdconfidence: highlive ✓

License gate for Intel NM 'Get Limiting Policy ID' (NM cmd 0xCA). Returns 0x6F if lmCheckLcFeature(0xc) is not licensed.

Request

req+6=0xCA. Inner bytes not examined.

Response

CC=0x00 (licensed); CC=0x6F (not licensed).

Backends `lmCheckLcFeature(0xc)`

**Security** — License gate only.

### 6.62DellNMCommand/0xCB Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xcbPriv  · · · **A**libmisccmdconfidence: highlive ✓

License gate for NM command 0xCB (Intel NM alert threshold set/get). Selected via bitmask: (0xCB + 0x35) & 0x3F = 0, so bit 0 set, routes to lmCheckLcFeature(0xb) gate. Returns 0x6F if not licensed.

Request

req+6=0xCB. Inner bytes not examined.

Response

CC=0x00 (licensed); CC=0x6F (not licensed).

Backends `lmCheckLcFeature(0xb)`

**Security** — License gate only.

### 6.63DellNMCommand/0xCE Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xcePriv  · · · **A**libmisccmdconfidence: highlive ✓

License gate for NM command 0xCE. Explicitly handled (not via bitmask) to lmCheckLcFeature(0xc) gate. Returns 0x6F if not licensed.

Request

req+6=0xCE. Inner bytes not examined.

Response

CC=0x00 (licensed); CC=0x6F (not licensed).

Backends `lmCheckLcFeature(0xc)`

**Security** — License gate only.

### 6.64DellNMCommand/0xD0 Medium

NetFn 0x30 · Cmd 0x26 · Sub 0xd0Priv  · · · **A**libmisccmdconfidence: highlive ✓

Manufacturing-mode gate for NM command 0xD0. Selected via bitmask: (0xD0 + 0x35) & 0x3F = 5, bit 5 set, matches mask 0x50A0. Returns CC=0xD6 if manufacturing mode jumper is not installed. Same pattern applies to 0xD2 (bit 7), 0xD7 (bit 12), 0xD9 (bit 14) within the 0xCB-0xD9 range.

Request

req+6=0xD0 (or 0xD2/0xD7/0xD9). Inner bytes not examined.

Response

CC=0xD6 (jumper absent); CC=0x00 (manufacturing mode active, pass).

Backends `IsManufacturingModeJumperOn()`

**Security** — Only reachable with physical manufacturing-mode jumper installed. Returns 0xD6 in any production configuration.

### 6.65DellSetFanControlParameters Medium

NetFn 0x30 · Cmd 0x30Priv  · · · **A**libmisccmdconfidence: medlive ✓

Set fan control parameters. Access is hard-gated: requires X-Rev hardware (isXRev()) OR manufacturing test mode 2 (IsInManufacturingTestMode(2)); otherwise returns CC=0xD4. System IDs 0x10/0x11/0x12 always return CC=0x80. Dispatches on req\[8\] (subtype): (1) enable/disable fan test mode via Set_Fan_Test_Mode(); (2) override fan speed % per zone or all zones via Set_Fan_Speed(); (3) validate-only parameter (appears no-op, accepts zone=-1 and value 0-100, returns CC=0); (4) write an IMC status byte to internal state and set IMC bit 0x40, modular/blade platform (type=2) only.

Request

req\[7\]=data_length (2 for subtype 1; 3 for subtypes 2-4). req\[8\]=subtype (1-4). Subtype 1: req\[9\]=mode (0=off, 1=on). Subtype 2: req\[9\]=zone (-1=all zones, else zone index), req\[10\]=speed_percent (1-100). Subtype 3: req\[9\] must be -1 (0xFF), req\[10\]=value (0-100). Subtype 4: req\[9\]=ignored, req\[10\]=IMC_status_byte (any). Min length: 2 bytes.

Response

CC=0x00 success. Error CCs: 0xD4 (not X-Rev and not manufacturing test mode 2); 0x80 (system ID 0x10/0x11/0x12 or invalid subtype \> 4); 0xC7 (wrong data length for subtype); 0xCC (subtype 4: platform not modular type 2, or subtype 2: zone index out of range); 0xFF (Set_Fan_Test_Mode() internal failure).

Backends `isXRev(); IsInManufacturingTestMode(2); Dell_get_system_id(); get_platform_type(); Set_Fan_Test_Mode(); Set_Fan_Speed(); DellSetIMCStatusBit(0x40); global IMC status byte DAT_0016c99d`

**Security** — Direct hardware fan speed override reachable only with X-Rev hardware or manufacturing test mode. In manufacturing mode, setting fans to minimum speed can cause thermal damage (DoS). Subtype 3 purpose is undetermined — may be a hidden parameter.

### 6.66DellGetFanControlParameters Medium

NetFn 0x30 · Cmd 0x31Priv  · · · **A**libmisccmdconfidence: mediumlive ✓

Manufacturing/debug command to read fan control state. Subcmd 1 returns whether fan override test mode is active; subcmds 2/3/4 return per-fan or per-zone PWM percentages. Gated on IsInManufacturingTestMode(2) returning non-zero OR isXRev() returning non-zero; returns CC=0xd4 in normal production.

Request

req+8=subcmd (uint8). Subcmd 1: req+7=0x01 (no extra data). Subcmds 2/3/4: req+7=0x02; req+9=fan index (1-based uint8) or 0xff for all fans. On modular platforms (get_platform_type==2) req+9 must be 0xff or 0x01; for subcmd 2/4 any other value returns CC=0xc7 (199). Subcmd 3 (XRev path) requires req+9=0xff, else CC=0xcc. \[subcmd-note\] req+8 selector: 1=get fan test mode status, 2=get fan PWM by index or all (production path), 3=XRev/modular fan path, 4=get all fan-zone PWMs (modular). Selectors outside {1,2,3,4} return CC=0x80.

Response

Subcmd 1: 1 byte (\*param_2=1); resp\[0\] = (DFS thermal_get_fan_test_mode raw == 0) → 1 if raw==0 else 0 (documented semantic: 1=test mode active). Subcmd 2/3 all-fans (req+9==0xff): N bytes where N=fan count from DFS thermal_get_fan_speed; resp is the PWM% array ONLY — resp\[0..N-1\]=per-fan PWM%, \*param_2=N. There is NO fan-count prefix byte in the response (prior 'resp\[0\]=fan count, resp\[1..N\]=PWM' was WRONG; the count is returned via the length field, not embedded). Subcmd 2 single fan (req+9=1-based index): 1 byte; resp\[0\]=PWM% for that fan; 0xcc if index \> fan count. Subcmd 3 on XRev all-zones: 4 bytes, zeroed (\*param_3=0, \*param_2=4; stub). CC=0xd4 if not in mfg-test-mode and not XRev; 0x80 invalid subcmd; 0xc7(199) on length error or modular subcmd 2/4 with req+9 not in {0xff,0x01}; 0xcc on out-of-range single-fan index or XRev subcmd 3 with req+9 != 0xff; 0xff on DFS test-mode call failure.

Backends `get_platform_type, isXRev, IsInManufacturingTestMode (arg=2), Get_Fan_PWM (fnmgr_async_client → DFS 'thermal_get_fan_speed', writes fan count to byte[0] and PWM array to following bytes, up to 0x15), Get_Fan_Test_Mode (fnmgr_async_client → DFS 'thermal_get_fan_test_mode')`

**Security** — Gated on manufacturing test mode or XRev hardware; not reachable in normal production firmware. Exposes thermal/fan diagnostic data.

### 6.67DellCmdFreshAir Medium

NetFn 0x30 · Cmd 0x35Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Query Fresh Air cooling compliance status and thermal threshold exceedance timing. Reads FACompliance value from shared memory (seg 0x25, offset 0) and, if Fresh Air is active (compliance=1 or 2), reads the current active entry index and 22 bytes of FA sensor data (time-above-warning and time-above-critical counters) from SHM segment 0x11.

Request

req+7 must equal 10 (decimal, 0x0a); all 10 data bytes (req+8..req+17) must be zero, else CC 0xc7 (wrong length) or CC 0xcc (reserved bytes non-zero).

Response

23 bytes (resp_len=0x17). The handler first zeroes all 23 response bytes. resp\[0\]=FA_status (0=not FA-capable, 1=partial compliance \[FACompliance==2\], 3=full compliance \[FACompliance==1\]). When FA is active it reads a 0x16-byte (22) FA entry from SHM 0x11 into a LOCAL buffer but copies only two u16 fields out: resp\[1:2\]=time_above_warning_threshold, resp\[3:4\]=time_above_critical_threshold. resp\[5:22\] are NOT populated from SHM — they remain zero (the '22 bytes of sensor data' is the local SHM read, not the response payload). If FA_status=0, only resp\[0\]=0 and the rest stay zero. CC 0x00 on success, 0xff on SHM read error.

Backends `Dell_shm_memread(seg=0x25, offset=0, len=1) for FACompliance. Dell_shm_memread(seg=0x11, offset=3, len=1) for entry count. Dell_shm_memread(seg=0x11, offset=count*0x10+1, len=1) for active index. Dell_shm_memread(seg=0x11, offset=index<<4, len=0x16) for FA data.`

### 6.68DellCmdServerPwrOnResponse Medium

NetFn 0x30 · Cmd 0x87Priv  · · · **A**libmisccmdconfidence: highlive ✓

Receives the CMC power-on grant/deny response payload and forwards it to iDRAC's internal power management subsystem via Server_Pwr_On_Response_Client IPC. Clears two IMC status bits (0x20 power-on pending, 0x200 blade power consumption) before dispatching.

Request

req\[0\]\>\>4 must equal 7 (CMC channel; ONLY gate — no IsInBandCommand check); req+7=5 or 6 (data length). Handler memcpy's data_len bytes from req+8 into a 12-byte IPC payload. Fields: req+8=CC byte (CMC response code); req+9=fail code; req+10..11=power allocated (uint16 LE, Watts); req+12=warning-condition flags; req+13=extra fail code (present only when data_len=6). NOTE: prior 'power alloc2 at req+12..13, warning at req+14, extra-fail at req+15' was WRONG — the handler logs power-allocated twice from the same req+10..11 bytes; there is no second power value and req+14/req+15 lie outside the 5/6-byte payload.

Response

1 byte on success (\*param_2=0x01): resp\[0\]=0 (proceed/granted) or 1 (denied), from Server_Pwr_On_Response_Client (left 0 if IPC returns a value \>= 2). CC=0x00 success; 0xc1 if not CMC channel; 0xc7 if data length not in {5,6}; 0xff on IPC error

Backends `DellClearIMCPrevStatusBit (IMC bit 0x20), DellClearIMCPrevStatusBit_IPCClient (IMC bit 0x200), Server_Pwr_On_Response_Client (IPC, sends 12-byte payload with type=1/length=0xc header)`

**Security** — Reachable only over the CMC/chassis channel (req\[0\] high-nibble==7), not host system interface, not LAN.

### 6.69DellCmdRequestedAirflow Medium

NetFn 0x30 · Cmd 0x8cPriv  · · · **A**libmodularconfidence: highabsent

Report the current requested fan airflow (PWM %) to the CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 0 (else CC=0xc7). Checks AvctThermal_IsFanControlManual: if manual, calls GetBladeManualPWM() for the current PWM setting; if automatic, reads 1 byte from shared memory region 0x25 at offset 0xac3 (CC=0xff on shm read failure). Clears IMC status bit 0x40. Returns the fan PWM percentage and a zero pad byte.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=2 (length); resp_data\[0\]=fan_pwm_pct; resp_data\[1\]=0

Backends `AvctThermal_IsFanControlManual; Dell_shm_memread (region 0x25, offset 0xac3); GetBladeManualPWM; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 6.70DellCmdServerPwrConsumption Medium

NetFn 0x30 · Cmd 0x8fPriv  · · · **A**libmisccmdconfidence: highabsent

CMC-channel iDRAC power telemetry handler ('CMC Request 8Fh'). Returns instantaneous DC power, power allocated/threshold, warning threshold, throttle state, max/min potential power, and aux power allocation. Reads AC power from SHM and converts to DC via efficiency ratio; reads power allocated from CfgDB and throttle state from CPLD and SHM; reads potential power range and aux from DFS/IPC.

Request

| Offset | Request field |
|----|----|
| 0 | \>\>4 must equal 7 (CMC channel; this is the ONLY gate — there is NO IsInBandCommand/system-interface check |
| 7 | 0x00 (subcmd selector must be zero, no additional data |

Response

| Offset | Response field |
|----|----|
| 0 | ..1\]=DC actual power (uint16 LE, Watts, AC reading \* efficiency |
| 2 | ..3\]=power allocated/threshold (uint16 LE, Watts, from System.Embedded.1#ServerPwr.1#PowerAllocated |
| 4 | ..5\]=warning threshold (uint16 LE, same value as \[2..3\] |
| 6 | throttle state byte (CPLD THROTTLE bit \| SHM status byte at region 0x27 offset 0x302 |
| 7 | ..8\]=max potential/normal power (uint16 LE, Watts |
| 9 | ..10\]=min potential/throttled power (uint16 LE, Watts |
| 11 | aux power (byte, Watts |
| 12 | 0 (reserved). CC=0x00 success; 0xc1 if not CMC channel; 0xc7 if subcmd != 0; 0xff on any SHM/CfgDB/DFS/IPC error |

Backends `Dell_shm_memread (region 6 offset 0x8c for AC watts, region 0x27 offset 0x302 for throttle status), CfgGetAttributeInt (System.Embedded.1#ServerPwr.1#PowerAllocated), cpld_read_bit_hwabs (THROTTLE), Request_Power_Numbers_Client (DFS, loops over 6 power-number tuples), GetAuxPower (IPC), GetPowerEfficiency (SHM region 0x30 offset 0xbc13, default 0.85), PowerConvertACToDC (inline multiply+round)`

**Security** — Reachable only over the CMC/chassis channel (req\[0\] high-nibble==7), not the host system interface and not LAN sessions; telemetry read only.

### 6.71DellCmdChassisFanStatus Medium

NetFn 0x30 · Cmd 0x95Priv  · · · **A**libmodularconfidence: highlive ✓

Acknowledge chassis fan status from the CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 3 (else CC=0xc7). Clears IMC previous-status bit 0x2000 (bit 13) and returns a 2-byte zero payload. The 3 request data bytes are not inspected.

Request

| Offset | Request field              |
|--------|----------------------------|
| 7      | 3 (fixed len; else CC=0xc7 |
| 8      | ..10\]=ignored             |

Response

resp\[0\]=2 (length); resp_data\[0..1\]=0x0000

Backends `DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band/system-interface gate.

### 6.72DellCmdGetPowerCycleInterval High

NetFn 0x30 · Cmd 0x9bPriv  · · · **A**libmodularconfidence: highlive ✓

Return the configured AC power-cycle interval in seconds. req\[7\] must == 0 (CC=0xc7 otherwise). Calls GetPowerCycleInterval(0) and returns the result as a single byte.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=1 (length); resp_data\[0\]=interval_seconds

Backends `GetPowerCycleInterval`

### 6.73DellPwrGetPwrConsumptionData Medium

NetFn 0x30 · Cmd 0x9cPriv  · **U** O Alibmisccmdconfidence: medlive ✓

Read accumulated power consumption statistics (min/avg/max/peak watts) for the system or a specific entity. Gated by LC feature 0xc (power monitoring license). Supports a broadcast 'all-entities' mode when the upper nibble of the internal message header byte (req\[0\]\>\>4) equals 7, which bypasses entity validation and requests aggregate data. Returns 24 bytes of statistics data filled by GetPowerConsumptionData().

Request

req+7: data_length (no explicit length check; minimum 2 data bytes required for entity fields). req+0: internal message header byte; upper nibble (bits 7:4) == 7 selects all-entities/aggregate mode, any other value selects per-entity mode using req+8/req+9. req+8 (data\[0\]): entity_id — on monolithic platforms validated via CheckEntityInfo(); on modular/DCS platforms must be 0x07 (with instance=0x01, i.e. little-endian uint16 at req+8 == 0x0107). req+9 (data\[1\]): entity_instance — paired with entity_id; ignored when all-entities mode is active.

Response

Completion code (return value): 0x00=success, 0x6f=LC feature 0xc not licensed, 0xc1=SHM feature capability bit0 set and not in all-entities mode (platform restriction), 0xcb=entity_id/instance invalid (modular), 0xff=GetPowerConsumptionData() backend error. On success: resp_len=0x18 (24 bytes). resp_data\[0..23\]: power consumption statistics opaque struct filled by GetPowerConsumptionData(); internal layout not statically derivable (pointer passed by reference).

Backends `Get_SHM_feature_capabilities() (SHM feature flags, index 0); lmCheckLcFeature(0xc) (LC licensing for power monitoring); get_platform_type() (monolithic=1 vs modular); Dell_get_idrac_type() (iDRAC type, 2=modular excluded from entity check); CheckEntityInfo(entity_id, entity_instance) (entity validation on monolithic); GetPowerConsumptionData() (reads from SHM/cfgdb, opaque backend).`

**Security** — User-privilege read of power statistics. No write path. The all-entities mode (req\[0\]\>\>4==7) bypasses per-entity validation on both monolithic and modular paths — crafting a message with upper-nibble 7 in the header byte retrieves aggregate data regardless of entity fields supplied. Confidence in req\[0\] interpretation is medium.

### 6.74DellPwrResetPwrConsumptionData Critical

NetFn 0x30 · Cmd 0x9dPriv  · · · **A**libmisccmdconfidence: highlive ✓

Reset accumulated power consumption statistics (min/avg/max history) by writing a reset-mode code to the cfgdb key System.Embedded.1#ServerPwrMon.1#PowerConfigReset. Gated by LC feature 0xc. Validates the entity matches the platform type (monolithic uses CheckEntityInfo; modular requires entity_id=0x07/instance=0x01). Reset-mode codes 1–4 are accepted; codes outside \[1..4\] are rejected.

Request

| Offset | Request field |
|----|----|
| 7 | data_length (minimum 3 data bytes required). |
| 8 | data\[0\]): entity_id — monolithic: validated by CheckEntityInfo(); modular: must be 0x07. |
| 9 | data\[1\]): entity_instance — monolithic: validated by CheckEntityInfo(); modular: must be 0x01. |
| 10 | data\[2\]): reset_type — must be in range \[1..4\] (checked as (byte)(data\[2\]-1) \<= 3); written directly to cfgdb. |

Response

Completion code: 0x00=success, 0x6f=LC feature 0xc not licensed, 0xcc=reset_type out of range \[1..4\] or entity invalid (modular path entity mismatch), 0xcb=entity_id/instance mismatch on monolithic, 0xff=CfgSetAttributeInt() write to cfgdb failed. On success: resp_len=0 (no data bytes).

Backends `lmCheckLcFeature(0xc); get_platform_type(); Dell_get_idrac_type(); CheckEntityInfo(entity_id, entity_instance) (monolithic only); CfgSetAttributeInt('System.Embedded.1#ServerPwrMon.1#PowerConfigReset', reset_type, 0, 0) — persistent cfgdb write.`

**Security** — Admin-priv persistent cfgdb write. reset_type value (1–4) is written verbatim to cfgdb without further filtering. Destruction of power history is the intended effect. No path to execute arbitrary code or read credentials, but could be used to cover tracks by erasing power anomaly records.

### 6.75DellCmdBladeACPowerCycle High

NetFn 0x30 · Cmd 0x9ePriv  · · · **A**libmodularconfidence: highlive ✓

Initiate an AC power cycle for the blade or sled. In-band only (IsInBandCommand gate). Requires req\[7\]==2 (else CC=0xc7). Requires modular platform (platform_type==2); returns CC=0 with empty response on non-modular. On NGM (next-gen modular) platforms (NGMPlatform cfg attribute==1) this command is effectively disabled: operation req\[8\] \< 2 (op 0 or 1) returns CC=0xff and op \>= 2 returns CC=0xcc, with no power cycle performed. On legacy modular (NGMPlatform != 1, or when the NGM attribute read fails): op=0 triggers blade AC power cycle via DellSetIMCStatusBit(0x80000) after GetBladeNodeID; op=1 triggers sled AC power cycle via DellSetIMCStatusBit(0x40000000); other ops → CC=0xcc. Responds with 2 zero bytes on success.

Request

| Offset | Request field |
|----|----|
| 7 | 2 (fixed len; else CC=0xc7 |
| 8 | operation. Legacy: 0=blade AC cycle, 1=sled AC cycle. NGM: op\<2 → CC=0xff, op\>=2 → CC=0xcc (no-op). |

Response

resp\[0\]=2 (length); resp_data\[0..1\]=0x0000 on success

Backends `IsInBandCommand; get_platform_type; CfgGetAttributeInt (iDRAC.Embedded.1#PlatformCapability.1#NGMPlatform); DellSetIMCStatusBit; GetBladeNodeID`

**Security** — Triggers hardware AC power cycle via IMC status bit; in-band-only gate (IsInBandCommand) prevents remote IPMI abuse. On NGM platforms the legacy path is disabled and returns error codes. No additional authentication beyond Admin priv.

### 6.76DellPwrPSUInfo High

NetFn 0x30 · Cmd 0xb0Priv  · · · **A**libmisccmdconfidence: medlive ✓

Read static PSU attributes from shared memory: rated input watts, rated amps, rated volts, component ID (4 bytes), firmware version (8 bytes), PSU type, rated DC watts, and online status. Two code paths: RSM-capable systems read from SHM segment 0x17 (up to 2 PSUs, indices 1–2); non-RSM systems read a 0x330-byte per-PSU block from SHM segment 7 at offset (instance-1)\*0x330 (up to local_6ab PSUs, count from SHM 0x27).

Request

| Offset | Request field |
|----|----|
| 7 | data_length, must be exactly 2 (= 0x02); other lengths return completion code 0xc7 (199). |
| 8 | data\[0\]): entity_id, must be 0x0a (decimal 10, IPMI entity 'Power Supply'). |
| 9 | data\[1\]): entity_instance (1-based PSU index); RSM path: must be 1 or 2; non-RSM path: must be in \[1..local_6ab\] where local_6ab is the PSU count from SHM. |

Response

Completion code: 0x00=success, 0xc7 (199)=bad length or initial fail, 0xcc=entity_id != 0x0a or instance out of range, 0xd3=SHM read failure on RSM path. On success resp_len=0x17 (23 bytes). resp_data layout (non-RSM path, primary): \[0..1\]=Rated Input Watts (uint16 LE); \[2..3\]=Rated Amps x10 (int16 LE, scale factor 10); \[4..5\]=Rated Volts (uint16 LE); \[6..9\]=Component ID (4 bytes opaque); \[10..17\]=Firmware Version (8 bytes); \[18\]=PSU Type (1 byte); \[19..20\]=Rated DC Watts (uint16 LE); \[21\]=Online Status byte. RSM path populates \[0..1\], \[4..5\], \[18\]=0, \[19..20\] only; \[2..3\] and \[6..17\] and \[21\] are zeroed.

Backends `Dell_shm_memread(0x16, ...) — RSM-capable flag; Dell_shm_memread(0x17, ...) — RSM PSU data (up to 2 PSUs, 0x202 bytes); Dell_shm_memread(0x27, ...) — PSU count; Dell_shm_memread(7, ..., offset=(instance-1)*0x330, size=0x330) — per-PSU data block on non-RSM systems.`

**Security** — Admin-priv, read-only. Exposes PSU firmware version strings (8 bytes) and component IDs which could assist supply-chain targeting. The non-RSM path reads (instance-1)\*0x330 bytes into SHM segment 7 — instance is validated against the PSU count from SHM, but if that count value is corrupted/spoofed in SHM, arbitrary SHM offsets could be accessed. No direct write path.

### 6.77DellPwrRealTimePwrConsumption Medium

NetFn 0x30 · Cmd 0xb3Priv  · · · **A**libmisccmdconfidence: medlive ✓

Read real-time (instantaneous) power consumption in watts and amps for either the entire system (entity_instance=0) or a specific PSU (entity_instance=1..N). System total is read from SHM segment 6 at fixed offsets (0x8c for watts uint16, 0x8e for amps float). Per-PSU data is read from SHM segment 7 at (instance-1)\*0x330 into a 0x330-byte per-PSU block; checks a presence flag within the block before returning values. Gated by LC feature 0xc.

Request

| Offset | Request field |
|----|----|
| 7 | data_length, must be exactly 2 (= 0x02); other lengths or entity_id mismatch returns 0xcc. |
| 8 | data\[0\]): entity_id, must be 0x0a (PSU entity). |
| 9 | data\[1\]): entity_instance — 0=system aggregate (reads SHM segment 6), 1..N=specific PSU (reads SHM segment 7 per-PSU block); N is the PSU count from SHM segment 0x27. |

Response

Completion code: 0x00=success, 0x6f=LC feature 0xc not licensed, 0xcc=data_length != 2 or entity_id != 0x0a, 0xff=SHM read error. On success resp_len=7 (7 data bytes reported; only 4 bytes explicitly written). resp_data: \[0..1\]=Power in Watts (uint16 LE); \[2\]=Amps LSB (amps \* 10.0 cast to int, low byte); \[3\]=Amps MSB (amps \* 10.0 cast to int, high byte); \[4..6\]=undetermined (resp_len=7 but only bytes \[0..3\] are explicitly populated by the handler; bytes \[4..6\] are uninitialised stack-buffer content or zero-initialised depending on allocator).

Backends `lmCheckLcFeature(0xc); Dell_shm_memread(0x27, ...) — PSU count; Dell_shm_memread(6, offset=0x8c, size=2) — system watts; Dell_shm_memread(6, offset=0x8e, size=4) — system amps (float); Dell_shm_memread(7, offset=(instance-1)*0x330, size=0x330) — per-PSU block including presence flag at buf[0x1ac], watts at buf[0x190], amps (float) at buf[0x194].`

**Security** — Admin-priv, read-only. Note: resp_len is set to 7 but only 4 bytes are written — bytes \[4..6\] of resp_data are undetermined content (possible stack leak at the IPMI response layer if the transport copies resp_len bytes verbatim from an uninitialised buffer). Confidence in the 3-byte leak is medium — depends on whether the calling layer zero-initialises the response buffer.

### 6.78DellPwrPSUFirmwareUpdate High

NetFn 0x30 · Cmd 0xb6Priv  · · · **A**libmisccmdconfidence: highlive ✓

Initiate a PSU firmware update for a specific PSU slot (1–6). Checks a global firmware-update-in-progress flag in SHM (segment 0x27 offset 5) and the per-PSU FWUpdateState (SHM segment 7 per-PSU block at offset 0x1b6); refuses with 0xd1 if either indicates an update is already running. On success: calls PowerPSUFwupdate_IPCClient() to start the update, reads back the current FWUpdateStatus from SHM (segment 7 per-PSU offset 0x14a), writes updated status and power-state flag back to SHM, and returns the status byte.

Request

| Offset | Request field |
|----|----|
| 7 | data_length, must be exactly 3 (= 0x03); other lengths return 0xc7 (199). |
| 8 | data\[0\]): entity_id, must be 0x0a (PSU). |
| 9 | data\[1\]): PSU entity_instance (1-based), must be in \[1..6\] (validated as (data\[1\]-1) \< 6 unsigned); instance 0 fails the range check and returns 0xcc. |
| 10 | data\[2\]): update_flags — bit 0 = desired PSU power state during update (passed to PowerPSUFwupdate_IPCClient). |

Response

Completion code: 0x00=success, 0xc7 (199)=data_length != 3, 0xcc=entity_id != 0x0a or instance out of range, 0xd1=update already in progress (global flag != 0 or per-PSU FWUpdateState == 1). On success resp_len=1. resp_data\[0\]=FWUpdateStatus byte read from SHM before update is triggered (previous status). If the prior status was 0x00, it is overwritten in SHM with 0x01 (in-progress) before returning.

Backends `Dell_shm_memread(0x27, offset=5, size=1) — global PSU FW update state flag; Dell_shm_memread(7, offset=(instance-1)*0x330+0x1b6, size=1) — per-PSU FWUpdateState; PowerPSUFwupdate_IPCClient(psu_index, power_state) — IPC call to PSU firmware update daemon; Dell_shm_memread/write(7, offset=(instance-1)*0x330+0x14a, size=1) — per-PSU FWUpdateStatus; Dell_shm_memwrite(7, offset=(instance-1)*0x330+0x1bd, size=1) — per-PSU FWUpdatePowerState.`

**Security** — Admin-priv. Triggers PSU firmware update via IPC; firmware image source is managed by the IPC daemon (not in this handler). Writes to two SHM fields per-PSU. The instance range check (1..6) is correct and consistent with the FirmwareUpdateStatus handler. No path to supply an arbitrary firmware image path through this command. The update_flags bit 0 controls PSU power state during update, which could cause a brief PSU power interruption if abused.

### 6.79DellPwrPSUFirmwareUpdateStatus High

NetFn 0x30 · Cmd 0xb7Priv  · · · **A**libmisccmdconfidence: highlive ✓

Poll the firmware update status of a specific PSU slot by reading the FWUpdateStatus byte from shared memory (segment 7, per-PSU block at offset (instance-1)\*0x330 + 0x14a). Read-only; does not modify SHM or trigger any action.

Request

| Offset | Request field |
|----|----|
| 7 | data_length, must be exactly 2 (= 0x02). |
| 8 | data\[0\]): entity_id, must be 0x0a (PSU). |
| 9 | data\[1\]): PSU entity_instance — validated only as (data\[1\] \< 7), i.e. accepted values are 0–6. CAUTION: instance=0 is not rejected but produces SHM offset (0-1 & 0xff = 0xff = 255) \* 0x330 + 0x14a = 0x32DEA (208,362), which is almost certainly beyond the bounds of SHM segment 7 (a valid segment holds at most 6 \* 0x330 = 0x1380 bytes). Instance 0 is an off-by-one bug compared to DellPwrPSUFirmwareUpdate which rejects instance 0. |

Response

Completion code: 0x00=success, 0xc7 (199)=data_length != 2, 0xcc=entity_id != 0x0a or instance \>= 7. On success resp_len=1. resp_data\[0\]=FWUpdateStatus byte from SHM (interpretation: 0x00=idle/not started, 0x01=in-progress per FirmwareUpdate handler's write-back, other values implementation-defined).

Backends `Dell_shm_memread(7, offset=(instance-1 & 0xff)*0x330 + 0x14a, size=1) — per-PSU FWUpdateStatus.`

**Security** — Admin-priv. Off-by-one bug: instance=0 is accepted (bVar3 \< 7 check passes), yielding SHM segment 7 read at offset ~208 KB, far outside the expected per-PSU data area. This is an out-of-bounds SHM read that returns 1 byte of arbitrary SHM memory to an Admin caller. Impact is limited by the Admin privilege requirement but could leak SHM contents at a large offset if the SHM mapping is large enough to not fault.

### 6.80DellPwrCapEnable Medium

NetFn 0x30 · Cmd 0xbaPriv  · · · **A**libmisccmdconfidence: highlive ✓

Get or set the system power cap enable state. Gated by LC feature 0xb (power capping). Supports two operations selected by data\[0\]: op=0 sets the cap enable/disable state and active policy name in cfgdb; op=1 reads the current cap state and platform capability. On get (op=1), returns a bitmask of the current cap state and whether the platform supports user-settable power caps. On set (op=0), writes the new enable state to cfgdb and sets the ActivePolicyName to 'iDRAC' (enabled) or '' (disabled).

Request

| Offset | Request field |
|----|----|
| 7 | data_length, must be exactly 2 (= 0x02); other lengths or op \> 1 return 0xcc. |
| 8 | data\[0\]): operation — 0=set cap enable, 1=get cap status; values \> 1 are rejected (0xcc). |
| 9 | data\[1\]): for op=0 only — new state, bit 0 = enable (1) / disable (0) power cap. For op=1, data\[1\] is not used. |

Response

Completion code: 0x00=success, 0x6f=LC feature 0xb not licensed, 0xcc=data_length != 2 or op \> 1, 0xd5=platform does not support user power capping (UserPowerCapCapable==0, set op only), 0xff=cfgdb read or write failed. On success resp_len=1. resp_data\[0\] semantics: op=1 (get): bit0=PowerCapSetting current value, bit1=(UserPowerCapCapable != 0); op=0 (set): resp_data\[0\]=0xff (hardcoded success indicator).

Backends `lmCheckLcFeature(0xb) — power cap license; CfgGetAttributeInt('iDRAC.Embedded.1#PlatformCapability.1#UserPowerCapCapable') — platform cap capability flag; CfgGetAttributeInt('System.Embedded.1#ServerPwr.1#PowerCapSetting') — current cap on/off; CfgSetAttributeInt('System.Embedded.1#ServerPwr.1#PowerCapSetting', value, 0, requester_ctx) — persistent write; CfgSetAttribute('System.Embedded.1#ServerPwr.1#ActivePolicyName', 'iDRAC'|'', 0, 0) — persistent write.`

**Security** — Admin-priv with two persistent cfgdb writes on set. Disabling the power cap (op=0, data\[1\]=0x00) removes power consumption limits on the system. Setting ActivePolicyName is a cfgdb string write but uses only hardcoded strings ('iDRAC' or ''), so no injection risk. The get operation exposes whether the platform supports power capping and the current state, which is low-sensitivity.

### 6.81DellPwrHeadroom Medium

NetFn 0x30 · Cmd 0xbbPriv  · · · **A**libmisccmdconfidence: highlive ✓

Read instantaneous and peak power headroom (power budget remaining) from shared memory segment 6. Gated by LC feature 0xc. Not supported on modular (platform type 2) systems. Checks cfgdb key PowerBudgetCapable: if the platform is not power-budget-capable, returns all 0xFF (headroom undefined). Otherwise reads two uint16 values from SHM segment 6: instantaneous headroom at offset 2 and peak headroom at offset 0.

Request

req+7: data_length, must be exactly 0 (no data bytes); any non-zero value returns 0xc7 (199).

Response

| Offset | Response field |
|----|----|
| 0 | ..1\]=Instantaneous Headroom in watts (uint16 LE, from SHM segment 6 offset 2; 0xFFFF if not PowerBudgetCapable). |
| 2 | ..3\]=Peak Headroom in watts (uint16 LE, from SHM segment 6 offset 0; 0xFFFF if not PowerBudgetCapable). |

Backends `lmCheckLcFeature(0xc) — power monitoring license; get_platform_type() — platform type check (rejects type 2=modular/CMC); CfgGetAttributeInt('iDRAC.Embedded.1#PlatformCapability.1#PowerBudgetCapable') — capability flag; Dell_shm_memread(6, offset=2, size=2) — instantaneous headroom; Dell_shm_memread(6, offset=0, size=2) — peak headroom.`

**Security** — Admin-priv, read-only. No write path. Returns 0xFFFF (all-bits-set) when power budgeting is not supported rather than an error code, which is a benign but potentially surprising semantic. No attack surface beyond information disclosure of power headroom values.

### 6.82DellPwrEfficiency Medium

NetFn 0x30 · Cmd 0xc0Priv  · **U** O Alibmisccmdconfidence: medlive ✓

Sets the current power efficiency value in the iDRAC shared memory power subsystem (SHM ID=0x30, offset=0xbc13). Accepts an integer part (u16) and a decimal part (u16 in units of 1/10000), combines them into a 4-byte IEEE-754 float, and writes it to shared memory. The decimal part is capped at 9999 if \>= 10000; if \>= 10000 the value is divided by 10 before use.

Request

| Offset | Request field |
|----|----|
| 0 | high-nibble must equal 7 (internal message-format validity check; semantics of byte 0 in this handler's calling convention are undetermined). |
| 7 | 0x10 (data_len must be exactly 16 bytes). |
| 8 | 9\] = u16 LE digital/integer part of efficiency. |
| 10 | 11\] = u16 LE decimal part (0-9999 used as-is; \>=10000 divided by 10; result divided by 10000.0 to form the fractional part). |
| 12 | 15\] = not validated (undetermined). Min length: 16 data bytes. |

Response

CC=0x00 (success): resp_len=0 (no response data). CC=0xff: Dell_shm_memwrite failed. CC=0xc7 (decimal 199): message-format or length validation failed (req\[0\] high-nibble != 7 or data_len != 0x10).

Backends `Dell_shm_memwrite(SHM_ID=0x30, offset=0xbc13, 4 bytes) — stores power efficiency as a float in the power SHM segment`

**Security** — Write operation accessible at User privilege (lower than Admin). Overwrites a power efficiency float in shared memory which may influence power management and reporting. Unusual that a config-write is User-accessible; potential avenue for corrupting power metrics without Admin rights.

### 6.83DellPwrAverageInterval Medium

NetFn 0x30 · Cmd 0xccPriv  · · · **A**libmisccmdconfidence: lowlive ✓

Gets or sets the power averaging interval by proxying the request to the Power_Average_Interval_Client IPC service. The handler extracts the value at req\[7\] (likely the first data byte or data_len, used as an operation selector by the IPC service) and passes the remaining bytes starting at req\[8\] as the data buffer. The IPC client populates the response buffer directly.

Request

| Offset | Request field |
|----|----|
| 7 | operation selector passed as first arg to IPC (0=GET inferred, non-zero=SET inferred; exact semantics determined by Power_Average_Interval_Client). |
| 8 | +\] = data bytes forwarded to IPC service. Min length: undetermined (IPC-service-dependent). |

Response

CC = return code from Power_Average_Interval_Client IPC call. resp_len = value written by IPC into local_4c (initial max = 11 bytes). resp_data\[0..N\] = bytes written by IPC service into response buffer. Full response layout undetermined without IPC service source.

Backends `Power_Average_Interval_Client IPC service — full semantics undetermined from static analysis of this handler alone`

**Security** — Admin-only pass-through to an IPC service. If the IPC service does not re-validate length/content, crafted data bytes could be forwarded. Low confidence without IPC service source.

### 6.84DellPwrAverageRange Critical

NetFn 0x30 · Cmd 0xcdPriv  · · · **A**libmisccmdconfidence: medlive ✓

Returns the supported power averaging interval range (minimum interval and maximum range). Gated by Lifecycle Controller feature 0x0c. Returns either a fine-resolution minimum (5 seconds, if data\[1\]==0x01) or coarse-resolution minimum (30 seconds) along with a hardcoded maximum range constant (0x01038400 LE; bytes \[0x00, 0x84, 0x03, 0x01\]; likely encodes max range ~900 seconds in the 0x0384 subfield).

Request

| Offset | Request field |
|----|----|
| 7 | data_len, must be 0x02 (exactly 2 data bytes). |
| 8 | data\[0\]: not validated by the handler (undetermined). |
| 9 | data\[1\]: 0x01 = fine resolution (5 sec minimum), any other value = coarse resolution (30 sec minimum). Min length: 2 data bytes. |

Response

CC=0x6f: LC feature 0x0c not available (lmCheckLcFeature returned 0). CC=0xc7 (decimal 199): data_len != 0x02. CC=0x00 (success): resp_len=5. resp_data\[0\] = minimum interval in seconds: 0x05 (fine, data\[1\]==1) or 0x1e (coarse, default). resp_data\[1\]=0x00, resp_data\[2\]=0x84, resp_data\[3\]=0x03, resp_data\[4\]=0x01 (LE u32=0x01038400; likely max range constant; 0x0384=900 may encode max interval in seconds).

Backends `lmCheckLcFeature(0x0c) — Lifecycle Controller feature gate (no other backend dependencies; response is hardcoded constants)`

**Security** — Read-only capability enumeration. Admin-only. No config write, no credential exposure. Low risk.

## 7. Remote Enablement / Provisioning (0)

Auto-discovery, provisioning-server config, certificate sign/remove, DUP capability — zero-touch enrolment surface.

*No commands in this generation.*

## 8. SupportAssist / Diagnostics / ToolSet (0)

Diagnostic data collection, OS-collection, installer exposure, ToolSet exec/system-erase.

*No commands in this generation.*

## 9. Modular / Blade / CMC / KVM (26)

Blade/CMC chassis, IMC status registers, EDID injection, virtual KVM / virtual media status.

### 9.1CmdOEMEnableMsgChannelRecv Medium

NetFn 0x06 · Cmd 0x32Priv  · **U** O Alibmodularconfidence: highabsent

Enable or disable message-channel receive on a specified channel. System-interface (KCS/in-band) only; rejects channel 7 (CMC channel). Validates req data length == 2, then extracts channel_num from the low nibble of req\[8\]. Delegates to the standard default handler after those checks pass.

Request

| Offset | Request field                                         |
|--------|-------------------------------------------------------|
| 7      | 2 (fixed len; else CC=0xc7                            |
| 8      | bits\[3:0\]=channel_num (channel 7 rejected → CC=0xcc |

Response

From default handler; no additional data added by this wrapper

Backends `GetCommandDefaultHandleFunction (IPMI channel subsystem); IsMsgFromSystemInterface gate`

**Security** — Hard in-band gate: IsMsgFromSystemInterface checked first; returns CC=0xc1 if called from any non-system-interface channel. Channel 7 (CMC) explicitly rejected (CC=0xcc).

### 9.2CmdOEMGetChannelInfo Medium

NetFn 0x06 · Cmd 0x42Priv  · **U** O Alibmodularconfidence: highlive ✓

Get channel info with platform-specific DB9 serial-port capability fixup. Calls the default IPMI Get Channel Info handler; if the response medium-type byte is 0x05 (serial) and the platform generation is not gen-3, reads iDRAC.Embedded.1#PlatformCapability.1#SerialDB9PCapable; if that attribute is 0 (absent), zeroes the response length (suppresses the result) and the command returns CC=0xcc. Channel 7 returns CC=0xcc; channel num \>= 0x10 returns CC=0xcc.

Request

req\[8\]=channel_num (must be \< 0x10; channel 7 rejected)

Response

From default handler on the normal success path (CC=0). Response length zeroed and CC=0xcc when DB9 serial port not present and medium type==5.

Backends `GetCommandDefaultHandleFunction; CfgGetAttributeInt (iDRAC.Embedded.1#PlatformCapability.1#SerialDB9PCapable); Dell_get_generation`

**Security** — Platform capability attribute controls response content. No authentication beyond channel priv. No IsMsgFromSystemInterface gate.

### 9.3OEMCmdSetUserAccess Medium

NetFn 0x06 · Cmd 0x43Priv  · · · **A**libmodularconfidence: highlive ✓

OEM wrapper for IPMI Set User Access with CMC pre-processing. If from CMC channel (channel\>\>4==7): if req\[7\]==4, zeroes req\[11\] (session_limit field). Reads the target user record via aim DDS osi_function_getuserbyid, then writes it back via osi_function_setuser, then updates channel 1 access data via ChannelDataAccess (0x10f). On DDS success, falls through to the default IPMI Set User Access handler. On DDS failure, returns CC=0xff without calling the default handler. Non-CMC callers skip the DDS pre-processing and go directly to the default handler.

Request

This wrapper indexes req\[0\] (channel), req\[7\] (if ==4, zeroes req\[11\]), req\[9\] (low nibble used as user_id in the DDS pre-processing), and req\[11\]. Full Set User Access field semantics (channel_access_flags, user_id, priv_limit, session_limit) are the default-handler layout.

Response

From default handler (CC only) on the non-CMC path and the CMC-success path; CC=0xff on CMC DDS failure

Backends `aim_function_execute_DDS (osi_function_getuserbyid, osi_function_setuser); ChannelNumToChannelID; ChannelDataAccess; GetCommandDefaultHandleFunction`

**Security** — CMC path performs a read-modify-write of the user record via DDS before calling the default handler, allowing CMC to modify user access through a different code path than non-CMC callers. DDS failure aborts with CC=0xff. Gated on CMC channel, not an in-band gate.

### 9.4OEMCmdSetUserName Critical

NetFn 0x06 · Cmd 0x45Priv  · · · **A**libmodularconfidence: highlive ✓

OEM wrapper for IPMI Set User Name with CMC duplicate-name eviction. If from CMC channel (channel\>\>4==7): searches all users (UserInfoSearchByName over 0xf entries) for an existing entry matching the requested name at req\[9+\]. If a match is found whose id+1 differs from req\[8\]&0x3f: removes the name from both channel 1 and channel 2 user tables via ChannelDataAccess(0x201), resets channel 1 access via ChannelDataAccess(0x10f), zeroes the in-memory user record fields, then commits via osi_function_setuser. On success (or no duplicate found), falls through to default IPMI Set User Name handler. Non-CMC callers go directly to the default handler.

Request

| Offset | Request field |
|----|----|
| 0 | channel |
| 8 | bits\[5:0\]=target user_id, compared against found_id+1), and |
| 9 | +\] (username passed to UserInfoSearchByName). Full Set User Name payload (username field) is the default-handler layout. |

Response

From default handler (CC only); CC=0xff on CMC DDS failure

Backends `UserInfoSearchByName; aim_function_execute_DDS (osi_function_getuserbyid, osi_function_setuser); ChannelNumToChannelID; ChannelDataAccess (0x201 = clear name, 0x10f = reset access); GetCommandDefaultHandleFunction`

**Security** — CMC rename operation zeroes the existing user record fields before calling osi_function_setuser — any user whose name is being taken has their record cleared, stripping credentials and privileges. Side-channel for forced user eviction with CMC-channel IPMI access (not an in-band gate).

### 9.5CmdOEMSetUserPassword Critical

NetFn 0x06 · Cmd 0x47Priv  · · · **A**libmodularconfidence: highlive ✓

Set IPMI user password with CMC-channel compatibility shim. For CMC-channel requests (channel\>\>4==7) where: bit 7 of req\[8\] is clear (not explicitly 20-byte mode), bit 1 of req\[9\] is set (set-password operation), and req\[7\] \> 18 — scans the password bytes starting at req\[10\] for a null terminator. If a null is found before position 19, truncates req\[7\] to 18 (forces 16-byte password mode). If no null found through the full length, sets bit 7 of req\[8\] (20-byte mode flag). Then delegates to default IPMI Set User Password handler for all paths.

Request

This wrapper indexes req\[0\] (channel), req\[7\] (declared data length, may be rewritten to 0x12), req\[8\] (bit7=20byte_mode flag, may be OR'd with 0x80), req\[9\] (bit1 tested for set-pw op), and scans req\[10..\] for a null. The user_id/operation/password field semantics (Standard IPMI Set User Password: req\[8\] bits\[6:0\]=user_id, req\[9\] bits\[1:0\]=operation, req\[10..29\]=password) are the default-handler layout, only partially referenced here.

Response

From default handler (CC only)

Backends `GetCommandDefaultHandleFunction (IPMI user management)`

**Security** — CMC-channel requests with a null-containing 20-byte password are silently downgraded to 16-byte mode by truncating the declared length, changing password semantics without caller awareness. This is a compatibility shim, not a security control. No IsMsgFromSystemInterface gate.

### 9.6CmdOEMReadFRUData Medium

NetFn 0x0a · Cmd 0x11Priv  · **U** O Alibmodularconfidence: highlive ✓

Read FRU device data. Enforces a maximum count of 200 bytes (CC=0xc9 if req\[11\] \>= 0xc9). For requests arriving via channel 7 (CMC) or from a WCS iDRAC type (Dell_get_idrac_type()==3), returns CC=0 with an empty response immediately, bypassing the FRU storage layer. All other callers are forwarded to the default IPMI Read FRU Data handler.

Request

| Offset | Request field |
|----|----|
| 11 | count_to_read (must be \< 0xc9=201; else CC=0xc9) and |
| 0 | channel) are the only bytes this wrapper indexes. fru_device_id and read_offset (Standard IPMI Read FRU Data |
| 9 | ..10\]) are not parsed here — undetermined from this handler, consumed by the default handler. |

Response

CC=0 + empty data (resp len 0) for CMC/WCS path; from default handler for the normal path

Backends `GetCommandDefaultHandleFunction (IPMI FRU storage); get_system_identification; Dell_get_idrac_type`

**Security** — CMC-channel path silently returns empty success without touching FRU storage. WCS iDRAC type also takes this shortcut. No IsMsgFromSystemInterface gate.

### 9.7CmdOEMGetSELEntry Medium

NetFn 0x0a · Cmd 0x43Priv  · **U** O Alibmodularconfidence: highlive ✓

Get a SEL (System Event Log) entry. Thin wrapper: if the request arrives via channel 7 (CMC), clears IMC previous-status bit 0x08 (bit 3) before delegating to the default IPMI Get SEL Entry handler.

Request

This wrapper only indexes req\[0\] (channel; \>\>4==7 selects the CMC side-effect) and req\[3\]/req\[6\] (netfn/cmd). The record/offset payload layout (Standard IPMI Get SEL Entry: reservation_id, record_id, offset, bytes-to-read) is not parsed here — undetermined from this handler, consumed by the default handler.

Response

From default handler (next_record_id + SEL record); not shaped by this wrapper

Backends `GetCommandDefaultHandleFunction (IPMI SEL); DellClearIMCPrevStatusBit`

**Security** — CMC-channel access has the side effect of clearing IMC status bit 3 (event-pending flag). No additional restriction.

### 9.8CmdOEMSetSELTime Medium

NetFn 0x0a · Cmd 0x49Priv  · · **O** Alibmodularconfidence: highlive ✓

Set the SEL clock timestamp. Thin wrapper: if the request is from channel 7 (CMC), clears IMC previous-status bit 0x2000000 (bit 25) before delegating to the default IPMI Set SEL Time handler.

Request

This wrapper only indexes req\[0\] (channel; \>\>4==7 selects the CMC side-effect) and req\[3\]/req\[6\]. The 4-byte timestamp payload (Standard IPMI Set SEL Time) is not parsed here — undetermined from this handler, consumed by the default handler.

Response

From default handler (CC only)

Backends `GetCommandDefaultHandleFunction (IPMI SEL); DellClearIMCPrevStatusBit`

**Security** — Clears an IMC status flag on CMC-channel SEL time writes as a side effect.

### 9.9DellCmdGetBladeSlotId Medium

NetFn 0x30 · Cmd 0x18Priv  · · · **A**libmodularconfidence: highlive ✓

Return the physical blade slot number. Rejects requests on channel 5 and channel 3 (CC=0xc1). req\[7\] must == 0 (else CC=0xc7). Calls GetBladeSlotNumber, masks the result to 6 bits \[5:0\], and sets bit 7 if is_system_modular_sled() returns non-zero (indicating a sled form factor). Returns the resulting single byte. On GetBladeSlotNumber failure → CC=0xff.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=1 (length); resp_data\[0\]=slot_id (bits\[5:0\]=slot_number, bit\[7\]=1 if modular sled)

Backends `GetBladeSlotNumber; is_system_modular_sled; ChannelHandleToChannelID; ChannelIDToChannelNum`

**Security** — Channel 3 and channel 5 are rejected (CC=0xc1); this is a channel-number filter, not an IsMsgFromSystemInterface gate.

### 9.10DellCmdGetHostEventStatus Medium

NetFn 0x30 · Cmd 0x51Priv  · · · **A**libmodularconfidence: mediumlive ✓

Return host power/event status. req\[7\] must == 0 (else CC=0xc7). Calls GetHostStatus passing the raw host-status buffer and a boolean indicating whether the request is from channel 7 (CMC). On success: writes the 5-byte status into the response and clears IMC previous-status bit 0x10 (bit 4). On GetHostStatus failure, returns CC=0xff.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=5 (length); resp_data\[0..1\]=status_word (2B); resp_data\[2\]=extended_status; resp_data\[3\]=event_flags (OR of two status bytes); resp_data\[4\]=0

Backends `GetHostStatus (host-event subsystem IPC); DellClearIMCPrevStatusBit`

**Security** — No channel restriction; the channel-7 boolean is passed through to GetHostStatus but does not gate access.

### 9.11DellCmdVKVMStatus Medium

NetFn 0x30 · Cmd 0x8dPriv  · · · **A**libmodularconfidence: highabsent

Report virtual KVM session status to the CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 0 (else CC=0xc7). Lazily reads the max KVM session count from aim config key rp_int_max_kvm_sessions on first call (cached in DAT_00137c02/04). Clears IMC status bit 0x80. Returns: max_sessions (0 if config unavailable), active_session_count (from G_u8KVMSessionsActive), and 2 zero pad bytes.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=4 (length); resp_data\[0\]=max_kvm_sessions; resp_data\[1\]=active_sessions; resp_data\[2..3\]=0

Backends `aim_config_get_int (rp_int_max_kvm_sessions); G_u8KVMSessionsActive global; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 9.12DellCmdVMediaStatus Medium

NetFn 0x30 · Cmd 0x8ePriv  · · · **A**libmodularconfidence: highabsent

Report virtual media attach and RFS session status to the CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 0 (else CC=0xc7). Clears IMC status bit 0x100. Reads the virtual media attach state integer from aim config key rm_int_attach_state (CC=0xff if the read fails). Constructs a 2-byte flags word: 0x0101 (local+remote slots present) when attach_state is 1 or 2, otherwise 0x0000; if G_u8RfsSession is non-zero, ORs 0x03 into byte\[0\] (marks RFS active). Returns flags + 2 zero bytes.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=4 (length); resp_data\[0..1\]=media_flags (0x0101 if attach_state in {1,2}, else 0x0000; byte0 OR'd with 0x03 if RFS session active); resp_data\[2..3\]=0

Backends `aim_config_get_int (rm_int_attach_state); G_u8RfsSession global; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 9.13DellCmdGetIMCStatusRegister High

NetFn 0x30 · Cmd 0x90Priv  · · · **A**libmodularconfidence: highabsent

Read the 64-bit IMC inter-controller status register. Modular platform only (platform_type==2). req\[7\] must == 0 (else CC=0xc7). Acquires a semaphore (100ms timeout; CC=0xc3 on timeout). Returns the current 48-bit status value (6B) and the 48-bit previous-status value (6B). If bit 0 (IMC-ready) of current status is set, creates /tmp/imcready_read. If request is from CMC channel (channel\>\>4==7): atomically clears the current status register (sets to 0) and ORs the cleared value into previous-status before releasing the semaphore.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=0x0e (length 14); resp_data\[0..5\]=current_status_48bit_LE; resp_data\[6..11\]=prev_status_48bit_LE; resp_data\[12..13\]=0

Backends `_lx_SemaphoreGet/Put (G_txModularImcRegisterSemaphore); S_u64IMCStatusValue; S_u64IMCPreviousStatusValue; fopen64 (/tmp/imcready_read); get_platform_type`

**Security** — CMC-channel read is destructive: atomically consumes (clears) the current status register in one semaphore-protected operation. A non-CMC Admin caller can read status without consuming it. Modular-platform gate (platform_type==2), not an in-band gate.

### 9.14DellCmdIMCFirmwareUpdate High

NetFn 0x30 · Cmd 0x91Priv  · · · **A**libmodularconfidence: highlive ✓

Firmware update notification stub from CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 0x25 (37 bytes present; else CC=0xc7). The 37 data bytes are accepted but not processed by this handler — returns CC=0 immediately. Actual firmware update logic is expected to be triggered elsewhere.

Request

req\[7\]=0x25 (37B present, content ignored by this handler; else CC=0xc7)

Response

resp\[0\]=0 (empty), CC=0

Backends `none`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate. Stub — accepts 37 opaque bytes from CMC with no parsing or validation.

### 9.15DellCmdEDIDInfo Medium

NetFn 0x30 · Cmd 0x92Priv  · · · **A**libmodularconfidence: highlive ✓

Deliver EDID (Extended Display Identification Data) for the local KVM display from the CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). EDID is stored only when req\[7\] != 0 AND req\[8\] != 0 AND req\[7\] == 0x81 (else CC=0xc7); when req\[8\]==0 the command is a no-op that just clears IMC status bit 0x800 and returns CC=0. On the storage path it validates a single-byte checksum: CalcChecksum over req\[9..0x87\] (127 bytes) must equal req\[0x88\] (else CC=0xcc); on success it clears then copies the EDID block into the G_sEDIDLKVM in-memory struct and fires SetGPTaskEvent to notify the VKVM subsystem, then clears IMC status bit 0x800.

Request

req\[7\]=0x81 (required for storage); req\[8\]!=0 (required for storage; req\[8\]==0 is a no-op ack); req\[9..0x87\]=EDID data (127B); req\[0x88\]=checksum byte

Response

resp\[0\]=0 (empty), CC=0 on success

Backends `CalcChecksum; SetGPTaskEvent (S_u32EDIDEventID); G_sEDIDLKVM global struct; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate. EDID payload is checksum-validated (127-byte checksum at req\[0x88\]) before storing; a pre-computed valid-checksum payload could inject arbitrary display configuration into the KVM subsystem.

### 9.16DellCmdLCDReadFromStaging Medium

NetFn 0x30 · Cmd 0x93Priv  · **U** O Alibmodularconfidence: highlive ✓

Read an LCD display message from the blade LCD staging buffer (pre-queue). CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 1 (else CC=0xc7). req\[8\]==1: special message from staging (DellAppGetSpecialMessageFromStaging); req\[8\]==0: SEL/SDR pair from staging (DellAppGetSelSdrPairFromStaging); other → CC=0xc9. Clears IMC status bit 0x1000 after read.

Request

| Offset | Request field |
|----|----|
| 7 | 1 (else CC=0xc7 |
| 8 | msg_type (0=SEL/SDR pair from staging, 1=special message from staging; other → CC=0xc9 |

Response

resp\[0\]=msg_len+1 (length); resp_data\[0\]=msg_len; resp_data\[1..N\]=message_bytes. CC=0xff on backend failure.

Backends `DellAppGetSpecialMessageFromStaging; DellAppGetSelSdrPairFromStaging; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 9.17DellCmdLCDReadFromQueue Medium

NetFn 0x30 · Cmd 0x94Priv  · **U** O Alibmodularconfidence: highlive ✓

Read the next LCD display message from the blade LCD message queue. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 2 (else CC=0xc7). req\[8\]==1: special message (DellAppGetSpecialMessage with index req\[9\]). req\[8\]==0: SEL/SDR pair — DellAppGetSelSdrPair() if RSM not supported, else DellAppGetSelSdrPair_CMC with index req\[9\]. Other req\[8\] → CC=0xc9. Clears IMC status bit 0x1000 after the read.

Request

| Offset | Request field                                                |
|--------|--------------------------------------------------------------|
| 7      | 2 (else CC=0xc7                                              |
| 8      | msg_type (0=SEL/SDR pair, 1=special message; other → CC=0xc9 |
| 9      | message_index                                                |

Response

resp\[0\]=msg_len+1 (length); resp_data\[0\]=msg_len; resp_data\[1..N\]=message_bytes. CC=0xff on backend failure.

Backends `DellAppGetSpecialMessage; DellAppGetSelSdrPair; DellAppGetSelSdrPair_CMC; Is_RSM_Supported; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 9.18DellCmdLoginAccess Critical

NetFn 0x30 · Cmd 0x96Priv  · · · **A**libmodularconfidence: mediumlive ✓

Authenticate a user by username and 20-byte credential hash on behalf of the CMC. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 0x24 (36B; else CC=0xc7). Looks up the user by name at req\[8+\] via UserInfoSearchByName, then retrieves the full user record via aim DDS function osi_function_getuserbyid. Performs a 20-byte MemCmp of req\[0x18..0x2b\] against the credential field at offset 64 in the user record buffer. On match: extracts 4 privilege nibbles from the user record and returns them. On any failure: CC=0xff.

Request

| Offset | Request field                                                |
|--------|--------------------------------------------------------------|
| 7      | 0x24 (else CC=0xc7                                           |
| 8      | ..0x17\]=username (16B field, passed to UserInfoSearchByName |
| 0x18   | ..0x2b\]=20-byte credential (compared via MemCmp             |

Response

resp\[0\]=5 (length); resp_data\[0..3\]=privilege_nibbles (low nibble of each of 4 record bytes, LS byte first); resp_data\[4\]=0

Backends `UserInfoSearchByName; aim_function_execute_DDS (osi_function_getuserbyid); MemCmp`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate. Non-constant-time 20-byte MemCmp of credential hash — timing side-channel potential. Any CMC session can verify arbitrary user credentials; on success, leaks per-channel privilege levels. The credential field at user_record+64 is consistent with the iDRAC9 user-table hash offset.

### 9.19DellCmdSetIMCStatusRegister Medium

NetFn 0x30 · Cmd 0x97Priv  · · · **A**libmodularconfidence: highlive ✓

Set or clear a single bit in the 48-bit IMC inter-controller status register. Validates that at most 1 bit is set in the 6-byte bitmask at req\[9..14\] (popcount over 48 bits; CC=0xc7 if \> 1 bit set). Modular platform only (platform_type==2; else CC=0xc1). req\[7\] must == 9 (else CC=0xc7). req\[8\]=0: calls DellSetIMCStatusBit with the 48-bit mask value (CC=0xc3 on failure). req\[8\]=1: acquires the IMC register semaphore, ANDs the inverse mask out of both S_u64IMCStatusValue and S_u64IMCPreviousStatusValue, then releases the semaphore. req\[8\]==other → CC=0xcc.

Request

| Offset | Request field                                                |
|--------|--------------------------------------------------------------|
| 7      | 9 (else CC=0xc7                                              |
| 8      | operation (0=set bit, 1=clear bit; other → CC=0xcc           |
| 9      | ..14\]=48-bit bitmask (6B LE, at most 1 bit set else CC=0xc7 |

Response

resp\[0\]=0 (empty), CC=0 on success

Backends `DellSetIMCStatusBit; _lx_SemaphoreGet/Put (G_txModularImcRegisterSemaphore); S_u64IMCStatusValue; S_u64IMCPreviousStatusValue; get_platform_type`

**Security** — Any Admin IPMI caller (no channel/in-band restriction) can set or clear individual bits in the shared IMC status register used for inter-controller signalling. One-bit-at-a-time enforcement is a safety guard, not a security control.

### 9.20DellCmdLEDStatus Medium

NetFn 0x30 · Cmd 0x98Priv  · · · **A**libmodularconfidence: highlive ✓

Return the current blade front-panel LED status. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 2 (else CC=0xc7; the 2 data bytes are not examined). Calls the D-Bus method com.dell.bmc.fplcd / ModularGetLEDStatus with a 1-second timeout. Returns the single LED status byte on success; CC=0xff on D-Bus error.

Request

req\[7\]=2 (data content ignored; else CC=0xc7)

Response

resp\[0\]=1 (length); resp_data\[0\]=led_status_byte

Backends `D-Bus: service=com.dell.bmc.fplcd, path=/com/dell/bmc/fplcd, method=ModularGetLEDStatus (1s timeout)`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 9.21DellCmdGetLastPostCode Medium

NetFn 0x30 · Cmd 0x99Priv  · · · **A**libmodularconfidence: highlive ✓

Return the last BIOS POST code and its descriptive string. req\[7\] must == 0 (else CC=0xc7). Reads the POST code from iDRAC.Embedded.1#PrivateStore.1#LastPostCode via configdb (CC=0xff on failure). Calls DellGetPOSTCodeInfo to look up a human-readable description. Returns the numeric code byte, the string length, and the string (max 198 bytes via strlcpy). If DellGetPOSTCodeInfo returns non-zero, returns only the code byte with zero string length.

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=strlen+2 (length); resp_data\[0\]=post_code_byte; resp_data\[1\]=str_len; resp_data\[2..N\]=description_string (max 198B). On DellGetPOSTCodeInfo failure: resp_data\[0\]=code, resp_data\[1\]=0, length=2.

Backends `CfgGetAttributeInt (iDRAC.Embedded.1#PrivateStore.1#LastPostCode); DellGetPOSTCodeInfo`

### 9.22DellCmdMemThrottlingCtrl Medium

NetFn 0x30 · Cmd 0x9aPriv  · · · **A**libmodularconfidence: highlive ✓

Memory throttle control acknowledgement stub. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 3 (else CC=0xc7); req\[8\]=throttle_pct (must be \< 101; CC=0xcc if \>= 101). Validates the throttle percentage range and returns a 2-byte zero payload. No actual throttle control logic is visible in this handler — acknowledgement only.

Request

| Offset | Request field                              |
|--------|--------------------------------------------|
| 7      | 3 (else CC=0xc7                            |
| 8      | throttle_percent (0..100; \>=101 → CC=0xcc |

Response

resp\[0\]=2 (length); resp_data\[0..1\]=0x0000

Backends `none`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an in-band gate.

### 9.23DellCmdIMCFeatureSupport Medium

NetFn 0x30 · Cmd 0xbdPriv  · · · **A**libmodularconfidence: highlive ✓

Report iDRAC (IMC) feature capabilities to the CMC. req\[7\] must == 0 (else CC=0xc7). Reads platform type, server generation (iDRAC.Embedded.1#Info.1#ServerGen; CC=0xff on read failure), iDRAC type, and system ID. Builds a 6-byte feature response: a 16-bit feature-flags word (base 0x8aff, or 0x92ff when is_system_modular_stomp; bit 14 (0x4000) is SET by default and CLEARED when IsDellPCIereassingsupport; bit 13 (0x2000) is SET by default and CLEARED when IsDellStashsupported); a system-ID character (system_id + '@'); and a generation+type code (e.g. 0x41=gen4 modular, 0x42=gen4 rack idrac-type2, 0x52=gen5 rack idrac-type2, 0x30/0x40/0x50/0x60=rack non-type2, 0x31/0x51/0x61=modular).

Request

req\[7\]=0 (no data; else CC=0xc7)

Response

resp\[0\]=6 (length); resp_data\[0..1\]=feature_flags_LE (16-bit); resp_data\[2..3\]=0 (high half of the 32-bit write); resp_data\[4\]=sysid_char (system_id+'@'); resp_data\[5\]=gen_type_byte

Backends `CfgGetAttributeInt (iDRAC.Embedded.1#Info.1#ServerGen); get_platform_type; get_system_identification; Dell_get_idrac_type; IsDellPCIereassingsupport; IsDellStashsupported; is_system_modular_stomp`

**Security** — Leaks server generation, iDRAC type, platform type, and an encoded system-ID character to any Admin IPMI caller.

### 9.24DellCmdCMCFeatureSupport Medium

NetFn 0x30 · Cmd 0xc3Priv  · **U** O Alibmodularconfidence: highlive ✓

Accept the CMC feature-support capability bitmap from the chassis management controller. CMC-channel only (channel\>\>4==7; else CC=0xc1). req\[7\] must == 8 (else CC=0xc7). Stores all 8 request data bytes into G_au8CMCFeatureSupport global. If chassis type is 10 (blade enclosure), reads two shared-memory flags (offsets 0x1cb and 0x1cc from region 0x27); if the CMC-ready flag (bit 2 of feature byte 0) is set and both shm flags are non-zero, clears then sets IMC status bit 0x20 (power-on request).

Request

| Offset | Request field                            |
|--------|------------------------------------------|
| 7      | 8 (fixed len; else CC=0xc7               |
| 8      | ..15\]=8-byte CMC feature support bitmap |

Response

resp\[0\]=0 (empty), CC=0 on success

Backends `G_au8CMCFeatureSupport global; CfgGetAttributeInt (System.Embedded.1#ChassisInfo.1#ChassisType); Dell_shm_memread (region 0x27, offsets 0x1cb, 0x1cc); DellSetIMCStatusBit; DellClearIMCPrevStatusBit`

**Security** — Gated on CMC channel (channel\>\>4==7), NOT an IsMsgFromSystemInterface/in-band gate. CMC can overwrite the 8-byte feature bitmap without content validation.

### 9.25DellCmdBladeVirtualMAC Medium

NetFn 0x30 · Cmd 0xc9Priv  · · · **A**libmodularconfidence: highlive ✓

Get or set the blade's virtual (flex-address) MAC. req\[8\]==1 (get): returns a 31-byte response containing G_au8FlexAddressMAC (6B) and G_au8DefaultMAC (6B) after a leading zero pad byte. req\[8\]==0 (set): requires req\[7\]==32 and IMC state (G_u8IMCState)==2; builds a MAC string from req\[10..15\], compares it against the current iDRAC.Embedded.1#NIC.1#Flexmacaddress cfg attribute; if different, updates the cfg attribute, creates /tmp/flexaddress sentinel, sets IMC status bit 1. If IMC state==1, checks D9net init and fires a GP task event. Creates /tmp/imcpreready_compl on entry to the set path. req\[8\]==other → CC=0xcc.

Request

| Offset | Request field                    |
|--------|----------------------------------|
| 8      | operation (0=set, 1=get          |
| 7      | 32 for set (else CC=0xc7         |
| 10     | ..15\]=MAC address (6B, set only |

Response

get: resp\[0\]=0x1f (length 31); resp_data\[0\]=0 (pad); resp_data\[1..6\]=flex_MAC; resp_data\[7..12\]=default_MAC; resp_data\[13..30\]=0. set: resp\[0\]=0 (empty), CC=0.

Backends `CfgGetAttribute/CfgSetAttribute (iDRAC.Embedded.1#NIC.1#Flexmacaddress); fopen64 (/tmp/imcpreready_compl, /tmp/flexaddress); SetGPTaskEvent; DellSetIMCStatusBit; DellBladeCheckD9netInitState`

**Security** — Set path creates /tmp sentinel files and updates a persistent cfg attribute. No CMC-channel or in-band restriction: any Admin IPMI caller can overwrite the blade NIC flex MAC address.

### 9.26DellCmdBladeChassisInfo High

NetFn 0x30 · Cmd 0xcbPriv  · · · **A**libmodularconfidence: highlive ✓

Multi-purpose chassis metadata get/set command used for CMC-to-iDRAC information exchange. Requires req\[7\] \>= 6 (else CC=0xc7). Dispatches on req\[8\]=direction (0=write, 1=read, 2=CMC-write) and req\[9\]=data_type. count = MakeUINT16(req\[11\],req\[10\]) (req\[10..11\] LE); offset = MakeUINT16(req\[13\],req\[12\]) (req\[12..13\] LE); data at req\[14+\]. Supported types: 0=IOM slot info (offset+count\<0x10 to/from G_au8ChassisInfo_IomInfo global); 7=chassis model string (write bounded: req\[14\] length byte must be \<=0x86, triggers CfgSetAttribute + shm 0x19 offset 0); 8=dynamic IOM data (shm 0x19 offset 0x80, offset+count\<0x83); 9=CMC network deploy blob (dir 0 write region 0x23, dir 2 write region 0x22, dir 1 read region 0x23 if CMC-channel else 0x22 — NO offset+count bounds check before memcpy to 0x137ca0+offset); 10=PCIe peripheral info (shm 0x19 offset 0x104, offset+count\<0x61); 11=CMC misc features (RSM setting\<3, redundancy policy\<5, redundancy state\<3; shm 0x19 offset 0x164, offset+count\<0x21; notify powerd). Read paths mirror the write paths from the same shared memory regions.

Request

| Offset | Request field                         |
|--------|---------------------------------------|
| 7      | \>=6 (else CC=0xc7                    |
| 8      | direction (0=write,1=read,2=CMC-write |
| 9      | data_type (0,7,8,9,10,11              |
| 10     | ..11\]=count (2B LE                   |
| 12     | ..13\]=offset (2B LE                  |
| 14     | +\]=data (for writes                  |

Response

Writes: resp_data\[0\]=data_type, resp_data\[1..4\]=0, resp\[0\]=5 (length). Reads: resp_data\[0\]=type, resp_data\[1..2\]=count_LE, resp_data\[3..4\]=offset_LE, resp_data\[5+\]=data, resp\[0\]=count+5 (length).

Backends `Dell_shm_memread/Dell_shm_memwrite (regions 0x19, 0x22, 0x23); CfgSetAttribute (System.Embedded.1#ChassisInfo.1#ChassisModel); DellSetIMCStatusBit; DellClearIMCPrevStatusBit; DellNotifyRedundancyState_IPCClient; MakeUINT16/GetLSB16/GetMSB16`

**Security** — Type 9 (CMC network deploy) write performs an unchecked memcpy(0x137ca0+offset, req+14, count) before Dell_shm_memwrite — no offset+count bounds guard, unlike types 0/7/8/10/11 which all range-check. Any Admin caller can corrupt the global buffer at 0x137ca0 with attacker-controlled offset and length. Chassis model write bounded at 134 bytes. No IsMsgFromSystemInterface gate (the channel\>\>4==7 test on the type-9 read path only selects region 0x23 vs 0x22, not a restriction).

## 10. Chassis / Front Panel / LCD (8)

Chassis capabilities/status/identify, front-panel and LCD read/write, LED status.

### 10.1CmdOEMGetChassisCapabilities Medium

NetFn 0x00 · Cmd 0x00Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Return chassis capability flags. Delegates to the standard IPMI Get Chassis Capabilities handler via GetCommandDefaultHandleFunction. On modular chassis (is_system_modular != 0), clears bit 0 of the first response byte (disables intrusion/physical-security capability flag).

Request

No request data. req+7=0.

Response

| Offset | Response field |
|----|----|
| 0 | capabilities byte (bit 0 cleared on modular |
| 1 | chassis FRU info device address |
| 2 | SDR device address |
| 3 | SEL device address |
| 4 | system management device address. resp_len set by underlying handler (typically 5 bytes). |

Backends `GetCommandDefaultHandleFunction (routes to standard chassis caps handler). is_system_modular (checks chassis type).`

### 10.2DellCmdGetChassisStatus Medium

NetFn 0x00 · Cmd 0x01Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Return chassis power/fault status augmented with Dell front-panel data. Delegates to the standard Get Chassis Status handler, then ORs the result with: AC restore state (from cfgdb attribute ACRestoreState, shifted to bits 5:4 of resp\[0\]), current power status (ChassisGetPowerStatus), front-panel option flags, and identify/intrusion bits from SHM (segment 0x0c, offset 0x132f).

Request

No request data.

Response

| Offset | Response field                                                  |
|--------|-----------------------------------------------------------------|
| 0      | power_status\|((ACRestoreState&3)\<\<5)\|ChassisGetPowerStatus. |
| 1      | last_power_event (from standard handler).                       |
| 2      | standard_misc_flags)\|0x40\|identify_active_bit.                |
| 3      | G_u8FrontPanelOpt (global front-panel options byte).            |

Backends `GetCommandDefaultHandleFunction (standard chassis status). CfgGetAttributeInt(iDRAC.Embedded.1#PrivateStore.1#ACRestoreState). ChassisGetPowerStatus. Dell_shm_memread(seg=0x0c, offset=0x132f, len=4). G_u8FrontPanelOpt global.`

### 10.3CmdOEMChassisIdentify Medium

NetFn 0x00 · Cmd 0x04Priv  · · **O** Aliboemcmdsconfidence: highlive ✓

Trigger chassis identify LED blink via D-Bus. Thin wrapper around DellCmdChassisIdentify which calls com.dell.bmc.fplcd ChassisIdentify. Supports timed (default 15 s), interval, and forced-on modes.

Request

req+7=data length; must not exceed 2, else CC 0xc7. Three valid lengths: req+7=0 → start 15-second identify with force=off (interval hardcoded 0x0f). req+7=1 → interval=req+8, force=off. req+7=2 → req+8=interval_seconds, req+9=force_identify (0=timed, 1=force on); req+9 \>1 → CC 0xcc.

Response

No response data (resp_len=0). Returns CC 0x00 on success.

Backends `D-Bus: com.dell.bmc.fplcd /com/dell/bmc/fplcd method ChassisIdentify (timeout 1 s per call, 2 s bus timeout). sd_bus_default_system.`

### 10.4CmdOEMSetChassisCapabilities Medium

NetFn 0x00 · Cmd 0x05Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Set chassis capability flags. On modular chassis, rejects any write that has bit 0 of the capabilities byte set (feature not supported on modular). Otherwise delegates to the standard CmdSetChassisCapabilities handler.

Request

req+8=capabilities_flags byte. Bit 0 = intrusion sensor present. If is_system_modular and req+8 bit 0 set → CC 0xcc (parameter out of range).

Response

No response data on success (resp_len=0, CC 0x00). CC 0xcc if modular+bit0 set.

Backends `CmdSetChassisCapabilities (standard handler, imported). is_system_modular.`

### 10.5DellCmdSetFrntPanelState Medium

NetFn 0x00 · Cmd 0x0aPriv  · **U** O Aliboemcmdsconfidence: highlive ✓

Enable or disable the physical power button on the front panel. Reads FPButtonCapability from cfgdb to determine which button bits are changeable. If bit 0 of the new state differs from current and is within capability, updates G_u8FrontPanelOpt, calls setPowerbuttonMask to apply to hardware, and persists FPButtonStatus via cfgdb.

Request

| Offset | Request field |
|----|----|
| 7 | must equal 1 (exactly 1 data byte), else CC 0xc7. |
| 8 | state_byte: bit 0 = power button enable (1=enabled, 0=disabled). Bits that exceed FPButtonCapability mask → CC 0xcc. |

Response

No response data (CC 0x00 on success).

Backends `CfgGetAttributeInt(iDRAC.Embedded.1#PrivateStore.1#FPButtonCapability). CfgSetAttributeInt(iDRAC.Embedded.1#PrivateStore.1#FPButtonStatus). getPowerbuttonMask / setPowerbuttonMask. G_u8FrontPanelOpt global.`

### 10.6DellCmdReadWriteFrontPanel Medium

NetFn 0x30 · Cmd 0x1cPriv  · · · **A**liboemcmdsconfidence: highlive ✓

Arbitrary front-panel register read/write via the fplcd D-Bus service. Passes the entire request data blob (req+8, req+7 bytes) directly to com.dell.bmc.fplcd CmdReadWriteFrontPanel and returns the D-Bus response verbatim. No local validation of register addresses or data values.

Request

req+7=length of data. req+8..req+8+len-1=opaque command blob forwarded to fplcd. Internal structure is fplcd-service-defined (sub-opcode, register address, value).

Response

Variable; resp_len=\*local_60 (first 4-byte word from D-Bus reply is length), resp data=remainder. CC 0x00 on success. CC 0xcc (-0x34) if param_3 null. CC 0xce (-0x32) if D-Bus returns null reply.

Backends `D-Bus: com.dell.bmc.fplcd /com/dell/bmc/fplcd method CmdReadWriteFrontPanel (1 s timeout). C_com_dell_bmc_fplcd_CmdReadWriteFrontPanel_func (D-Bus client wrapper, imported).`

**Security** — Admin-only no-validation proxy: any caller with Admin privilege can issue arbitrary front-panel register read/write operations without address or data validation in this handler. Security depends entirely on the fplcd service.

### 10.7DellQueryChassisIdentifyStatus Medium

NetFn 0x30 · Cmd 0x32Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Query whether chassis identification mode (flashing LEDs or audible alert) is currently active. Reads the IdentifyModeOn boolean property from the front-panel LCD D-Bus service and returns it as a single byte. On D-Bus failure, returns 0 (identify off) with a success completion code—failures are masked.

Request

No request data fields consumed (no length or field checks in handler). Min total req data bytes = 0.

Response

Always CC 0x00. resp_len = 1. resp\[0\] = IdentifyModeOn property value: non-zero if chassis identify is active, 0 if inactive or if the D-Bus call failed.

Backends `D-Bus property fplcd_get_property('/com/dell/bmc/fplcd', 'IdentifyModeOn'); fplcd daemon.`

**Security** — User-accessible, read-only. Low security impact: reveals only chassis LED/identify state. D-Bus failures silently return 0, so callers cannot distinguish 'identify off' from 'fplcd daemon dead'—could mask a DoS against the fplcd service.

### 10.8DellCmdGetFrontPanelInfo Medium

NetFn 0x30 · Cmd 0xb5Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Retrieve front-panel display information (LCD text, status indicators) from the fplcd D-Bus service. Forwards the request data blob to com.dell.bmc.fplcd CmdGetFrontPanelInfo and returns the D-Bus response verbatim.

Request

req+7=length of data. req+8..req+8+len-1=opaque query blob forwarded to fplcd.

Response

Variable; resp_len=\*local_60 (first 4-byte word from D-Bus reply), resp data=remainder. CC 0x00. CC 0xcc if param_3 null. CC 0xce if D-Bus null reply.

Backends `D-Bus: com.dell.bmc.fplcd /com/dell/bmc/fplcd method CmdGetFrontPanelInfo (1 s timeout). C_com_dell_bmc_fplcd_CmdGetFrontPanelInfo_func (imported).`

## 11. Serial / Terminal (6)

Serial-channel terminal-mode passthrough, serial/modem and SOL configuration.

### 11.1DellCmdSetSerModemConfigParam Medium

NetFn 0x0c · Cmd 0x10Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Set serial/modem configuration parameters with platform and baud-rate validation. Blocks on modular chassis (platform_type=2) unless the channel handle is '@' (0x40, internal). For baud-rate parameter (param_sel=7), restricts allowed values to \[6..10\] excluding 8. For connection-mode parameter (param_sel=0x33) with LCP option patterns 0xc021 or 0x4221 (PPP negotiation), also re-runs the command against the SOL channel if SOL is active, and calls SerialMuxSetMuxPositionInternal to switch the serial multiplexer.

Request

Modular block: on platform_type==2 the command is rejected (CC 0xc1) UNLESS the arriving channel-handle byte at req+0 == '@' (0x40) — the bypass byte is req+0, NOT req+8. req+8=channel-parameter data byte (data\[0\]); req+9=param_sel (confirmed in C). Special: param_sel==7 (baud rate) → req+11 bits\[3:0\] must be in {6,7,9,10}; \<6 → CC 0xcc, \>10 or ==8 → CC 0xc9. param_sel==0x33 (connection mode) → bytes at req+12/req+13 checked against LCP option patterns (0xc021 / 0x4221 / 0xc221).

Response

No response data (CC 0x00 on success). CC 0xc1 if modular+non-internal channel. CC 0xcc if baud out of range. CC 0xc9 if other validation fails. CC 0xff if SOL re-run fails.

Backends `GetCommandDefaultHandleFunction (standard Transport 0x10 handler). get_platform_type. IsInSOLAPI. SerGetInstanceByChannelID. SerialMuxSetMuxPositionInternal. ChannelHandleToChannelID / ChannelNumToChannelID.`

### 11.2DellCmdGetSerModemConfigParam Medium

NetFn 0x0c · Cmd 0x11Priv  · · **O** Aliboemcmdsconfidence: highlive ✓

Get serial/modem configuration parameters. Blocks on modular chassis (platform_type=2) unless channel is '@' (0x40, internal). After delegating to the standard handler, on non-Gen-3 platforms checks SerialDB9PCapable; if DB9 is absent and the requested parameter is neither 0x33 (connection mode) nor all-zero selector, returns CC 0xcb (parameter not supported for DB9-capable constraint).

Request

Modular block: on platform_type==2, rejected (CC 0xc1) unless the channel-handle byte at req+0 == '@' (0x40) — bypass byte is req+0, NOT req+8. req+9=param_sel (the only data byte the handler inspects: DB9 check exempts param_sel==0x33 and param_sel where (param_sel & 0xf7)==0). req+10 (set_selector) and req+11 (block_selector) are standard IPMI fields but are NOT read by this handler — undetermined here.

Response

Variable; standard Get Serial/Modem Config Param response. CC 0xc1 on modular block. CC 0xcb if DB9 not present and param unsupported. CC 0xc1 if dispatch fails.

Backends `GetCommandDefaultHandleFunction (standard Transport 0x11 handler). get_platform_type. Dell_get_generation. CfgGetAttributeInt(iDRAC.Embedded.1#PlatformCapability.1#SerialDB9PCapable).`

### 11.3DellCmdSetSOLConfiguration Medium

NetFn 0x0c · Cmd 0x21Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Set SOL (Serial over LAN) configuration parameters with Dell-specific validation. For baud-rate parameters (param_sel 5 or 6), validates that req+10 bits\[3:0\] (SOL baud code) is in the set {6,7,9,10} (i.e., \[6..10\] excluding 8). All other parameters bypass the baud check. Delegates to the standard SOL Set Configuration handler.

Request

| Offset | Request field |
|----|----|
| 8 | channel. |
| 9 | param_sel. |
| 10 | param_data_byte_0 (for baud params, bits\[3:0\]=baud_code). Baud code must be 6-10 excluding 8, else CC 0xc9. Param_sel 5 or 6 trigger baud check. |

Response

No data (CC 0x00 on success). CC 0xc9 if baud code invalid. CC 0xc1 if dispatch fails.

Backends `GetCommandDefaultHandleFunction (standard Transport 0x21 handler). NetFnLUNCoupleGetNetFn.`

### 11.4DellCmdGetSOLConfiguration Medium

NetFn 0x0c · Cmd 0x22Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Get SOL configuration parameters. Special-cases param_sel=0xc0 (Dell revision query): returns a hardcoded 4-byte version token 0x1bffff11 without touching the standard handler. All other param_sel values are delegated to the standard Get SOL Configuration handler.

Request

| Offset | Request field |
|----|----|
| 8 | channel. |
| 9 | param_sel. If param_sel=0xc0 → immediate fixed response. Otherwise standard IPMI Transport 0x22 format. |

Response

If param_sel=0xc0: resp_len=4, resp\[0:3\]=0x11, 0xff, 0xff, 0x1b (little-endian 0x1bffff11). Otherwise: standard SOL config param response. CC 0x00. CC 0xc1 if dispatch fails.

Backends `GetCommandDefaultHandleFunction (standard Transport 0x22 handler for non-0xc0 params). NetFnLUNCoupleGetNetFn.`

### 11.5CmdTerminalSYS High

NetFn 0x2e · Cmd 0x07Priv  · **U** O Alibserialcmdsconfidence: medabsent

Serial terminal-mode system command dispatcher (Dell OEM Group Extension, netfn 0x2e). Validates two preconditions before dispatching: (1) the first 3 bytes of request data must match a 3-byte header constant {0x5e,0x2b,0x00} found in .rodata — semantic meaning undetermined, possibly a Dell OEM terminal-mode framing marker; (2) the channel protocol type of the originating channel (extracted from req\[0\] \>\> 4 via GetSerChannelProtocolType) must equal 9 — likely a Dell OEM or terminal-mode serial protocol type. After stripping the 3-byte prefix the handler dispatches on a subcommand byte (req_data\[3\]) to: set IPMI boot flags (0x01/0x02 via CmdSetSystemBootOptions), call undetermined internal functions (0x03/0x11/0x12), chassis power-cycle (0x21 via ChassisControlImp(3)), chassis controlled power-on/off (0x31), query system health (0x41 via SenMgrGetSysHealth), proxy an arbitrary IPMI command through the local dispatch table (0x51), or dispatch OEM ASCII commands via a global function-pointer hook (0x80-0xFF via SerTOEMASCIICmd/G_pTermSYSOEMRouteHandlerHookFun).

Request

req+7: req_data_len (must be \> 2; minimum useful value = 4 to avoid CC 0xC7 after prefix strip). req+8..+10 (req_data\[0..2\]): 3-byte header constant, must equal {0x5e,0x2b,0x00}; mismatch or channel-proto != 9 returns CC 0xC1. req+11 (req_data\[3\]): subcommand byte — after the 3-byte prefix is stripped via memmove this becomes new req+8. Per-subcommand payload at req+12+ (req_data\[4+\]): 0x01 — no extra bytes (param selector forced to 5 before forwarding to CmdSetSystemBootOptions); 0x02 — remaining bytes forwarded as-is to CmdSetSystemBootOptions (req_data_len adjusted to original_len-4); 0x03/0x11/0x12 — undetermined; 0x21 — no extra bytes (chassis power-cycle hardcoded); 0x31 — req_data\[4\] (req+12) = chassis control flag: 0 -\> ChassisControlImp(1), nonzero -\> ChassisControlImp(0); 0x41 — req_data\[4\] (req+12) = health selector (echoed in response); 0x51 — req_data\[4\] (req+12) = proxy flag (0=passthrough, nonzero=clear), optional req_data\[5\] (req+13) = proxied-command byte (used when flag=0 and req_data_len==3 post-strip); 0x80-0xFF — req_data\[4+\] = OEM payload passed to G_pTermSYSOEMRouteHandlerHookFun; invalid subcmd -\> CC 0xCC.

Response

Return value = completion code: 0x00 success, 0xC1 (unrecognized command or channel-proto mismatch), 0xC7 (request data truncated — req_data_len==3 after prefix strip leaves no subcommand byte), 0xCC (invalid data field — unknown subcommand). On success: resp_data\[0..1\] = DAT_00102b60 (2 bytes, echoes request header LE word); resp_data\[2\] = DAT_00102b62 (1 byte, echoes request header byte); resp_data\[3\] = subcommand echo byte. resp_len starts at subcommand handler's value then +3 for the header. Per-subcommand additional response: 0x01/0x02 — resp_len=4 (no bytes beyond header+subcmd echo; CmdSetSystemBootOptions result absorbed); 0x21/0x31 — resp_len=4 (header\[3\]+subcmd_echo\[1\] only); 0x41 — resp_len=14: resp_data\[4\]=req_data\[4\] (selector echo), resp_data\[5..12\]=8-byte SenMgrGetSysHealth output blob, resp_data\[13\]=1-byte health trailer; 0x51 — resp_len=4+proxied_handler_resp_len (header+subcmd+proxied handler's resp_data, resp_len incremented by proxied result); 0x80-0xFF — resp_len=4+ (header+subcmd echo + OEM handler output starting at resp_data\[4\]); 0x03/0x11/0x12 — undetermined.

Backends `GetSerChannelProtocolType (serial channel config, channel number from req[0]>>4); CmdSetSystemBootOptions (0x01/0x02 — boot flags, IPMI boot options store); ChassisControlImp (0x21/0x31 — chassis power control subsystem); SenMgrGetSysHealth (0x41 — sensor/health manager, returns 9-byte health blob); RequestHandleTableSearch + IPMI command dispatch table (0x51 proxy — finds and calls handler for modified netfn/cmd); NetFnLUNCoupleDecouple/NetFnLUNCoupleConstruct (0x51 — netfn/LUN reconstruction); G_pTermSYSOEMRouteHandlerHookFun (0x80-0xFF — global function pointer to OEM ASCII command router)`

**Security** — User-privilege chassis power-on/off (0x31) and power-cycle (0x21) from any terminal-mode serial session enable host OS denial-of-service. Boot-option writes (0x01/0x02) at User privilege allow persistent boot-order manipulation — lower privilege than standard CmdSetSystemBootOptions would normally require. Subcommand 0x51 proxies an IPMI command through RequestHandleTableSearch after modifying netfn and channel (forced to 4); if the target handler does not independently re-check the caller's privilege level the proxy may escalate effective privileges. OEM hook (0x80-0xFF) calls via the global function pointer G_pTermSYSOEMRouteHandlerHookFun — if this pointer is attacker-writable (e.g., via a prior arbitrary-write primitive in the same process) it is a direct code-execution pivot. Channel-protocol-type check (value 9) restricts this command to a specific serial channel type and makes it unreachable via standard LAN IPMI sessions.

### 11.6CmdTerminalSYSDRAC High

NetFn 0x2e · Cmd 0x08Priv  · **U** O Alibserialcmdsconfidence: medabsent

DRAC-specific variant of the terminal-mode system command dispatcher (Dell OEM Group Extension, netfn 0x2e). Structurally near-identical to CmdTerminalSYS (0x07) but with two key differences: (1) the channel-protocol-type guard (GetSerChannelProtocolType == 9) is absent, making this potentially reachable via any IPMI channel including LAN; (2) the IPMI-proxy subcommand (0x51) is absent. Validates only the 3-byte header constant {0x5e,0x2b,0x00} at req_data\[0..2\], then dispatches on a subcommand byte (req_data\[3\]) to: set boot flags (0x01/0x02), call undetermined internal functions (0x03/0x11/0x12), chassis power-cycle (0x21), chassis controlled power-on/off (0x31), query system health (0x41), or dispatch OEM ASCII commands via global hook (0x80-0xFF).

Request

req+7: req_data_len (must be \> 2; minimum useful = 4 to avoid CC 0xC7 after prefix strip). req+8..+10 (req_data\[0..2\]): 3-byte header constant, must equal {0x5e,0x2b,0x00}; mismatch returns CC 0xC1. req+11 (req_data\[3\]): subcommand byte — after 3-byte prefix stripped via memmove becomes new req+8. Per-subcommand payload at req+12+ (req_data\[4+\]): 0x01 — no extra bytes (CmdSetSystemBootOptions with selector forced to 5); 0x02 — remaining bytes forwarded to CmdSetSystemBootOptions; 0x03/0x11/0x12 — undetermined; 0x21 — no extra bytes (chassis power-cycle hardcoded to arg 3); 0x31 — req_data\[4\] (req+12) = control flag: 0 -\> ChassisControlImp(1), nonzero -\> ChassisControlImp(0); 0x41 — req_data\[4\] (req+12) = health selector echoed; 0x80-0xFF — req_data\[4+\] = OEM payload; other values -\> CC 0xCC.

Response

Return value = completion code: 0x00 success, 0xC1 (unrecognized command or bad 3-byte prefix), 0xC7 (truncated — data_len==3 after prefix strip), 0xCC (invalid subcommand). On success: resp_data\[0..1\] = DAT_00102b60 (2-byte echo of header constant); resp_data\[2\] = DAT_00102b62 (1-byte echo); resp_data\[3\] = subcommand echo byte; resp_len = subcommand result + 3. Per-subcommand additional bytes: 0x01/0x02/0x21/0x31 — resp_len=4 (header\[3\]+subcmd_echo\[1\] only); 0x41 — resp_len=14: resp_data\[4\]=req_data\[4\] (selector echo), resp_data\[5..12\]=8-byte SenMgrGetSysHealth blob, resp_data\[13\]=1-byte health trailer; 0x80-0xFF — resp_len=4+ (header+subcmd+OEM output at resp_data\[4+\]); 0x03/0x11/0x12 — undetermined.

Backends `CmdSetSystemBootOptions (0x01/0x02 — boot flags store); ChassisControlImp (0x21/0x31 — chassis power control); SenMgrGetSysHealth (0x41 — sensor/health manager, 9-byte health output); G_pTermSYSOEMRouteHandlerHookFun (0x80-0xFF — global OEM ASCII command router function pointer)`

**Security** — Absent channel-protocol-type guard means this handler may be reachable over IPMI LAN (netfn 0x2e with the 3-byte header constant matching) at User privilege — broader attack surface than CmdTerminalSYS. Chassis power-on/off (0x31) and power-cycle (0x21) at User privilege allow host denial-of-service from any IPMI network session. Boot-option writes (0x01/0x02) allow persistent boot-order manipulation. OEM hook (0x80-0xFF) calls G_pTermSYSOEMRouteHandlerHookFun via global function pointer — same code-execution pivot risk as CmdTerminalSYS if the pointer is attacker-controlled. No IPMI-proxy (0x51) subcommand, so proxy-privilege-escalation risk absent here.

## 12. Config / System Info (10)

Extended-configuration reservation/get/set, system-info get/set parameters, internal variables.

### 12.1CmdResvExtendedConfigure Medium

NetFn 0x2e · Cmd 0x01Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Reserve the extended configuration channel. Atomically increments the global one-byte reservation ID (G_u8RacResvID) and clears all three in-process 0x6000-byte staging buffers used for multi-packet RAC extended config get/set transfers. The returned reservation ID must be supplied as a token in subsequent CmdGetExtendedConfigure and CmdSetExtendedConfigure calls to guard against interleaved access.

Request

req+7: u8DataLen (1 B), must be exactly 3; any other value → CC 0xC7. req+8: IANA byte 0 (1 B), Dell OEM IANA LSB = 0xA2. req+9: IANA byte 1 (1 B) = 0x02. req+10: IANA byte 2 (1 B) = 0x00. 24-bit LE integer {req+10,req+9,req+8} must equal 0x0002A2 (Dell OEM IANA 674); mismatch → CC 0xCC. Min total req data bytes = 3.

Response

| Offset | Response field                                            |
|--------|-----------------------------------------------------------|
| 0      | req+8 echoed (0xA2                                        |
| 1      | req+9 echoed (0x02                                        |
| 2      | req+10 echoed (0x00                                       |
| 3      | new G_u8RacResvID value (prior value + 1, wraps at 0xFF). |

Backends `In-process global G_u8RacResvID (1-byte counter); three global 0x6000-byte staging buffers for get/set extended config (all zeroed on reservation); associated per-buffer metadata fields (length, token, index, offset tracking).`

**Security** — User-privilege—low bar. Calling this races and clears any in-progress multi-packet CmdSetExtendedConfigure transaction belonging to another session, enabling denial-of-config-write against concurrent Admin activity. Reservation ID is a single sequential byte; predictable after one successful reservation read, trivially brute-forceable (256 values) on an Admin CmdSetExtendedConfigure that has not yet committed.

### 12.2CmdGetExtendedConfigure Critical

NetFn 0x2e · Cmd 0x02Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Read a window of RAC extended configuration data identified by a (token, index) tuple. Supports multi-packet reads: first call with offset=0 fetches the full blob from GetRACExtendedConfig into a per-channel staging buffer; subsequent calls with non-zero offset slice from that cache. A special path exists for in-band IPMI (channel upper nibble == 7) with token == 0x0B: it returns 20 bytes from three static global variables (DAT_00137d10/18/20) without calling GetRACExtendedConfig.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B), must be exactly 9; other → CC 0xC7. |
| 8 | IANA byte 0 (1 B) = 0xA2. |
| 9 | IANA byte 1 (1 B) = 0x02. |
| 10 | IANA byte 2 (1 B) = 0x00 (IANA 0x0002A2; mismatch → CC 0xCC). |
| 11 | reservation ID (1 B); value is logged (dlog_printf) but NOT validated by this handler—no check is performed on this field. |
| 12 | token byte (1 B), config group selector; validated by FUN_00116eb0, invalid → CC 0x6F; on non-zero offset continuation must also match the token cached from the prior offset=0 call (mismatch → CC 0xCC). |
| 13 | index byte (1 B), sub-index within group; on non-zero offset continuation must match the index cached from the prior offset=0 call (mismatch → CC 0xCC). |
| 14 | ..15: u16 read offset LE (2 B); 0=start new read, non-zero=continuation of prior transfer for same (token,index). |
| 16 | max read length (1 B); capped at 0x80 internally; if requested\<0x80 and less than available, final-packet cleanup is deferred to caller. Min total req data bytes = 9. |

Response

| Offset | Response field |
|----|----|
| 0 | IANA\[0\] (0xA2 |
| 1 | IANA\[1\] (0x02 |
| 2 | IANA\[2\] (0x00 |
| 3 | token |
| 4 | index |
| 5 | n (byte count returned |
| 6 | ..6+n-1\]=config blob window. Total response length = n+6. Special in-band path (channel\>\>4==7 AND token==0x0B): resp=20 bytes from static globals, resp_len=0x14, no standard header fields. |

Backends `GetRACExtendedConfig() internal API (likely cfgmgrd/cfgdb); two per-channel 0x6000-byte read staging buffers (one for channel-7/in-band, one for LAN); global (token,index,offset) state per outstanding multi-packet transfer; static globals DAT_00137d10/18/20 for special token-0x0B path.`

**Security** — User-accessible. Reads arbitrary RAC extended config blobs by (token,index); depending on what tokens expose, this could leak network config, credential material, or service-account settings to any IPMI User. The special in-band channel-7 + token-0x0B path bypasses GetRACExtendedConfig and returns 20 bytes of undetermined static global content—contents not derivable from static analysis alone.

### 12.3CmdSetExtendedConfigure Medium

NetFn 0x2e · Cmd 0x03Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Write a block of RAC extended configuration identified by a (token, index) tuple. Accepts multi-packet writes by streaming payload into a 0x6000-byte staging buffer at the requested offset. When the commit flag is set in the final packet, calls SetRACExtendedConfig to persist the staged blob. Reservation ID must match G_u8RacResvID (obtained via CmdResvExtendedConfigure).

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B), must be ≥ 9; if \< 9 → CC 0xC7. |
| 8 | IANA byte 0 (1 B) = 0xA2. |
| 9 | IANA byte 1 (1 B) = 0x02. |
| 10 | IANA byte 2 (1 B) = 0x00 (IANA 0x0002A2; mismatch → CC 0xCC). |
| 11 | reservation ID (1 B), must exactly match G_u8RacResvID; mismatch → CC 0xC5. |
| 12 | token byte (1 B), config group selector; validated by FUN_00116eb0, invalid → CC 0x6F. |
| 13 | index byte (1 B). |
| 14 | ..15: u16 write offset LE (2 B); 0=reset staging buffer and start fresh; non-zero=append at that offset (must match running total). |
| 16 | commit flag (1 B); 1=last packet, flush staging buffer to SetRACExtendedConfig and clear. |
| 17 | ..end: data payload (u8DataLen-9 bytes, 0 to 0x6000 cumulative across packets). Min total req data bytes = 9 (zero-byte payload allowed for control-only packets). |

Response

| Offset | Response field                              |
|--------|---------------------------------------------|
| 0      | IANA\[0\] (0xA2                             |
| 1      | IANA\[1\] (0x02                             |
| 2      | IANA\[2\] (0x00                             |
| 3      | bytes appended in this packet (uint8 cast). |

Backends `SetRACExtendedConfig() internal API (persists to cfgmgrd/cfgdb); in-process 0x6000-byte write staging buffer at DAT_001537bc; G_u8RacResvID global; token/index/offset tracking state.`

**Security** — Admin-only. Reservation ID is a single sequential byte—predictable after observation or brute-force (256 values). A compromised Admin session or reservation-ID collision allows overwriting arbitrary RAC extended config blobs (network, authentication, service config). Sending offset=0 silently resets and re-stages, discarding any in-progress transfer from another session. No cryptographic integrity on staged data before commit.

### 12.4DellGetInternalVariable Medium

NetFn 0x30 · Cmd 0x27Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Retrieve an internal BMC variable from the front-panel LCD D-Bus service (com.dell.bmc.fplcd) via the CmdGetInternalVariable method. Passes the IPMI request payload verbatim to the D-Bus method and returns the response byte array. The nature and set of readable variables is defined entirely by the fplcd service.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B), full IPMI data section (u8DataLen bytes from |
| 8 | forwarded to D-Bus. Internal selector field layout defined by fplcd service, not validated here. Min meaningful data length: undetermined. |

Response

CC 0xCC (−0x34) if response buffer is NULL. CC 0xCE (−0x32) if D-Bus returns no data. Otherwise: resp\[0..n-1\] = byte array from fplcd CmdGetInternalVariable return; resp_len = n. D-Bus call return code propagated on failure.

Backends `D-Bus service com.dell.bmc.fplcd, object /com/dell/bmc/fplcd, method CmdGetInternalVariable; 1-second D-Bus call timeout; fplcd daemon internal state.`

**Security** — Admin-required. Exposes arbitrary BMC-internal variables via the fplcd D-Bus interface. If the fplcd service exposes sensitive state (e.g., hardware revision tokens, debug flags, or manufacturing variables), a malicious Admin IPMI caller could enumerate them. Variable namespace not enumerable from this handler alone.

### 12.5ConfigValDDCmdHndlr/0x00 Medium

NetFn 0x30 · Cmd 0xdd · Sub 0x00Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read a slice of the manufacturing configuration file /mnt/persistent_data/mmc2/mfgconfigtable/config_mfg.cfg. The handler reads up to 150 (0x96) bytes starting at the requested offset, parses lines for a Dell-internal config flag, and masks the second comma-separated field of flagged lines by overwriting it with spaces and appending 'Dell'. Returns file size metadata and the (partially masked) file slice.

Request

Direct dispatch (not through SubCmdHandler). IPMI data bytes: data\[0\]=0x00 (file index); data\[1..4\]=file-offset uint32_LE (byte offset within the file, unaligned read). Min: 5 data bytes. CheckCfgvalStatus() must return non-zero (cfgval service alive) or handler silently returns CC=0xff.

Response

CC=0x00: resp_len = bytes_returned + 5; resp\[0..3\]=file-size uint32_LE (iVar4); resp\[4\]=(char)bytes_returned (number of actual data bytes, max 0x96=150); resp\[5..5+bytes_returned-1\]=file data slice (up to 150 bytes, potentially partially masked for flagged config lines). CC=0xff: cfgval not alive, file open/seek/read error, or returned bytes \>= 0x97. Resp\[0..3\]=0 if out-of-range offset.

Backends `/mnt/persistent_data/mmc2/mfgconfigtable/config_mfg.cfg; CheckCfgvalStatus() (cfgval DBus service liveness); _parse() (internal config-line parser)`

**Security** — Exposes manufacturing configuration data (factory settings, calibration, hardware IDs) via IPMI. Data masking is only partial: it applies only to parsed lines that pass the internal \_parse() flag check; raw bytes in unparseable regions are returned verbatim. An attacker with Admin IPMI priv can slide through the full file by varying the offset, bypassing partial masking by targeting inter-line regions. No KCS gate — LAN-reachable.

### 12.6ConfigValDDCmdHndlr/0x01 Medium

NetFn 0x30 · Cmd 0xdd · Sub 0x01Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read a slice of the user configuration file /flash/data0/usrconfigtable/config_usr.cfg from flash storage. Same masking and slicing logic as 0x00.

Request

IPMI data bytes: data\[0\]=0x01 (file index); data\[1..4\]=file-offset uint32_LE. Min: 5 data bytes.

Response

| Offset | Response field                                             |
|--------|------------------------------------------------------------|
| 0      | ..3\]=file-size                                            |
| 4      | bytes_returned                                             |
| 5      | +\]=file data slice (max 150 bytes). CC=0xff on any error. |

Backends `/flash/data0/usrconfigtable/config_usr.cfg; CheckCfgvalStatus(); _parse()`

**Security** — Exposes user configuration data stored in flash. May contain network settings, user-defined parameters, or other persistent config. LAN-reachable with Admin priv; same partial-masking bypass as 0x00.

### 12.7ConfigValDDCmdHndlr/0x02 Medium

NetFn 0x30 · Cmd 0xdd · Sub 0x02Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read a slice of the iDRAC platform validation configuration /usr/share/platform_data/config-validation/config_idrac.cfg. Same masking and slicing logic as 0x00.

Request

IPMI data bytes: data\[0\]=0x02 (file index); data\[1..4\]=file-offset uint32_LE. Min: 5 data bytes.

Response

| Offset | Response field                                             |
|--------|------------------------------------------------------------|
| 0      | ..3\]=file-size                                            |
| 4      | bytes_returned                                             |
| 5      | +\]=file data slice (max 150 bytes). CC=0xff on any error. |

Backends `/usr/share/platform_data/config-validation/config_idrac.cfg; CheckCfgvalStatus(); _parse()`

**Security** — Exposes iDRAC platform validation schema/defaults. Primarily read-only metadata, but reveals expected configuration structure and any embedded defaults. LAN-reachable with Admin priv.

### 12.8ConfigValDDCmdHndlr/0x03 Critical

NetFn 0x30 · Cmd 0xdd · Sub 0x03Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read a slice of /var/log/configval/current_config.cfg — the running iDRAC configuration snapshot written by the config-validation service. Same masking and slicing logic as 0x00.

Request

IPMI data bytes: data\[0\]=0x03 (file index); data\[1..4\]=file-offset uint32_LE. Min: 5 data bytes.

Response

| Offset | Response field                                             |
|--------|------------------------------------------------------------|
| 0      | ..3\]=file-size                                            |
| 4      | bytes_returned                                             |
| 5      | +\]=file data slice (max 150 bytes). CC=0xff on any error. |

Backends `/var/log/configval/current_config.cfg; CheckCfgvalStatus(); _parse()`

**Security** — Exposes the full current iDRAC running configuration as it was last snapshotted by cfgval. This is the most sensitive of the six files: it may contain network addresses, credential hash parameters, service settings, SNMP community strings, and other live configuration. The masking only partially redacts flagged lines. LAN-reachable with Admin priv.

### 12.9ConfigValDDCmdHndlr/0x04 Medium

NetFn 0x30 · Cmd 0xdd · Sub 0x04Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read a slice of /mnt/pm/pm/idrac/config_pm.cfg — the iDRAC power-management configuration. Same masking and slicing logic as 0x00.

Request

IPMI data bytes: data\[0\]=0x04 (file index); data\[1..4\]=file-offset uint32_LE. Min: 5 data bytes.

Response

| Offset | Response field                                             |
|--------|------------------------------------------------------------|
| 0      | ..3\]=file-size                                            |
| 4      | bytes_returned                                             |
| 5      | +\]=file data slice (max 150 bytes). CC=0xff on any error. |

Backends `/mnt/pm/pm/idrac/config_pm.cfg; CheckCfgvalStatus(); _parse()`

**Security** — Exposes power-management configuration (power cap, policy, PSU settings). LAN-reachable with Admin priv.

### 12.10ConfigValDDCmdHndlr/0x05 Medium

NetFn 0x30 · Cmd 0xdd · Sub 0x05Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read a slice of /var/log/configval/matched_config.cfg — the config-validation 'matched' (accepted/committed) configuration log. Same masking and slicing logic as 0x00.

Request

IPMI data bytes: data\[0\]=0x05 (file index); data\[1..4\]=file-offset uint32_LE. Min: 5 data bytes.

Response

| Offset | Response field                                             |
|--------|------------------------------------------------------------|
| 0      | ..3\]=file-size                                            |
| 4      | bytes_returned                                             |
| 5      | +\]=file data slice (max 150 bytes). CC=0xff on any error. |

Backends `/var/log/configval/matched_config.cfg; CheckCfgvalStatus(); _parse()`

**Security** — Exposes the last successfully matched/committed iDRAC configuration set. Similar sensitivity to 0x03 (current_config). LAN-reachable with Admin priv; same partial-masking bypass applies.

## 13. Backplane / Drive (2)

Storage backplane and drive-fault handling.

### 13.1DellPcieSSDFRU Medium

NetFn 0x30 · Cmd 0x36Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Reads FRU (Field Replaceable Unit) data for PCIe SSD and NVMe storage devices. Supports six device type categories: PCIe card slots (type=1, via shared memory 0x1a), AIC (type=2), BOSS/NVMe (type=3), M.2 on riser (type=4), VOSS/NVMe (type=5), M.2 OCP Interposer (type=6). Two sub-operations: get FRU area size (sub_op=0) or read FRU bytes at an offset (sub_op=1).

Request

| Offset | Request field |
|----|----|
| 7 | must equal 0x07). Layout |
| 8 | device_type (0=BayID/SlotID via GetBPApiDataOverDBus_CAPI, 1=PCIeCard, 2=AIC, 3=BOSS/NVMe, 4=M2OnRiser, 5=VOSS/NVMe, 6=M2OCPInterposer; any value \>=7=0xcc). |
| 9 | primary_id (slot number or instance for type 1; BayID for type 0; slot for type 3). |
| 10 | secondary_id (SlotID for type 0; bay/channel ID for types 2,4,5,6; ignored by types 1,3). |
| 11 | sub_op (0=get_size, 1=read_data; others undocumented). |
| 12 | ..13=LE uint16 offset (used when sub_op=1; must be \<0x200 for most types, \<0x100 for type=1 with FRU size 0x100). |
| 14 | read_length (bytes to return when sub_op=1; must be \<=36 (0x24); offset+length must be \<=0x200). Min request data length: 7 bytes. |

Response

Byte 0: completion code (0x00=success, 0xc7=wrong data length, 0xc4=malloc failure, 0xc0=shm read failure, 0xc9=out-of-range (outer offset\>=0x200, offset+length\>0x200, type=1 FRU0 inner offset\>=0x100, or length\>36), 0xcb=device not found, 0xcc=invalid device_type). On success: resp_data length set to 2 (sub_op=0) or read_length (sub_op=1). sub_op=0: resp_data\[0..1\]=LE uint16 FRU area size in bytes (0x0100 for type-0 FRU format, 0x0200 for type-1 FRU format). sub_op=1: resp_data\[0..N-1\]=raw FRU bytes at requested offset.

Backends `Dell_shm_memread(region=0x1a, offset=0, len=0xa0b8) for PCIe card slot table (type=1); GetBPApiDataOverDBus_CAPI() for backplane info (type=0/bay-based); GetFRUFromBossNVMe(), GetFRUFromAIC(), GetFRUFromM2OnRiser(), GetFRUFromVOSSNVMe(), GetFRUFromM2OCPInterposer() helper functions (implementations not decompiled)`

**Security** — User-privilege read of hardware FRU identity data (manufacturer, part number, serial number). Allocates up to 41KB (0xa0b8) on heap per PCIe card lookup. Offset bounded to \<0x200 and length to \<=36, preventing overread of the shared memory struct. Discloses storage device identity/serial data to any IPMI User session.

### 13.2DellBpAckDriveRemoval Critical

NetFn 0x30 · Cmd 0xdePriv  · · · **A**libbackplaneconfidence: highlive ✓

Acknowledge drive-removal events on the backplane, clearing LCD fault indicators and health-manager fault entries via D-Bus. Two modes: ack_flag=0 sweeps all drives in the BP inventory that are absent (not installed) and clears each matching fault; ack_flag=1 targets a single drive identified by bay_id and drive_id. In both modes the handler fetches live backplane API data over D-Bus, validates that the drive is actually absent (not currently installed) and that its status flags permit acknowledgement, then calls com.dell.idrac.healthmgr HideUnhideFaultEntries to suppress the fault entry.

Request

Byte layout (standard ipmid message struct; req+7=data length; req+8+N=data\[N\]): req+7 data_len uint8 Must be 0x01..0x08 (\< 9); 0x00 accepted by outer but inner path for ack_flag=0 returns success trivially; for ack_flag=1 minimum is 3. req+8 \[0\] ack_flag uint8 0x00 = ack all absent drives in inventory; 0x01 = ack specific drive. Values \>= 0x02 return CC=0xCC. req+9 \[1\] bay_id uint8 Present and consumed only when ack_flag==1. Logical bay identifier matched against api-\>bay\[i\].bayId. req+10 \[2\] drive_id uint8 Present and consumed only when ack_flag==1. Slot/drive index within the specified bay passed to DellBpIpmiLibGetDrive. Minimum request data length: 1 byte (ack_flag=0); 3 bytes (ack_flag=1).

Response

Completion code only; no response data bytes are written. 0x00 Success — fault cleared (or no eligible drives found for broadcast mode). 0xC7 (199) Invalid data length — data_len \>= 9. 0xCC (204) Parameter out of range / data not present: bay not found; drive not found in bay; drive is currently installed (cannot ack removal of a present drive); drive status flags (bits 0x60 at struct offset +0x11/+0x12) indicate ack is not allowed. 0xCE (206) Unspecified error: null message context; BpAPI D-Bus fetch returned invalid/unready data; BpMsgThreadInfoAlloc allocation failure.

Backends `D-Bus system bus; GetBPApiDataOverDBus_CAPI() (fetches live backplane inventory into thread-local BpMsgThreadInfo struct); DellBpIpmiLibBayInventory (scans api->bay[] by bayId); DellBpIpmiLibGetDrive (resolves drive entry within bay); SendClrLCDCmdForBpDriveErr -> sd_bus call to service com.dell.idrac.healthmgr, object /com/dell/idrac/healthmgr, interface com.dell.idrac.healthmgr.Healthmgr, method HideUnhideFaultEntries(bool hide=true, string sensorPath=/xyz/openbmc_project/sensors/backplane/Drive_<N>, string healthPath=/com/dell/idrac/health/system/drive/Drive_<N>, int32 sensorId). No files or cfgdb keys touched.`

**Security** — Admin-only, but the security-relevant impact is fault suppression: a caller with Admin IPMI access can hide drive-removal health events from the LCD panel and health manager without physically reinstalling a drive. Broadcast mode (ack_flag=0) clears faults for every absent drive in one call. This could be used to mask ongoing hardware failures or drive-pull evidence from out-of-band monitoring. No credential, firmware, or configuration write path exposed. No input reflected in D-Bus arguments beyond integer sensor indices (no injection surface). No response data to leak information.

## 14. OSA / OEM Misc (13)

OSA OEM handler set and uncategorised OEM-misc dispatchers.

### 14.1CmdResetToDefault Medium

NetFn 0x2e · Cmd 0x21Priv  · · · **A**libosaconfidence: highlive ✓

Reset iDRAC configuration to factory defaults. Dual-mode: a mode byte of 0x00 queries whether an asynchronous reset is currently in progress (presence of /var/lock/rtd/r2default.lock); any other valid mode byte (0xaa, 0xcc, 0xdd, 0xee, 0xff) triggers an asynchronous config reset via a detached pthread (threadResetToDefault). Reset scope is mode-dependent: 0xaa/0xcc preserve network settings and user accounts (CfgResetConfigToDefaults mask=0xfffffffd); 0xdd resets to factory shipping state, root/calvin or ToeTag (mask=0xffffffff, preserve=0); 0xee factory-resets with users forced to root/calvin (mask=0xffffffff, preserve=1); 0xff applies custom defaults via CfgDAResetToDefaults. Any execute-mode call is blocked if a firmware update is in progress or preChecks fails. Special case: if the raw netfn byte's upper nibble equals 7 and mode=0xaa, the effective mode is silently upgraded to 0xdd (factory wipe).

Request

| Offset | Request field |
|----|----|
| 7 | 1 (data_length, must be exactly 1 |
| 8 | mode byte: 0x00=query in-progress status; 0xaa=preserve-net/users reset; 0xcc=preserve-net/users reset (identical effect to 0xaa); 0xdd=factory reset (ship state, root/calvin or ToeTag); 0xee=factory reset force root/calvin; 0xff=custom defaults reset. All other values → CC=0xcc. Minimum request data length: 1. |

Response

CC=0x00 on success. CC=0xd4 if preChecks blocked (SPI shadow or LocalConfig state). CC=0xc0 if firmware update semaphore active. CC=0xcc if mode byte is invalid. CC=0xff if pthread_create fails. On success resp_data_len=1. Query mode (req\[8\]=0x00): resp_data\[0\]=1 if no reset active (lock absent), 0 if reset is in progress (lock present). Execute modes: resp_data\[0\]=0 (thread queued; actual reset is asynchronous).

Backends `/var/lock/rtd/r2default.lock (in-progress sentinel); aim_semaphore_get_status('semaphore_firmware_update'); /mmc1/SPI_shadow.bin (firmware shadow guard via preChecks); IslocalConfigDisabled(); IsInBandCommand(); CfgResetConfigToDefaults() (cfgd/cfgdb); CfgDAResetToDefaults() (custom-defaults store); StartRemoveJobsEvent() (job-queue drain)`

**Security** — Admin-privileged factory reset with no IsMsgFromSystemInterface guard — reachable from any IPMI channel (LAN, KCS, SMBUS). Mode 0xaa sent through a registration whose netfn byte upper nibble is 7 is silently promoted to 0xdd (full factory wipe), making the scope of destruction dependent on the channel/registration rather than the explicit mode byte. All execute modes return CC=0x00 before the reset completes (async); a caller cannot distinguish queued-but-not-started from running.

### 14.2CmdOSAOEMCmdHandler/CmdGetFWVersion Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x06 0x00Priv  **C** U O Alibosaconfidence: highlive ✓

Returns firmware version fields for a selected firmware component. The caller supplies a type selector byte (0–9) that indexes into an internal table (DAT_00108da0) of (offset, length) pairs into a firmware info buffer obtained via ipmiMgtCtlrGetFWInfo. The response echoes the type selector followed by the raw version bytes for that component.

Request

| Offset | Request field |
|----|----|
| 7 | 6 (data_length, exactly 6 |
| 8 | 0x5e ('^' |
| 9 | 0x2b ('+' |
| 10 | 0x00 |
| 11 | 0x06 (subcmd\[0\] |
| 12 | 0x00 (subcmd\[1\] |
| 13 | type selector (0–9, selects firmware component version slot). Minimum data length: 6. |

Response

CC=0x00 on success; CC=0xc9 if type selector \>= 10 (parameter out of range); CC=0xff if ipmiMgtCtlrGetFWInfo fails or bounds check fails. On success: 5-byte OEM echo header (resp\[0\]=0x5e, resp\[1\]=0x2b, resp\[2\]=0x00, resp\[3\]=0x06, resp\[4\]=0x00) followed by resp\[5\]=type_selector, resp\[6..5+N\]=version bytes (N=length from internal table, varies per type).

Backends `ipmiMgtCtlrGetFWInfo() — queries management controller firmware version database; internal read-only table DAT_00108da0 mapping type selector to (offset,length) within firmware info block`

**Security** — Registered at Callback privilege (minimum IPMI privilege). Exposes firmware version information for up to 10 component types to any authenticated IPMI session. Low direct impact, useful for reconnaissance/fingerprinting.

### 14.3CmdOSAOEMCmdHandler/CmdGetFWID Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x06 0x01Priv  **C** U O Alibosaconfidence: highlive ✓

Returns a static firmware ID byte (hardcoded value 2). This appears to be a firmware type identifier for the OSA subsystem.

Request

OEM envelope: req\[7\]=5 (data_length, exactly 5); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x06; req\[12\]=0x01. No sub-command payload. Minimum data length: 5.

Response

| Offset | Response field                                  |
|--------|-------------------------------------------------|
| 0      | ..4\]=\[0x5e,0x2b,0x00,0x06,0x01\]) followed by |
| 5      | 0x02 (hardcoded FW ID).                         |

Backends `None (static constant returned from decompiled code at 0x00106740: value=2)`

**Security** — Callback-privilege exposure of a static identifier. No write side-effect. Useful only for fingerprinting the iDRAC10 OSA firmware build.

### 14.4CmdOSAOEMCmdHandler/CmdSetSysGUID Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x06 0x40Priv  **C** U O Alibosaconfidence: medlive ✓

Writes a 16-byte system GUID to persistent storage via SetSysGUID(). The completion code is always 0x00 regardless of whether SetSysGUID() succeeds or fails — errors are silently swallowed.

Request

OEM envelope: req\[7\]=21 (data_length, exactly 21); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x06; req\[12\]=0x40; req\[13..28\]=16-byte GUID (raw binary, no format enforcement in handler). Minimum data length: 21.

Response

CC=0x00 always (SetSysGUID failure is not reflected in the completion code). No response payload beyond CC (leaf returns 0 so dispatcher does not write OEM echo header; only the CC byte is returned).

Backends `SetSysGUID() — writes to cfgd/cfgdb GUID attribute; exact cfgdb key undetermined from this file`

**Security** — Registered at Callback privilege — any authenticated IPMI session can overwrite the system GUID. Failures are silently discarded (CC always 0x00), so callers cannot detect write errors. GUID is used for system identity and management correlation; tampering could affect asset-tracking and attestation flows.

### 14.5CmdOSAOEMCmdHandler/CmdSetBMCSA Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x06 0x41Priv  **C** U O Alibosaconfidence: highlive ✓

Sets the BMC IPMI slave address (SA) on the IPMB bus. The new SA must have its LSB clear (even address); odd addresses are rejected. Calls SetBMCSA() to apply the change.

Request

OEM envelope: req\[7\]=6 (data_length, exactly 6); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x06; req\[12\]=0x41; req\[13\]=new_sa (1 byte, must be even — bit 0 must be 0). Minimum data length: 6.

Response

CC=0x00 on success. CC=0xc9 if new_sa is odd (invalid field value). CC=0xff if SetBMCSA() returns non-zero (hardware/config write failure). No response payload (leaf returns 0; dispatcher does not write OEM header; only CC returned).

Backends `SetBMCSA() — applies new IPMB slave address; likely writes to cfgd and updates hardware I2C controller registration`

**Security** — Callback-privilege command that can change the BMC's IPMB bus address. Changing the SA to a conflicting or invalid value could disrupt IPMB communication, making IPMI unreachable until corrected. No guard against setting SA to 0x00 or to address already occupied by another device.

### 14.6CmdOSAOEMCmdHandler/CmdGetBMCSA Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x06 0x42Priv  **C** U O Alibosaconfidence: highlive ✓

Reads and returns the current BMC IPMB slave address via GetControllerAddress().

Request

OEM envelope: req\[7\]=5 (data_length, exactly 5); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x06; req\[12\]=0x42. No sub-command payload. Minimum data length: 5.

Response

| Offset | Response field                                  |
|--------|-------------------------------------------------|
| 0      | ..4\]=\[0x5e,0x2b,0x00,0x06,0x42\]) followed by |
| 5      | current BMC slave address (1 byte).             |

Backends `GetControllerAddress() — reads current IPMB SA, likely from cfgd or I2C controller register`

**Security** — Callback-privilege read of IPMB addressing. Low impact on its own; useful for attacker reconnaissance of bus topology.

### 14.7CmdOSAOEMCmdHandler/CmdSensorTest Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x04 0x40Priv  **C** U O Alibosaconfidence: medlive ✓

Sensor test stub. If running on an 'inext' build (internal/engineering build, detected via isInextBuild()), returns CC=0xd5 (command not supported). Otherwise falls through with no action and no response payload. Effectively a no-op in production firmware.

Request

OEM envelope: req\[7\]\>=6 (data_length minimum 6, byte3=0x81 means minimum check of data_len-5\>=1); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x04; req\[12\]=0x40; req\[13+\]=sensor test payload (format undetermined, not parsed in this handler). Minimum data length: 6.

Response

If inext build: CC=0xd5. Otherwise: CC=0xff (default unset, no payload). No OEM response header is written (leaf always returns 0). Effectively always an error response.

Backends `isInextBuild() — reads build-type flag (likely compiled-in constant or cfgd attribute)`

**Security** — Callback-privilege. No functional effect in production firmware. The permissive byte3=0x81 (minimum-length check rather than exact) means extra payload bytes are silently accepted and ignored.

### 14.8CmdOSAOEMCmdHandler/CmdResetToDefaultOSA Critical

NetFn 0x2e · Cmd 0xcc · Sub 0x0a 0x01Priv  **C** U O Alibosaconfidence: highlive ✓

Selective per-module reset to factory defaults. Stores the requested module ID in G_u8ResetToDefaultModuleID and calls ResetToDefaultImp(). Module IDs select which subsystem to reset: 0x01=OEM Config, 0x02=LAN/IP, 0x03=UserInfo, 0x04=Serial Channel, 0x05=SOL, 0x06=PEF+LAN PEF, 0x07=Firewall, 0x09=LC Attributes, 0xFF=all modules in sequence. Reserved bytes 1–3 of the payload must be 0x00 or the command is rejected.

Request

OEM envelope: req\[7\]=9 (data_length, exactly 9 — byte3=0x04, data_len-5=4); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x0a; req\[12\]=0x01; req\[13\]=module_id (1 byte; 0x01-0x09 or 0xFF); req\[14..16\]=0x00 reserved (must all be zero, else CC=0xcc). Minimum data length: 9.

Response

| Offset | Response field                                                     |
|--------|--------------------------------------------------------------------|
| 0      | ..4\]=\[0x5e,0x2b,0x00,0x0a,0x01\]) followed by                    |
| 5      | result of ResetToDefaultImp() (1 byte; 0=success, non-zero=error). |

Backends `G_u8ResetToDefaultModuleID (global written before ResetToDefaultImp call); ResetToDefaultImp() — dispatches to: LCAttributesResetToDefault, LANChannelResetToDefault, ResetLANIPCfgToDefault, UserInfoResetToDefault, ResetSerChannelToDefault, ResetSOLToDefault, ResetPEFSettingToDefault, PEFLANCfgResetToDefault, ResetFirewallSettingToDefault, OEMConfigResetToDefault; aim_exec_systemcmd_DDS('aimexec_fullfw_start_reset_to_defaults'); DAT_0011abc4 global (reset-mode state machine gate)`

**Security** — Registered at Callback privilege — any authenticated IPMI session can reset individual config subsystems (LAN, users, SOL, PEF, firewall, OEM config). Module ID 0xFF resets all modules in one call. This is a privilege escalation path: a Callback-level user can wipe UserInfo (user accounts), LAN credentials, and firewall rules. ResetToDefaultImp also gates on DAT_0011abc4 global state — if the global is not in the expected state (0xaa/-0x56), the per-module reset path is silently skipped; if it equals 0xbb/-0x45, a full filesystem wipe + reboot is triggered instead.

### 14.9CmdOSAOEMCmdHandler/CmdMemoryChk Critical

NetFn 0x2e · Cmd 0xcc · Sub 0x10 0x00Priv  **C** U O Alibosaconfidence: highlive ✓

Performs a RAM range check by calling EXRamCheck() with a start and end address. EXRamCheck is currently a stub that always returns 0 (pass), so this command always reports success regardless of the supplied range.

Request

OEM envelope: req\[7\]=13 (data_length, exactly 13 — byte3=0x08, data_len-5=8); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x10; req\[12\]=0x00; req\[13..16\]=start_addr (uint32 LE); req\[17..20\]=end_addr (uint32 LE). Minimum data length: 13.

Response

| Offset | Response field |
|----|----|
| 0 | ..4\]=\[0x5e,0x2b,0x00,0x10,0x00\]) followed by |
| 5 | check_result (1 byte; 1=pass, 0=fail). Currently always 1 (EXRamCheck stub always returns 0=success). |

Backends `EXRamCheck() — RAM test function, currently a stub returning 0`

**Security** — Callback-privilege. EXRamCheck is a stub; no actual memory probing occurs. If a real implementation is installed later, arbitrary physical address ranges could be probed. Input addresses are passed directly to EXRamCheck with no bounds validation visible in this handler.

### 14.10CmdOSAOEMCmdHandler/CmdGetDynaAllocMemorySize Medium

NetFn 0x2e · Cmd 0xcc · Sub 0x10 0x01Priv  **C** U O Alibosaconfidence: highlive ✓

Stub command intended to return dynamic allocation memory size. The implementation checks only that no extra data bytes were supplied (data_len-5 must be 0); if extra bytes are present it returns CC=0xc7. If no extra bytes, it falls through without writing any response (leaf returns 0, dispatcher does not build response header). Effectively always fails.

Request

OEM envelope: req\[7\]=5 (data_length, exactly 5 — byte3=0x00, data_len-5=0); req\[8\]=0x5e; req\[9\]=0x2b; req\[10\]=0x00; req\[11\]=0x10; req\[12\]=0x01. No sub-command payload. Minimum data length: 5.

Response

CC=0xc7 if extra data bytes present. CC=0xff (unspecified, default) if data_length is correct — no payload written (leaf returns 0; dispatcher skips response header). Effectively always returns an error CC with no useful payload.

Backends `None — stub with no backend calls`

**Security** — Callback-privilege stub. No functional effect. The always-failing behavior means it is either disabled pending implementation or intentionally removed.

### 14.11CmdResetToDefault Medium

NetFn 0x30 · Cmd 0x21Priv  · · · **A**libosaconfidence: highlive ✓

Identical handler to CmdResetToDefault registered on netfn 0x2e — this is a second registration of the same CmdResetToDefault function on netfn 0x30 (Dell OEM). All logic, mode bytes, and side effects are identical. See CmdResetToDefault/netfn=0x2e for full details.

Request

| Offset | Request field |
|----|----|
| 7 | 1 (data_length, must be exactly 1 |
| 8 | mode byte: 0x00=query status; 0xaa/0xcc=preserve-net/users reset; 0xdd=factory reset (ship state); 0xee=factory reset force root/calvin; 0xff=custom defaults reset. Minimum data length: 1. |

Response

CC=0x00 on success. CC=0xd4 preChecks blocked. CC=0xc0 FW update in progress. CC=0xcc invalid mode. CC=0xff thread creation failure. resp_data_len=1; resp_data\[0\]=lock-absent flag (query) or 0x00 (execute).

Backends `/var/lock/rtd/r2default.lock; aim_semaphore_get_status('semaphore_firmware_update'); /mmc1/SPI_shadow.bin; IslocalConfigDisabled(); IsInBandCommand(); CfgResetConfigToDefaults() (cfgd/cfgdb); CfgDAResetToDefaults(); StartRemoveJobsEvent()`

**Security** — Second-channel exposure of the same Admin-privileged factory-reset handler. Having the command on two netfns (0x2e OEM Group Extension and 0x30 Dell OEM) means access-control differences between channels could allow one to be reachable where the other is not. No IsMsgFromSystemInterface guard.

### 14.12CmdOEMMiscCmd/OEMMiscCMDEventSELFiltering Medium

NetFn 0x30 · Cmd 0xd0 · Sub 0x01Priv  · · · **A**libmisccmdconfidence: medlive ✓

Get or set the OEM event SEL filter enable flag (iDRAC.Embedded.1#Logging.1#SELOEMEventFilterEnable). Controls whether OEM-defined events are filtered from the System Event Log. The dispatcher (CmdOEMMiscCmd) routes here when data\[1\]=0x01 and data\[0\] is 0 (SET) or 1 (GET). The response echoes data\[1\] and for GET includes the current flag value.

Request

req\[7\] = data_len. req\[8\] = data\[0\] = operation: 0x00=SET, 0x01=GET (must be \< 2; else 0xcc). req\[9\] = data\[1\] = subcommand = 0x01 (routed here by dispatcher). SET requires data_len=9: req\[10:11\]=data\[2:3\] (not validated); req\[12:13\]=data\[4:5\] must be 0x0000 (LE u16); req\[14\]=data\[6\]=0x03; req\[15\]=data\[7\]=0x00 (together form big-endian 0x0003 version/group field); req\[16\]=data\[8\]=enable_flag (0=disable, 1=enable; must be \< 2). GET requires data_len \>= 6 and != 5; req\[12:13\]=data\[4:5\] must be 0x0000.

Response

CC=0xcc: SET data_len != 9 or field validation failed; GET data_len \<= 4 or == 5. CC=0xff: CfgGet or CfgSet call failed. CC=0x00 (SET success): resp_len=5; resp_data\[0\]=0x01 (echo of data\[1\]); resp_data\[1:4\]=0x00000000. CC=0x00 (GET success): resp_len=8; resp_data\[0\]=0x01 (echo); resp_data\[1:4\]=0x03000000 (LE u32=3, likely spec/version constant); resp_data\[5:6\]=0x0300 (LE u16=3); resp_data\[7\]=current SELOEMEventFilterEnable value (0 or 1).

Backends `CfgSetAttributeInt / CfgGetAttributeInt on 'idrac.Embedded.1#Logging.1#SELOEMEventFilterEnable'`

**Security** — Admin-only config write that controls SEL OEM event filtering. An attacker with Admin IPMI can disable OEM event filtering to suppress security-relevant log entries or re-enable to restore them. The 0x0003 group/version field validation may be an undocumented protocol requirement not in public specs.

### 14.13CmdOEMMiscCmd/SubCmdHandler Medium

NetFn 0x30 · Cmd 0xd0 · Sub 0x02Priv  · · · **A**libmisccmdconfidence: lowlive ✓

CmdOEMMiscCmd routes to SubCmdHandler when data\[1\] \>= 0x02. SubCmdHandler.c is not present in the decompiled corpus; its internal subcommand cases, request/response format, and backend dependencies are entirely undetermined from static analysis of the dispatcher alone.

Request

| Offset | Request field |
|----|----|
| 8 | data\[0\]: undetermined (must be \< 2 per outer dispatcher validation). |
| 9 | data\[1\]: \>= 0x02 (triggers this branch). Further fields: undetermined. |

Response

Return value is the return code of SubCmdHandler(). Response layout undetermined.

Backends `undetermined — SubCmdHandler source not available`

**Security** — undetermined — further analysis requires SubCmdHandler decompilation

## 15. Other / Uncategorised (24)

Commands not matched by a category rule.

### 15.1DellCmdNodeMgrDebugInfo Medium

NetFn undetermined · Cmd undeterminedPriv  · · · ·libmisccmdconfidence: low

Claimed SECOND dispatch registration of the DellCmdNodeMgrDebugInfo stub (previously asserted as App netfn 0x06 cmd 0x33). CORRECTED: only ONE handler body exists (single function @0x0011aba0); no dispatch/registration table is present in the decompiled corpus, and the authoritative per-command doc (libmisccmd.so.9.9.9-5.json) lists this stub only at netfn 0x2e cmd 0xe0. The 0x06/0x33 netfn/cmd was not observed in any decompiled artifact and is treated as undetermined. If a second registration exists, its handler body would be identical: log one debug line, return CC=0xc1.

Request

any (not parsed)

Response

none; CC=0xc1 unconditionally (identical handler body)

### 15.2OEMCmdSetSystemBootOptions Medium

NetFn 0x00 · Cmd 0x08Priv  · · **O** Aliboemcmdsconfidence: highlive ✓

Set IPMI System Boot Options with lockdown and modular-chassis enforcement. When system lockdown is active, only allows setting boot-flags (param_sel=5) with a specific initiator channel (0x80 or 0x10) and all other data zero and no boot device. On modular chassis (platform_type=2), after success with param_sel=5, updates internal boot-device globals and signals IMC via DellSetIMCStatusBit(0x1000000).

Request

req+8=param_sel ((req+8 & 0x7f); IPMI boot options parameter selector). req+9..req+13=parameter data. Lockdown exception (all must hold): (req+8 & 0x7f)==5 (boot flags param), the arriving channel/source byte at req+0 must equal 0x80 OR (req+0 & 0xbf)==0x10 (NOT req+8), and req+9..req+13 all zero. Any violation while locked → CC 0xd4, resp\[0\]=1.

Response

No response data (CC 0x00 on success). Resp_len set by underlying standard handler.

Backends `GetCommandDefaultHandleFunction (standard boot options handler). IsSystemLockdownEnabled. get_platform_type. DellSetIMCStatusBit(0x1000000). Globals DAT_00153670 (boot device), DAT_00153671 (persist flag).`

**Security** — Lockdown bypass: a specific crafted boot-flags packet (param_sel=5, src=0x80/0x10, data=zero) is accepted even under system lockdown, allowing an operator-level caller to clear boot flags while locked.

### 15.3CmdOEMGetSelfTestResults Medium

NetFn 0x06 · Cmd 0x04Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Return BMC self-test results. Sets resp_len to 2, calls IsInManufacturingTestMode(2, &resp_len, 0) (its second arg is the resp_len pointer; effect on the response undetermined), then GetStdSelfTestError(resp, resp+1) (imported) populates both response bytes.

Request

No request data.

Response

resp_len=2. Note: the literal '2' written by the handler (\*resp_len=2) is the RESPONSE LENGTH, not a status default. resp\[0\]=self_test_status byte and resp\[1\]=error field are BOTH written by GetStdSelfTestError(resp, resp+1); their exact values are produced by that imported function (undetermined here — standard IPMI would be 0x55/0x56/0x57/0xFF for byte0). IsInManufacturingTestMode(2, &resp_len, ...) may adjust resp_len; effect undetermined. CC 0x00.

Backends `IsInManufacturingTestMode (imported). GetStdSelfTestError (imported).`

### 15.4CmdOEMManufacturingTestOn Medium

NetFn 0x06 · Cmd 0x05Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Enable manufacturing test mode. Delegates to the standard Manufacturing Test On handler via GetCommandDefaultHandleFunction. After execution, logs whether manufacturing mode is now active and whether the request arrived via the system interface. The IsMsgFromSystemInterface check is informational only and does not gate the command.

Request

Standard IPMI Manufacturing Test On format. req+8+ = manufacturing test data bytes per IPMI spec.

Response

Set by underlying handler. CC 0x00 on success, 0xc1 if dispatch fails, 0xff if handler pointer null.

Backends `GetCommandDefaultHandleFunction (standard App 0x05 handler). IsInManufacturingTestMode (status check, imported). IsMsgFromSystemInterface (logging only, imported).`

### 15.5CmdOEMGetCommandSupport Medium

NetFn 0x06 · Cmd 0x0aPriv  · **U** O Aliboemcmdsconfidence: highlive ✓

Query whether a given IPMI command is supported on this BMC. Pure passthrough to GetCommandDefaultHandleFunction which locates the standard Get Command Support handler.

Request

req+8=netfn, req+9=cmd (command code to query). Standard IPMI Get Command Support format.

Response

Variable; standard IPMI Get Command Support response (completion, support bitmap). CC 0xc1 if handler not found.

Backends `GetCommandDefaultHandleFunction (routes to standard App 0x0a handler).`

### 15.6OEMCmdSetChannelSecurityKeys Critical

NetFn 0x06 · Cmd 0x56Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Set IPMI channel security keys (K_R, K_C, K_G) with lockdown and local-config-disable enforcement. Read/query operations (req+9=0) always pass through. Write operations (req+9 != 0) are blocked with CC 0xd4 when: system lockdown is enabled, OR local config is disabled AND the request is NOT from the in-band (system) interface.

Request

req+8=channel_number, req+9=operation (0=read/no-set, non-zero=set a key per IPMI 2.0). req+10+=key_data. Gate: req+9==0 always passes. For req+9 != 0 the request is BLOCKED with CC 0xd4 when IsSystemLockdownEnabled()==1, OR ( IslocalConfigDisabled()!=0 AND IsInBandCommand(req)!=0 ). The direction of the IsInBandCommand test (whether !=0 means in-band or out-of-band) is undetermined — IsInBandCommand is imported and its body is not in this decompilation.

Response

Variable; standard IPMI Set Channel Security Keys response from delegated handler. CC 0xd4 if blocked by the lockdown/local-config gate. CC 0xc1 if dispatch fails.

Backends `GetCommandDefaultHandleFunction (standard App 0x56 handler). IsSystemLockdownEnabled. IslocalConfigDisabled. IsInBandCommand (imported; body not decompiled).`

**Security** — Write ops (req+9 != 0) are gated by lockdown and local-config-disable. When local config is disabled the block additionally depends on IsInBandCommand(req)!=0; because that function's semantics are not visible here, whether in-band or out-of-band callers are exempt is undetermined. A read/query (req+9==0) is never blocked.

### 15.7CmdPOSTEvent Medium

NetFn 0x2e · Cmd 0x04Priv  · · · **A**liboemcmdsconfidence: medlive ✓

Accept a POST (Power-On Self Test) event notification from the host. Validates a fixed 4-byte payload and echoes the first three bytes back. No event logging, SEL write, or further dispatch is visible in the decompiled handler—this appears to be a stub or the real work occurs in a caller or listener layer not captured here.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B), must be exactly 4; other → CC 0xC7 (199). |
| 8 | event byte 0 (1 B), echoed in response; semantics undetermined. |
| 9 | event byte 1 (1 B), echoed. |
| 10 | event byte 2 (1 B), echoed. |
| 11 | event type (1 B), must be 0 or 1; value ≥ 2 → CC 0xCC. No IANA check. Min total req data bytes = 4. |

Response

| Offset | Response field          |
|--------|-------------------------|
| 8      | resp\[1\]               |
| 9      | resp\[2\]               |
| 10     | three echo bytes only). |

Backends `None visible in decompiled code; likely a stub or notification consumed by a higher layer.`

**Security** — Admin-required. Minimal handler logic; no evident injection or persistent-state side-effect from static analysis. If POST-event processing does occur elsewhere (e.g., via shared memory or a signal), a malicious host OS could fabricate POST events to influence BMC state—not confirmed from this handler alone.

### 15.8DellCmdNodeMgrDebugInfo Medium

NetFn 0x2e · Cmd 0xe0Priv  · · · **A**libmisccmdconfidence: highlive ✓

Stub placeholder for Intel Node Manager debug-info retrieval. Logs 'IPMI Get-Message Handler' at debug level and unconditionally returns CC=0xc1 (invalid command). Not implemented.

Request

any (not parsed)

Response

none; CC=0xc1 unconditionally

### 15.9DellCmdNodeMgrSendRaw Medium

NetFn 0x2e · Cmd 0xe1Priv  · · · **A**libmisccmdconfidence: highlive ✓

Stub placeholder for sending raw Intel Node Manager commands. No request parsing; unconditionally returns CC=0xd6 (cannot execute command). Not implemented.

Request

any (not parsed)

Response

none; CC=0xd6 unconditionally

### 15.10DellSetTeamingMode Medium

NetFn 0x30 · Cmd 0x24Priv  · · · **A**libmisccmdconfidence: highlive ✓

Set NIC teaming mode. The decompiled body is a stub: it unconditionally returns 0x80 (unspecified error) with no implementation logic or cfgdb writes. The function is effectively dead code / a placeholder.

Request

No bytes parsed (stub body). Min length: undetermined.

Response

CC=0x80 (unspecified error) unconditionally. No response data.

Backends `none`

**Security** — Always fails; harmless stub.

### 15.11CmdSetNICSelectionFailover Medium

NetFn 0x30 · Cmd 0x28Priv  · · · **A**libmisccmdconfidence: highlive ✓

Set iDRAC management NIC primary selection (dedicated vs. shared LOM) and failover NIC. Values are translated from IPMI-encoded integers to cfgdb integers via lookup tables (DAT_00141a70 / DAT_00141b40). Validates NIC presence via NicPresenceMask before writing. Only supported on generation \<= 5 iDRAC hardware.

Request

| Offset | Request field |
|----|----|
| 7 | 2 (data length, must be exactly 2). |
| 8 | NIC selection (IPMI-encoded, e.g. 1=dedicated). |
| 9 | failover NIC selection (IPMI-encoded, 0 or 5=none). Min length: 2 bytes. |

Response

CC=0x00 success, \*param_2 (resp_len) set to 0 (no additional bytes). Error CCs: 0xC1 (generation \> 5, unsupported); 0xC7 (data length != 2); 0xD5 (shared LOM is in use as management NIC, failover config blocked); 0xCC (primary NIC not present in NicPresenceMask, or failover NIC not present); 0xFF (cfgdb write failure).

Backends `Dell_get_generation(); cfgdb: iDRAC.Embedded.1#NIC.1#Selection, iDRAC.Embedded.1#NIC.1#Failover, iDRAC.Embedded.1#NIC.1#NicPresenceMask, iDRAC.Embedded.1#MgmtNetworkInterface.1#EnableStatus, iDRAC.Embedded.1#MgmtNetworkInterface.1#NicConfig; IPMI_To_CFG() translation tables`

**Security** — Admin config write changing management network interface selection. Misconfiguration can disable management network connectivity. NIC presence mask checked before write, preventing phantom-NIC selection.

### 15.12CmdGetNICSelectionFailover Medium

NetFn 0x30 · Cmd 0x29Priv  · · · **A**libmisccmdconfidence: highlive ✓

Read current management NIC primary selection and failover NIC from cfgdb. Translates cfgdb integer values to IPMI-encoded bytes via lookup tables (CFG_To_IPMI). If primary NIC selection is 1 (dedicated), forces failover byte to 0 in the response. Only supported on generation \<= 5 iDRAC.

Request

req\[7\]=0 (data length, must be exactly 0). No data bytes. Min length: 0.

Response

CC=0x00, \*param_2=2 (2 response bytes). resp\[0\]=NIC selection (IPMI-encoded). resp\[1\]=failover NIC (IPMI-encoded; forced to 0x00 if resp\[0\]==0x01). Error CCs: 0xC1 (generation \> 5); 0xC7 (data length != 0); 0xFF (cfgdb read failure, both Failover and Selection reads logged).

Backends `Dell_get_generation(); cfgdb: iDRAC.Embedded.1#NIC.1#Selection, iDRAC.Embedded.1#NIC.1#Failover; CFG_To_IPMI() translation tables`

**Security** — Read-only; leaks management network configuration. Low risk.

### 15.13DellQueryGetCPLDRevision High

NetFn 0x30 · Cmd 0x33Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Returns the CPLD (Complex Programmable Logic Device) firmware version as a 3-byte major.minor.maint tuple. On generation \< 6 (pre-iDRAC10) it reads directly from hardware via cpld_read_group_hwabs("MAJOR_REV"), ("MINOR_REV"), ("MAINT_REV"). On generation \>= 6 (iDRAC10) it reads the string attribute iDRAC.Embedded.1#Info.1#CPLDVersion from cfgdb and sscanf-parses it as "%hhu.%hhu.%hhu".

Request

No data bytes are consumed; the function does not read req+7 (data length) or any data bytes. Min request data length: 0 bytes.

Response

Byte 0: completion code (0x00=success, 0xff=hardware/cfgdb error). Bytes 1-3 (resp_data\[0..2\]): \[0\]=CPLD MAJOR revision, \[1\]=CPLD MINOR revision, \[2\]=CPLD MAINT/patch revision. Response data length is always set to 3.

Backends `cpld_read_group_hwabs("MAJOR_REV"/"MINOR_REV"/"MAINT_REV") for gen<6; CfgGetAttribute("iDRAC.Embedded.1#Info.1#CPLDVersion") cfgdb key for gen>=6`

**Security** — Read-only version disclosure of CPLD firmware version. No write path. Reachable by any User-privilege IPMI session. Could aid firmware fingerprinting or downgrade attack targeting.

### 15.14DellCmdSpecialACCycle High

NetFn 0x30 · Cmd 0x9fPriv  · · · **A**libmisccmdconfidence: highabsent

Initiates a virtual AC power cycle on monolithic (non-modular) platforms, but only when the system is pre-POST. Calls SetSystemPowerOff, VirtualAcCycleReq_IPCClient, and then forks /usr/bin/jssmtask via utl_execmd. Returns immediately after dispatching; actual cycle is asynchronous.

Request

no data required (content ignored). Gates checked in order: (1) get_platform_type must return non-2 (not modular/blade); (2) IsInBandCommand must return non-zero; (3) SHM region 0x25 offset 0xab9 POST-status byte must not be 'Q' (0x51) nor in range 0x7e..0x7f (POST done)

Response

2 bytes on success (\*param_2=0x02): resp\[0..1\]=0x0000. CC=0x00 success; 0xcb if modular platform (type==2); 0xc1 if not in-band; 0xff if POST already completed / vAC not allowed

Backends `get_platform_type, IsInBandCommand, Dell_shm_memread (region 0x25 offset 0xab9, POST status byte), SetSystemPowerOff (arg=1), VirtualAcCycleReq_IPCClient (IPC), utl_execmd (/usr/bin/jssmtask, no-wait), calloc/free`

**Security** — In-band Admin caller can trigger full virtual AC cycle (complete system reset) before POST completes. utl_execmd spawns /usr/bin/jssmtask; if that binary is writable or path is manipulable, this path executes arbitrary code as the iDRAC IPMI handler process.

### 15.15CmdGetSoftLockStatus Medium

NetFn 0x30 · Cmd 0xa0Priv  · **U** O Aliboemcmdsconfidence: medlive ✓

Returns the iDRAC local-configuration soft-lock status. When soft-lock is active, local (KCS/in-band) IPMI and racadm configuration commands are blocked. Uses GetLocalConfigDisableSetting() to query the current state.

Request

req+7=data_len; must be 0 (CC=0xc7 if data_len != 0). No request data bytes.

Response

CC=0xc7 (request data length invalid) if data_len != 0. CC=0 → resp_len=1. resp\[0\]=GetLocalConfigDisableSetting() result: 0=config unlocked, non-zero=soft-locked (exact bit semantics undetermined; implementation is in an internal helper).

Backends `GetLocalConfigDisableSetting() internal function (likely reads cfgdb or shared memory for the LocalConfigurationLock setting).`

**Security** — User-readable. Reveals whether the BMC is in a locked-down state, which could inform an attacker whether local-channel exploitation is viable.

### 15.16QueueSpdDimmInfoCmd Medium

NetFn 0x30 · Cmd 0xb8Priv  · **U** O Aliboemcmdsconfidence: high for gen-check stub behavior; low for gen\<=5 behavior (no processing code visible)live ✓

Queues collection of SPD (Serial Presence Detect) DIMM information. On iDRAC10 (generation \> 5) this command is unconditionally stubbed out and returns completion code 0xc1 (command not supported). On earlier generations (\<=5) it returns 0x00 but no processing logic is visible in the decompiled code.

Request

Not validated; request bytes are not read. Min request data length: 0.

Response

Completion code only (no response data). CC=0xc1 on iDRAC10 (gen\>5). CC=0x00 on gen\<=5 (no data bytes, resp_len=0).

Backends `Dell_get_generation() to determine hardware generation`

**Security** — Effectively a no-op / dead command on iDRAC10. No write path, no data disclosure.

### 15.17QueueSpdDimmInfoCmd Medium

NetFn 0x30 · Cmd 0xb9Priv  · · · **A**liboemcmdsconfidence: high for gen-check stub behavior; low for gen\<=5 behaviorlive ✓

Admin-privileged variant registered to the same QueueSpdDimmInfoCmd handler as cmd 0xb8. On iDRAC10 (generation \> 5) unconditionally returns 0xc1 (command not supported). On earlier generations returns 0x00 with no visible processing. The handler function is shared with cmd 0xb8; the only distinction is the privilege level enforced by the IPMI stack before dispatch.

Request

Not validated; request bytes are not read. Min request data length: 0.

Response

Completion code only (no response data). CC=0xc1 on iDRAC10 (gen\>5). CC=0x00 on gen\<=5.

Backends `Dell_get_generation() to determine hardware generation`

**Security** — Admin-gated no-op on iDRAC10. No write path, no data disclosure.

### 15.18DellCPLDAccessStatus Critical

NetFn 0x30 · Cmd 0xbcPriv  · · · **A**liboemcmdsconfidence: high for op logic and field layout; med for DellAbsReadCPLDMem address range limits (truncated); med for op=3 response behavior (uninitialised resp_data)live ✓

Manages direct CPLD register access. Four sub-operations: (0) disable CPLD direct access (clears g_CPLD_Status global, writes 0x01 to shared memory region 0x28 offset 0); (1) enable CPLD direct access (sets g_CPLD_Status=1, writes 0x00 to shm 0x28); (2) read count bytes from CPLD address space starting at start_addr (requires CPLD access to be enabled first); (3) compute the byte count needed to represent a count-bit CPLD register range.

Request

| Offset | Request field |
|----|----|
| 7 | . |
| 8 | op (0=disable, 1=enable, 2=read, 3=get_byte_count; any other=CC 0xcc). |
| 9 | ..10 = LE uint16 count_or_offset: for op=2, byte count to read (1-199; 0 returns CC 0xcc; \>199 returns CC 0xca); for op=3, bit count (must be \>0 and count+start_addr\<=0xd0). |
| 11 | ..14 = int32 start_addr: for op=2, base CPLD byte address to read from; for op=3, added to count for range bounds check. All 7 data bytes are unconditionally accessed; sending fewer may cause an out-of-bounds read in the handler. |

Response

op=0 (disable): CC=0x00, resp_len=0. op=1 (enable): CC=0x00, resp_len=0. op=2 (read): CC=0x00 on success, resp_len=count, resp_data\[0..count-1\]=CPLD memory bytes from start_addr. CC=0xff if g_CPLD_Status=0 (not enabled) or if DellAbsReadCPLDMem fails. CC=0xcc if count=0; CC=0xca if count\>199. op=3 (get_byte_count): CC=0x00, resp_len=(count\>\>3)+1, resp_data\[\] not populated (undetermined bytes). CC=0xff if count=0 or count+start_addr\>0xd0.

Backends `g_CPLD_Status in-process global flag; Dell_shm_memwrite(region=0x28, offset=0, len=1) for enable/disable state propagation; DellAbsReadCPLDMem(addr, dest_ptr) for CPLD register reads (implementation in another library, truncated)`

**Security** — Admin-only. Op=2 allows reading up to 199 bytes of raw CPLD register space from an arbitrary int32 start address; actual address space limits depend on DellAbsReadCPLDMem implementation which is not decompilable here. Op=3 response buffer (resp_data) is not written, so the response contains whatever memory follows the IPMI response header — minor information disclosure. Enable/disable ops write to shared memory, affecting all concurrent CPLD access callers (TOCTOU if enable+read not atomic).

### 15.19DellRollbackFW High

NetFn 0x30 · Cmd 0xbePriv  · · · **A**liboemcmdsconfidence: high for wrapper structure; low for actual rollback mechanism and response format (CmdRollbackFirmwareVersion decompilation truncated)live ✓

Initiates firmware rollback to the previously installed (standby) firmware version. Thin wrapper: calls CmdRollbackFirmwareVersion() with no argument processing. CmdRollbackFirmwareVersion is defined in another shared library; its decompilation is truncated (bad instruction data).

Request

No request bytes are read or validated by this handler. All input ignored. Min request data length: 0.

Response

Delegated entirely to CmdRollbackFirmwareVersion(). Exact completion code and response data undetermined (implementation not decompilable in this library).

Backends `CmdRollbackFirmwareVersion() in an external shared library (not decompiled)`

**Security** — Admin-only firmware downgrade trigger. Rolling back to a prior firmware version can re-expose patched vulnerabilities present in that version. No request validation in this handler layer — all enforcement (if any) is inside CmdRollbackFirmwareVersion.

### 15.20DellGetFWVersion Medium

NetFn 0x30 · Cmd 0xbfPriv  · **U** O Aliboemcmdsconfidence: medlive ✓

Returns iDRAC firmware version for a requested component. Validates the component selector byte and delegates to CmdGetFirmwareVersion(). Component 2 is explicitly rejected; components 0, 1, 3, 4 are accepted.

Request

| Offset | Request field                                                      |
|--------|--------------------------------------------------------------------|
| 7      | data_len (min 1).                                                  |
| 8      | data\[0\]: component selector (0/1/3/4 valid; 2 or \>4 → CC=0xcc). |

Response

CC=0xcc if component selector is 2 or \>4 (invalid field). CC=0 → firmware version payload from CmdGetFirmwareVersion() (external symbol in libipmid/libipmilinux; response layout undetermined without decompiling that library).

Backends `CmdGetFirmwareVersion() external symbol (likely in libipmid.so or libipmilinux.so.9)`

**Security** — Read-only firmware version disclosure. Component selector 2 explicitly rejected suggests a reserved/sensitive component. Allows firmware version enumeration for targeting attacks.

### 15.21DellGetActiveLOM Medium

NetFn 0x30 · Cmd 0xc1Priv  · **U** O Aliboemcmdsconfidence: highlive ✓

Returns the active LOM (LAN on Motherboard) NIC identifier and a selected network attribute (link status, speed, or duplex) from the iDRAC configuration database. Only available on platform generations \<= 5 (CC=0xc1 on gen\>5). The active NIC index is read from cfgdb and mapped through an internal type table.

Request

| Offset | Request field |
|----|----|
| 7 | data_len; must be exactly 3 (CC=0xcc if not 3). |
| 8 | data\[0\]: attribute selector: 0=NIC type only, 1=NIC type + link status, 2=NIC type + link speed, 3=NIC type + duplex mode. Must be \<= 3 (CC=0xcc if \>3). |
| 9 | data\[1\] |
| 10 | data\[2\]: ignored. |

Response

CC=0xc1 if platform generation \> 5 (command not supported). CC=0xcc if data_len != 3 or attribute selector \> 3. CC=0xff if cfgdb read fails. CC=0 → 3 bytes: resp\[0\]=NIC type code (mapped from ActiveNIC cfgdb index via internal 18-entry table); resp\[1\]=attribute value (0 if selector=0, else LinkStatus/Speed/Duplex cfgdb value); resp\[2\]=0x00.

Backends `cfgdb keys: iDRAC.Embedded.1#currentNIC.1#ActiveNIC (int, index 0..17), iDRAC.Embedded.1#currentNIC.1#LinkStatus (selector=1), iDRAC.Embedded.1#currentNIC.1#Speed (selector=2), iDRAC.Embedded.1#currentNIC.1#Duplex (selector=3).`

**Security** — Read-only. Exposes NIC topology, link status, and negotiated speed/duplex to any authenticated user. Could aid network reconnaissance. No write path.

### 15.22DellCmdiDracPOSTCode Medium

NetFn 0x30 · Cmd 0xd4Priv  · · · **A**liboemcmdsconfidence: highlive ✓

Read the current BIOS POST code status dword from shared memory. If bit 14 of the status dword indicates a boot-complete event, clears IMC status bit 0x8000000 (previously-set POST progress flag). Returns the full 4-byte SHM status word.

Request

req+8..req+11 must all be zero (interpreted as a 32-bit zero integer). Non-zero → CC 0xcc.

Response

resp_len=16 (0x10). resp\[0:3\]=POST_code_status_dword (4 bytes from SHM segment 10, offset 0). Bytes 4-15 are uninitialized padding from the response buffer. CC 0x00 on success. CC 0xff if SHM read fails. CC 0xcc if req+8:11 non-zero.

Backends `Dell_shm_memread(seg=10, offset=0, len=4). DellClearIMCPrevStatusBit(0x8000000) if SHM bit14 set.`

**Security** — Exposes raw internal POST code state dword including IMC status bits to any Admin-level caller. Automatically side-effects IMC state (clears boot-complete bit) on read if bit 14 set, making this command non-idempotent.

### 15.23FileObjCmdHandler Medium

NetFn 0x30 · Cmd 0xdbPriv  · · · **A**liboemcmdsconfidence: medlive ✓

Dispatcher stub for file-object IPMI sub-commands (netfn 0x30, cmd 0xDB). Validates GET/SET direction and request-type fields but all reachable code paths return error completion codes—no sub-command handler is invoked in the decompiled code. The comment string 'no handler for Request type' with CC 0xC1 is returned for otherwise-valid inputs, indicating an unimplemented or stripped dispatcher. Sub-command dispatch table not visible in available decompilation.

Request

| Offset | Request field |
|----|----|
| 7 | u8DataLen (1 B), not checked for length minimum beyond field accesses. |
| 8 | direction byte (1 B); 0=GET, 1=SET; value ≥ 2 → CC 0xCC ('invalid GET/SET command'). |
| 9 | request type byte (1 B); must be 0 or 1; value ≥ 2 → CC 0xCC ('invalid Request type'). |
| 12 | ..13: u16 data-amount LE (2 B); if offset+5 ≥ 0xC9 → CC 0xC7 ('exceeds IPMI msg limit'). All other valid inputs → CC 0xC1 ('no handler for Request type'). Sub-command byte position and further fields: undetermined. |

Response

CC 0xCC if direction byte ≥ 2 or request type ≥ 2. CC 0xC7 (199) if req+12 offset+5 ≥ 0xC9. CC 0xC1 for all otherwise-valid inputs (no sub-handler invoked). No success response body observed in decompiled code.

Backends `None reachable from decompiled code; actual sub-command backends undetermined.`

**Security** — Admin-required. All inputs currently rejected; no exploitable code path visible in this handler. If sub-commands become routable in a different firmware version or via a patched dispatch table, the Admin privilege bar applies. Stub status means behavior may differ at runtime if dynamic registration populates a handler table not captured in this decompilation.

### 15.24DellCmdSmaMbxFlag Medium

NetFn 0x30 · Cmd 0xfaPriv  · · · **A**liboemcmdsconfidence: highlive ✓

Return a static SMA mailbox protocol identification flag. Always responds with a single byte value 0xd5. No input is read, no backend is queried. Likely used by host-side agents to confirm Dell SMA mailbox protocol availability.

Request

No data consumed.

Response

1 byte: resp\[0\]=0xd5. CC 0x00 always.

------------------------------------------------------------------------

Source: idrac10-commands.json. Fixed taxonomy; impact heuristic; request/response tables parsed from RE'd offset prose (prose fallback when not cleanly tabular).
