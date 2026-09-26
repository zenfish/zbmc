<!-- html2md:auto source=boxes/irmc-fujitsu/irmc-s6-oem-reference.html source-sha256=c76b95d78ea9a1ad326e60609b4429a1a96f8629af6ff55d6d454022e716065c body-sha256=104e2d8d73711467070f5b05584f51c28bdbfcb27f6fb5f5e1abdc4c81202e95 -->

zBMC · RX2540 M7 · iRMC S6 02.63S

# Fujitsu OEM IPMI command reference

A firmware-bound dispatch and selector inventory. A registration, a decoded wrapper, and a live-reachable wire contract are different levels of proof; the tables say which level each entry has reached.

**148**

active table records

**138**

LUN-aware identities (135 pairs)

**228**

2e selector candidates

**10**

duplicate MSMM callbacks

## Proof boundary

The 160-row recovered table has 12 terminators. Ten MSMM entries duplicate the normal 2e handlers; three LUN-3 FRU identities share command numbers with different LUN-0 handlers and are not proved over LAN (prior probe returned C0). Of 104 C0/D0 handlers, 91 have direct wrapper contracts and 13 retain partial backend or field semantics. Rack-relevant power paths and blade-gated paths coexist; the table name alone does not decide applicability. F1/F5 jump tables identify 192 candidate leaves, but partial or unknown leaf contracts are not runnable codecs.

## Safe live proof

The fresh Debby cold run `20260926T200725Z-7ecec0c7-f88e-4945-b3b2-2fe97bcb9e3a` reached required-service READY in 27m34s after initial host CPU contention. A cipher-17 Admin session sent 22 statically reviewed four-byte read requests, serialized. Twenty-one returned CC00; 2e/e0 selector 00 returned CC01, showing a device-side rejection. No request had a transport error. One named zipmi power-read command was also exercised successfully. [Exact requests and responses](evidence/20260926T204500Z-safe-live-22.json) are retained; no changing selector was sent.

## Security and impact boundaries

- 2e/01 is User-privileged yet includes state-changing power selectors 17, 1b, 1c, and 20; branch-specific short-request checks are weak.
- 2e/e0 selector 04 is a NVRAM/IDPROM maintenance multiplexer, not a read-only comparison. It includes FRU restore, IDPROM writes, and a short-request 32-bit read.
- 2e/F1 selectors 11 and 40 can change GUID/configuration state before an error reply; selector 40 returns C7 unconditionally after its write attempt.
- 2c/02 group 52 is an Admin/channel-0f credential-creation path for any second byte, not just A5; it is not a safe DCMI read and has not been invoked live.
- 06/45 can bypass standard Set User Name validation after its Fujitsu config write succeeds; malformed inputs can drive an unbounded strlen or user-slot underflow.
- 34/38–39 back up and restore persistent configuration. The restore wrapper can copy a 24-byte page from an undersized request; static-only finding.
- 2e/F5 selectors 52, a5, and f8 reach I2C write/read, persistent POH reset, and user deletion respectively; these are static findings, not live probes.
- 34/00–0c flash routes, 30/e6 raw PECI, F1/58, and F1/ff have high-impact or weak-length boundaries. No state-changing command was used for this reference.

## Top-level dispatch identities

All 138 unique LUN-aware identities are below. Standard-NetFn rows are Fujitsu overrides, not newly assigned OEM opcodes. Full evidence: [exact table](evidence/irmc-s6-command-tables.tsv), [C0/D0 handlers](evidence/c0d0-handler-audit.json), [standard/group overrides](evidence/standard-overrides.json).

Filter top-level commands

