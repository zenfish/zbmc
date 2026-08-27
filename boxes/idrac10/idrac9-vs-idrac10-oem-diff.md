<!-- html2md:auto source=boxes/idrac10/idrac9-vs-idrac10-oem-diff.html -->

# iDRAC9 vs iDRAC10 — OEM IPMI Command Diff

Per-command comparison of the reverse-engineered Dell OEM handler catalogs, matched by normalized leaf capability. iDRAC9 = 240 OEM commands (7.10.90, ARMv7); iDRAC10 = 373 commands (1.30.10.50, AArch64). Supersedes the dispatch-tuple-only diff.

- 154
  shared capabilities
- 78
  changed (slot/parent/priv/in-band)
- 121
  in iDRAC10, not in iDRAC9 scope
- 86
  in iDRAC9, not in iDRAC10

**Scope caveat.** The iDRAC9 catalog is the OEM fine-tooth scope (liboemcmds / libmaser / libipmicmdtableapi, 276 cmds); iDRAC10 is comprehensive (446 cmds, all libs incl. libmisccmd / libmodular / libdcmi / libkcspassthru). So *“in iDRAC10 not in iDRAC9” and “removed”* conflate genuine surface changes with commands the iDRAC9 pass never targeted — treat them as leads, not conclusions. The reliable comparison is the **154 shared capabilities** and the **78 that changed slot / parent / priv / in-band gate** (matched by normalized leaf capability, so the 9→10 rename+reorg — e.g. vFlash split out of MASERPartitionAccess — is followed, not miscounted). Type in the filter bar to narrow any table.

## Changed handlers (78)

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr>
<th>handler</th>
<th>deltas (9 → 10)</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>ConfigValDDCmdHndlr/0x00</code>
iDRAC9: DellCmdSetSysInfo/0x00</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0x00 → ConfigValDDCmdHndlr/0x00<br />
<strong>parent</strong>: DellCmdSetSysInfo → ConfigValDDCmdHndlr<br />
<strong>netfn</strong>: 0x06 → 0x30<br />
<strong>cmd</strong>: 0x58 → 0xdd</td>
</tr>
<tr>
<td><code>ConfigValDDCmdHndlr/0x01</code>
iDRAC9: DellCmdGetSysInfo/0x01</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0x01 → ConfigValDDCmdHndlr/0x01<br />
<strong>parent</strong>: DellCmdGetSysInfo → ConfigValDDCmdHndlr<br />
<strong>netfn</strong>: 0x06 → 0x30<br />
<strong>cmd</strong>: 0x59 → 0xdd<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>ConfigValDDCmdHndlr/0x02</code>
iDRAC9: DellCmdSetSysInfo/0x02</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0x02 → ConfigValDDCmdHndlr/0x02<br />
<strong>parent</strong>: DellCmdSetSysInfo → ConfigValDDCmdHndlr<br />
<strong>netfn</strong>: 0x06 → 0x30<br />
<strong>cmd</strong>: 0x58 → 0xdd</td>
</tr>
<tr>
<td><code>ConfigValDDCmdHndlr/0x03</code>
iDRAC9: DellCmdSetSysInfo/0x03</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0x03 → ConfigValDDCmdHndlr/0x03<br />
<strong>parent</strong>: DellCmdSetSysInfo → ConfigValDDCmdHndlr<br />
<strong>netfn</strong>: 0x06 → 0x30<br />
<strong>cmd</strong>: 0x58 → 0xdd</td>
</tr>
<tr>
<td><code>ConfigValDDCmdHndlr/0x04</code>
iDRAC9: DellCmdGetSysInfo/0x04</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0x04 → ConfigValDDCmdHndlr/0x04<br />
<strong>parent</strong>: DellCmdGetSysInfo → ConfigValDDCmdHndlr<br />
<strong>netfn</strong>: 0x06 → 0x30<br />
<strong>cmd</strong>: 0x59 → 0xdd<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>ConfigValDDCmdHndlr/0x05</code>
iDRAC9: DellCmdGetSysInfo/0x05</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0x05 → ConfigValDDCmdHndlr/0x05<br />
<strong>parent</strong>: DellCmdGetSysInfo → ConfigValDDCmdHndlr<br />
<strong>netfn</strong>: 0x06 → 0x30<br />
<strong>cmd</strong>: 0x59 → 0xdd<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc1</code>
iDRAC9: DellCmdSetSysInfo/0xc1</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc1 → DellNMCommand/0xc1<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc1</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc2</code>
iDRAC9: DellCmdSetSysInfo/0xc2</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc2 → DellNMCommand/0xc2<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc2</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc3</code>
iDRAC9: DellCmdSetSysInfo/0xc3</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc3 → DellNMCommand/0xc3<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc3</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc4</code>
iDRAC9: DellCmdSetSysInfo/0xc4</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc4 → DellNMCommand/0xc4<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc4</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc5</code>
iDRAC9: DellCmdSetSysInfo/0xc5</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc5 → DellNMCommand/0xc5<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc5<br />
<strong>inBandOnly</strong>: True → False</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc7</code>
iDRAC9: DellCmdSetSysInfo/0xc7</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc7 → DellNMCommand/0xc7<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc7</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc8</code>
iDRAC9: DellCmdSetSysInfo/0xc8</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc8 → DellNMCommand/0xc8<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc8</td>
</tr>
<tr>
<td><code>DellNMCommand/0xc9</code>
iDRAC9: DellCmdSetSysInfo/0xc9</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xc9 → DellNMCommand/0xc9<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xc9</td>
</tr>
<tr>
<td><code>DellNMCommand/0xca</code>
iDRAC9: DellCmdSetSysInfo/0xca</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xca → DellNMCommand/0xca<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xca</td>
</tr>
<tr>
<td><code>DellNMCommand/0xce</code>
iDRAC9: DellCmdGetSysInfo/0xce</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0xce → DellNMCommand/0xce<br />
<strong>parent</strong>: DellCmdGetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x59 → 0xce<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellNMCommand/0xcf</code>
iDRAC9: DellCmdGetSysInfo/0xcf</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0xcf → DellNMCommand/0xcf<br />
<strong>parent</strong>: DellCmdGetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x59 → 0xcf<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellNMCommand/0xd1</code>
iDRAC9: DellCmdSetSysInfo/0xd1</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xd1 → DellNMCommand/0xd1<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xd1</td>
</tr>
<tr>
<td><code>DellNMCommand/0xd4</code>
iDRAC9: DellCmdGetSysInfo/0xd4</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0xd4 → DellNMCommand/0xd4<br />
<strong>parent</strong>: DellCmdGetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x59 → 0xd4<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellNMCommand/0xd7</code>
iDRAC9: DellCmdSetSysInfo/0xd7</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xd7 → DellNMCommand/0xd7<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xd7</td>
</tr>
<tr>
<td><code>DellNMCommand/0xd8</code>
iDRAC9: DellCmdSetSysInfo/0xd8</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xd8 → DellNMCommand/0xd8<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xd8</td>
</tr>
<tr>
<td><code>DellNMCommand/0xd9</code>
iDRAC9: DellCmdGetSysInfo/0xd9</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdGetSysInfo/0xd9 → DellNMCommand/0xd9<br />
<strong>parent</strong>: DellCmdGetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x59 → 0xd9<br />
<strong>priv</strong>: 2 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellNMCommand/0xdc</code>
iDRAC9: DellCmdSetSysInfo/0xdc</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xdc → DellNMCommand/0xdc<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xdc</td>
</tr>
<tr>
<td><code>DellNMCommand/0xdf</code>
iDRAC9: DellCmdSetSysInfo/0xdf</td>
<td style="font-size: .85rem"><strong>name</strong>: DellCmdSetSysInfo/0xdf → DellNMCommand/0xdf<br />
<strong>parent</strong>: DellCmdSetSysInfo → DellNMCommand<br />
<strong>netfn</strong>: 0x06 → 0x2e<br />
<strong>cmd</strong>: 0x58 → 0xdf</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMADByName</code>
iDRAC9: CmdOEMMASERPartitionAccess/ADByName</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/ADByName → CmdOEMMASERPartitionAccess/CmdOEMADByName<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMAttachPartitions</code>
iDRAC9: CmdOEMMASERPartitionAccess/AttachPartitions</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/AttachPartitions → CmdOEMMASERPartitionAccess/CmdOEMAttachPartitions<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMBeginSECUPD</code>
iDRAC9: CmdOEMMASERPartitionAccess/BeginSECUPD</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/BeginSECUPD → CmdOEMMASERPartitionAccess/CmdOEMBeginSECUPD<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/CancelCmd</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMChangePartitionAccessType</code>
iDRAC9: CmdOEMMASERPartitionAccess/ChangePartitionAccessType</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/ChangePartitionAccessType → CmdOEMMASERPartitionAccess/CmdOEMChangePartitionAccessType<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMChassisIdentify</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 3 → Operator (3)</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMClrPMUpdateFlag</code>
iDRAC9: CmdOEMMASER_PM/ClrPMUpdateFlag</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/ClrPMUpdateFlag → CmdOEMMASER_PM/CmdOEMClrPMUpdateFlag<br />
<strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: False → True</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMCreateDynamicPartition</code>
iDRAC9: CmdOEMMASERPartitionAccess/CreateDynamicPartition</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/CreateDynamicPartition → CmdOEMMASERPartitionAccess/CmdOEMCreateDynamicPartition<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMDeleteDynamicPartition</code>
iDRAC9: CmdOEMMASERPartitionAccess/DeleteDynamicPartition</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/DeleteDynamicPartition → CmdOEMMASERPartitionAccess/CmdOEMDeleteDynamicPartition<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMDetachPartitions</code>
iDRAC9: CmdOEMMASERPartitionAccess/DetachPartitions</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/DetachPartitions → CmdOEMMASERPartitionAccess/CmdOEMDetachPartitions<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMEndSECUPD</code>
iDRAC9: CmdOEMMASERPartitionAccess/EndSECUPD</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/EndSECUPD → CmdOEMMASERPartitionAccess/CmdOEMEndSECUPD<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/GetAutoFeatureStatus</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/GetAutoRestoreVflCap</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMGetBIOSPasswordInfo</code>
iDRAC9: CmdOEMMASER_PM/GetBIOSPasswordInfo</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/GetBIOSPasswordInfo → CmdOEMMASER_PM/CmdOEMGetBIOSPasswordInfo<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMGetMASERAccessState</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMGetMASERType</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMGetPartitionIndexInfo</code>
iDRAC9: CmdOEMMASERPartitionAccess/GetPartitionIndexInfo</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/GetPartitionIndexInfo → CmdOEMMASERPartitionAccess/CmdOEMGetPartitionIndexInfo<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfo</code>
iDRAC9: CmdOEMMASERPartitionAccess/GetPartitionInfo</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/GetPartitionInfo → CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfo<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfoByName</code>
iDRAC9: CmdOEMMASERPartitionAccess/GetPartitionInfoByName</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/GetPartitionInfoByName → CmdOEMMASERPartitionAccess/CmdOEMGetPartitioninfoByName<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMGetPkgCacheUpdateFlag</code>
iDRAC9: CmdOEMMASERPartitionAccess/GetPkgCacheUpdateFlag</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/GetPkgCacheUpdateFlag → CmdOEMMASERPartitionAccess/CmdOEMGetPkgCacheUpdateFlag<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMGetPMDefaultBrand</code>
iDRAC9: CmdOEMMASER_PM/GetPMDefaultBrand</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/GetPMDefaultBrand → CmdOEMMASER_PM/CmdOEMGetPMDefaultBrand<br />
<strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: False → True</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMGetPMRebrand</code>
iDRAC9: CmdOEMMASER_PM/GetPMRebrand</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/GetPMRebrand → CmdOEMMASER_PM/CmdOEMGetPMRebrand<br />
<strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: False → True</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMGetPMStatus</code>
iDRAC9: CmdOEMMASER_PM/GetPMStatus</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/GetPMStatus → CmdOEMMASER_PM/CmdOEMGetPMStatus<br />
<strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: False → True</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMGetPMUpdateFlag</code>
iDRAC9: CmdOEMMASER_PM/GetPMUpdateFlag</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/GetPMUpdateFlag → CmdOEMMASER_PM/CmdOEMGetPMUpdateFlag<br />
<strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: False → True</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMGetUEFIFlag</code>
iDRAC9: CmdOEMMASERPartitionAccess/GetUEFIFlag</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/GetUEFIFlag → CmdOEMMASERPartitionAccess/CmdOEMGetUEFIFlag<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>DellCmdIMCFeatureSupport</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellCmdIMCFirmwareUpdate</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellCmdLCDReadFromQueue</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellCmdLCDReadFromStaging</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMLCLWipe</code>
iDRAC9: CmdOEMMASERPartitionAccess/LCLWipe</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/LCLWipe → CmdOEMMASERPartitionAccess/CmdOEMLCLWipe<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>DellCmdLEDStatus</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMLockMASER</code>
iDRAC9: CmdOEMMASERPartitionAccess/LockMASER</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/LockMASER → CmdOEMMASERPartitionAccess/CmdOEMLockMASER<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>DellCmdLoginAccess</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMMASERLockWDreset</code>
iDRAC9: CmdOEMMASERPartitionAccess/MASERLockWDReset</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/MASERLockWDReset → CmdOEMMASERPartitionAccess/CmdOEMMASERLockWDreset<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>DellCmdMemThrottlingCtrl</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellCmdNodeMgrDebugInfo</code></td>
<td style="font-size: .85rem"><strong>netfn</strong>: 0x2e → undetermined<br />
<strong>cmd</strong>: 0xe0 → undetermined<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>DellCmdNodeMgrSendRaw</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin (0x04)<br />
<strong>inBandOnly</strong>: undetermined; no handler code to inspect for IsMsgFromSystemInterface gate → False</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/PopulateBackupCmd</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/PopulateRestoreCmd</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMProcessSECUPD</code>
iDRAC9: CmdOEMMASERPartitionAccess/ProcessSECUPD</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/ProcessSECUPD → CmdOEMMASERPartitionAccess/CmdOEMProcessSECUPD<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/QueryJobID</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/QueryJobStatus</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMDellFactory/SecureDefaultPassword</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMSecureUpdatePartition</code>
iDRAC9: CmdOEMMASERPartitionAccess/SecureUpdatePartition</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/SecureUpdatePartition → CmdOEMMASERPartitionAccess/CmdOEMSecureUpdatePartition<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/SendBackupCmd</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/SendRestoreCmd</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMRemoteEnablement/SetCCRAutoSyncState</code>
iDRAC9: CmdOEMSetCCRAutoSyncState</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMSetCCRAutoSyncState → CmdOEMRemoteEnablement/SetCCRAutoSyncState<br />
<strong>parent</strong>: CmdOEMSetCCRAutoSyncState → CmdOEMRemoteEnablement<br />
<strong>netfn</strong>: 0x18 → 0x30<br />
<strong>cmd</strong>: 0x8c → 0xa3<br />
<strong>priv</strong>: Operator (3) → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMBackupRestore/SetJobStatusCmd</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 2 → User (0x02)</td>
</tr>
<tr>
<td><code>CmdOEMMASER_PM/CmdOEMSetPMInstall</code>
iDRAC9: CmdOEMMASER_PM/SetPMInstall</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASER_PM/SetPMInstall → CmdOEMMASER_PM/CmdOEMSetPMInstall<br />
<strong>priv</strong>: 4 → Admin<br />
<strong>inBandOnly</strong>: False → True</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMSetUEFIFlag</code>
iDRAC9: CmdOEMMASERPartitionAccess/SetUEFIFlag</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/SetUEFIFlag → CmdOEMMASERPartitionAccess/CmdOEMSetUEFIFlag<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMSingleIPMI</code>
iDRAC9: CmdOEMMASERPartitionAccess/SingleIPMI</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/SingleIPMI → CmdOEMMASERPartitionAccess/CmdOEMSingleIPMI<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMStartSECUPD_PM</code>
iDRAC9: CmdOEMMASERPartitionAccess/StartSECUPD_PM</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/StartSECUPD_PM → CmdOEMMASERPartitionAccess/CmdOEMStartSECUPD_PM<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMiscCmd/SubCmdHandler</code></td>
<td style="font-size: .85rem"><strong>priv</strong>: 4 → Admin</td>
</tr>
<tr>
<td><code>CmdOEMMASERPartitionAccess/CmdOEMUnLockMASER</code>
iDRAC9: CmdOEMMASERPartitionAccess/UnlockMASER</td>
<td style="font-size: .85rem"><strong>name</strong>: CmdOEMMASERPartitionAccess/UnlockMASER → CmdOEMMASERPartitionAccess/CmdOEMUnLockMASER<br />
<strong>priv</strong>: 4 → Admin</td>
</tr>
</tbody>
</table>