<table style="width:100%;">
<colgroup>
<col style="width: 14%" />
<col style="width: 14%" />
<col style="width: 14%" />
<col style="width: 14%" />
<col style="width: 14%" />
<col style="width: 14%" />
<col style="width: 14%" />
</colgroup>
<thead class="bg-slate-800">
<tr>
<th class="p-2">Wire</th>
<th class="p-2">Handler / source</th>
<th class="p-2">Privilege / admission</th>
<th class="p-2">Request</th>
<th class="p-2">Response</th>
<th class="p-2">Effect</th>
<th class="p-2">Proof / activation</th>
</tr>
</thead>
<tbody id="top-rows">
<tr class="border-b border-slate-700 align-top" data-search="06/01oem_fts_getdeviceidread">
<td class="p-2 font-mono whitespace-nowrap">06/01</td>
<td class="p-2">OEM_FTS_GetDeviceID
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">0 exact (handler)</td>
<td class="p-2">16 bytes including CC on success</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="06/37oem_fts_getsystemguidread">
<td class="p-2 font-mono whitespace-nowrap">06/37</td>
<td class="p-2">OEM_FTS_GetSystemGUID
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">0 exact (handler)</td>
<td class="p-2">17 bytes including CC plus 16-byte GUID on success</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="06/45oem_fts_setusernameuser identity mutation; malformed-input out-of-bounds read candidate and standard-validation bypass on successful config write">
<td class="p-2 font-mono whitespace-nowrap">06/45</td>
<td class="p-2">OEM_FTS_SetUserName
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">variable table; handler reads user selector byte0 and calls strlen(request+1) without validating request length or a NUL terminator</td>
<td class="p-2">one-byte CC 00 when Fujitsu configuration write succeeds; standard SetUserName response only when that write fails</td>
<td class="p-2">user identity mutation; malformed-input out-of-bounds read candidate and standard-validation bypass on successful config write</td>
<td class="p-2">handler decompiled at 0x00028c90; backend index handling and exploitability unproven
normal OEM map; static; Admin table privilege still applies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="06/47oem_fts_setuserpasswordcredential mutation">
<td class="p-2 font-mono whitespace-nowrap">06/47</td>
<td class="p-2">OEM_FTS_SetUserPassword
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">variable table; standard Set User Password format</td>
<td class="p-2">standard handler response</td>
<td class="p-2">credential mutation</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="06/43oem_fts_setuseraccessuser privilege mutation">
<td class="p-2 font-mono whitespace-nowrap">06/43</td>
<td class="p-2">OEM_FTS_SetUserAccess
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">variable table; standard Set User Access format</td>
<td class="p-2">standard handler response</td>
<td class="p-2">user privilege mutation</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="06/40oem_fts_setchaccesschannel access mutation">
<td class="p-2 font-mono whitespace-nowrap">06/40</td>
<td class="p-2">OEM_FTS_SetChAccess
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x04 · 3 length</td>
<td class="p-2">3 exact (table)</td>
<td class="p-2">standard handler response, possibly replaced by AMI KCS/LAN interface hook</td>
<td class="p-2">channel access mutation</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="06/58oem_fts_setsysteminfoparamsystem-info mutation">
<td class="p-2 font-mono whitespace-nowrap">06/58</td>
<td class="p-2">OEM_FTS_SetSystemInfoParam
g_Oem_App_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">variable table; standard Set System Info format</td>
<td class="p-2">standard handler response</td>
<td class="p-2">system-info mutation</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/10 · lun 3oem_fts_getinventorylun3read">
<td class="p-2 font-mono whitespace-nowrap">0a/10 · LUN 3</td>
<td class="p-2">OEM_FTS_GetInventoryLUN3
g_LUN11_App_CmdHndlr · wire LUN 3</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">variable table; reads first device-selector byte</td>
<td class="p-2">4 bytes including CC, hidden FRU size LE16, access byte</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled; LAN reachability unproven
static LUN-3 dispatch; prior LAN LUN-3 request returned CC c0</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/11 · lun 3oem_fts_readfrudatalun3read hidden fru">
<td class="p-2 font-mono whitespace-nowrap">0a/11 · LUN 3</td>
<td class="p-2">OEM_FTS_ReadFRUDataLUN3
g_LUN11_App_CmdHndlr · wire LUN 3</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">4 exact (handler): device, offset LE16, count</td>
<td class="p-2">on success CC, returned count, data</td>
<td class="p-2">read hidden FRU</td>
<td class="p-2">handler decompiled; LAN reachability unproven
static LUN-3 dispatch; prior LAN LUN-3 request returned CC c0</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/12 · lun 3oem_fts_writefrudatalun3hidden fru mutation">
<td class="p-2 font-mono whitespace-nowrap">0a/12 · LUN 3</td>
<td class="p-2">OEM_FTS_WriteFRUDataLUN3
g_LUN11_App_CmdHndlr · wire LUN 3</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">at least 4 (handler): device, offset LE16, data</td>
<td class="p-2">on success CC and written count</td>
<td class="p-2">hidden FRU mutation</td>
<td class="p-2">handler decompiled; LAN reachability unproven
static LUN-3 dispatch; prior LAN LUN-3 request returned CC c0</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/00bladesetbiosflashparatftpwrite or append configured tftp server address for bios flash; helper uses strnlen(31) but inet_pton reads text without guaranteed in-payload nul terminator">
<td class="p-2 font-mono whitespace-nowrap">34/00</td>
<td class="p-2">bladesetBiosFlashParaTftp
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 32 bytes [selector 01 replace or 02 append,address text in bytes1..31]; address must parse as IPv4/IPv6 unless config permits non-IP names; append requires 1..30 text bytes</td>
<td class="p-2">[cc]; C9 invalid selector/text or wrapper length, CE feature disabled, otherwise configuration-write result byte</td>
<td class="p-2">write or append configured TFTP server address for BIOS flash; helper uses strnlen(31) but inet_pton reads text without guaranteed in-payload NUL terminator</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/01bladegetbiosflashparatftpread paged configured tftp server address for bios flash">
<td class="p-2 font-mono whitespace-nowrap">34/01</td>
<td class="p-2">bladegetBiosFlashParaTftp
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte selector 1/2</td>
<td class="p-2">32 bytes [cc,31-byte zero-padded page] on helper path; selector 1 reads bytes 0..30 and selector 2 bytes 31..61 from stored string; FF if config read fails, C9 invalid wrapper length/selector, CE feature disabled</td>
<td class="p-2">read paged configured TFTP server address for BIOS flash</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/02setbiosflashparameterimagenameselector 01 writes first 31 bytes of bios image-name config; selector&gt;=02 reads 62-byte page and overwrites bytes31..61; helper strlen on request+1 may read past fixed request when unterminated">
<td class="p-2 font-mono whitespace-nowrap">34/02</td>
<td class="p-2">setBiosFlashParameterImageName
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 32 bytes [selector 01 replace or selector&gt;=02 second page,31 image-name bytes]; second-page branch requires strlen(request+1)&lt;=30, then copies all 31 bytes into offsets31..61 of 62-byte config page</td>
<td class="p-2">1 byte [cc]; C9 wrong length; backend write error propagated, but success path does not visibly assign CC in helper</td>
<td class="p-2">selector 01 writes first 31 bytes of BIOS image-name config; selector&gt;=02 reads 62-byte page and overwrites bytes31..61; helper strlen on request+1 may read past fixed request when unterminated</td>
<td class="p-2">partial
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/03getbiosflashparameterimagenameread paged bios flash image name from 62-byte configuration buffer">
<td class="p-2 font-mono whitespace-nowrap">34/03</td>
<td class="p-2">getBiosFlashParameterImageName
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte selector 1/2</td>
<td class="p-2">32 bytes [cc,31-byte zero-padded page] on success or page exhaustion; selector 1 reads bytes 0..30, selector 2 reads bytes 31..61; config-read error returns single-byte backend error; C9 invalid selector/length, CE feature disabled</td>
<td class="p-2">read paged BIOS flash image name from 62-byte configuration buffer</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/04examinebiosparametersets bios flash override/status, validates configured tftp address and image name, then starts detached validation thread; cc00 is not proof validation or update completed">
<td class="p-2 font-mono whitespace-nowrap">34/04</td>
<td class="p-2">examineBiosParameter
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty; nonempty returns C9</td>
<td class="p-2">[cc]: 00 when async validation thread starts or missing TFTP/image config only updates status; C9 invalid length/target; CC invalid server address; 0E config read failure; FF allocation/thread failure; CE feature disabled</td>
<td class="p-2">sets BIOS flash override/status, validates configured TFTP address and image name, then starts detached validation thread; CC00 is not proof validation or update completed</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/05bladestartbiosflashtftpstarts asynchronous bios tftp flash worker after loading server and image config; updates flash status before thread creation; cc00 does not mean flash completed">
<td class="p-2 font-mono whitespace-nowrap">34/05</td>
<td class="p-2">bladestartBiosFlashTftp
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc]: 00 when detached updater thread starts, D3 missing flash configuration, C0 flash marker already exists or stat error, FF allocation/thread failure, C9 nonempty request, CE feature disabled</td>
<td class="p-2">starts asynchronous BIOS TFTP flash worker after loading server and image config; updates flash status before thread creation; CC00 does not mean flash completed</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/06bladesetirmcflashparatftpwrite or append configured tftp server address for irmc flash; shared helper has unterminated-text and oversized-append hazards">
<td class="p-2 font-mono whitespace-nowrap">34/06</td>
<td class="p-2">bladesetiRMCFlashParaTftp
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 32 bytes [selector 01 replace or 02 append,address text in bytes1..31]; address must parse as IPv4/IPv6 unless config permits non-IP names; append requires 1..30 text bytes</td>
<td class="p-2">[cc]; C9 invalid selector/text or wrapper length, CE feature disabled, otherwise configuration-write result byte</td>
<td class="p-2">write or append configured TFTP server address for iRMC flash; shared helper has unterminated-text and oversized-append hazards</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/07bladegetirmcflashparatftpread paged configured tftp server address for irmc flash">
<td class="p-2 font-mono whitespace-nowrap">34/07</td>
<td class="p-2">bladegetiRMCFlashParaTftp
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte selector 1/2</td>
<td class="p-2">32 bytes [cc,31-byte zero-padded page] on helper path; selector 1 reads bytes 0..30 and selector 2 bytes 31..61 from stored string; FF if config read fails, C9 invalid wrapper length/selector, CE feature disabled</td>
<td class="p-2">read paged configured TFTP server address for iRMC flash</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/08setirmcflashparameterimagenameselector 01 writes first 31 bytes of irmc image-name config; selector&gt;=02 reads 62-byte page and overwrites bytes31..61; helper strlen on request+1 may read past fixed request when unterminated">
<td class="p-2 font-mono whitespace-nowrap">34/08</td>
<td class="p-2">setiRMCFlashParameterImageName
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 32 bytes [selector 01 replace or selector&gt;=02 second page,31 image-name bytes]; second-page branch requires strlen(request+1)&lt;=30, then copies all 31 bytes into offsets31..61 of 62-byte config page</td>
<td class="p-2">1 byte [cc]; C9 wrong length; backend write error propagated, but success path does not visibly assign CC in helper</td>
<td class="p-2">selector 01 writes first 31 bytes of iRMC image-name config; selector&gt;=02 reads 62-byte page and overwrites bytes31..61; helper strlen on request+1 may read past fixed request when unterminated</td>
<td class="p-2">partial
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/09getirmcflashparameterimagenameread paged irmc flash image name from 62-byte configuration buffer">
<td class="p-2 font-mono whitespace-nowrap">34/09</td>
<td class="p-2">getiRMCFlashParameterImageName
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte selector 1/2</td>
<td class="p-2">32 bytes [cc,31-byte zero-padded page] on success or page exhaustion; selector 1 reads bytes 0..30, selector 2 reads bytes 31..61; config-read error returns single-byte backend error; C9 invalid selector/length, CE feature disabled</td>
<td class="p-2">read paged iRMC flash image name from 62-byte configuration buffer</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/0aexamineirmcparametersets irmc flash override/status, validates configured tftp address and image name, then starts detached validation thread; cc00 is not proof validation or update completed">
<td class="p-2 font-mono whitespace-nowrap">34/0a</td>
<td class="p-2">examineiRMCParameter
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty; nonempty returns C9</td>
<td class="p-2">[cc]: 00 when async validation thread starts or missing TFTP/image config only updates status; C9 invalid length/target; CC invalid server address; 0E config read failure; FF allocation/thread failure; CE feature disabled</td>
<td class="p-2">sets iRMC flash override/status, validates configured TFTP address and image name, then starts detached validation thread; CC00 is not proof validation or update completed</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/0bstartirmcfflasloads tftp server/image config, sets upload selector and pending flash status, then posts firmware-flash task for current channel; on successful session type 6 also requests mmb sel">
<td class="p-2 font-mono whitespace-nowrap">34/0b</td>
<td class="p-2">startiRMCFFlas
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=1 byte; byte 0 is firmware-upload selector accepted by helper for 00..05 or FF (other values CC); trailing bytes ignored</td>
<td class="p-2">[cc]: 00 when pending flash task posted; CC invalid upload selector/empty request, D1 already in active flash mode, FF missing config or flasher failure, CE feature disabled</td>
<td class="p-2">loads TFTP server/image config, sets upload selector and pending flash status, then posts firmware-flash task for current channel; on successful session type 6 also requests MMB SEL</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/0cgetbiosflashstatusread current bios tftp flash progress/status and two detail bytes">
<td class="p-2 font-mono whitespace-nowrap">34/0c</td>
<td class="p-2">getBiosFlashStatus
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty; nonempty returns C9</td>
<td class="p-2">4 bytes [00,flash_status,flash_detail_0,flash_detail_1] via tflashGetStatus; C9 nonempty request, CE feature disabled</td>
<td class="p-2">read current BIOS TFTP flash progress/status and two detail bytes</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/0dgetirmcflashstatusread irmc tftp flash status">
<td class="p-2 font-mono whitespace-nowrap">34/0d</td>
<td class="p-2">getiRMCFlashStatus
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[00,status,byte,byte]</td>
<td class="p-2">read iRMC TFTP flash status</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/0eresetflashstatusreset bios/irmc flash status; malformed lengths still read selector and may mutate">
<td class="p-2 font-mono whitespace-nowrap">34/0e</td>
<td class="p-2">resetFlashStatus
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">nominally exactly 1 byte selector 0/1</td>
<td class="p-2">[cc,previous_status] on recognized selector</td>
<td class="p-2">reset BIOS/iRMC flash status; malformed lengths still read selector and may mutate</td>
<td class="p-2">direct
Registered Admin; handler checks a feature-global (CE when off); live rack state unproved.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/10getmastermmblocation_d010read mmb location gpio 0x1e; blade only">
<td class="p-2 font-mono whitespace-nowrap">34/10</td>
<td class="p-2">getMasterMmbLocation_D010
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,location 1|2]</td>
<td class="p-2">read MMB location GPIO 0x1e; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/11setmastermmblocationtrigger mmb role change; blade only">
<td class="p-2 font-mono whitespace-nowrap">34/11</td>
<td class="p-2">setMasterMmbLocation
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte location</td>
<td class="p-2">[cc]</td>
<td class="p-2">trigger MMB role change; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/1agetdnsnameread blade dns name page">
<td class="p-2 font-mono whitespace-nowrap">34/1a</td>
<td class="p-2">getDnsName
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte page index</td>
<td class="p-2">[cc,total_length,page,up to 20 DNS chars]</td>
<td class="p-2">read blade DNS name page</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/20setirmcpowercontrolpolicymutates runtime power-control state; fun_00037454 loads current mode/parameter config and can write a 52-byte state file, while fun_00037680 writes mode 0x1a00 and seven indexed parameter sets for mode 04 or five scalar records for mode 05; may clear active state on malformed mode-04/05 requests">
<td class="p-2 font-mono whitespace-nowrap">34/20</td>
<td class="p-2">setiRMCPowerControlPolicy
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">byte0 input mode 00 disables; 01/02 select simple policy; 03 only succeeds on an active-mode equality path; 04 needs &gt;=8 bytes and uses bytes1/3/5/6 at unchecked seven-slot array index byte7; 05 needs &gt;=7 bytes and consumes bytes1..4/6. Input 06 is rejected C9, though an internal mode-06 branch is reachable from input 05</td>
<td class="p-2">usually 3 bytes [00,requested_mode,00]; input 05's internal mode-06 branch returns 1 byte; C7 short mode-04/05 request, C9 unsupported mode, CE feature disabled. Config read/write and state-file helper results are ignored, so CC00 does not prove persistence</td>
<td class="p-2">mutates runtime power-control state; FUN_00037454 loads current mode/parameter config and can write a 52-byte state file, while FUN_00037680 writes mode 0x1a00 and seven indexed parameter sets for mode 04 or five scalar records for mode 05; may clear active state on malformed mode-04/05 requests</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/21getirmcpowercontrolpolicyread persisted policy id 0x1a00; stored mode 04 reads four records selected by requested index, with the final two-byte read overlapping response byte7 and writing byte8 beyond returned length; stored mode 05 reads four scalar records">
<td class="p-2 font-mono whitespace-nowrap">34/21</td>
<td class="p-2">getiRMCPowerControlPolicy
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=1 byte; byte0 policy index 0..6; trailing bytes ignored</td>
<td class="p-2">[00,mode] for stored config 0/1/2/6, or 8 bytes [00,mode,6 config bytes] for stored mode 4/5; stored mode4 is reported as mode3, stored mode5 as mode4, stored mode6 as mode5; C7 empty request, CC index&gt;6, C9 unsupported stored mode, 80 any config-read error, CE feature disabled</td>
<td class="p-2">read persisted policy ID 0x1a00; stored mode 04 reads four records selected by requested index, with the final two-byte read overlapping response byte7 and writing byte8 beyond returned length; stored mode 05 reads four scalar records</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/22getactualirmcperformancestateread performance state combining config 0x1a00 and node manager">
<td class="p-2 font-mono whitespace-nowrap">34/22</td>
<td class="p-2">getActualiRMCPerformanceState
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,state]</td>
<td class="p-2">read performance state combining config 0x1a00 and Node Manager</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/23forceirmcminpowerstartforce minimum power; save policy and write config 0x1a00=2">
<td class="p-2 font-mono whitespace-nowrap">34/23</td>
<td class="p-2">forceiRMCMinPowerStart
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc]</td>
<td class="p-2">force minimum power; save policy and write config 0x1a00=2</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/24forceirmcminpowerendend minimum power; restore saved policy">
<td class="p-2 font-mono whitespace-nowrap">34/24</td>
<td class="p-2">forceiRMCMinPowerEnd
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc]</td>
<td class="p-2">end minimum power; restore saved policy</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/27setfandutycycleset fan duty; second byte purpose unknown">
<td class="p-2 font-mono whitespace-nowrap">34/27</td>
<td class="p-2">setFanDutyCycle
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 2 bytes; byte 0 duty used</td>
<td class="p-2">[cc]</td>
<td class="p-2">set fan duty; second byte purpose unknown</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/28getfandutycycleread fan duty">
<td class="p-2 font-mono whitespace-nowrap">34/28</td>
<td class="p-2">getFanDutyCycle
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,duty]</td>
<td class="p-2">read fan duty</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/29setpoweronledforce power-on led on">
<td class="p-2 font-mono whitespace-nowrap">34/29</td>
<td class="p-2">setPowerOnLed
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc]</td>
<td class="p-2">force power-on LED on</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/2agetpowerconsumptionhistorysampleread power history sample with class-specific index bounds">
<td class="p-2 font-mono whitespace-nowrap">34/2a</td>
<td class="p-2">getPowerConsumptionHistorySample
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">[class,index_le16], no local length check</td>
<td class="p-2">[cc,0c,12-byte sample]</td>
<td class="p-2">read power history sample with class-specific index bounds</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/2cgetpowercappingcountermode 0 clears prior nm flag, starts cpu-throttling averaging interval and conditionally resets runtime counters; other modes page a saved 20-byte runtime array">
<td class="p-2 font-mono whitespace-nowrap">34/2c</td>
<td class="p-2">getPowerCappingCounter
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty reuses stored mode; nonempty byte 0 sets stored mode; if length &gt;1, blindly copies 20 bytes from request+1 to runtime state regardless of actual length</td>
<td class="p-2">mode 0: 7 bytes [cc,prior NM flag,00,counter_a_le16,counter_b_le16]; other modes: 3 bytes [cc,saved_page_byte,mode], with saved-page cursor advancing up to 20</td>
<td class="p-2">mode 0 clears prior NM flag, starts CPU-throttling averaging interval and conditionally resets runtime counters; other modes page a saved 20-byte runtime array</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/2dgetpowerconsumptionsensornumberresolve power-consumption sdr sensors for entities 0x1b/0xe0">
<td class="p-2 font-mono whitespace-nowrap">34/2d</td>
<td class="p-2">getPowerConsumptionSensorNumber
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 2 bytes; byte 0 mask used</td>
<td class="p-2">[cc,sensor IDs]</td>
<td class="p-2">resolve power-consumption SDR sensors for entities 0x1b/0xe0</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/2egetenhancedpowerbudgetread enhanced power budget; c1 on non-blade">
<td class="p-2 font-mono whitespace-nowrap">34/2e</td>
<td class="p-2">getEnhancedPowerBudget
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,big-endian uint32]</td>
<td class="p-2">read enhanced power budget; C1 on non-blade</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/44setekeystatuscopy e-key status to runtime state; blade only">
<td class="p-2 font-mono whitespace-nowrap">34/44</td>
<td class="p-2">setEKeyStatus
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes</td>
<td class="p-2">[cc]</td>
<td class="p-2">copy E-key status to runtime state; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/45sethssdataclears 63-byte per-port hss runtime data, saves declared length, and copies that many bytes from request+3; declared length can exceed supplied payload">
<td class="p-2 font-mono whitespace-nowrap">34/45</td>
<td class="p-2">setHssData
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=4 bytes [selector(1..4),class(high nibble of byte1 &lt;=5),declared_length(0..63),data...]; selector/class gate and declared length checked but actual data bytes not checked</td>
<td class="p-2">[cc]: 00 copied, C9 invalid selector/class/declared length, C7 request shorter than 4, C1 non-blade</td>
<td class="p-2">clears 63-byte per-port HSS runtime data, saves declared length, and copies that many bytes from request+3; declared length can exceed supplied payload</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/46getsetuserassettagget reads config id 0x210; set stages data in 40-byte runtime buffer, clears it on page index 0, and writes config id 0x210 when byte 1 bit7 is set">
<td class="p-2 font-mono whitespace-nowrap">34/46</td>
<td class="p-2">getSetUserAssetTag
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">get: exactly 2 bytes [0x80|page_size(0..20),page_index(low nibble)]; set: 3..22 bytes [page_size(1..20),page_index(low nibble)|commit(bit7),data(1..page_size bytes)]; offset=page_size*page_index, max config size 40</td>
<td class="p-2">get: [cc,total_length,data(0..page_size bytes)]; set: [cc,bytes_written]; errors: C7 bad length, C9 invalid page/offset, CB config backend failure, C1 non-blade</td>
<td class="p-2">get reads config ID 0x210; set stages data in 40-byte runtime buffer, clears it on page index 0, and writes config ID 0x210 when byte 1 bit7 is set</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/47enalbeeventlognotificationget/set sel notification; blade only">
<td class="p-2 font-mono whitespace-nowrap">34/47</td>
<td class="p-2">enalbeEventLogNotification
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty get; one byte bit7 sets state</td>
<td class="p-2">[cc,state bit7]</td>
<td class="p-2">get/set SEL notification; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/4agetbladeselentrylongtextipmiread paged, formatted sel long text through shared getbladeselentrylongtext/formatselentrylongtext helpers">
<td class="p-2 font-mono whitespace-nowrap">34/4a</td>
<td class="p-2">getBladeSelEntryLongTextIpmi
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">alias of 30/AD: exactly 4 bytes [SEL_record_id_le16,text_offset,requested_chunk_length]; zero or &gt;32 chunk length is clamped to 32</td>
<td class="p-2">alias of 30/AD: [cc,next_record_id_le16,7-byte SEL header,severity,total_text_length_minus_one,text_chunk,NUL]; success length 13..45, C6 on successful clamped &gt;32 request, C9 missing record, CB decode failure, C7 wrong length, C1 non-blade</td>
<td class="p-2">read paged, formatted SEL long text through shared getBladeSelEntryLongText/FormatSelEntryLongText helpers</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/61getirmcldapdepartmentread configuration string for ldap department">
<td class="p-2 font-mono whitespace-nowrap">34/61</td>
<td class="p-2">getIrmcLdapDepartment
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,NUL-terminated LDAP department]</td>
<td class="p-2">read configuration string for LDAP department</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/40getlancardfruidread lan-card fru id through interface control; platform mapping partial">
<td class="p-2 font-mono whitespace-nowrap">34/40</td>
<td class="p-2">getLanCardFruId
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 2 bytes: port selector and peer field</td>
<td class="p-2">[cc,fru_id,property_lo,property_hi,flag]</td>
<td class="p-2">read LAN-card FRU ID through interface control; platform mapping partial</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/41disablelanportunconditional command-invalid stub; does not disable lan">
<td class="p-2 font-mono whitespace-nowrap">34/41</td>
<td class="p-2">disableLanPort
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[c1]</td>
<td class="p-2">unconditional command-invalid stub; does not disable LAN</td>
<td class="p-2">direct
Registered Admin; handler itself unconditionally returns C1.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/42getmezzaninemuxsettingsread mezzanine mux through interface control">
<td class="p-2 font-mono whitespace-nowrap">34/42</td>
<td class="p-2">getMezzanineMuxSettings
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">first byte nonzero mezzanine index; no local length check</td>
<td class="p-2">[cc,mux_state]</td>
<td class="p-2">read mezzanine mux through interface control</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/43setmezzaninemuxsettingsset mezzanine mux through interface control">
<td class="p-2 font-mono whitespace-nowrap">34/43</td>
<td class="p-2">setMezzanineMuxSettings
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">first byte nonzero index, second byte low two bits mux; no local length check</td>
<td class="p-2">[cc]</td>
<td class="p-2">set mezzanine mux through interface control</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/49getavrsessioncntread avr session count; ce feature off, ff backend failure">
<td class="p-2 font-mono whitespace-nowrap">34/49</td>
<td class="p-2">getAVRSessionCnt
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,count]</td>
<td class="p-2">read AVR session count; CE feature off, FF backend failure</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/62getbssosessiondatareserves sso session through message-queue daemon; session-based transport caps requested privilege to channel user&#39;s privilege and masks requested flags by configureuser/configurebmc/avr/remote-storage rights; non-session/ipmb paths choose default or requested username differently">
<td class="p-2 font-mono whitespace-nowrap">34/62</td>
<td class="p-2">getBssoSessionData
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=5 bytes [requested_privilege,requested_flags_le32,optional_username_bytes(5..20),optional_aux_bytes(21..66)]; bytes beyond offset66 ignored; handler itself only checks length&gt;4</td>
<td class="p-2">[cc] on failure or 25 bytes [00,24-byte session material] on IPC success; D5 SSO disabled, C0 no current session on session-based transport, CE IPC queue absent, 82 daemon reply invalid, C7 request &lt;=4</td>
<td class="p-2">reserves SSO session through message-queue daemon; session-based transport caps requested privilege to channel user's privilege and masks requested flags by ConfigureUser/ConfigureBmc/AVR/remote-storage rights; non-session/IPMB paths choose default or requested username differently</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/63getserverbladetyperead server-blade product type">
<td class="p-2 font-mono whitespace-nowrap">34/63</td>
<td class="p-2">getServerbladeType
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,product_id_le16,00,00]</td>
<td class="p-2">read server-blade product type</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/38backupirmcsingleparameterallocates parameter buffer, invokes spbackupirmcparameter, returns page*24 slice of backed-up configuration parameter. backend searches a 92-record static table (id 0 marker plus 91 distinct ids), bounds-checks sub-id against each record&#39;s exclusive limit, reads configuration or special parameter classes, and returns table type/restriction metadata. high-impact mapped ids include 0x1452 user password, 0x197a ldap auth password, 0x1273 smtp auth password, 0x1981 ssl private key, 0x1982/0x1983 certificates, 0x1440-0x1442 network addresses, and 0xffff local encryption parameter; actual secret contents may depend on the configuration provider. allocator gives 257 bytes normally, 1537 for key id 0x1981, and 2561 for certificate ids 0x1982/0x1983, smaller than their table-declared maxima">
<td class="p-2 font-mono whitespace-nowrap">34/38</td>
<td class="p-2">backupiRMCSingleParameter
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 6 bytes [id_le16,sub_le16,page_le16]</td>
<td class="p-2">success 9..33 bytes [cc,id_le16,sub_le16,type_code,restore_restriction_flag,total_length_le16,page_data(0..24)]; type_code comes from table +0x0c (0 numeric, 1 or 2 other table classes); flag comes from +0x14 (0/1, with 1 rejecting ordinary restore); cc 00 last page, CA more pages; CE disabled or page beyond length, C9 wrong request length, CB backend code 0x18, CC other backend/alloc failure</td>
<td class="p-2">allocates parameter buffer, invokes spBackupiRMCParameter, returns page*24 slice of backed-up configuration parameter. Backend searches a 92-record static table (ID 0 marker plus 91 distinct IDs), bounds-checks sub-ID against each record's exclusive limit, reads configuration or special parameter classes, and returns table type/restriction metadata. High-impact mapped IDs include 0x1452 user password, 0x197a LDAP auth password, 0x1273 SMTP auth password, 0x1981 SSL private key, 0x1982/0x1983 certificates, 0x1440-0x1442 network addresses, and 0xffff local encryption parameter; actual secret contents may depend on the configuration provider. Allocator gives 257 bytes normally, 1537 for key ID 0x1981, and 2561 for certificate IDs 0x1982/0x1983, smaller than their table-declared maxima</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/39restoreirmcsingleparameterstages and commits parameter restoration via sprestoreirmcparameter; page 0 allocates total+1 and copies 24 bytes regardless supplied payload length; direct short-total path similarly passes request+8 without validating remaining data. backend uses the same 92-record id table, rejects sub-id at or above a record&#39;s exclusive limit, rejects values longer than record maximum (or &gt;4 bytes for type 0), converts type-0 negative 32-bit values to their declared 1/2-byte width, and writes via writeconfigurationspace with table-dependent sub-id adjustment or ip-address text-to-binary conversion. the table&#39;s +0x14 restriction flag blocks restore for flagged ids except 0xffff; flagged ordinary ids include user, ldap, and smtp passwords">
<td class="p-2 font-mono whitespace-nowrap">34/39</td>
<td class="p-2">restoreiRMCSingleParameter
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=8 bytes [id_le16,sub_le16,page_le16,total_le16,data...]; total&lt;=24 calls backend directly with total bytes; larger total stages pages of 24 bytes (up to five concurrent staging slots), final page copies remaining total-page*24 bytes then commits</td>
<td class="p-2">[cc]: 00 page staged/restore succeeded, C9 invalid page/sequence or exactly 8-byte request, FF buffer allocation/backend failure, CE feature disabled</td>
<td class="p-2">stages and commits parameter restoration via spRestoreiRMCParameter; page 0 allocates total+1 and copies 24 bytes regardless supplied payload length; direct short-total path similarly passes request+8 without validating remaining data. Backend uses the same 92-record ID table, rejects sub-ID at or above a record's exclusive limit, rejects values longer than record maximum (or &gt;4 bytes for type 0), converts type-0 negative 32-bit values to their declared 1/2-byte width, and writes via WriteConfigurationSpace with table-dependent sub-ID adjustment or IP-address text-to-binary conversion. The table's +0x14 restriction flag blocks restore for flagged IDs except 0xffff; flagged ordinary IDs include user, LDAP, and SMTP passwords</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="34/80getadaptivemodedebuginfounconditional command-invalid stub">
<td class="p-2 font-mono whitespace-nowrap">34/80</td>
<td class="p-2">getAdaptiveModeDebugInfo
g_OEM_D0_CmdHndlrBlade · blade D0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[c1]</td>
<td class="p-2">unconditional command-invalid stub</td>
<td class="p-2">direct
Registered Admin; handler itself unconditionally returns C1.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/00getbootwatchdogtimeread boot-watchdog tier; tiers 0–7 map 120–6000 seconds">
<td class="p-2 font-mono whitespace-nowrap">30/00</td>
<td class="p-2">getBootWatchdogTime
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,tier_le16,minutes]</td>
<td class="p-2">read boot-watchdog tier; tiers 0–7 map 120–6000 seconds</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/01setbootwatchdogtimeset boot-watchdog timeout; extended minute 0–100">
<td class="p-2 font-mono whitespace-nowrap">30/01</td>
<td class="p-2">setBootWatchdogTime
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">tier_le16 or &gt;=3 bytes with extended minute at offset 2</td>
<td class="p-2">[cc]</td>
<td class="p-2">set boot-watchdog timeout; extended minute 0–100</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/02getbootwatchdogenableread boot-watchdog enable">
<td class="p-2 font-mono whitespace-nowrap">30/02</td>
<td class="p-2">getBootWatchdogEnable
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,state]</td>
<td class="p-2">read boot-watchdog enable</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/03setbootwatchdogenableset boot-watchdog enable">
<td class="p-2 font-mono whitespace-nowrap">30/03</td>
<td class="p-2">setBootWatchdogEnable
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">[state 0|1]</td>
<td class="p-2">[cc]</td>
<td class="p-2">set boot-watchdog enable</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/04getbootwatchdogbehaviorread watchdog behavior">
<td class="p-2 font-mono whitespace-nowrap">30/04</td>
<td class="p-2">getBootWatchdogBehavior
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,state]</td>
<td class="p-2">read watchdog behavior</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/05setbootwatchdogbehaviorset watchdog behavior; no local range check">
<td class="p-2 font-mono whitespace-nowrap">30/05</td>
<td class="p-2">setBootWatchdogBehavior
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">[behavior]</td>
<td class="p-2">[cc]</td>
<td class="p-2">set watchdog behavior; no local range check</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/06getpowerfailbehaviorread ac power-restore policy">
<td class="p-2 font-mono whitespace-nowrap">30/06</td>
<td class="p-2">getPowerFailBehavior
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,restore_policy]</td>
<td class="p-2">read AC power-restore policy</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/07setpowerfailbehaviorset ac power-restore policy; no local range check">
<td class="p-2 font-mono whitespace-nowrap">30/07</td>
<td class="p-2">setPowerFailBehavior
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">[restore_policy]</td>
<td class="p-2">[cc]</td>
<td class="p-2">set AC power-restore policy; no local range check</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/0agetrebootretrycounterread configuration id 0x30">
<td class="p-2 font-mono whitespace-nowrap">30/0a</td>
<td class="p-2">getRebootRetryCounter
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,retry_count]</td>
<td class="p-2">read configuration ID 0x30</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/0bsetrebootretrycounterwrite one byte to configuration id 0x30">
<td class="p-2 font-mono whitespace-nowrap">30/0b</td>
<td class="p-2">setRebootRetryCounter
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=1 byte, first byte used</td>
<td class="p-2">[cc]</td>
<td class="p-2">write one byte to configuration ID 0x30</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/10geterroffrestarttimeread error-off restart delay from configuration id 0x32">
<td class="p-2 font-mono whitespace-nowrap">30/10</td>
<td class="p-2">getErrOffRestartTime
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,restart_delay_le16]</td>
<td class="p-2">read error-off restart delay from configuration ID 0x32</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/11seterroffrestarttimewrite error-off restart delay to configuration id 0x32">
<td class="p-2 font-mono whitespace-nowrap">30/11</td>
<td class="p-2">setErrOffRestartTime
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=2 bytes, first LE16 used</td>
<td class="p-2">[cc]</td>
<td class="p-2">write error-off restart delay to configuration ID 0x32</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/12startloopbackteststart/stop nic loopback thread; cc d5 if already busy">
<td class="p-2 font-mono whitespace-nowrap">30/12</td>
<td class="p-2">startLoopBackTest
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">5 bytes: NIC selector plus LE32 loopback value</td>
<td class="p-2">[cc]</td>
<td class="p-2">start/stop NIC loopback thread; CC D5 if already busy</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/13getloopbackstatusread loopback status for selected nic">
<td class="p-2 font-mono whitespace-nowrap">30/13</td>
<td class="p-2">getLoopBackStatus
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">[NIC selector]</td>
<td class="p-2">15 bytes on success: cc,state,status,counters</td>
<td class="p-2">read loopback status for selected NIC</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/14getcriticalflagread critical flag byte">
<td class="p-2 font-mono whitespace-nowrap">30/14</td>
<td class="p-2">getCriticalFlag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,flags]</td>
<td class="p-2">read critical flag byte</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/15setcriticalflagset critical flag bit 0">
<td class="p-2 font-mono whitespace-nowrap">30/15</td>
<td class="p-2">setCriticalFlag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc]</td>
<td class="p-2">set critical flag bit 0</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/16resetcriticalflagclear entire critical flag byte">
<td class="p-2 font-mono whitespace-nowrap">30/16</td>
<td class="p-2">resetCriticalFlag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc]</td>
<td class="p-2">clear entire critical flag byte</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/18getcpubladeidreturn platform blade-port index +1">
<td class="p-2 font-mono whitespace-nowrap">30/18</td>
<td class="p-2">getCpuBladeId
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,blade_id]</td>
<td class="p-2">return platform blade-port index +1</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/19clearpohcounterclear battery-backed power-on-hours state">
<td class="p-2 font-mono whitespace-nowrap">30/19</td>
<td class="p-2">clearPohCounter
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc]</td>
<td class="p-2">clear battery-backed power-on-hours state</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/1agetenablememorymoduleread memory-enable mask from config id 0x21; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/1a</td>
<td class="p-2">getEnableMemoryModule
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,4 config bytes]</td>
<td class="p-2">read memory-enable mask from config ID 0x21; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/1bsetenablememorymodulewrite memory-enable mask to config id 0x21; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/1b</td>
<td class="p-2">setEnableMemoryModule
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes</td>
<td class="p-2">[cc]</td>
<td class="p-2">write memory-enable mask to config ID 0x21; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/1cgetdisablememorymodulereasonread memory-disable reason config id 0x24; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/1c</td>
<td class="p-2">getDisableMemoryModuleReason
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,4 config bytes]</td>
<td class="p-2">read memory-disable reason config ID 0x24; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/1dsetdisablememorymodulereasonwrite memory-disable reason config id 0x24; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/1d</td>
<td class="p-2">setDisableMemoryModuleReason
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes</td>
<td class="p-2">[cc]</td>
<td class="p-2">write memory-disable reason config ID 0x24; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/20getgracefulshutdownenalberead graceful-shutdown enable">
<td class="p-2 font-mono whitespace-nowrap">30/20</td>
<td class="p-2">getGracefulShutdownEnalbe
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,state]</td>
<td class="p-2">read graceful-shutdown enable</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/21setgracefulshutdownenableset graceful-shutdown enable">
<td class="p-2 font-mono whitespace-nowrap">30/21</td>
<td class="p-2">setGracefulShutdownEnable
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">first byte; no local length check</td>
<td class="p-2">[cc]</td>
<td class="p-2">set graceful-shutdown enable</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/22getgracefulshutdownflagread shutdown communication flags masked 0x0b">
<td class="p-2 font-mono whitespace-nowrap">30/22</td>
<td class="p-2">getGracefulShutdownFlag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,flag]</td>
<td class="p-2">read shutdown communication flags masked 0x0b</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/23getenablecpuread cpu-enable mask from config id 0x20; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/23</td>
<td class="p-2">getEnableCpu
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,4 config bytes]</td>
<td class="p-2">read CPU-enable mask from config ID 0x20; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/24setenablecpuwrite cpu-enable mask to config id 0x20; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/24</td>
<td class="p-2">setEnableCpu
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes</td>
<td class="p-2">[cc]</td>
<td class="p-2">write CPU-enable mask to config ID 0x20; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/25getdisablecpureasonread cpu-disable reason config id 0x23; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/25</td>
<td class="p-2">getDisableCpuReason
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,4 config bytes]</td>
<td class="p-2">read CPU-disable reason config ID 0x23; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/26setdisablecpureasonwrite cpu-disable reason config id 0x23; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/26</td>
<td class="p-2">setDisableCpuReason
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes</td>
<td class="p-2">[cc]</td>
<td class="p-2">write CPU-disable reason config ID 0x23; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/27setdumpflagset power-off inhibit/dump flag; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/27</td>
<td class="p-2">setDumpflag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc]</td>
<td class="p-2">set power-off inhibit/dump flag; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/28cleardumpflagclear power-off inhibit/dump flag; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/28</td>
<td class="p-2">clearDumpflag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc]</td>
<td class="p-2">clear power-off inhibit/dump flag; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/32getsystemguidread two 16-byte system guid config records; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/32</td>
<td class="p-2">getSystemGuid
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,32 GUID bytes]</td>
<td class="p-2">read two 16-byte system GUID config records; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/51gethostsystemstatusread host power and message-led mode as a single status byte">
<td class="p-2 font-mono whitespace-nowrap">30/51</td>
<td class="p-2">getHostSystemStatus
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored; handler has no local request-length check</td>
<td class="p-2">6 bytes [cc,status,00,00,00,00] on blade; status 04 if LED mode 0 and host off, 00 if LED mode 0 and host on, 02 for LED modes 1/3/4, 03 for modes 2/5/6/7/8; C1 non-blade, CE unknown LED mode</td>
<td class="p-2">read host power and message-LED mode as a single status byte</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/52getcpuinforead cpu socket count/type, two minimum per-socket configuration values, cpu status, model/name chunks, manufacturer and component signal">
<td class="p-2 font-mono whitespace-nowrap">30/52</td>
<td class="p-2">getCpuInfo
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">selector 1 requires exactly [01] and needs active CPU cache; selectors 2/3/4/5 require exactly [selector,cpu_index], with index &lt;8 locally enforced for 3/4/5; selector 2 passes index to HAL</td>
<td class="p-2">selector 1: 7 bytes [cc,socket_count,cpu_type,min_config_a_le16,min_config_b_le16] or D5 if no populated CPU values; selector 2: 27 bytes [cc,status,cpu_count,4-byte config,10-byte sensor designator,10-byte manufacturer] on HAL success; selectors 3/4: variable CPU name string chunks; selector 5: 5 bytes [cc,component_status,00,00,00]; C7 length, C9 selector/index, C0 unavailable cache</td>
<td class="p-2">read CPU socket count/type, two minimum per-socket configuration values, CPU status, model/name chunks, manufacturer and component signal</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/53getmemoryinforead dimm status/type/capacity, enable/disable settings, lightpath designator, health, and spd module type">
<td class="p-2 font-mono whitespace-nowrap">30/53</td>
<td class="p-2">getMemoryInfo
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly [slot_index] for base view, or [slot_index,00/01]; index must be below HAL memory-slot count</td>
<td class="p-2">base/selector 00: 29 bytes [cc,slot_count,DIMM metadata bytes(2..13),10-byte lightpath designator/space pad at 14..23,4 config bytes at 24..27,health at 28]; selector 01: 3 bytes [cc,SPD-derived module type bytes]; C7 wrong length, C9 invalid slot, C0 cache unavailable</td>
<td class="p-2">read DIMM status/type/capacity, enable/disable settings, lightpath designator, health, and SPD module type</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/54getbootinforead boot configuration/status">
<td class="p-2 font-mono whitespace-nowrap">30/54</td>
<td class="p-2">getBootInfo
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">14 bytes on blade success</td>
<td class="p-2">read boot configuration/status</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/56setbootoptionwrite two boot-option bytes to config; blade only; ignores write result">
<td class="p-2 font-mono whitespace-nowrap">30/56</td>
<td class="p-2">setBootOption
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">handler reads first 2 bytes without local length check</td>
<td class="p-2">[cc]</td>
<td class="p-2">write two boot-option bytes to config; blade only; ignores write result</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/59setsrvbladeforceshutdownrequest host power-off">
<td class="p-2 font-mono whitespace-nowrap">30/59</td>
<td class="p-2">setSrvBladeForceShutdown
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc]</td>
<td class="p-2">request host power-off</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/5dsetsrvbladeeventupdate tftp flash status based on event bits 0x20/0x40">
<td class="p-2 font-mono whitespace-nowrap">30/5d</td>
<td class="p-2">setSrvBladeEvent
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">&gt;=2 bytes: blade ID, event bits</td>
<td class="p-2">[cc]</td>
<td class="p-2">update TFTP flash status based on event bits 0x20/0x40</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/57getseverbladestatusread blade power status">
<td class="p-2 font-mono whitespace-nowrap">30/57</td>
<td class="p-2">getSeverBladeStatus
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,power_good/status]</td>
<td class="p-2">read blade power status</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/5fgetdumpflagread power-off inhibit flag; blade only">
<td class="p-2 font-mono whitespace-nowrap">30/5f</td>
<td class="p-2">getDumpflag
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">empty</td>
<td class="p-2">[cc,inhibit_state]</td>
<td class="p-2">read power-off inhibit flag; blade only</td>
<td class="p-2">direct
Registered Admin; explicitly gated by utIsBladeSystem(), so C1 on rack where non-blade.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/68getassrconfigread configuration ids 0x74,0x41,0x30,0x32 and runtime power-restore policy; bucket maps timer intervals 0..7">
<td class="p-2 font-mono whitespace-nowrap">30/68</td>
<td class="p-2">getAssrConfig
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored; handler has no local request-length check</td>
<td class="p-2">12 bytes [cc,watchdog_behavior(0/1/3),00,power_restore_policy_shifted,watchdog_bucket_le16,config_0x30_byte,config_0x32_le16,00,00,watchdog_minutes_byte] on success; CE backend failure, C7 timer above platform cap</td>
<td class="p-2">read configuration IDs 0x74,0x41,0x30,0x32 and runtime power-restore policy; bucket maps timer intervals 0..7</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/69setassrconfigwrites config ids 0x74,0x41,0x30,0x32 and power-restore policy in mask order; partial writes can occur before a later validation/backend error">
<td class="p-2 font-mono whitespace-nowrap">30/69</td>
<td class="p-2">setAssrConfig
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">bitmask byte 0: bit7 writes watchdog behavior from byte1 (0/1/3), bit5 sets power-restore policy from byte3 (0/1/2), bit4 sets watchdog timer from bytes4-5 bucket or byte11 minutes when length&gt;=12, bit3 writes config ID 0x30 from byte6&amp;7, bit2 writes config ID 0x32 from bytes7-8; handler lacks comprehensive length check</td>
<td class="p-2">[cc]</td>
<td class="p-2">writes config IDs 0x74,0x41,0x30,0x32 and power-restore policy in mask order; partial writes can occur before a later validation/backend error</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/6agetwatchdogtimerenableread watchdog-enable state">
<td class="p-2 font-mono whitespace-nowrap">30/6a</td>
<td class="p-2">getWatchdogTimerEnable
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,state]</td>
<td class="p-2">read watchdog-enable state</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/6bsetwatchdogtimerenableset watchdog-enable state">
<td class="p-2 font-mono whitespace-nowrap">30/6b</td>
<td class="p-2">setWatchdogTimerEnable
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">first byte</td>
<td class="p-2">[cc]</td>
<td class="p-2">set watchdog-enable state</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/70setflashrecoveryset/query bios recovery; 0/1 are inverted at hal">
<td class="p-2 font-mono whitespace-nowrap">30/70</td>
<td class="p-2">setFlashRecovery
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte: 0/1 set, 2 query</td>
<td class="p-2">[cc,recovery_state]</td>
<td class="p-2">set/query BIOS recovery; 0/1 are inverted at HAL</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/75getbladelaninfopnigetlaninfo builds a 10-byte blade lan record: it zeroes output, places a port/controller byte at payload[0], interface-type byte at [1], six mac bytes at [2..7], and index/group bits at [8..9] after pni state checks">
<td class="p-2 font-mono whitespace-nowrap">30/75</td>
<td class="p-2">getBladeLanInfo
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte [index in low 7 bits (nonzero), mode in high bit]</td>
<td class="p-2">11 bytes [00,10-byte LAN structure] on backend success; C9 zero index, C7 wrong length, C0 platform/PNI not initialized, CE feature disabled or pniGetLanInfo failure</td>
<td class="p-2">pniGetLanInfo builds a 10-byte blade LAN record: it zeroes output, places a port/controller byte at payload[0], interface-type byte at [1], six MAC bytes at [2..7], and index/group bits at [8..9] after PNI state checks</td>
<td class="p-2">partial
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/80setserverbladelocaltimeset blade local time from mmb">
<td class="p-2 font-mono whitespace-nowrap">30/80</td>
<td class="p-2">setServerBladeLocalTime
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes LE time</td>
<td class="p-2">[cc]</td>
<td class="p-2">set blade local time from MMB</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/81getsystemlocaltimeread sel timestamp on blade">
<td class="p-2 font-mono whitespace-nowrap">30/81</td>
<td class="p-2">getSystemLocalTime
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,time_le32]</td>
<td class="p-2">read SEL timestamp on blade</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/87getpowerfullread blade type, actual or fallback power consumption, peripheral counts, and calculated/dummy power budget">
<td class="p-2 font-mono whitespace-nowrap">30/87</td>
<td class="p-2">getPowerFull
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">14 bytes [cc,blade_type,power_consumption_be32,pci_present,memory_slot_count,pci_card_count,mezzanine_card_count,power_budget_be32]; C1 on non-blade</td>
<td class="p-2">read blade type, actual or fallback power consumption, peripheral counts, and calculated/dummy power budget</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/96getfancontrolinfoincrements an internal call counter, resets it on sixth call, then resolves two fan sensor numbers via sdr lookup">
<td class="p-2 font-mono whitespace-nowrap">30/96</td>
<td class="p-2">getFanControlInfo
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">first five calls return [C0]; sixth call returns [00,06,sensor_0,00,00,sensor_1,00,00] when both sensor lookups succeed, else [CB]; CE if feature disabled</td>
<td class="p-2">increments an internal call counter, resets it on sixth call, then resolves two fan sensor numbers via SDR lookup</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/a3getbladeselentryread blade sel record by id using standard 16-byte sel record backend">
<td class="p-2 font-mono whitespace-nowrap">30/a3</td>
<td class="p-2">getBladeSelEntry
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">bytes 2–3 are SEL record ID little-endian; bytes 0–1 ignored; no local request-length check</td>
<td class="p-2">19 bytes [00,next_record_id_le16,16-byte SEL record] on success; [CB] if no record, [C1] non-blade</td>
<td class="p-2">read blade SEL record by ID using standard 16-byte SEL record backend</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/aagetperipheraleventstatusread i/o blade presence and peripheral-event sensor state">
<td class="p-2 font-mono whitespace-nowrap">30/aa</td>
<td class="p-2">getPeripheralEventStatus
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 1 byte; only selector 00 accepted</td>
<td class="p-2">6 bytes [cc,status,00,00,00,00]; selector!=0 gives [D5,01,00,00,00,00]; host off status 04; host on status 00/01/02/03/05 based on I/O blade presence and sensor state; C7 wrong length</td>
<td class="p-2">read I/O blade presence and peripheral-event sensor state</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/adgetbladeselentrylongtextread and page formatted blade sel long text; bytes3..9 echo sel header fields, byte10 encodes severity, byte11 text length minus one, text begins at byte12">
<td class="p-2 font-mono whitespace-nowrap">30/ad</td>
<td class="p-2">getBladeSelEntryLongText
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 4 bytes [SEL_record_id_le16,text_offset,requested_chunk_length]; zero or &gt;32 chunk length is clamped to 32</td>
<td class="p-2">[cc,next_record_id_le16,7-byte SEL header,severity,total_text_length_minus_one,text_chunk,NUL]; success length 13..45, C6 on successful clamped &gt;32 request, C9 missing record, CB decode failure, C7 wrong length, C1 non-blade</td>
<td class="p-2">read and page formatted blade SEL long text; bytes3..9 echo SEL header fields, byte10 encodes severity, byte11 text length minus one, text begins at byte12</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/ddgetviomsupportreport viom support when feature enabled">
<td class="p-2 font-mono whitespace-nowrap">30/dd</td>
<td class="p-2">getViomSupport
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[cc,01]</td>
<td class="p-2">report VIOM support when feature enabled</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/9bsetcpuerrorconfigunconditional no-op success stub; does not configure cpu errors">
<td class="p-2 font-mono whitespace-nowrap">30/9b</td>
<td class="p-2">setCPUErrorConfig
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">ignored</td>
<td class="p-2">[00]</td>
<td class="p-2">unconditional no-op success stub; does not configure CPU errors</td>
<td class="p-2">direct
Registered Admin; handler itself unconditionally returns 00.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="30/e6sendrawpeciallowed peci command set 01,61,65,a1,a5,b1,b5,e1,e5,f7; requires host on">
<td class="p-2 font-mono whitespace-nowrap">30/e6</td>
<td class="p-2">sendRawPeci
g_OEM_C0_CmdHndlrBlade · blade C0</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">[PECI target,write_len,read_len,write_bytes...]</td>
<td class="p-2">[cc,read_bytes...]</td>
<td class="p-2">allowed PECI command set 01,61,65,a1,a5,b1,b5,e1,e5,f7; requires host on</td>
<td class="p-2">direct
Registered Admin privilege, channel mask 0xaaaa; runtime gate or backend support may vary.</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/f1oem_fts_bioscmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/f1</td>
<td class="p-2">OEM_FTS_BiosCmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">93 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/f5oem_fts_bmccmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/f5</td>
<td class="p-2">OEM_FTS_BmcCmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">99 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/f8oem_fts_bladecmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/f8</td>
<td class="p-2">OEM_FTS_BladeCmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">4 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/e0oem_fts_scci_cs_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/e0</td>
<td class="p-2">OEM_FTS_SCCI_CS_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">10 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/01oem_fts_scci_power_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/01</td>
<td class="p-2">OEM_FTS_SCCI_POWER_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">8 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/02oem_fts_scci_com_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/02</td>
<td class="p-2">OEM_FTS_SCCI_COM_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">7 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/03oem_fts_scci_fan_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/03</td>
<td class="p-2">OEM_FTS_SCCI_FAN_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x03 · variable length</td>
<td class="p-2">1 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/07oem_fts_scci_mem_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/07</td>
<td class="p-2">OEM_FTS_SCCI_MEM_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">4 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/09oem_fts_scci_statistics_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/09</td>
<td class="p-2">OEM_FTS_SCCI_STATISTICS_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">1 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2e/10oem_fts_scci_signalling_cmdsmixed or selector-specific">
<td class="p-2 font-mono whitespace-nowrap">2e/10</td>
<td class="p-2">OEM_FTS_SCCI_SIGNALLING_Cmds
g_OEM_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">1 selector candidates; see operation table</td>
<td class="p-2">Selector-specific; see operation table</td>
<td class="p-2">mixed or selector-specific</td>
<td class="p-2">selector map
Registered; rack applicability varies</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2c/01groupextension01read">
<td class="p-2 font-mono whitespace-nowrap">2c/01</td>
<td class="p-2">GroupExtension01
g_Oem_GroupExtension_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">variable table; at least group byte; dc branch requires 2 including group</td>
<td class="p-2">dc: standard DCMI capabilities; 52: CC, group byte, 1, 32-byte fingerprint on success</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled; 52 branch not live tested
normal group-extension OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="2c/02groupextension02dc is read; 52 creates a privileged user, may clear bootstrap flag, and can return credentials">
<td class="p-2 font-mono whitespace-nowrap">2c/02</td>
<td class="p-2">GroupExtension02
g_Oem_GroupExtension_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">variable table; at least group byte; dc branch requires 4 including group; 52 leaf requires at least 2 bytes [52,selector]</td>
<td class="p-2">dc: 19 bytes including CC per existing analysis; 52: 2 bytes [cc,52] on short/channel/config error, otherwise always 34 bytes [cc,52,32 body bytes]. Username/password body is copied only after both createNewUser and follow-up config write succeed; failure can still return 34 bytes with body not filled, and config-write failure may retain CC 00 after deleting the user.</td>
<td class="p-2">dc is read; 52 creates a privileged user, may clear bootstrap flag, and can return credentials</td>
<td class="p-2">GroupExtension02@0x0003db3c and GroupRedfishCmd02@0x0003dd40 decompiled; 52 branch not live tested
normal group-extension OEM map; 52 branch static only, LAN channel rejected by leaf</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0c/01oem_fts_setlanconfigparamnetwork configuration mutation">
<td class="p-2 font-mono whitespace-nowrap">0c/01</td>
<td class="p-2">OEM_FTS_SetLanConfigParam
g_Oem_Config_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">variable table; standard Set LAN Configuration format</td>
<td class="p-2">standard handler response</td>
<td class="p-2">network configuration mutation</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/10oem_fts_getfruareainforead">
<td class="p-2 font-mono whitespace-nowrap">0a/10</td>
<td class="p-2">OEM_FTS_GetFRUAreaInfo
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">1 exact (handler): FRU device ID</td>
<td class="p-2">on success CC, size LE16, access byte</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/11oem_fts_readfrudataread fru">
<td class="p-2 font-mono whitespace-nowrap">0a/11</td>
<td class="p-2">OEM_FTS_ReadFRUData
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">4 exact (handler): FRU device, offset LE16, count</td>
<td class="p-2">on success CC, returned count, data</td>
<td class="p-2">read FRU</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/12oem_fts_writefrudatafru mutation">
<td class="p-2 font-mono whitespace-nowrap">0a/12</td>
<td class="p-2">OEM_FTS_WriteFRUData
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x03 · variable length</td>
<td class="p-2">at least 4 (handler): FRU device, offset LE16, data</td>
<td class="p-2">on success CC and written count</td>
<td class="p-2">FRU mutation</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/23oem_fts_getsdrread">
<td class="p-2 font-mono whitespace-nowrap">0a/23</td>
<td class="p-2">OEM_FTS_GetSdr
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">6 for specialized path; other lengths delegated to standard handler</td>
<td class="p-2">standard Get SDR response with Fujitsu filtering for selected sessions</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled; exact skipped record identity unresolved
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/20oem_fts_getsdrrepositoryinforead">
<td class="p-2 font-mono whitespace-nowrap">0a/20</td>
<td class="p-2">OEM_FTS_GetSdrRepositoryInfo
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">variable table; standard Get SDR Repository Info format</td>
<td class="p-2">standard response with reported count adjusted outside channel 0d</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/49oem_fts_setseltimenone observed despite setter name">
<td class="p-2 font-mono whitespace-nowrap">0a/49</td>
<td class="p-2">OEM_FTS_SetSelTime
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x03 · variable length</td>
<td class="p-2">variable table; request ignored by handler</td>
<td class="p-2">CC 00 only</td>
<td class="p-2">none observed despite setter name</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="0a/5coem_fts_getseltimeutcoffsetread">
<td class="p-2 font-mono whitespace-nowrap">0a/5c</td>
<td class="p-2">OEM_FTS_GetSelTimeUtcOffset
g_Oem_Storage_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">variable table; request ignored by handler</td>
<td class="p-2">3 bytes including CC and signed UTC offset LE16 on success</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="04/16oem_fts_alertimmediateoperation 0 may send network alert; operation 2 clears alert-status byte">
<td class="p-2 font-mono whitespace-nowrap">04/16</td>
<td class="p-2">OEM_FTS_AlertImmediate
g_Oem_SensorEvent_CmdHndlr · normal</td>
<td class="p-2">0x04 · variable length</td>
<td class="p-2">exactly 3 or 11 bytes (handler); byte0 low nibble selects LAN channel, byte1 high two bits select operation 0/1/2 and bits4-5 must be zero</td>
<td class="p-2">operation 1 returns [00,current_alert_status]; operations 0/2 return one-byte CC; C7 other lengths, CC invalid channel/operation bits, D3 unmapped LAN interface, 81 alert already pending, CE async post failure</td>
<td class="p-2">operation 0 may send network alert; operation 2 clears alert-status byte</td>
<td class="p-2">handler decompiled at 0x00036bec; downstream network delivery unproven
normal OEM map; static; CC 00 on posted alert does not prove delivery</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="00/0foem_fts_getpohcounterread">
<td class="p-2 font-mono whitespace-nowrap">00/0f</td>
<td class="p-2">OEM_FTS_GetPOHCounter
g_Oem_Chassis_CmdHndlr · normal</td>
<td class="p-2">0x02 · variable length</td>
<td class="p-2">variable table; handler ignores request</td>
<td class="p-2">6 bytes including CC, count unit 05 and count LE32</td>
<td class="p-2">read</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="00/02oem_fts_chassiscontrolhost power/reset/nmi mutation">
<td class="p-2 font-mono whitespace-nowrap">00/02</td>
<td class="p-2">OEM_FTS_ChassisControl
g_Oem_Chassis_CmdHndlr · normal</td>
<td class="p-2">0x03 · 1 length</td>
<td class="p-2">1 exact (table): action</td>
<td class="p-2">CC only</td>
<td class="p-2">host power/reset/NMI mutation</td>
<td class="p-2">handler decompiled; physical actuation not implied by CC 00
normal OEM map; static</td>
</tr>
<tr class="border-b border-slate-700 align-top" data-search="00/08oem_fts_setsysbootoptionsboot configuration mutation; semaphore signal">
<td class="p-2 font-mono whitespace-nowrap">00/08</td>
<td class="p-2">OEM_FTS_SetSysBOOTOptions
g_Oem_Chassis_CmdHndlr · normal</td>
<td class="p-2">0x03 · variable length</td>
<td class="p-2">variable table; standard Set System Boot Options format</td>
<td class="p-2">standard handler response or CC 82 for selected parameters and platform state</td>
<td class="p-2">boot configuration mutation; semaphore signal</td>
<td class="p-2">handler decompiled
normal OEM map; static</td>
</tr>
</tbody>
</table>

## 2e selector dispatch candidates

The 228 candidates include 93 BIOS F1, 99 BMC F5, and 36 other SCCI/blade leaves. 102 are decoded, 126 partial, and 0 unknown; “partial” and “unknown” name real unresolved wire-contract boundaries, not tested success. [Exact F1/F5 jump-table map](evidence/fujitsu-selector-dispatch.json).

Filter selector operations

| Wire | Operation | Request | Response | Effect | Evidence state |
|----|----|----|----|----|----|
| 2e/f1 · 80 28 00 06 | Set BIOS slot/state byte | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "one state byte, written to BIOS object+0x765"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 07 | Get BIOS slot/state bytes | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 6, "payload": "low nibble of BIOS object+0x765, followed by slot/state flag byte"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 08 | Selector 08 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 09 | Get BIOS state byte at object+0x766 | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 5, "payload": "BIOS object byte at offset 0x766"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 0a | Set BIOS state byte at object+0x767 and notify | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "one BIOS state/POST-code byte, written to object+0x767"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 0b | Get BIOS state byte at object+0x767 | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 5, "payload": "BIOS object byte at offset 0x767"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 0f | Set flash lock | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 10 | Selector 10 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 11 | Write system GUID to configuration space | {"shared_minimum_total_bytes": 4, "selector_specific_length": 20, "payload": "16-byte system GUID at bytes 4..19"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 13 | Selector 13 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 14 | Selector 14 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 15 | Selector 15 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 16 | Graphics-controller control/query | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 17 | Uncorrectable-memory active state | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 8 checked, but one branch reads byte 8 and thus needs at least 9", "payload": "byte 4 controls read/write branch; subsequent bytes include uncorrectable-memory active state fields"} | {"success_total_bytes": null, "payload": null} | mixed/read-or-mutate | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 18 | Read indexed BMC slot-record fields | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 5", "payload": "byte 4 is a seven-bit slot index; trailing bytes ignored"} | {"success_total_bytes": 11, "payload": "two little-endian 16-bit fields from indexed record offsets +2/+4, one byte at +6, then little-endian 16-bit field from parallel indexed table"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 19 | Append PCI slot information | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 1a | Selector 1a | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 1b | BIOS feature info get/set | {"shared_minimum_total_bytes": 4, "selector_specific_length": "subcommand 0: at least 9; subcommand 1: at least 5", "payload": "subcommand 0 sets little-endian 32-bit BIOS feature flags at bytes 5..8; subcommand 1 reads current flags"} | {"success_total_bytes": 8, "payload": "current little-endian 32-bit BIOS feature flags for both subcommands"} | mixed/read-or-mutate | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 1c | Validate bounded BIOS subrecord request (no-op) | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 2\*(byte 5 + 1), with at least 6 bytes overall", "payload": "byte 4 must be 0..7; byte 5 must be 0..32; remaining bytes are ignored by this leaf"} | {"success_total_bytes": 4, "payload": "none"} | read/compute | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 1d | Extended FRU device read/write/lock | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 1e | BSPBR boot status get/set | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 5", "payload": "byte 4 selects 0/1: get BSPBR boot status of bank 0/1; 2/3: set bank 0/1 status to zero; trailing bytes ignored"} | {"success_total_bytes": "5 for get (0/1), 4 for set (2/3)", "payload": "get returns one byte from getBSPBRBootStatus; set returns none"} | mixed/read-or-mutate | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 20 | Set BMC Interrupt Enable (bank 0) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 21 | Get BMC Interrupt Enable (bank 0) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 22 | Get BMC Interrupt Status (bank 0) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 23 | Reset BMC Interrupt Status (bank 0) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 24 | Set BMC Interrupt Enable (bank 1) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 5, "payload": "no helper output seen; shared epilogue returns bank-index extra bytes"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 25 | Get BMC Interrupt Enable (bank 1) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 26 | Get BMC Interrupt Status (bank 1) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 27 | Reset BMC Interrupt Status (bank 1) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 5, "payload": "no helper output seen; shared epilogue returns bank-index extra bytes"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 28 | Set BMC Interrupt Enable (bank 2) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 6, "payload": "no helper output seen; shared epilogue returns bank-index extra bytes"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 29 | Get BMC Interrupt Enable (bank 2) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 2a | Get BMC Interrupt Status (bank 2) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 2b | Reset BMC Interrupt Status (bank 2) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 6, "payload": "no helper output seen; shared epilogue returns bank-index extra bytes"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 2c | Set BMC Interrupt Enable (bank 3) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 7, "payload": "no helper output seen; shared epilogue returns bank-index extra bytes"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 2d | Get BMC Interrupt Enable (bank 3) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 2e | Get BMC Interrupt Status (bank 3) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "4-byte helper output"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 2f | Reset BMC Interrupt Status (bank 3) | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "opaque 4-byte helper input"} | {"success_total_bytes": 7, "payload": "no helper output seen; shared epilogue returns bank-index extra bytes"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 30 | Update hardware-change state | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 31 | Nested PCI-slot/subselector command | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | mixed/unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 32 | Return constant BIOS value 0x32 | {"shared_minimum_total_bytes": 4, "selector_specific_length": 6, "payload": "two bytes ignored by this branch"} | {"success_total_bytes": 5, "payload": "constant byte 0x32"} | read/compute | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 39 | Interface-control dispatch | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 3a | SPD manufacturer information | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 3b | Read BIOS-side file data | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 3c | Delete all 40 persisted PPRData records | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 40 | Write configuration space | {"shared_minimum_total_bytes": 4, "selector_specific_length": 20, "payload": "16 configuration-space bytes at bytes 4..19"} | {"success_total_bytes": null, "payload": "none; no CC00 branch in this leaf"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 43 | Read configuration-space presence marker | {"shared_minimum_total_bytes": 4, "selector_specific_length": 6, "payload": "byte 4 must equal 1 and byte 5 must equal 0"} | {"success_total_bytes": 6, "payload": "constant byte 1, then 0xff if the first configuration-space byte equals 6 or 0x00 otherwise"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 44 | Read/write seven BIOS configuration-mirror bytes | {"shared_minimum_total_bytes": 4, "selector_specific_length": "5 for read, 12 for write", "payload": "byte 4 must be zero; write carries seven bytes at bytes 5..11"} | {"success_total_bytes": "11 for read, 4 for write", "payload": "read returns seven bytes from BMC object offsets 0xa46d..0xa473; write returns none"} | mixed/read-or-mutate | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 45 | Read PCIe AIC metadata and status | {"shared_minimum_total_bytes": 4, "selector_specific_length": 6, "payload": "byte 5 selects the PCIe AIC; byte 4 is not consumed in the traced branch"} | {"success_total_bytes": "8+name length in normal path; upper bound unproved", "payload": "connectivity byte, form-factor byte, bifurcation byte, name length byte, then name bytes (?Unknown? fallback)"} | read | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 4a | Read configuration space | {"shared_minimum_total_bytes": 4, "selector_specific_length": "valid caller must send at least 5 bytes; firmware does not enforce this", "payload": "byte 4 used as a subselector after configuration-space read"} | {"success_total_bytes": null, "payload": null} | read | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 50 | Get PMB Object Counts and System Power Instance | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 8, "payload": "type 1, count(type 0), count(type 1), system-power instance"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 51 | Get PMB object event status | {"shared_minimum_total_bytes": 4, "selector_specific_length": 6, "payload": "PMB object type and instance bytes"} | {"success_total_bytes": 7, "payload": "one status byte followed by little-endian 16-bit event-status flags"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 52 | Set PMB Object Event Enable | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "object type, instance, 16-bit event-enable flags"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 53 | Get PMB Object Event Enable | {"shared_minimum_total_bytes": 4, "selector_specific_length": 6, "payload": "object type, instance"} | {"success_total_bytes": 6, "payload": "16-bit event-enable flags"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 54 | Clear PMB Object Event Status | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "object type, instance, 16-bit status clear mask"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 55 | Get PSU Object Status | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "PSU object instance byte"} | {"success_total_bytes": 5, "payload": "one status byte"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 56 | Get Power-Meter Capability | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "power-meter object instance byte"} | {"success_total_bytes": 36, "payload": "32 opaque capability bytes from helper"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 57 | Get Power-Meter Reading and Parameters | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "power-meter object instance byte"} | {"success_total_bytes": 24, "payload": "20-byte composite reading/parameter payload, individual fields unresolved"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 58 | Set Power-Meter Parameter | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 7 checked, but request offsets through 9 are read", "payload": "object instance, parameter ID, four-byte value (requires at least 10 bytes to contain all fields)"} | {"success_total_bytes": 4, "payload": "none on helper success"} | mutating | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 60 | Network/LAN configuration operation | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 61 | Selector 61 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 62 | Selector 62 | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 63 | Read SMBIOS structure data | {"shared_minimum_total_bytes": 4, "selector_specific_length": 8, "payload": "byte 4 must equal 1; byte 5 is SMBIOS structure type; bytes 6..7 are little-endian offset"} | {"success_total_bytes": "7+N, where helper returns N in 0..50", "payload": "remaining-byte count (zero at end), reserved zero, returned-byte count N, then N SMBIOS bytes"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 64 | Start BIOS PFR flash | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "byte 4 selects flash-thread action 0 or 1"} | {"success_total_bytes": 4, "payload": "none"} | mutating/asynchronous | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 65 | Interface-control dispatch | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 66 | Consume Redfish set-default-boot-order action marker | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 5, "payload": "one byte: 1 if the marker existed (unlink attempted), 0 otherwise"} | mutating/conditional | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 67 | Interface-control dispatch | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 68 | Start BIOS PFR flash | {"shared_minimum_total_bytes": 4, "selector_specific_length": 5, "payload": "byte 4 selects flash-thread action 0 or 1"} | {"success_total_bytes": 4, "payload": "none"} | mutating/asynchronous | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 69 | Nested selector 0..8 (likely S3M family) | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | mixed/unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 6a | Set CPU S3M state | {"shared_minimum_total_bytes": 4, "selector_specific_length": "5+9\*N bytes, N=1..8 (14..77 total)", "payload": "version byte 0, followed by N records of slot index 0..7 and two little-endian 32-bit values"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 6b | Get CPU S3M state | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": "5+9\*N, N=0..8 (5..77 total)", "payload": "version byte 0, followed by each present slot index 0..7 and two little-endian 32-bit values"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d0 | VIOM table confirmation | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d1 | Set server boot option | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 6", "payload": "bytes 4 and 5 passed as the first two arguments to setServerBootOptionEx; trailing bytes ignored by wrapper"} | {"success_total_bytes": 4, "payload": "none"} | mutating | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d2 | Get server boot option | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 5, "payload": "one server-boot-option byte"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d3 | Write VIOM flag | {"shared_minimum_total_bytes": 4, "selector_specific_length": "at least 5", "payload": "byte 4 is VIOM flag value 0 or 1; trailing bytes ignored by wrapper"} | {"success_total_bytes": 4, "payload": "none"} | mutating | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d4 | Read VIOM flag | {"shared_minimum_total_bytes": 4, "selector_specific_length": 4, "payload": "none"} | {"success_total_bytes": 7, "payload": "three VIOM flag/status bytes from viomReadViomFlag"} | read | decoded · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d5 | Get VIOM inventory table | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d6 | Set VIOM table | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d7 | Get VIOM table chunk | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d8 | Lock/unlock VIOM table | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 d9 | Get VIOM table element | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 da | Lock/unlock VIOM inventory table | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 db | Set VIOM inventory element | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 dc | Clear VIOM inventory table | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 de | Set VIOM BIOS status | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 df | Get VIOM BIOS status | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 e0 | Interface-control dispatch | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 e1 | Get VIOM table element extended | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 e2 | Set VIOM inventory element extended | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 e3 | Read BIOS state bytes by subselector | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | read/unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 f4 | Set preferred VIOM inventory inversion | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 f5 | Get preferred VIOM inventory inversion | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 f6 | Set/get VIOM communication trap parameter | {"shared_minimum_total_bytes": 4, "selector_specific_length": null, "payload": null} | {"success_total_bytes": null, "payload": null} | unknown | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f1 · 80 28 00 ff | Generate patterned response of caller-requested length | {"shared_minimum_total_bytes": 4, "selector_specific_length": "valid caller must send at least 5 bytes; firmware does not enforce this", "payload": "byte 4 requests N output bytes (0..255)"} | {"success_total_bytes": "4+N (up to 259), subject to unchecked output capacity", "payload": "N bytes: each byte is 0xf0 OR its zero-based index, truncated to eight bits"} | read/compute | partial · [evidence](evidence/f1-selector-contracts.json) |
| 2e/f5 · 80 28 00 00 | Selector 00 | {"prefix_hex": "80280000", "length_check_at_entry": "not established at entry", "payload": "total length 9 or 11; little-endian 32-bit address at offsets4-7, byte8 count \<=64; 11-byte form adds control bytes at offsets9-10"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "up to count bytes read from validated address on one branch; exact alternate control modes unresolved"} | reads mapped BMC memory on the traced branch; no write proved there | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 07 | Selector 07 | {"prefix_hex": "80280007", "length_check_at_entry": "cmp\tr6, \#4", "payload": "nested selector byte at offset4 (observed 01,02,03,04,07); selector-specific tail"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "nested-selector-specific; selector 02 returns one configuration byte from 0x2140"} | nested flash/dual-image operations; selector 01 writes configuration space 0x2140, selector 03/04/07 delegate flash/dual-image helpers | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 08 | Selector 08 | {"prefix_hex": "80280008", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 09 | Selector 09 | {"prefix_hex": "80280009", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 0b | Selector 0b | {"prefix_hex": "8028000b", "length_check_at_entry": "not established at entry", "payload": "If prerequisite shared flag is 1: exact total length 5 chooses byte-4 flash selector; byte4=0x80 initiates BIOS TFTP flash, while other byte-4 values 0x00..0x05 or 0xff can queue ordinary TFTP firmware update (other values rejected by StartTFTPFWUpdate). Exact total length 6 reads byte4 and flags byte5; byte4=0x81 takes examineFlashParameter; otherwise byte5 bit4 must be set, then low bits feed FlashOverHTI. Other lengths reject."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "Completion-only immediate reply. The success reply acknowledges scheduling/starting update work, not completed flashing; backend status/progress is separate."} | HIGH RISK: length-5 non-0x80 path reads configured TFTP server/file, sets firmware configuration and enqueues firmware upload via PostPendTask; length-5 0x80 path reads BIOS TFTP settings and creates detached pthTftpBiosFlash worker; length-6 HTI path prepares flash area, creates detached iRMCFWVerifyFlashThread_HTI worker, and can verify and start image flashing. tflashSetOverride updates per-selector shared override state. | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 0c | Selector 0c | {"prefix_hex": "8028000c", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 0d | Selector 0d | {"prefix_hex": "8028000d", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 0e | Selector 0e | {"prefix_hex": "8028000e", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 10 | Selector 10 | {"prefix_hex": "80280010", "length_check_at_entry": "cmp\tr6, \#7", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 12 | Selector 12 | {"prefix_hex": "80280012", "length_check_at_entry": "cmp\tr6, \#4", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 18 | Selector 18 | {"prefix_hex": "80280018", "length_check_at_entry": "cmp\tr6, \#4", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 1c | Selector 1c | {"prefix_hex": "8028001c", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 2c | Selector 2c | {"prefix_hex": "8028002c", "length_check_at_entry": "cmp\tr6, \#5", "payload": "total length 4 or 5 clears all sensor-force and power-history-force overrides; longer requests accept nested ASCII F/I modes"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "no body on clear/reset-injection branch; other nested mode responses unresolved"} | length\<=5 clears all sensor and power-history force overrides; nested IR branch calls ResetSensorInject | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 2d | Selector 2d | {"prefix_hex": "8028002d", "length_check_at_entry": "cmp\tr6, \#5", "payload": "two modes: total length \<=5 clears bit0 across 32-byte shared array; longer requests enter another subdispatch"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none in clear mode; longer-mode response unresolved"} | clear mode mutates 32 shared-state bytes by clearing bit 0 | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 2e | Selector 2e | {"prefix_hex": "8028002e", "length_check_at_entry": "cmp\tr6, \#8", "payload": "at least 5 bytes after selector: bytes4-5 arguments, little-endian output cap at6-7, byte8 mode, data at9+ (length total-9)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "backend-generated bytes and length constrained by channel maximum"} | delegates raw test command to bmcTestCmdMain; side effects backend-dependent | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 2f | Selector 2f | {"prefix_hex": "8028002f", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none; exact total length 4 (other lengths branch to alternate path)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "up to 40 bytes of log information; actual length is helper return value"} | none; reads log information via utGetLogInfo | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 33 | Selector 33 | {"prefix_hex": "80280033", "length_check_at_entry": "sub\tr3, r6, \#5 (followed by comparison; inspect entry)", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 34 | Selector 34 | {"prefix_hex": "80280034", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly one fan/sensor selector at offset4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | clears stored values for mapped fan via fcClearStoredValues | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 35 | Selector 35 | {"prefix_hex": "80280035", "length_check_at_entry": "cmp\tr6, \#6", "payload": "at least 3 bytes after selector; byte6 is status index 0..15; if signed byte5 is negative, reads status; otherwise byte7 is set value (except total length 9 rejected)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "read branch returns one status byte; write branch no body"} | read branch calls utGetHostSystemStatus; write branch calls utSetHostSystemStatus | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 40 | Selector 40 | {"prefix_hex": "80280040", "length_check_at_entry": "sub\tr3, r6, \#6 (followed by comparison; inspect entry)", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 41 | Selector 41 | {"prefix_hex": "80280041", "length_check_at_entry": "cmp\tr6, \#7", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 42 | Selector 42 | {"prefix_hex": "80280042", "length_check_at_entry": "cmp\tr6, \#6", "payload": "total request length \>=7. Bytes 4, 5, 6 are passed as the three signal identifiers to GetComponentStatusSignalRead. Optional byte 7 supplies mode bits 0-1; mode is zero for exactly 7 bytes."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "GetComponentStatusSignalRead result: response offsets 4-6 are returned bytes at stack +437..439; byte at +439 is also the count for data copied from stack +440 into response offset 7. Response body length is 2 when mode bit 0 is clear, otherwise 3 + returned count. Underlying signal encoding and count bounds remain unproved."} | reads component-status signals through GetComponentStatusSignalRead | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 43 | Selector 43 | {"prefix_hex": "80280043", "length_check_at_entry": "cmp\tr6, \#7", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 45 | Selector 45 | {"prefix_hex": "80280045", "length_check_at_entry": "cmp\tr6, \#5", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 46 | Selector 46 | {"prefix_hex": "80280046", "length_check_at_entry": "cmp\tr6, \#10", "payload": "at least 7 bytes after selector (total length \>10); event fields at offsets 4-10 and possibly following bytes"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "on event decode, severity byte and length-prefixed text; exact alternate paths unresolved"} | none proved; passes event to istDecodeEvent for text/severity decoding | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 48 | Selector 48 | {"prefix_hex": "80280048", "length_check_at_entry": "cmp\tr6, \#4", "payload": "one-byte sensor selector at offset4; total length 5 reads sensor value; length \>5 uses byte5 to force/update sensor state (byte4 high bit rejected)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "read mode: one sensor-state byte; write mode: none"} | read/force memory-module sensor state; write path updates shared sensor field +0x8f20 and calls asUpdateSensorStatus | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 49 | Selector 49 | {"prefix_hex": "80280049", "length_check_at_entry": "cmp\tr6, \#4", "payload": "one-byte sensor selector at offset4; total length 5 reads sensor value; length \>5 uses byte5 to force/update sensor state (byte4 high bit rejected)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "read mode: one sensor-state byte; write mode: none"} | read/force memory-module sensor state; write path updates shared sensor field +0x8fa0 and calls asUpdateSensorStatus | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 4a | Selector 4a | {"prefix_hex": "8028004a", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none; exact total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "two bytes: memory-module policy, memory-module count"} | none; reads memory-module policy/count | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 4b | Selector 4b | {"prefix_hex": "8028004b", "length_check_at_entry": "cmp\tr6, \#4", "payload": "one-byte slot index 0..7 at offset4; with total length 6, byte5 is written to shared slot field +0x29; length5 enters read path"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "length5 read path returns one byte or checks UDS session; full fallback unresolved"} | length6 marks shared slot flag +0x2d and writes value at +0x29 | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 4c | Selector 4c | {"prefix_hex": "8028004c", "length_check_at_entry": "cmp\tr6, \#4", "payload": "one-byte slot index 0..7 at offset4; with total length 6, byte5 is written to shared slot field +0x2a; length5 enters read path"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "length5 read path unresolved"} | length6 marks shared slot flag +0x2d and writes value at +0x2a | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 4d | Selector 4d | {"prefix_hex": "8028004d", "length_check_at_entry": "not established at entry", "payload": "none"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: 00"} | none; returns constant zero byte | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 4e | Selector 4e | {"prefix_hex": "8028004e", "length_check_at_entry": "cmp\tr6, \#11", "payload": "16-bit little-endian index at offsets4-5; values \<0x180 follow direct branch, \>=0x180 an unresolved alternate; total length6 enters read path, length11 writes five bytes from offsets6-10"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "read-path value unresolved; write-path no body"} | length11 writes five bytes into shared indexed table (or alternate branch for index\>0x7f) | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 4f | Selector 4f | {"prefix_hex": "8028004f", "length_check_at_entry": "cmp\tr6, \#6", "payload": "at least 3 bytes after selector; byte4 must equal 01, further fields at offsets5-6 consumed by SDR path"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "response begins with 01; remainder from SDR/backend unresolved"} | none proved; traverses SDR via GetNextSdr | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 50 | Selector 50 | {"prefix_hex": "80280050", "length_check_at_entry": "not established at entry", "payload": "none; shared minimum total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "three bytes: when shared flag==1, \[shared byte3, 01, shared byte4\]; otherwise \[00,00,00\]"} | none; reads shared BMC state | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 51 | Selector 51 | {"prefix_hex": "80280051", "length_check_at_entry": "cmp\tr6, \#6", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 52 | Selector 52 | {"prefix_hex": "80280052", "length_check_at_entry": "cmp\tr6, \#5", "payload": "at least 2 bytes after selector; byte4 must equal configured bus token; byte5 is read length; bytes6+ are I2C write data"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "I2C read data written via backend output pointer; exact length unresolved"} | performs I2C write/read against configured bus/device via I2cMasterWriteRead | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 53 | Selector 53 | {"prefix_hex": "80280053", "length_check_at_entry": "cmp\tr6, \#7", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 54 | Selector 54 | {"prefix_hex": "80280054", "length_check_at_entry": "sub\tr3, r6, \#7 (followed by comparison; inspect entry)", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 55 | Selector 55 | {"prefix_hex": "80280055", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly one selector byte at offset 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte written by SNTCI_On_Off_Stat on backend success"} | none; reads SNTCI on/off status | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 5a | Selector 5a | {"prefix_hex": "8028005a", "length_check_at_entry": "cmp\tr6, \#7", "payload": "at least 4 bytes after selector: argument bytes at offsets4-5, requested read count at6, write data at7+ (write length=total-7)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "on success exactly requested read-count bytes from peciMWR output"} | performs PECI multi-write/read transaction via peciMWR | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 5c | Selector 5c | {"prefix_hex": "8028005c", "length_check_at_entry": "cmp\tr6, \#6", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 5f | Selector 5f | {"prefix_hex": "8028005f", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 60 | Selector 60 | {"prefix_hex": "80280060", "length_check_at_entry": "cmp\tr6, \#8", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | allocates SSO session | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 61 | Selector 61 | {"prefix_hex": "80280061", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly one byte 0x01 at offset 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "two bytes: echoed 0x01, boolean MMB override-active state"} | none; reads MMB override flag | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 70 | Selector 70 | {"prefix_hex": "80280070", "length_check_at_entry": "cmp\tr6, \#9", "payload": "total request length \>=10. Bytes 4-5 are little-endian SEL record ID; byte 6 must be 0x02 when the linked global flag at +0x70 is zero; bytes 7-8 are a little-endian field and byte 9 is another field. GetSelRecordFromId constructs a 6-byte GetSELEntry request with reservation 0, this record ID, and offset 0xff00; on success it obtains a 16-byte SEL record and next-record ID. The later error-decoding fields remain unresolved."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "Uses GetSelRecordFromId and a subsequent SEL-error decoder. Exact variable response layout is not yet proved."} | reads/decodes a SEL record; no mutation proved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 71 | Selector 71 | {"prefix_hex": "80280071", "length_check_at_entry": "cmp\tr6, \#4", "payload": "total request length \>=5. Byte 4 is the one-byte text-cache entry ID. Additional request bytes are ignored by this handler."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "After istTextCacheRead copies up to 50 bytes from the entry's current cursor, response offsets 4-5 contain little-endian bytes remaining (not total text length), offset 6 is copied chunk length, and offsets 7+ are the chunk bytes. Body length is 3 + copied chunk length."} | stateful text-cache read: advances the cache entry's read cursor and refreshes its access timestamp; if no bytes remain after a nonempty chunk, calls istTextCacheDelete(entry ID,-1) to unlink that entry | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 72 | Selector 72 | {"prefix_hex": "80280072", "length_check_at_entry": "cmp\tr6, \#6", "payload": "total request length \>=7. Byte 4 must equal 0x02 when linked global flag at +0x70 is zero; bytes 5-6 are little-endian SEL record ID. GetSelRecordFromId constructs a 6-byte GetSELEntry request with reservation 0, this ID, and offset 0xff00; on success it obtains the next-record ID and 16-byte SEL record."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "On success offsets 4-7 hold little-endian decoded error code, offset 8 CSS severity, offset 9 decoded selector/type byte, and offset 10+ variable backend text. Text length expression remains unresolved."} | reads a SEL record and decodes its error via GetSelRecordFromId and istGetErrorCodeFromSEL | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 73 | Selector 73 | {"prefix_hex": "80280073", "length_check_at_entry": "cmp\tr6, \#13", "payload": "total request length \>=14. Bytes 4-7 are a little-endian 32-bit error/event identifier; bytes 8-9 form a little-endian 16-bit field; byte 10 is a type/mode field (0x02 is specially gated by linked global flag); bytes 11-12 form another little-endian 16-bit field; byte 13 is an additional field. Exact parameter semantics still depend on the text-generator backend."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "A cache-hit branch reads up to 50 text bytes using istTextCacheRead and responds with two-byte length at offsets 4-5, chunk length at offset 6, and chunk bytes at offset 7+; it deletes the cache entry when exhausted. Miss branch generates text via istGetTextFromErrorcode; its wire packing and other branches remain unresolved."} | looks up cached generated error text, refreshes cache entry timestamp and may consume/delete it; cache miss invokes text generation from error-code metadata | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 74 | Selector 74 | {"prefix_hex": "80280074", "length_check_at_entry": "not established at entry", "payload": "none; shared minimum total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "seven bytes: 03 followed by three little-endian 16-bit values loaded from shared structure offsets 0, 8, 16"} | none; reads shared structure | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 75 | Selector 75 | {"prefix_hex": "80280075", "length_check_at_entry": "cmp\tr6, \#21", "payload": "total request length \>=22. Bytes 4-17 are copied as a 14-byte SEL record; byte 18 is event-format selector 0..4; bytes 19-20 are a little-endian field; byte 21 is an additional field. The exact meanings of the latter fields remain backend-defined."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "istDecodeEvent produces CSS severity at offset 4, a little-endian field at offsets 5-6, little-endian decoded-text length at offsets 7-8, and variable decoded event text beginning at offset 11. Offset 10 is initialized to zero; offset 9 is the low byte of text length. Text length \>50 branches to separate error handling; full returned-length arithmetic is unresolved."} | decodes supplied event data using istDecodeEvent; no persistent mutation proved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 7e | Selector 7e | {"prefix_hex": "8028007e", "length_check_at_entry": "cmp\tr6, \#5", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 80 | Selector 80 | {"prefix_hex": "80280080", "length_check_at_entry": "cmp\tr6, \#5", "payload": "at least 2 bytes: TPM status flag inputs at offsets 4 and 5; additional bytes ignored by this branch"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | sets TPM status flags via SetTPMstatusFlags | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 81 | Selector 81 | {"prefix_hex": "80280081", "length_check_at_entry": "cmp\tr6, \#4", "payload": "at least one mask byte at offset4; extra bytes ignored by this branch"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "two bytes: first = mask & shared\[0x9051\]; second = mask & shared\[0x9051\] & shared\[0x9050\]"} | none; reads shared TPM-related status mask | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 82 | Selector 82 | {"prefix_hex": "80280082", "length_check_at_entry": "not established at entry", "payload": "none read by entry; shared minimum total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "21 bytes produced by iELgetInfo"} | none; reads iEL metadata | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 84 | Selector 84 | {"prefix_hex": "80280084", "length_check_at_entry": "cmp\tr6, \#7", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 85 | Selector 85 | {"prefix_hex": "80280085", "length_check_at_entry": "cmp\tr6, \#11", "payload": "total request length \>=12. Bytes 4-5 supply a 16-bit field to iELAddEntry arg1; bytes 6-7 supply a signed 16-bit value whose low byte becomes arg0; bytes 8-9 initialize the in/out 16-bit entry-ID slot. Bytes 10 and 11 are flag bytes; bytes 12+ are the event payload and its byte count is arg2. Exact semantic names of the 16-bit fields are not proved."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "On iELAddEntry success returns little-endian created entry ID in response offsets 4-5; error response contains no proved data body."} | persistent iEL add request: iELAddEntry validates the in/out pointer and requires a payload pointer only when payload length is nonzero, builds a timestamped IPC message, sends it to the iEL daemon with sigwrap_msgsnd, waits for iELgetResponse, and returns the daemon-created entry ID on success; failure can occur before storage | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 86 | Selector 86 | {"prefix_hex": "80280086", "length_check_at_entry": "cmp\tr6, \#17", "payload": "total request length \>=18. Bytes 4-17 are a 14-byte SEL record; iELAddEntryFromSelData first derives an error code using istGetErrorCodeOnlyFromSEL, chooses an event-data layout according to record byte 2, and passes the normalized payload to the same timestamped IPC add-entry path as selector 85."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "On helper success returns little-endian created iEL entry ID at response offsets 4-5; backend failure packing is shared with selector 85."} | persistent iEL add request derived from supplied SEL record; the provider decodes the SEL error, sends a timestamped IPC message to the iEL daemon, waits for acknowledgement and returns the created entry ID on success | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 87 | Selector 87 | {"prefix_hex": "80280087", "length_check_at_entry": "cmp\tr6, \#4", "payload": "total request length \>=5. Byte 4=0x80 invokes clear-all with any length \>=5. Byte 4=0x00 requires total length \>=7 and treats bytes 5-6 as little-endian entry ID for clear-one. Other byte-4 values are invalid, but call utLogUserInfoiEL(0xc7,session) before returning 0xce."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "Completion-only response (no data body)."} | byte 4=0x80 sends an iEL clear-all IPC message (opcode 4), waits for the daemon response and sends a notification on success. Byte 4=0x00 calls iELclearEntry, but this provider's implementation is a stub returning 12, so individual deletion is not performed in this firmware. Invalid modes log user info. | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 89 | Selector 89 | {"prefix_hex": "80280089", "length_check_at_entry": "cmp\tr6, \#11", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 8a | Selector 8a | {"prefix_hex": "8028008a", "length_check_at_entry": "cmp\tr6, \#8", "payload": "total request length \>=9. Bytes 4-7 are four backend fields. Bytes 8+ are treated as a NUL-terminated string after the handler writes a NUL at the request buffer's end, then measures strlen(request+8). Exact field meanings and string encoding are not proved."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "Completion-only response; no returned data body proved."} | writes/sends an iEL socket event via iELwriteSocketEvent (externally visible event side effect) | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 8b | Selector 8b | {"prefix_hex": "8028008b", "length_check_at_entry": "sub\tr1, r6, \#4 (followed by comparison; inspect entry)", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 8c | Selector 8c | {"prefix_hex": "8028008c", "length_check_at_entry": "cmp\tr6, \#8", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 8d | Selector 8d | {"prefix_hex": "8028008d", "length_check_at_entry": "sub\tr2, r6, \#8 (followed by comparison; inspect entry)", "payload": "total request length must be 8 or 9. Byte 5 chooses operation. Mode 0 uses byte 7, optionally byte 8 as a high byte, as a little-endian NVMe index. Mode 1 passes fields to InterfaceControl; its exact protocol remains unresolved."} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "Mode 0 succeeds with exactly 45 body bytes (total reply length 49): offset 4 = backend struct byte +39; offsets 5-7 = zero; offsets 8-9 = backend little-endian field +40; offsets 10-29 = 20 bytes from +44; offsets 30-45 = 16 bytes from +12; offsets 46-48 = bytes +36..38. Mode 1 uses InterfaceControl(0x80000002,0x80000000) to acquire a callback, calls it with operation 2 and an 8-byte argument structure containing the NVMe index, and on success returns 3 callback output bytes at offsets 4-6; callback and InterfaceControl failure return 0xcb. Callback semantics remain unresolved."} | mode 0 reads NVMe monitor state through getNvmeData/getNvmeMonitorData; mode 1 queries an InterfaceControl callback but terminal semantics and possible side effects are unresolved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 8e | Selector 8e | {"prefix_hex": "8028008e", "length_check_at_entry": "cmp\tr6, \#10", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 8f | Selector 8f | {"prefix_hex": "8028008f", "length_check_at_entry": "cmp\tr6, \#5", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 90 | Selector 90 | {"prefix_hex": "80280090", "length_check_at_entry": "sub\tr1, r6, \#4 (followed by comparison; inspect entry)", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 a2 | Selector a2 | {"prefix_hex": "802800a2", "length_check_at_entry": "cmp\tr6, \#5", "payload": "one byte; only bit 0 is stored"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | writes bit 0 at BMC shared-state offset 0x76d | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 a3 | Selector a3 | {"prefix_hex": "802800a3", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: bit 0 of BMC shared-state offset 0x76d"} | none; reads shared-state bit | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 a4 | Selector a4 | {"prefix_hex": "802800a4", "length_check_at_entry": "cmp\tr6, \#4", "payload": "nested selector byte at offset4 (01..28 hex); selector-specific tail"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "nested-selector-specific; not decoded uniformly"} | 40-way nested controller including comm-register flags, logs, FRU, bonding, interface and snapshot actions | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 a5 | Selector a5 | {"prefix_hex": "802800a5", "length_check_at_entry": "cmp\tr6, \#12", "payload": "bytes4-12 must spell 'Reset POH' for side effect; total length 13-16 selects fixed reset value, length \>=17 supplies little-endian 32-bit value at 13-16"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none on observed paths"} | matching magic with total length 13-16 calls WrBBRegPOH(0x02800000); length \>=17 and value \<0x800000 calls WrBBRegPOH((value \| 0x800000) \* 5); nonmatching magic is no-op success | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 a8 | Selector a8 | {"prefix_hex": "802800a8", "length_check_at_entry": "sub\tr1, r6, \#4 (followed by comparison; inspect entry)", "payload": "variable-length licensing key parameter payload (delegated unchanged to lkeySetKeyParameters)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "backend-generated length and bytes"} | sets licensing key parameters | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 a9 | Selector a9 | {"prefix_hex": "802800a9", "length_check_at_entry": "sub\tr1, r6, \#4 (followed by comparison; inspect entry)", "payload": "variable-length licensing application query payload (delegated unchanged to lkeyGetAppEnable)"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "backend-generated length and bytes"} | none; queries licensing application enable state | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 aa | Selector aa | {"prefix_hex": "802800aa", "length_check_at_entry": "cmp\tr6, \#6", "payload": "exactly two bytes: byte4 must be 01; byte5 must be 00 or 01"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | calls haSetLocalMonitorStatus(1) for byte5=00, or haSetLocalMonitorStatus(0) for byte5=01 | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 ab | Selector ab | {"prefix_hex": "802800ab", "length_check_at_entry": "cmp\tr6, \#6", "payload": "byte4=01, byte5=01, byte6=data length \<=200, followed by that many data bytes; total length exactly 7+data length"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "backend-generated response"} | passes data into OEM_FTS_BiosCmds after RC-init and SD-card checks; downstream side effects unresolved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b0 | Selector b0 | {"prefix_hex": "802800b0", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly 1 byte: identification LED setting at offset 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | sets identification LED via haSetIdentLed | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b1 | Selector b1 | {"prefix_hex": "802800b1", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none; exact total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: current identification LED value"} | none; reads identification LED | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b2 | Selector b2 | {"prefix_hex": "802800b2", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly 1 byte: message LED mode at offset 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | sets message LED mode via haSetMsgLedMode | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b3 | Selector b3 | {"prefix_hex": "802800b3", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none; exact total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: current message LED mode"} | none; reads message LED mode | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b4 | Selector b4 | {"prefix_hex": "802800b4", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none; exact total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: power LED status"} | none; reads power LED status | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b5 | Selector b5 | {"prefix_hex": "802800b5", "length_check_at_entry": "cmp\tr6, \#4", "payload": "none; exact total length 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "four bytes: low-level register values 3, 4, 5 and 6"} | none; reads LVP registers | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 b6 | Selector b6 | {"prefix_hex": "802800b6", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly one CSS test-mode byte at offset4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | calls SetCssTest with requested byte | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 de | Selector de | {"prefix_hex": "802800de", "length_check_at_entry": "cmp\tr6, \#7", "payload": "at least four bytes after selector; offsets4-7 must equal 43 4c 52 aa ('CLR' + 0xaa); extra bytes ignored in traced branch"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | calls ConfigurationSpaceStatus mode 4 with fixed configuration pointer; precise backend mutation unresolved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 df | Selector df | {"prefix_hex": "802800df", "length_check_at_entry": "cmp\tr6, \#7", "payload": "exactly four magic bytes 43 4c 52 aa ('CLR' + 0xaa) at offsets 4-7; extra bytes accepted"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | none in this wrapper branch; validates magic and returns success | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 e0 | Selector e0 | {"prefix_hex": "802800e0", "length_check_at_entry": "cmp\tr6, \#7", "payload": "at least four bytes after selector; offsets4-6 must equal 43 4c 52 ('CLR'); offset7 accepts 00, aa or bb; extra bytes ignored"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte from ConfigurationSpaceStatus mode 5 on observed return path"} | calls ConfigurationSpaceStatus mode 1/2/3 based on magic byte, emits an event and may unlink a state file on backend success | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 e1 | Selector e1 | {"prefix_hex": "802800e1", "length_check_at_entry": "cmp\tr6, \#7", "payload": "exactly 3 bytes: fan selector at offset 4; little-endian 16-bit configuration-space offset at 5-6"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "success: one length byte followed by configuration data (backend fills up to 0x100-byte buffer); exact maximum wire size unresolved"} | reads extended configuration space through ReadConfigurationSpaceExt | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 e2 | Selector e2 | {"prefix_hex": "802800e2", "length_check_at_entry": "cmp\tr6, \#7", "payload": "fan selector offset 4; little-endian 16-bit configuration-space offset at 5-6; byte count at 7; count data bytes at 8; total length must equal 8+count"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | writes configuration space via WriteConfigurationSpace | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 e3 | Selector e3 | {"prefix_hex": "802800e3", "length_check_at_entry": "cmp\tr6, \#13", "payload": "exactly nine bytes after selector (total length 13); byte4 must equal 01; three little-endian 16-bit fields begin at offsets5,7,9"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "backend-generated configuration-space response"} | configuration-space read/enum path; exact backend effect unresolved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 ef | Selector ef | {"prefix_hex": "802800ef", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f0 | Selector f0 | {"prefix_hex": "802800f0", "length_check_at_entry": "cmp\tr6, \#12", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f1 | Selector f1 | {"prefix_hex": "802800f1", "length_check_at_entry": "cmp\tr6, \#4", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f2 | Selector f2 | {"prefix_hex": "802800f2", "length_check_at_entry": "not established at entry", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f6 | Selector f6 | {"prefix_hex": "802800f6", "length_check_at_entry": "cmp\tr6, \#6", "payload": "exactly 2 bytes: account/user selector at offset 4, shell value at offset 5"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | writes BMC account user-shell setting through salCsBMCAcctUserShell_write | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f7 | Selector f7 | {"prefix_hex": "802800f7", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly 1 byte: account/user selector at offset 4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: shell value from salCsBMCAcctUserShell_read"} | none; reads account shell setting | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f8 | Selector f8 | {"prefix_hex": "802800f8", "length_check_at_entry": "cmp\tr6, \#5", "payload": "exactly one nonzero user ID at offset4"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "none"} | deletes selected BMC user ID via utDeleteUserID | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 f9 | Selector f9 | {"prefix_hex": "802800f9", "length_check_at_entry": "sub\tr1, r6, \#4 (followed by comparison; inspect entry)", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | undetermined from entry block | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 fa | Selector fa | {"prefix_hex": "802800fa", "length_check_at_entry": "cmp\tr6, \#6", "payload": "exactly two bytes after selector (total length 6); byte4 is nested selector 01/02/03, byte5 nested argument"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "branch-specific; unresolved"} | nested selector dispatch may change BMC state; leaf effects unresolved | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 fc | Selector fc | {"prefix_hex": "802800fc", "length_check_at_entry": "cmp\tr6, \#5", "payload": "at least 2 bytes after selector; byte4 must 01, byte5 must 01, total length exactly 7 on connection-test branch; byte6 passed to ldapTestConnectionReq"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte filled by ldapTestConnectionReq on success"} | initiates LDAP test connection (network side effect) | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 fd | Selector fd | {"prefix_hex": "802800fd", "length_check_at_entry": "cmp\tr6, \#6", "payload": "selector-specific; not fully resolved"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "not fully resolved"} | manufacturing-command side effects depend on inner request | partial · [evidence](evidence/f5-selector-contracts.json) |
| 2e/f5 · 80 28 00 fe | Selector fe | {"prefix_hex": "802800fe", "length_check_at_entry": "not established at entry", "payload": "none; minimum total length 4 from shared outer gate"} | {"layout": "completion code, Fujitsu IANA 80 28 00, selector-specific body", "body": "one byte: 01"} | none; returns fixed one-byte value 01 | decoded · [evidence](evidence/f5-selector-contracts.json) |
| 2e/01 · 80 28 00 15 | Get last power-on reason | {"accepted_total_bytes": "at least 4", "fields": "none"} | {"success_total_bytes": 6, "fields": "byte4 length=1, byte5 reason"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 16 | Get next/last power-off reason | {"accepted_total_bytes": "at least 4", "fields": "none"} | {"success_total_bytes": 6, "fields": "byte4 length=1, byte5 reason"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 17 | Set next power transition reason | {"accepted_total_bytes": "at least 4 by shared guard; no selector-specific length check, though meaningful payload needs 9 bytes", "minimum_read_bytes": 9, "fields": "bytes4-7 must equal 00 00 00 01; byte8 reason; trailing bytes ignored. Short accepted requests can cause out-of-bounds reads"} | {"success_total_bytes": 4, "fields": "no body"} | mutating persistent reason | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 18 | Get last power-on timestamp | {"accepted_total_bytes": "at least 4", "fields": "none"} | {"success_total_bytes": 9, "fields": "byte4 length=4, bytes5-8 timestamp LE from state +0x8a1c"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 1b | Set power on/off reason | {"accepted_total_bytes": "at least 4 by shared guard; meaningful payload needs 9 bytes but selector never checks length", "minimum_read_bytes": 9, "fields": "bytes4-7 must equal 00 00 00 01; byte8 reason; trailing bytes ignored. Short accepted requests can read beyond input"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: reason 03 is no-op, 09 stores BBR and emits SEL, 15/16/1d/1e store temporary reason, 1a prints only, all other values store BBR | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 1c | Set power-off inhibit | {"accepted_total_bytes": "at least 4 by shared guard; meaningful payload needs 9 bytes but selector never checks length", "minimum_read_bytes": 9, "fields": "bytes4-7 must equal 00 00 00 01; byte8 inhibit; trailing bytes ignored. Short accepted requests can read beyond input"} | {"success_total_bytes": 4, "fields": "no body"} | mutating power-off policy | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 1d | Get power-off inhibit | {"accepted_total_bytes": "at least 4", "fields": "none"} | {"success_total_bytes": 6, "fields": "byte4 length=1, byte5 inhibit"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/01 · 80 28 00 20 | Set next power-on time | {"accepted_total_bytes": "at least 4 by shared guard; meaningful payload needs 12 bytes but selector never checks length", "minimum_read_bytes": 12, "fields": "bytes4-7 must equal 00 00 00 04; bytes8-11 next power-on time LE32; trailing bytes ignored. Short accepted requests can read beyond input"} | {"success_total_bytes": 4, "fields": "no body"} | mutating power schedule and power-saving inhibit | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 01 | Set host-agent connection state | {"accepted_total_bytes": "exactly 4, 5, 7, or 8; state 3/4 require 7 or 8", "fields": "4-byte form implicitly stores state 1; otherwise byte4 state 0..4. States 3/4 read bytes5-6 LE value; 8-byte form requires byte7=1. Extra bytes in 7/8-byte forms are ignored for states 0..2"} | {"success_total_bytes": 4, "fields": "no body; errors also return completion plus echoed IANA"} | mutating: state 0 clears connection/value/flag; 1/2 store state and clear value/flag; 3/4 store state/value/optional flag. Accepted forms may increment boot counter, notify PCI scan, and set host status. A 5-byte state 3/4 or invalid 8-byte flag calls utSetHostSystemStatus(0,5) before returning error | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 02 | Disconnect host agent | {"accepted_total_bytes": "at least 4; trailing bytes ignored", "fields": "none"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: calls onRequestAsrrShutdown when shared-state bytes +0x76d and +0x76c are both nonzero, then always calls onSetAgentDisconnected | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 05 | Set communication register connected | {"accepted_total_bytes": "at least 4; trailing bytes ignored", "fields": "none"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: if temporary power reason is FF stores 00, then calls onSetCommunicationReg(1) | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 06 | Set communication register disconnected | {"accepted_total_bytes": "at least 4; trailing bytes ignored", "fields": "none"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: calls onSetCommunicationReg(2) | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 08 | Get host-agent connection state | {"accepted_total_bytes": "at least 4", "fields": "none"} | {"success_total_bytes": "8 or 9", "fields": "byte4 length 1/3/4, byte5 state, bytes6-7 features LE, byte8 optional flag"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 09 | Reset communication and power-cycle request | {"accepted_total_bytes": "at least 4; trailing bytes ignored", "fields": "none"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: clears prevent-power-saving reason 0x400, sets communication register 0, cancels power-cycle request, stores temporary reason FF | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/02 · 80 28 00 0f | Mark OS shutdown in progress | {"accepted_total_bytes": "at least 4 by shared guard; meaningful payload needs 9 bytes but selector never checks length", "minimum_read_bytes": 9, "fields": "bytes4-7 must equal 00 00 00 01; byte8 selects a shutdown-reason bit via (1 \<\< byte8) & FF; trailing bytes ignored. Short accepted requests can read beyond input"} | {"success_total_bytes": 4, "fields": "no body"} | mutating host status and shutdown state; utSetHostSystemStatus(0,6) runs before marker validation, including failed requests | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/03 · 80 28 00 10 | Start fan test | {"accepted_total_bytes": "at least 4; trailing bytes ignored", "fields": "none"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: calls fcStartFanTest(0,0) on non-blade systems; blade systems return success without invoking it | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/07 · 80 28 00 05 | Get memory PDA module mark/CRC | {"accepted_total_bytes": 5, "fields": "byte4 module index 0..127 (bit7 rejected)"} | {"success_total_bytes": 10, "fields": "byte4 length=5, byte5 mark-valid flag, bytes6-9 LE32 record or CRC. If first bitwise-op query succeeds, reads cached record; otherwise requires SPD-present byte and uses getCrcByNumber plus utIsMemorySpdMemoryMarkValid"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/07 · 80 28 00 06 | Set memory PDA module record | {"accepted_total_bytes": 13, "fields": "byte4 module index 0..127; bytes5-7 ignored by wrapper; byte8 zero selects bitwise operation 3, nonzero selects operation 2; bytes9-12 LE32 record stored at state +0x79c+4\*index"} | {"success_total_bytes": 4, "fields": "no body"} | mutating: invokes two mcMemModuleBitwiseOp calls (their return values are ignored), then stores LE32 module record | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/07 · 80 28 00 10 | Clear all memory PDA data | {"accepted_total_bytes": 4, "fields": "none"} | {"success_total_bytes": 4, "fields": "no body"} | destructive reset of memory PDA data | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/07 · 80 28 00 11 | Clear memory PDA module entries | {"accepted_total_bytes": 5, "fields": "byte4 module index 0..127; bit7 rejected"} | {"success_total_bytes": 4, "fields": "no body"} | destructive reset: calls clearMemoryPDAModuleEntries(index) | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/09 · 80 28 00 40 | Get power-history data | {"accepted_total_bytes": 7, "fields": "byte4 history kind 0/1/2, bytes5-6 sample index LE16. Kind 0 maps helper ring 3 with index \<0x5a1; kind 1 maps ring 1 with index \<0x2e9; kind 2 maps ring 2 with index \<= runtime max and helper bound"} | {"success_total_bytes": 17, "fields": "byte4 length=12; bytes5-16 encoded cached sample: LE32 record field at offsets 0..3, LE16 at 4..5, LE16 at 6..7 with source bit14 cleared and bit15 preserved, then LE16 fields at 8..9 and 10..11. Physical units and producer are not proved"} | read of mutex-protected cached history ring; not a direct PSU measurement | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/10 · 80 28 00 02 | Set local visual panel text | {"accepted_total_bytes": "success requires total\>=10, line byte4\<2, and signed(total-7)\>byte7; no upper bound", "minimum_read_bytes": 10, "fields": "byte4 line 0/1; bytes5-6 copied to unused local; byte7 declared count; byte8 alignment flag (1=center, other values left-aligned); bytes9.. display text. Copies min((byte7-1)&ff,20) bytes from byte9; byte7=0 with a 10-byte request passes guards but reads 20 bytes beyond request"} | {"success_total_bytes": 4, "fields": "no body"} | mutating front-panel display; builds 42-byte two-line buffer with line length at offset 0 or 21 and up to 20 text bytes after optional leading spaces. lvp_updateLastUpdateTime is also called on several rejected requests | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 00 | Configuration-space status | {"accepted_total_bytes": "at least 4; no selector-specific check", "fields": "none"} | {"success_total_bytes": 4, "fields": "completion encodes status 00,01,02"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 01 | Read configuration-space variable | {"accepted_total_bytes": 7, "fields": "byte4 subindex, bytes5-6 variable ID little-endian"} | {"success_total_bytes": "5+returned length on ordinary path; blade callback can emit a separate response and cause this handler to return length zero", "fields": "byte4 returned length; bytes5.. value"} | read | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 02 | Write configuration-space variable | {"accepted_total_bytes": "8+byte7 length (zero length is accepted by visible guard)", "minimum_read_bytes": "10 for blade schedule variable IDs 0xa0/0xa1 and subindex 0..6; helper reads two payload bytes even when declared length is zero or one", "fields": "byte4 subindex, bytes5-6 variable ID LE, byte7 length, bytes8.. data"} | {"success_total_bytes": "4 on ordinary path; blade callback can emit a separate response and cause this handler to return length zero", "fields": "no ordinary-path body; blade callback response unresolved"} | mutating; blade schedule helper may read beyond short accepted payload | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 03 | Configuration-space self-test update | {"accepted_total_bytes": "at least 4; no selector-specific check", "fields": "none"} | {"success_total_bytes": 4, "fields": "completion 00,02,03 according to status"} | mutating BMC self-test bit | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 04 | NVRAM/IDPROM maintenance multiplexer | {"accepted_total_bytes": "5..9 regardless of helper subcommand; wrapper checks only total-5\<5", "minimum_read_bytes": "5 for most subcommands; 9 for DF, which loads a 32-bit value at byte5 without a matching wrapper length check", "fields": "byte4 helper subcommand. DE selects five output bytes; other subcommands select one. DF consumes bytes5-8 as a 32-bit flags value. Additional bytes are ignored by most subcommands"} | {"success_total_bytes": "5 for subcommands other than DE; 9 for DE", "fields": "completion is CheckNvramToIdprom return; bytes4.. are helper output initialized to zero and selectively overwritten, not a uniform comparison result"} | mixed; many subcommands mutate persistent NVRAM, IDPROM, FRU, or BMC state. Examples: A3 backup; C0/C1 restore; D0-DD and DF alter flags; E3 writes IDPROM; EA clears IDPROM/FRU; F6 restores NVRAM. Treat the entire parent selector as unsafe | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 07 | Chunked configuration-space read | {"accepted_total_bytes": 13, "fields": "byte4 version=1, byte5 subindex, bytes6-7 variable ID LE, byte8=0, bytes9-10 offset LE, bytes11-12 requested chunk length LE (nonzero)"} | {"success_total_bytes": "9+returned chunk length; on offset beyond total the unsigned total-offset calculation can wrap and drive a large cache read", "fields": "byte4=0, bytes5-6 total size LE, bytes7-8 returned length LE, bytes9.. chunk"} | read; session state/cache and notification side effects | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 08 | Chunked configuration-space write | {"accepted_total_bytes": "\>11 by actual guard; coherent wire format needs at least 13 plus chunk, but no safe lower-bound or declared-total check is proved", "minimum_read_bytes": "13 for chunk header; 15 when blade schedule helper intercepts variable IDs 0xa0/0xa1, because it reads two bytes at chunk start regardless of chunk length", "fields": "byte4 version=1, byte5 subindex, bytes6-7 variable ID LE, byte8=0, bytes9-10 total size LE, bytes11-12 offset LE, bytes13.. chunk. A 12-byte request passes the guard but computes unsigned chunk length total-13 = 0xffffffff before memcpy"} | {"success_total_bytes": "4 on ordinary path; blade callback may return a separate response and cause this handler to return length zero", "fields": "no ordinary-path body; error path may append helper bytes; callback response unresolved"} | mutating; malformed short requests can trigger oversized cache copy before final write or blade helper out-of-bounds read | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 09 | Read configuration-space default | {"accepted_total_bytes": 7, "fields": "byte4 subindex, bytes5-6 variable ID LE"} | {"success_total_bytes": "5+returned length on ordinary path; blade callback can emit a separate response and cause this handler to return length zero", "fields": "byte4 length, bytes5.. default value"} | read | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 0a | Read configuration-space limits | {"accepted_total_bytes": 7, "fields": "byte4 ignored by wrapper; bytes5-6 variable ID LE"} | {"success_total_bytes": "5+low8(strlen(limits)); helper output is a NUL-terminated limits string but NUL is not included in response length", "fields": "byte4 low8 text length, bytes5.. limits string bytes"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/e0 · 80 28 00 10 | Reset configuration-space variable to defaults | {"accepted_total_bytes": 7, "fields": "byte4 subindex, bytes5-6 variable ID LE"} | {"success_total_bytes": 4, "fields": "no body"} | mutating; restores variable default | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/f8 · 80 28 00 06 | Get blade port name | {"accepted_total_bytes": "exactly 6 or 7 by unsigned total-6 \<= 1", "fields": "byte4 port index 0..5, byte5 type 1..4; optional byte6 ignored by wrapper. Validation checks both fields, but selected cached name comes from utGetPortNumber(0), not the supplied port index"} | {"success_total_bytes": "5 if stored name length is 0 or 255; otherwise 6+stored name length", "fields": "byte4 is stored name length+1, bytes5.. name and terminating NUL; empty/error-length case byte4=0. Non-blade C1 returns five bytes with byte4 unproved"} | read | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/f8 · 80 28 00 10 | Blade interface state action | {"accepted_total_bytes": "no explicit length check; handler reads selector byte3 even for undersized input, and ignores trailing bytes", "minimum_read_bytes": 4, "fields": "selector only; behavior depends on cached blade interface state at platform object +0x776"} | {"success_total_bytes": 4, "fields": "no body on blade systems; non-blade C1 path returns five bytes with one extra byte of unproved content"} | mutating only for invalid cached states: state 4 or outside 1..4 is reset to 1; states 1/2 return C0 without changing state, state 3 returns success | decoded · [evidence](evidence/scci-selector-contracts.json) |
| 2e/f8 · 80 28 00 20 | Set blade interface control | {"accepted_total_bytes": null, "minimum_read_bytes": 6, "fields": "byte4 bit0 mode, bits1-2 type, bits3-5 slot; byte5 bit7 flag"} | {"success_total_bytes": 4, "fields": "no body"} | mutating | partial · [evidence](evidence/scci-selector-contracts.json) |
| 2e/f8 · 80 28 00 21 | Get blade interface control | {"accepted_total_bytes": null, "minimum_read_bytes": 5, "fields": "byte4 bit0 mode, bits1-2 type, bits3-5 slot"} | {"success_total_bytes": "5 on success", "fields": "byte4 flag bit7; local_1c source unresolved"} | read | partial · [evidence](evidence/scci-selector-contracts.json) |

## F5/A4 nested dispatch

F5/A4 has 40 additional inner selector targets beyond the 228 outer leaves. These rows prove dispatch identity and entry behavior only; field-level contracts remain partial and none is a safe-call recipe. [Nested contracts and source evidence](evidence/f5-selector-contracts.json).

| Wire                     | Entry behavior                 | Handler address |
|--------------------------|--------------------------------|-----------------|
| 2e/f5 · 80 28 00 a4 0x01 | read comm bit 0x100            | 0x0002152c      |
| 2e/f5 · 80 28 00 a4 0x02 | reset comm bit 0x100           | 0x00021510      |
| 2e/f5 · 80 28 00 a4 0x03 | explicit C9 stub               | 0x00020920      |
| 2e/f5 · 80 28 00 a4 0x04 | explicit C9 stub               | 0x00020920      |
| 2e/f5 · 80 28 00 a4 0x05 | read comm bit 0x80 / SD status | 0x0002159c      |
| 2e/f5 · 80 28 00 a4 0x06 | reset comm bit 0x80            | 0x00021580      |
| 2e/f5 · 80 28 00 a4 0x07 | read comm bit 0x40             | 0x00021564      |
| 2e/f5 · 80 28 00 a4 0x08 | reset comm bit 0x40            | 0x00021548      |
| 2e/f5 · 80 28 00 a4 0x09 | set ASRR disable               | 0x000216f0      |
| 2e/f5 · 80 28 00 a4 0x0a | clear ASRR disable             | 0x000216d4      |
| 2e/f5 · 80 28 00 a4 0x0b | read ASRR disable              | 0x000216b8      |
| 2e/f5 · 80 28 00 a4 0x0c | explicit C9 stub               | 0x0001ef60      |
| 2e/f5 · 80 28 00 a4 0x0d | explicit C9 stub               | 0x0001ef60      |
| 2e/f5 · 80 28 00 a4 0x0e | read modular LAN port          | 0x0002169c      |
| 2e/f5 · 80 28 00 a4 0x0f | read low-noise mode            | 0x00021680      |
| 2e/f5 · 80 28 00 a4 0x10 | GPIO function lookup           | 0x0002163c      |
| 2e/f5 · 80 28 00 a4 0x11 | LVP device status              | 0x00021628      |
| 2e/f5 · 80 28 00 a4 0x12 | SD-card status                 | 0x000215b8      |
| 2e/f5 · 80 28 00 a4 0x13 | start debug-log export         | 0x00021a88      |
| 2e/f5 · 80 28 00 a4 0x14 | read debug-log export status   | 0x00021a6c      |
| 2e/f5 · 80 28 00 a4 0x15 | delete debug-log archive       | 0x00021a44      |
| 2e/f5 · 80 28 00 a4 0x16 | I2C bus number                 | 0x00021a04      |
| 2e/f5 · 80 28 00 a4 0x17 | get LAN link status            | 0x000219e4      |
| 2e/f5 · 80 28 00 a4 0x18 | initialize LAN link status     | 0x000219c4      |
| 2e/f5 · 80 28 00 a4 0x19 | read SGPIO input               | 0x000219a0      |
| 2e/f5 · 80 28 00 a4 0x1a | read memory architecture       | 0x0002191c      |
| 2e/f5 · 80 28 00 a4 0x1b | read feature enable            | 0x000218f8      |
| 2e/f5 · 80 28 00 a4 0x1c | file state probe               | 0x000218e0      |
| 2e/f5 · 80 28 00 a4 0x1d | file state probe               | 0x000218bc      |
| 2e/f5 · 80 28 00 a4 0x1e | update FRU from CSV            | 0x0002189c      |
| 2e/f5 · 80 28 00 a4 0x1f | explicit C9 stub               | 0x0001ef60      |
| 2e/f5 · 80 28 00 a4 0x20 | interface control              | 0x000217d0      |
| 2e/f5 · 80 28 00 a4 0x21 | get system configuration       | 0x0002179c      |
| 2e/f5 · 80 28 00 a4 0x22 | get bonding active slave       | 0x00021750      |
| 2e/f5 · 80 28 00 a4 0x23 | change bonding active slave    | 0x0002170c      |
| 2e/f5 · 80 28 00 a4 0x24 | get bonding linked slaves      | 0x00021830      |
| 2e/f5 · 80 28 00 a4 0x25 | explicit C9 stub               | 0x0001ef60      |
| 2e/f5 · 80 28 00 a4 0x26 | explicit C9 stub               | 0x0001ef60      |
| 2e/f5 · 80 28 00 a4 0x27 | explicit C9 stub               | 0x0001ef60      |
| 2e/f5 · 80 28 00 a4 0x28 | snapshot invocation            | 0x000221b4      |

## E0/04 maintenance subcommands

The misleadingly named NVRAM/IDPROM check dispatches 50 helper cases inside outer selector E0/04: 32 mutate state, seven have read-only branch behavior, and 11 retain unresolved helper effects. Shared persistence can follow any branch, so none is a safe-call recommendation. The outer wrapper accepts five-byte requests even though DF reads four more bytes. [Case-by-case pinned evidence](evidence/e0-04-maintenance-subcommands.json).

| Byte 4 | Observed behavior | Branch class |
|----|----|----|
| 0x00 | Reports initialization/status: 0x10 if context unavailable, else a flag-dependent status byte. | read |
| 0x01 | Returns low byte of context field +0x510. | read |
| 0x02 | Same context field +0x510 read as 0x01. | read |
| 0x03 | Invokes optional callback at dispatch table +0x44; returns 0x10 if absent. Callback effect unresolved. | unknown |
| 0xa2 | Conditionally invokes FUN_0008ceac(0x88) when auxiliary flag is set and context +0x4fc is zero; helper effect unresolved. | unknown |
| 0xa3 | Clears context +0x70, sets two global state words, then calls SNTCI_Backup. | mutate |
| 0xa4 | Clears context +0x70 and sets two global state words; no backup call in this branch. | mutate |
| 0xa5 | Calls SNTCI_RuntimeInit; downstream initialization effects unresolved. | unknown |
| 0xac | Verbosity-gated print of two context halfwords (+0xf0 and +0x514). | read |
| 0xad | Calls SNTCI_CheckIfMoBoChanged and may print result; helper side effects unresolved. | unknown |
| 0xae | Clears context halfword +0xf0, optionally printing its previous value. | mutate |
| 0xaf | When two busy fields are clear, resets context/flags and calls ciCheckBigIDPROM; on nonzero check sets bits 0..2 at context +0xf0. | mutate |
| 0xc0 | Sets global flag 0x40 and invokes ciRestore; result is logged, but exact restored data is backend-dependent. | mutate |
| 0xc1 | Sets global flag 0x40 and invokes ciRestoreFru; result is logged. | mutate |
| 0xd0 | Clears global flags and context +0x18, marks SFS state dirty for shared postlude persistence. | mutate |
| 0xd1 | Sets global flag bit 0, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd2 | Sets global flag bit 1, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd3 | Sets global flag bit 2, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd4 | Sets global flag bit 3, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd5 | Sets global flag bit 4, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd6 | Sets global flag bit 5, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd7 | Sets global flag bit 6, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd8 | Sets global flag bit 7, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xd9 | Sets global flag bit 8, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xda | Sets global flag bit 9, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xdb | Sets global flag bit 10, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xdc | Sets global flag bit 11, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xdd | Sets global flag bit 12, copies flags to context +0x18, and marks SFS dirty. | mutate |
| 0xde | Returns five bytes: zero followed by the four bytes of global flags; helper requires length 5. | read |
| 0xdf | Loads unaligned 32-bit flags from request bytes5..8, replaces global flags, copies them to context +0x18, and marks SFS dirty. | mutate |
| 0xe1 | Resets IDPROM cursor at context +0x534 and advances a three-pattern test selector at +0x538. | mutate |
| 0xe2 | Reads 256 bytes of 1K IDPROM at current cursor, hex-prints them, and advances cursor by 256. | mutate |
| 0xe3 | Writes 256 bytes of 0xa5, 0x5a, or 0x00 pattern to 1K IDPROM at current cursor, then advances cursor. | mutate |
| 0xe7 | When both auxiliary state words are nonzero, invokes FUN_00089da4; delegated effect unresolved. | unknown |
| 0xe9 | Creates a named file, sets context flag bit 1 if previously clear, and may mark SFS state dirty. | mutate |
| 0xea | Writes 100 zero bytes to 1K IDPROM offset zero, then calls ciClearFru. | mutate |
| 0xeb | Sets context +0x0c to a fixed pointer, marks SFS dirty, and calls Put_SFS_RAM. | mutate |
| 0xec | Sets context flag bit 1 if clear and may mark SFS state dirty. | mutate |
| 0xed | Copies seven fixed bytes to context +0x3d, marks SFS dirty, and calls Put_SFS_RAM. | mutate |
| 0xee | No branch-local operation; shared postlude may flush previously dirty SFS state. | unknown |
| 0xf1 | Same branch as 0xee: no local operation; shared postlude may flush previously dirty SFS state. | unknown |
| 0xef | Resets context +0xdc and calls ciGetIDPROMValues; its complete state effects are unresolved. | unknown |
| 0xf2 | Clears auxiliary state word 2 and sets context +0x70 to one. | mutate |
| 0xf3 | Sets auxiliary state word 2 and clears context +0x70. | mutate |
| 0xf4 | Calls SNTCI_Init; downstream initialization effects unresolved. | unknown |
| 0xf6 | Calls ciRestore; on nonzero restore result initializes NVRAM and may remove a named file unless global flag 0x40 is set. | mutate |
| 0xf7 | Calls SNTCI_RuntimeInit; downstream initialization effects unresolved. | unknown |
| 0xfa | Calls ciGetSDRValues, which may refresh runtime context; downstream effects unresolved. | unknown |
| 0xfe | Temporarily sets global flags 0x12 while calling SNTCI_PrintValuesInSfsIdprom, then restores flags. | read |
| 0xff | Temporarily sets global flags 0x12 while calling SNTCI_PrintValues, then restores flags. | read |

## 34/38–39 backup and restore parameters

The pinned helper has 92 table records: an ID-0 marker and 91 distinct parameter IDs. Labels and metadata below are extracted from the binary, not proof that backup redacts sensitive values or that restore succeeds. Four IDs carry the restore-restriction flag. The table includes credentials, keys, certificates, and network settings; do not treat backup as a harmless read. [Field layout, addresses, and SHA-pinned evidence](evidence/backup-restore-parameter-table.json).

Filter parameter IDs or labels

| ID | Embedded label | Sub-ID \< | Type | Mode | Max bytes | Restore restricted | Read path |
|----|----|----|----|----|----|----|----|
| 0x0000 | First Parameter marker | 65535 | 2 | 0 | 0 | 0 | 0 |
| 0x1457 | User Enabled | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1451 | Name | 15 | 2 | 8 | 16 | 0 | 0 |
| 0x1452 | Password | 15 | 2 | 8 | 50 | 1 | 0 |
| 0x1454 | IPMI LAN Privilege | 15 | 0 | 8 | 1 | 0 | 0 |
| 0x145b | IPMI Serial Privilege | 15 | 0 | 8 | 1 | 0 | 0 |
| 0x1459 | ConfBMCAcctUserShell | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1453 | Configure User Accounts | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x145d | Configure iRMC S2 settings | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x145e | Video Redirection Enabled | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x145f | Remote Storage enabled | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x145a | ConfBMCAcctUserEnableEmailPag | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1288 | ConfAlarmMailType | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1458 | ConfBMCAcctUserEmailAddress | 15 | 2 | 8 | 64 | 0 | 1 |
| 0x1455 | User Description | 15 | 2 | 8 | 32 | 0 | 1 |
| 0x1901 | ConfBMCPagingSeverityFans | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1900 | ConfBMCPagingSeverityTemperatur | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1903 | ConfBMCPagingSeverityHWErrors | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1904 | ConfBMCPagingSeveritySysHang | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1905 | ConfBMCPagingSeverityPOSTErrors | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1906 | ConfBMCPagingSeveritySecurity | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1907 | ConfBMCPagingSeveritySysStatus | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1908 | ConfBMCPagingSeverityHDErrors | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1909 | ConfBMCPagingSeverityNetwork | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x190a | ConfBMCPagingSeverityRemote | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x190b | ConfBMCPagingSeverityPower | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1902 | ConfBMCPagingSeverityMemory | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x193f | ConfBMCPagingSeverityOthers | 15 | 0 | 8 | 1 | 0 | 1 |
| 0x1971 | LDAP Enable | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x1972 | LDAP SSL Enable | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x1974 | Directory Server Type | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x1976 | LDAP Server \[1 \| 2\] | 2 | 2 | 0 | 64 | 0 | 1 |
| 0x1977 | Domain Name | 1 | 2 | 0 | 64 | 0 | 1 |
| 0x1978 | Dept.name | 1 | 2 | 0 | 32 | 0 | 1 |
| 0x1979 | LDAP Auth UserName | 1 | 2 | 0 | 32 | 0 | 1 |
| 0x197a | LDAP Auth Password | 1 | 2 | 0 | 48 | 1 | 1 |
| 0x197b | Disable Local Login | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x197c | Always use SSL Login | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x197d | Base DN | 2 | 2 | 0 | 64 | 0 | 1 |
| 0x197e | Principal User DN | 2 | 2 | 0 | 64 | 0 | 1 |
| 0x197f | Append Base DN to Prin User DN | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x1992 | Group DN Context | 1 | 2 | 0 | 63 | 0 | 1 |
| 0x1993 | User Search Contect | 1 | 2 | 0 | 63 | 0 | 1 |
| 0x1994 | User Login Search Filter | 1 | 2 | 0 | 63 | 0 | 1 |
| 0x1995 | Enhanced User Login | 1 | 0 | 0 | 1 | 0 | 1 |
| 0x1965 | ConfBMCIpNominalSpeed | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1966 | LAN Port | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1446 | DHCP enable | 1 | 0 | 16 | 1 | 0 | 0 |
| 0x1440 | IP Address | 1 | 2 | 16 | 64 | 0 | 0 |
| 0x1441 | Subnet Mask | 1 | 2 | 16 | 64 | 0 | 0 |
| 0x1442 | Gateway | 1 | 2 | 16 | 64 | 0 | 0 |
| 0x1960 | VLAN enable | 1 | 0 | 16 | 1 | 0 | 0 |
| 0x1961 | VLAD id | 1 | 0 | 16 | 2 | 0 | 0 |
| 0x1962 | VLAN Priority | 1 | 0 | 16 | 1 | 0 | 0 |
| 0x1420 | ConfBMCHttpPort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x1421 | ConfBMCHttpsPort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x1425 | ConfBMCForceHttps | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x2163 | ConfWebSessionTimeout | 1 | 1 | 16 | 2 | 0 | 1 |
| 0x2164 | ConfWebAutoRefreshEnabled | 1 | 1 | 16 | 1 | 0 | 1 |
| 0x2162 | ConfWebAutoRefreshTime | 1 | 1 | 16 | 2 | 0 | 1 |
| 0x1422 | ConfBMCTelnetPort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x1222 | ConfBMCTelnetDropTime | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x1423 | ConfBMCSshPort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x1426 | ConfBMCTelnetEnable | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1428 | ConfBMCVNCPort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x1429 | ConfBMCVNCSecurePort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x142a | ConfBMCRemoteStoragePort | 1 | 0 | 16 | 2 | 0 | 1 |
| 0x144a | Register DHCP Address in DNS | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1431 | Use iRMC S2 Name not Hostname | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1433 | Add Serial Number | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1434 | Add Extension | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x1430 | iRMC S2 Name | 1 | 2 | 16 | 16 | 0 | 1 |
| 0x1432 | Extension | 1 | 2 | 16 | 16 | 0 | 1 |
| 0x144b | DNS enabled | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x144c | Obtain DNS config from DHCP | 1 | 0 | 16 | 1 | 0 | 1 |
| 0x144d | DNS Domain | 1 | 2 | 16 | 48 | 0 | 1 |
| 0x144f | DNS Server\[1 .. 5\] | 5 | 2 | 16 | 16 | 0 | 0 |
| 0x0070 | Current Power State | 1 | 0 | 1 | 1 | 0 | 0 |
| 0x1405 | SNMP Community Name | 1 | 2 | 1 | 18 | 0 | 1 |
| 0x1952 | Remote Storage Server | 1 | 2 | 1 | 64 | 0 | 1 |
| 0x020a | Server IP Address 1 | 1 | 2 | 0 | 48 | 0 | 0 |
| 0x020b | Server IP Address 2 | 1 | 2 | 0 | 48 | 0 | 0 |
| 0x020c | Server IP Address 3 | 1 | 2 | 0 | 48 | 0 | 0 |
| 0x020d | Server IP Address 4 | 1 | 2 | 0 | 48 | 0 | 0 |
| 0x1491 | ConfDeplLanMacAddress | 8 | 2 | 0 | 32 | 0 | 0 |
| 0x1273 | ConfAlarmEmailSMTPAuthPassword | 2 | 2 | 0 | 64 | 1 | 1 |
| 0x1981 | ConfBMCSslPrivateKey | 1 | 2 | 2 | 4096 | 0 | 0 |
| 0x1982 | ConfBMCSslCertificate | 1 | 2 | 2 | 6144 | 0 | 0 |
| 0x1983 | ConfBMCSslCaCertificate | 1 | 2 | 2 | 6144 | 0 | 0 |
| 0xffff | Local Encryption Parameter | 65535 | 2 | 0 | 64 | 1 | 0 |
| 0x00a0 | ConfServerOnTime | 7 | 0 | 0 | 2 | 0 | 0 |
| 0x00a1 | ConfServerOffTime | 7 | 0 | 0 | 2 | 0 | 0 |

## Source and applicability

Target: PRIMERGY RX2540 M7 iRMC S6 02.63S / SDR 03.67. `libipmipdkcmds.so.1.53.20` SHA-256 `35839f7ab40993898666425d50e18654d68791c7dfe3bb5a3c3496e4daa23804`; table SHA-256 `6c25538d508e398135855d59550148b3fd93cdcc045bc9556e4f79c335f72dfa`. Compare the [power and transport map](oem-power-map.md), [Fujitsu iRMC S6 Concepts & Interfaces](https://support.ts.fujitsu.com/Search/SWP1267156.asp), and the [FreeIPMI Fujitsu definitions](https://github.com/chu11/freeipmi-mirror). Public cross-generation selectors are not promoted without this library's dispatch proof.