## In iDRAC10, not matched in the iDRAC9 OEM scope (121)

| handler | netfn/cmd | priv | security |
|----|----|----|----|
| `0x11` | `0x30/0x11` | Admin | Admin-gated. Only reachable on modular chassis (iDRAC type 2). Acts as a full Admin-privilege IPMI bridge to a physically separate BMC on the chassis fabric; any Admin iDRAC session can send arbitrary |
| `0x12` | `0x30/0x12` | Admin | Admin-gated SCBMC bridge. Same attack surface as cmd=0x11: no validation before forwarding to SCBMC. Potential for Admin-to-SCBMC pivot. |
| `0x13` | `0x30/0x13` | Admin | Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. |
| `0x14` | `0x30/0x14` | Admin | Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. |
| `0x15` | `0x30/0x15` | Admin | Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. |
| `0x16` | `0x30/0x16` | Admin | Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. |
| `0x17` | `0x30/0x17` | Admin | Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. |
| `0x19` | `0x30/0x19` | Admin | Admin-gated SCBMC bridge. No input validation before SCBMC forwarding. Gap at cmd=0x18 is notable. All 8 proxy commands (0x11-0x17, 0x19) share identical handler code and present the same attack surfa |
| `0x40` | `0x2e/0x40/0x40` | Admin | No license gate and no payload validation beyond the global AllowIpmiI2cCommands check. Any Admin-privileged caller on a gen-3 or AllowI2C-enabled system can push arbitrary bytes to the PCH Node Manag |
| `0x41` | `0x2e/0x41/0x41` | Admin | Same as 0x40: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control. |
| `0x42` | `0x2e/0x42/0x42` | Admin | Same as 0x40: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control. |
| `0x43` | `0x2e/0x43/0x43` | Admin | Same as 0x40: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control. |
| `0x44` | `0x2e/0x44/0x44` | Admin | Gate-only; no config writes, no data returned. CC 0x00 is returned even if the underlying NM relay does not execute (stub behavior in virtual build). An Admin can determine whether NM commands are ena |
| `0x45` | `0x2e/0x45/0x45` | Admin | Gate-only; no writes, no data leak. Identical gate to 0x44. The stub CC 0x00 response can mislead NM management tools into believing suspension periods were set when no NM hardware interaction occurre |
| `0x46` | `0x2e/0x46/0x46` | Admin | Gate-only. Stub CC 0x00 returns no suspension-period data; a caller expecting NM response payload will receive an empty response body, which may cause management software to misparse or crash if it as |
| `0x4b` | `0x2e/0x4b/0x4b` | Admin | Gate-only. No turbo-ratio data is exposed. Identical gate surface to other NM pass-through stubs. |
| `0x60` | `0x2e/0x60/0x60` | Admin | Gate-only. Stub CC 0x00 with empty body could cause CUPS-capable management stacks (e.g. Intel Data Center Manager) to misinterpret NM CUPS availability. |
| `0x61` | `0x2e/0x61/0x61` | Admin | Gate-only. Identical stub behavior to 0x60. |
| `0x64` | `0x2e/0x64/0x64` | Admin | Gate-only. An Admin calling this to enable/disable CUPS will receive CC 0x00 with no effect — the silent no-op could mask a failure to disable CUPS telemetry in a security hardening context. |
| `0x65` | `0x2e/0x65/0x65` | Admin | Gate-only. No CUPS configuration data is returned; stub CC 0x00 with empty payload is indistinguishable from a legitimate 'no CUPS data' response without further NM-layer context. |
| `0x66` | `0x2e/0x66/0x66` | Admin | Gate-only; no config writes, no data returned from iDRAC side. The AllowIpmiI2cCommands attribute is the sole enforcement point. Any Admin-privileged caller on a gen-3 system or one with AllowIpmiI2cC |
| `0x67` | `0x2e/0x67/0x67` | Admin | Gate-only. Identical to 0x66. Stub CC 0x00 with empty body is returned on success; management stacks expecting CUPS data payload on success will receive nothing, potentially causing incorrect capacity |
| `0x68` | `0x2e/0x68/0x68` | Admin | Gate-only. No CUPS configuration changes are performed by iDRAC itself; stub CC 0x00 may mislead a caller into believing CUPS was reconfigured when no PCH interaction occurred. Same gate surface as 0x |
| `0x69` | `0x2e/0x69/0x69` | Admin | Gate-only. An Admin can send this to reset CUPS statistics with no additional authorization beyond the AllowIpmiI2cCommands gate, potentially erasing historical utilization data used for capacity plan |
| `0x80` | `0x2e/0x80/0x80` | Admin | Physical manufacturing mode jumper is the primary additional gate beyond Admin privilege and AllowIpmiI2cCommands. When the jumper is installed (factory floor or lab setting), any Admin IPMI session c |
| `0x81` | `0x2e/0x81/0x81` | Admin | Same as 0x80: physical manufacturing jumper gate. CC 0xD6 distinguishes missing jumper from other errors and leaks hardware configuration state. When jumper is present, NM manufacturing payload reache |
| `0x82` | `0x2e/0x82/0x82` | Admin | Same as 0x80 and 0x81. The three commands 0x80-0x82 share the same manufacturing gate and together expose a cluster of NM manufacturing-test operations. If a production unit erroneously has the manufa |
| `0xa8` | `0x2e/0xa8/0xa8` | Admin | High-value target: cmd 0xa8 maps to SMBus Master Write-Read, which gives an Admin IPMI caller arbitrary I2C/SMBus read/write access to any device reachable by the PCH ME (power controllers, voltage re |
| `0xb7` | `0x2e/0xb7/0xb7` | Admin | No license gate. Any Admin caller that clears the global AllowIpmiI2c gate can push arbitrary bytes to the PCH Node Manager. Potentially covers NM extension commands whose PCH-side behavior is unknown |
| `0xba` | `0x2e/0xba/0xba` | Admin | Same as 0xb7: no license gate, arbitrary NM payload reaches PCH. Admin-only privilege is the sole iDRAC-side control. |
| `0xc0` | `0x2e/0xc0/0xc0` | Admin | In manufacturing mode can disable power capping (set PowerCapSetting=0) and clear ActivePolicyName. An Admin on a manufacturing-jumpered unit can remove all power throttling. The serial/monolithic res |
| `0xc6` | `0x2e/0xc6/0xc6` | Admin | Read-only. Exposes scheduled NM policy suspension windows to any Admin IPMI caller over LAN. |
| `0xcb` | `0x2e/0xcb/0xcb` | Admin | License probe only; no writes, no data exposed. Can fingerprint NM license presence. |
| `0xd0` | `0x2e/0xd0/0xd0` | Admin | Effectively unreachable in production (manufacturing jumper absent). If an attacker could assert manufacturing mode (e.g. via CPLD compromise), this would expose an undocumented NM command channel. Th |
| `0xd2` | `0x2e/0xd2/0xd2` | Admin | Double-gated: AllowIpmiI2cCommands AND manufacturing jumper. The manufacturing-mode requirement means this command is production-inaccessible on a fielded server regardless of Admin privilege or Allow |
| `0xd3` | `0x2e/0xd3/0xd3` | Admin | Single gate: AllowIpmiI2cCommands only (no manufacturing-mode or license requirement). Any Admin with AllowIpmiI2cCommands=1 can relay this to the PCH NM to read per-core turbo ratio configuration. St |
| `0xf1` | `0x2e/0xf1` | Admin | No active functionality. The cmd byte is allocated in the dispatch table, accepted by the gate, and returns success — a silent no-op. Not an exploitable surface based on static analysis, but leaves a |
| `0xf5` | `0x2e/0xf5` | Admin | No active functionality. Same dead slot characteristics as 0xf1. |
| `ack` | `0x30/0xa2/0x13` | Admin | ACK mechanism. Admin+inBand. |
| `bladeacpowercycle` | `0x30/0x9e` | Admin | Triggers hardware AC power cycle via IMC status bit; in-band-only gate (IsInBandCommand) prevents remote IPMI abuse. On NGM platforms the legacy path is disabled and returns error codes. No additional |
| `bladechassisinfo` | `0x30/0xcb` | Admin | Type 9 (CMC network deploy) write performs an unchecked memcpy(0x137ca0+offset, req+14, count) before Dell_shm_memwrite — no offset+count bounds guard, unlike types 0/7/8/10/11 which all range-check. |
| `bladevirtualmac` | `0x30/0xc9` | Admin | Set path creates /tmp sentinel files and updates a persistent cfg attribute. No CMC-channel or in-band restriction: any Admin IPMI caller can overwrite the blade NIC flex MAC address. |
| `bpackdriveremoval` | `0x30/0xde` | Admin | Admin-only, but the security-relevant impact is fault suppression: a caller with Admin IPMI access can hide drive-removal health events from the LCD panel and health manager without physically reinsta |
| `checkmaseripmicmdstatus` | `0x30/0xa2/0x0a` | Admin | Read-only status polling. Exposes internal command completion state. Admin+inBand only. |
| `clearbiosrtdflag` | `0x30/0xa9/0x18` | Admin | Writes to cfgdb RTD flag. Not inBand-gated — reachable via LAN at Admin priv. |
| `cmcinfo` | `0x2e/0xf2` | Admin | Admin-only. SET writes an IPv6 address string to cfgdb ChassisInfo.IPV6Address when the modular chassis flag is set, without visible input validation in this handler. The full attack surface depends o |
| `cmplntupdquerystatus` | `0x30/0xa9/0x1d` | Admin | Read-only status. Not inBand-gated. |
| `cmplntupdupdate` | `0x30/0xa9/0x1c` | Admin | Firmware update write. Not inBand-gated — reachable via LAN at Admin priv. HIGH risk if DUP validation is bypassed. |
| `cmplntupdvalidate` | `0x30/0xa9/0x1a` | Admin | Firmware validation step. Not inBand-gated — LAN-reachable at Admin priv. |
| `cmplntupdvalidatestatus` | `0x30/0xa9/0x1b` | Admin | Read-only status. Not inBand-gated. |
| `cpldaccessstatus` | `0x30/0xbc` | Admin | Admin-only. Op=2 allows reading up to 199 bytes of raw CPLD register space from an arbitrary int32 start address; actual address space limits depend on DellAbsReadCPLDMem implementation which is not d |
| `createfactoryhwinventory` | `0x30/0xa5/0x00` | User (0x02) | Manufacturing-mode gate (IsInManufacturingTestMode) required. No user-supplied data written to disk. |
| `dcsscbmcwrapper` | `0x30/0x1a` | Admin | Admin-privilege required. Blind proxy: all request bytes from an Admin IPMI session are forwarded verbatim to the SCBMC D-Bus service without any validation in this layer. Security enforcement and inp |
| `enablemsgchannelrecv` | `0x06/0x32` | User | Hard in-band gate: IsMsgFromSystemInterface checked first; returns CC=0xc1 if called from any non-system-interface channel. Channel 7 (CMC) explicitly rejected (CC=0xcc). |
| `getactivelom` | `0x30/0xc1` | User | Read-only. Exposes NIC topology, link status, and negotiated speed/duplex to any authenticated user. Could aid network reconnaissance. No write path. |
| `getbiosrtdflag` | `0x30/0xa9/0x17` | Admin | Read-only cfgdb flag. Not gated by inBand check — reachable via LAN at Admin priv. Low risk. |
| `getchannelinfo` | `0x06/0x42` | User | Platform capability attribute controls response content. No authentication beyond channel priv. No IsMsgFromSystemInterface gate. |
| `getchassiscapabilities` | `0x00/0x00` | User (2) | — |
| `getchassisstatus` | `0x00/0x01` | User (2) | — |
| `getcommandsupport` | `0x06/0x0a` | User (2) | — |
| `getfactorystatus` | `0x30/0xa5/0x02` | User (0x02) | Index is bounds-checked (\>4 returns CC 0xcc). Read-only; no write side-effects. |
| `getfancontrolparameters` | `0x30/0x31` | Admin (0x04) | Gated on manufacturing test mode or XRev hardware; not reachable in normal production firmware. Exposes thermal/fan diagnostic data. |
| `getinternalvariable` | `0x30/0x27` | Admin | Admin-required. Exposes arbitrary BMC-internal variables via the fplcd D-Bus interface. If the fplcd service exposes sensitive state (e.g., hardware revision tokens, debug flags, or manufacturing vari |
| `getmaserinfo` | `0x30/0xab` | User | Discloses storage device presence, capacity, and VFlash status at User privilege over LAN. SD write-protection state and VFlash-in-use exposed. Useful for attacker reconnaissance. |
| `getselentry` | `0x0a/0x43` | User | CMC-channel access has the side effect of clearing IMC status bit 3 (event-pending flag). No additional restriction. |
| `getselftestresults` | `0x06/0x04` | User (2) | — |
| `getsermodemconfigparam` | `0x0c/0x11` | Operator (3) | — |
| `getsolconfiguration` | `0x0c/0x22` | User (2) | — |
| `lclcopymutdata` | `0x30/0xaa/0x17` | User | Data copy operation. User+inBand. Manufacturing-test context. |
| `lclgetuscver` | `0x30/0xaa/0x16` | User | Read-only version info. Useful for fingerprinting LC version. User+inBand. |
| `lclmaserfactoryhwinventoryget` | `0x30/0xaa/0x11` | User | Discloses factory hardware fingerprints. Feature-gated. User+inBand. |
| `lclmasergetlclstatus` | `0x30/0xaa/0x15` | User | Read-only last LCL request status. User+inBand. |
| `lclmaserhistory` | `0x30/0xaa/0x0f` | User | Feature-gated read-only history. User+inBand. |
| `lclmaserhwinventory` | `0x30/0xaa/0x10` | User | Discloses hardware inventory. Feature-gated. User+inBand. |
| `lclmaserlogentry` | `0x30/0xaa/0x03` | User | Log write. User+inBand. Log injection risk if entry content is not sanitized. |
| `lclmaserquerycurrentrecords` | `0x30/0xaa/0x0b` | User | Read-only LC data. User+inBand. |
| `lclmaserquerydependency` | `0x30/0xaa/0x0e` | User | Read-only. User+inBand. |
| `lclmaserqueryeventrecord` | `0x30/0xaa/0x0d` | User | Read-only event query. User+inBand. |
| `lclmaserqueryrecordhistory` | `0x30/0xaa/0x0c` | User | Read-only LC history. User+inBand. |
| `lclmaserupdateinventoryorxml` | `0x30/0xaa/0x01` | User | Write path to inventory records. User+inBand. Inventory injection potential if input is not sanitized. |
| `lockmaserlockack` | `0x30/0xa2/0x12` | Admin | Same as subcmd 0x00. Having two subcmd values map to the same handler may indicate a version-compatibility alias. |
| `manufacturingteston` | `0x06/0x05` | Admin (4) | — |
| `misccmdeventselfiltering` | `0x30/0xd0/0x01` | Admin | Admin-only config write that controls SEL OEM event filtering. An attacker with Admin IPMI can disable OEM event filtering to suppress security-relevant log entries or re-enable to restore them. The 0 |
| `nodeidinfo` | `0x2e/0xf6` | Admin | Read-only (SET blocked at CC 0x82). Discloses the server Node ID string used in Dell blade/modular chassis management topology. The caller-controlled offset and count allow sub-string extraction acros |
| `oemgetlcstatus` | `0x30/0xa9/0x1e` | Admin | Read-only LC status. Not inBand-gated — LAN-reachable at Admin priv. |
| `pciessdfru` | `0x30/0x36` | User | User-privilege read of hardware FRU identity data (manufacturer, part number, serial number). Allocates up to 41KB (0xa0b8) on heap per PCIe card lookup. Offset bounded to \<0x200 and length to \<=36, p |
| `platformcachecleanup` | `0x30/0xa5/0x03` | User (0x02) | Writes fixed string 'features/platform cache cleanup request' to flash. Gated by manufacturing mode. |
| `powerbudget` | `0x2e/0xea` | Admin | Admin-only. SET writes PowerCapValue and ActivePolicyName to cfgdb, directly capping server power via iDRAC. An attacker with Admin IPMI and power-management license can set an arbitrarily low cap, de |
| `pwraverageinterval` | `0x30/0xcc` | Admin | Admin-only pass-through to an IPC service. If the IPC service does not re-validate length/content, crafted data bytes could be forwarded. Low confidence without IPC service source. |
| `pwraveragerange` | `0x30/0xcd` | Admin | Read-only capability enumeration. Admin-only. No config write, no credential exposure. Low risk. |
| `pwrcapenable` | `0x30/0xba` | Admin | Admin-priv with two persistent cfgdb writes on set. Disabling the power cap (op=0, data\[1\]=0x00) removes power consumption limits on the system. Setting ActivePolicyName is a cfgdb string write but us |
| `pwrefficiency` | `0x30/0xc0` | User | Write operation accessible at User privilege (lower than Admin). Overwrites a power efficiency float in shared memory which may influence power management and reporting. Unusual that a config-write is |
| `pwrgetpwrconsumptiondata` | `0x30/0x9c` | User | User-privilege read of power statistics. No write path. The all-entities mode (req\[0\]\>\>4==7) bypasses per-entity validation on both monolithic and modular paths — crafting a message with upper-nibble |
| `pwrheadroom` | `0x30/0xbb` | Admin | Admin-priv, read-only. No write path. Returns 0xFFFF (all-bits-set) when power budgeting is not supported rather than an error code, which is a benign but potentially surprising semantic. No attack su |
| `pwrpsufirmwareupdate` | `0x30/0xb6` | Admin | Admin-priv. Triggers PSU firmware update via IPC; firmware image source is managed by the IPC daemon (not in this handler). Writes to two SHM fields per-PSU. The instance range check (1..6) is correct |
| `pwrpsufirmwareupdatestatus` | `0x30/0xb7` | Admin | Admin-priv. Off-by-one bug: instance=0 is accepted (bVar3 \< 7 check passes), yielding SHM segment 7 read at offset ~208 KB, far outside the expected per-PSU data area. This is an out-of-bounds SHM rea |
| `pwrpsuinfo` | `0x30/0xb0` | Admin | Admin-priv, read-only. Exposes PSU firmware version strings (8 bytes) and component IDs which could assist supply-chain targeting. The non-RSM path reads (instance-1)\*0x330 bytes into SHM segment 7 — |
| `pwrrealtimepwrconsumption` | `0x30/0xb3` | Admin | Admin-priv, read-only. Note: resp_len is set to 7 but only 4 bytes are written — bytes \[4..6\] of resp_data are undetermined content (possible stack leak at the IPMI response layer if the transport cop |
| `pwrresetpwrconsumptiondata` | `0x30/0x9d` | Admin | Admin-priv persistent cfgdb write. reset_type value (1–4) is written verbatim to cfgdb without further filtering. Destruction of power history is the intended effect. No path to execute arbitrary code |
| `querychassisidentifystatus` | `0x30/0x32` | User | User-accessible, read-only. Low security impact: reveals only chassis LED/identify state. D-Bus failures silently return 0, so callers cannot distinguish 'identify off' from 'fplcd daemon dead'—could |
| `querygetcpldrevision` | `0x30/0x33` | User | Read-only version disclosure of CPLD firmware version. No write path. Reachable by any User-privilege IPMI session. Could aid firmware fingerprinting or downgrade attack targeting. |
| `readfrudata` | `0x0a/0x11` | User | CMC-channel path silently returns empty success without touching FRU storage. WCS iDRAC type also takes this shortcut. No IsMsgFromSystemInterface gate. |
| `recreatemaserdeprecated` | `0x30/0xa5/0x01` | User (0x02) | — |
| `rollbackfw` | `0x30/0xbe` | Admin | Admin-only firmware downgrade trigger. Rolling back to a prior firmware version can re-expose patched vulnerabilities present in that version. No request validation in this handler layer — all enforce |
| `setbiosrtdflag` | `0x30/0xa9/0x19` | Admin | Writes to cfgdb RTD requested flag. Not inBand-gated — reachable via LAN at Admin priv. Controlling BIOS RTD request may influence boot behavior. |
| `setchannelsecuritykeys` | `0x06/0x56` | Admin (4) | Write ops (req+9 != 0) are gated by lockdown and local-config-disable. When local config is disabled the block additionally depends on IsInBandCommand(req)!=0; because that function's semantics are no |
| `setchassiscapabilities` | `0x00/0x05` | Admin (4) | — |
| `setfancontrolparameters` | `0x30/0x30` | Admin | Direct hardware fan speed override reachable only with X-Rev hardware or manufacturing test mode. In manufacturing mode, setting fans to minimum speed can cause thermal damage (DoS). Subtype 3 purpose |
| `setseltime` | `0x0a/0x49` | Operator | Clears an IMC status flag on CMC-channel SEL time writes as a side effect. |
| `setsermodemconfigparam` | `0x0c/0x10` | Admin (4) | — |
| `setsolconfiguration` | `0x0c/0x21` | Admin (4) | — |
| `setsystembootoptions` | `0x00/0x08` | Operator (3) | Lockdown bypass: a specific crafted boot-flags packet (param_sel=5, src=0x80/0x10, data=zero) is accepted even under system lockdown, allowing an operator-level caller to clear boot flags while locked |
| `setteamingmode` | `0x30/0x24` | Admin | Always fails; harmless stub. |
| `setuseraccess` | `0x06/0x43` | Admin | CMC path performs a read-modify-write of the user record via DDS before calling the default handler, allowing CMC to modify user access through a different code path than non-CMC callers. DDS failure |
| `setusername` | `0x06/0x45` | Admin | CMC rename operation zeroes the existing user record fields before calling osi_function_setuser — any user whose name is being taken has their record cleared, stripping credentials and privileges. Sid |
| `setuserpassword` | `0x06/0x47` | Admin | CMC-channel requests with a null-containing 20-byte password are silently downgraded to 16-byte mode by truncating the declared length, changing password semantics without caller awareness. This is a |
| `snmpalerttrapdest` | `0x2e/0xf0` | Admin | Admin + license required. SET rewrites SNMP alert destination IPs from IPMI without going through the web UI or REST API, enabling silent alert redirection to an attacker host. The static-global block |
| `sysinfoparam243` | `0x2e/0xf3` | Admin | Admin-only. Arbitrary blob write to a SysInfo slot with no visible content validation beyond the AllowI2C gate. Risk depends on what downstream consumers read parameter 243; they are not identified in |
| `systemrevision` | `0x2e/0xf4` | Admin | Admin-only. SET writes arbitrary bytes into the SYS_REV SHM slot and immediately fires DellSysInfoEndTask, which signals LifecycleController and other subscribers. Injecting malformed data could affec |
| `utilityrequest` | `0x30/0xa2/0x15` | Admin | Admin+inBand. |
| `utilitystatus` | `0x30/0xa2/0x16` | Admin | Admin+inBand. |

## In iDRAC9, not matched in iDRAC10 (86)

| handler | netfn/cmd | priv | security |
|----|----|----|----|
| `0x06` | `0x06/0x59/0x06` | 2 | undetermined; no handler code to assess |
| `0x08` | `0x06/0x59/0x08` | 2 | undetermined; no handler code to assess |
| `0x09` | `0x06/0x59/0x09` | 2 | undetermined; no handler code to assess |
| `0xcc` | `0x06/0x59/0xcc` | 2 | undetermined; no handler code to assess |
| `0xd5` | `0x06/0x59/0xd5` | 2 | undetermined; no handler code to assess |
| `0xd6` | `0x06/0x58/0xd6` | Admin (4) | — |
| `0xda` | `0x06/0x58/0xda` | Admin (4) | — |
| `0xdd` | `0x06/0x59/0xdd` | 2 | undetermined; no handler code to assess |
| `0xde` | `0x06/0x59/0xde` | 2 | undetermined; no handler code to assess |
| `0xe0` | `0x06/0x58/0xe0` | Admin (4) | CMC channel gate only; NOT an in-band gate. |
| `0xe1` | `0x06/0x58/0xe1` | Admin (4) | — |
| `0xe2` | `0x06/0x58/0xe2` | Admin (4) | Admin caller can write arbitrary blocks (\<=0x400 each, up to index 0x17) into the VIS inventory buffer; checksum is integrity, not auth. |
| `0xe4` | `0x06/0x58/0xe4` | Admin (4) | — |
| `0xe5` | `0x06/0x58/0xe5` | Admin (4) | CMC channel gate only (NOT in-band gate). |
| `0xe6` | `0x06/0x59/0xe6` | 2 | undetermined; no handler code to assess |
| `0xe7` | `0x06/0x58/0xe7` | Admin (4) | — |
| `0xe8` | `0x06/0x58/0xe8` | Admin (4) | — |
| `0xea` | `0x06/0x58/0xea` | Admin (4) | — |
| `0xeb` | `0x06/0x59/0xeb` | 2 | undetermined; no handler code to assess |
| `0xec` | `0x06/0x59/0xec` | 2 | undetermined; no handler code to assess |
| `0xed` | `0x06/0x59/0xed` | 2 | undetermined; no handler code to assess |
| `0xf0` | `0x06/0x58/0xf0` | Admin (4) | License gate (d_licenseCheck) enforced before PCIe slot commit; bypass of license check would allow writing arbitrary slot config. |
| `0xf2` | `0x06/0x58/0xf2` | Admin (4) | — |
| `0xf3` | `0x06/0x58/0xf3` | Admin (4) | — |
| `0xf4` | `0x06/0x58/0xf4` | Admin (4) | — |
| `0xf6` | `0x06/0x59/0xf6` | 2 | undetermined; no handler code to assess |
| `0xf7` | `0x06/0x58/0xf7` | Admin (4) | — |
| `0xf8` | `0x06/0x59/0xf8` | 2 | undetermined; no handler code to assess |
| `0xf9` | `0x06/0x59/0xf9` | 2 | undetermined; no handler code to assess |
| `0xfa` | `0x06/0x58/0xfa` | Admin (4) | No channel or in-band gate. Admin IPMI over LAN can overwrite PCIe slot assignment array. Accepted under lockdown via the lockdown escape path. |
| `0xfb` | `0x06/0x59/0xfb` | 2 | undetermined; no handler code to assess |
| `0xfe` | `0x06/0x58/0xfe` | Admin (4) | — |
| `acknowledge` | `0x30/0xa2/0x13` | 4 | In-band only (IsMsgFromSystemInterface gate). Admin privilege required. MASER must be initialized and enabled; if not, MASERWatchdogTOFunc() is called to clear partition state and CC 0x05 is returned. |
| `broadcastacpowercycle` | `0x30/0x9e/0x00` | Admin (0x04) | In-band (KCS) only. Admin-gated. Triggers chassis-level AC power cycle affecting all blades — high-impact availability primitive accessible from the host OS with Admin IPMI access. |
| `checkipmicmdstatus` | `0x30/0xa2/0x0a` | 4 | In-band only (IsMsgFromSystemInterface gate). Admin privilege required. MASER must be initialized and enabled; if not, MASERWatchdogTOFunc() is called to clear partition state and CC 0x05 is returned. |
| `clearpmconfigflag` | `0x30/0xa9/0x18` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `compliantupdquerystatus` | `0x30/0xa9/0x1d` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `compliantupdupdate` | `0x30/0xa9/0x1c` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `compliantupdvalidate` | `0x30/0xa9/0x1a` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `compliantupdvalidatestatus` | `0x30/0xa9/0x1b` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `copymutdata` | `0x30/0xaa/0x17` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `default` | `0x06/0x58/0x80` | Admin (4) | — |
| `disable` | `0x30/0xe3/0x02` | Admin (4) | — |
| `enable` | `0x30/0xe3/0x00` | Admin (4) | — |
| `factoryhwinventoryget` | `0x30/0xaa/0x11` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `factoryreset` | `0x30/0xa5/0x00` | 2 | In-band only (IsMsgFromSystemInterface); also requires IsInManufacturingTestMode(2)=1, otherwise CC 0x09. MASER must be initialized and enabled, otherwise CC 0x05. User priv combined with manufacturin |
| `getlclstatus` | `0x30/0xaa/0x15` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `getlcstatus` | `0x30/0xa9/0x1e` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `getpmconfigflag` | `0x30/0xa9/0x17` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `getreading` | `0x30/0xe2` | Admin (4) | Admin-only read of NM power metrics. No write path. No notable exposure beyond information disclosure of server power readings. |
| `getuscver` | `0x30/0xaa/0x16` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `getvirtualmac` | `0x30/0xc9/0x01` | Admin (0x04) | Read-only. Returns the chassis-assigned virtual MACs. Admin-gated. |
| `history` | `0x30/0xaa/0x0f` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `hwinventory` | `0x30/0xaa/0x10` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `lockmaser0` | `0x30/0xa2/0x00` | 4 | In-band only (IsMsgFromSystemInterface gate). Admin privilege required. MASER must be initialized and enabled; if not, MASERWatchdogTOFunc() is called to clear partition state and CC 0x05 is returned. |
| `logentry` | `0x30/0xaa/0x03` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `primarydevice` | `0x30/0xab/0x00` | 2 | — |
| `querycurrentrecords` | `0x30/0xaa/0x0b` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `querydependency` | `0x30/0xaa/0x0e` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `queryeventrecord` | `0x30/0xaa/0x0d` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `querymfgmodeentry` | `0x30/0xa5/0x02` | 2 | In-band only (IsMsgFromSystemInterface); also requires IsInManufacturingTestMode(2)=1, otherwise CC 0x09. MASER must be initialized and enabled, otherwise CC 0x05. User priv combined with manufacturin |
| `queryrecordhistory` | `0x30/0xaa/0x0c` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `readchassis` | `0x30/0xcb/0x01` | Admin (0x04) | Admin-gated. Exposes chassis metadata (hostname, power budget, redundancy state) to any Admin-level IPMI caller on any channel. CMC channel (req\[0\]\>\>4==7) gets a different SHM view for region 9. |
| `recreatemaser` | `0x30/0xac` | User (0x02) | Manufacturing-mode gate (IsInManufacturingTestMode(3)) returns result 9 outside factory. Caller-supplied 16-bit partition_size at req+8 is formatted via snprintf into a shell command string passed to |
| `reserved` | `0x30/0xa5/0x01` | 2 | In-band only (IsMsgFromSystemInterface); also requires IsInManufacturingTestMode(2)=1, otherwise CC 0x09. MASER must be initialized and enabled, otherwise CC 0x05. User priv combined with manufacturin |
| `ripscontrol` | `0x30/0xc2` | User (2) | — |
| `sdcarddevice` | `0x30/0xab/0x01` | 2 | — |
| `selfiltering` | `0x30/0xd0/0x01` | 4 | Admin privilege. Primary dispatch on req\[9\] (data\[1\]); req\[8\] (data\[0\]) is a secondary parameter. No IsMsgFromSystemInterface gate visible in the decompile. SubCmdHandler (dispatched for data\[1\]\>=2) c |
| `setpmtype` | `0x30/0xa9/0x19` | 4 | Admin privilege. Subcmds 0x10–0x15 require in-band (IsMsgFromSystemInterface) OR CMC channel (req\[0\]\>\>4==7); the CMC check is NOT in-band — partner-module operations are reachable over the chassis man |
| `setvirtualmac` | `0x30/0xc9/0x00` | Admin (0x04) | Admin-gated. Allows any Admin-level IPMI caller on any channel to override the blade's flex MAC address, which can redirect network traffic on a modular chassis fabric. |
| `singlenodeacpowercycle` | `0x30/0x9e/0x01` | Admin (0x04) | In-band (KCS) only. Admin-gated. Allows an OS-resident attacker with Admin IPMI to power-cycle this blade node. |
| `specialwrite` | `0x30/0xcb/0x02` | Admin (0x04) | Admin-gated. Writes directly to SHM region 0x22 regardless of channel (the bVar12==2 path does not check req\[0\]\>\>4 and has no IMC-status side-effect). Could be used by an Admin attacker to overwrite S |
| `tsbeginmarker` | `0x30/0xa7/0x05` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tscollectdata` | `0x30/0xa7/0x03` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tsendmarker` | `0x30/0xa7/0x06` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tsexposeexecs` | `0x30/0xa7/0x00` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tsgetdatainfo` | `0x30/0xa7/0x04` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tsgetstatus` | `0x30/0xa7/0x02` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tshideexecs` | `0x30/0xa7/0x01` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tssystemerase` | `0x30/0xa7/0x08` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `tsupdatemarker` | `0x30/0xa7/0x07` | User (0x02) | In-band only (IsMsgFromSystemInterface gate in dispatcher). Leaf body is a PLT stub in this corpus; actual implementation in liboemcmds. |
| `updaterecords` | `0x30/0xaa/0x01` | 2 | In-band only (IsMsgFromSystemInterface gate); MASER must be initialized (IsMASERInit) and not disabled (IsMASERDisabled), else CC 0x05. Subcmds 0x0f, 0x10, 0x11 additionally require LC feature license |
| `utility0x15` | `0x30/0xa2/0x15` | 4 | In-band only (IsMsgFromSystemInterface gate). Admin privilege required. MASER must be initialized and enabled; if not, MASERWatchdogTOFunc() is called to clear partition state and CC 0x05 is returned. |
| `utility0x16` | `0x30/0xa2/0x16` | 4 | In-band only (IsMsgFromSystemInterface gate). Admin privilege required. MASER must be initialized and enabled; if not, MASERWatchdogTOFunc() is called to clear partition state and CC 0x05 is returned. |
| `writechassis` | `0x30/0xcb/0x00` | Admin (0x04) | Admin-gated. CMC typically calls this to push chassis metadata into the blade. An Admin-level out-of-band attacker can overwrite chassis hostname, power budget, and redundancy state in shared memory a |
| `writemfgconfigfile` | `0x30/0xa5/0x03` | 2 | In-band only (IsMsgFromSystemInterface); also requires IsInManufacturingTestMode(2)=1, otherwise CC 0x09. MASER must be initialized and enabled, otherwise CC 0x05. User priv combined with manufacturin |

------------------------------------------------------------------------

Sources: idrac9-commands.json, idrac10-commands.json. Match key = normalized leaf capability. 136 shared handlers carry security notes (see per-gen references).
