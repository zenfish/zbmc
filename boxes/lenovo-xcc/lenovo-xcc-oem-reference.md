<!-- html2md:auto source=boxes/lenovo-xcc/lenovo-xcc-oem-reference.html source-sha256=423545a5650e70a224a726f442888eed1779da39918ba873d0c45ba90068bfe4 body-sha256=8cbf3ce7d8f9d003df19701b4a7b4ea7334878517e45b9e8f35831e6e1355151 -->

# Lenovo XCC 6.92 OEM IPMI reference

Firmware-bound to **Newyork-pass1**. Full rootfs SquashFS SHA-256 `2aaedcb6c5939efabd49ac4da0a8066e17c5c3dea356ad33ad0d9246c4b192c2`; `libipmi.so` SHA-256 `b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485`.

**225** top-level identities

**210** top-level pairs

**107** exact operation contracts

**66** request codecs

**60** response codecs

**55/52** safe/unsafe contracts

## Closed denominator

Three active top-level surfaces are reconciled: 192 C++ registration occurrences (166 identities), 175 legacy admission rows, and the 134-row core request table. Their OEM union is 225 exact identities / 210 pairs. The core table adds `30/e2`, `30/e3`, and `3a/c7`. Dormant registrar libraries shipped in the SquashFS are excluded only because `pl_newyork` does not load them. Standard LAN commands `0c/01` and `0c/02` expand into selector operations below rather than new top-level OEM pairs.

## Bounded unknowns

58 operation records intentionally retain raw, partial, conflicting, or unresolved fields. Notable boundaries are inactive Avocent routes `3a/49`, `3a/4a`, and `3a/4d`; hostname public-doc/binary termination disagreement; PSoC FRU-ID and MTU endian; D4 priority-zero meaning; D6 mode enumeration; and delegated selector leaves not yet promoted to fixed codecs. Every non-safe or schema-unbounded named request requires `--unsafe`.

## Safe live proof

zBMC run `20260926T180101Z-a368af09-d224-4a10-b6f6-74c5e3d2490d` reached READY after a required 83-second stable interval. zipmi 0.5.0 then executed all 32 mechanically synthesizable fixed-request read-only contracts. Twenty-nine returned `CC00`; Board Hardware Revision returned `CCCE`, Front USB Enable Get returned `CCD5`, and inactive firmware-only LAN selector D2 returned `CCCC`. The retained [evidence artifact](evidence/20260926T180101Z-safe-live.json) records every exact request and response; no unsafe operation was sent.

## Exact operation contracts

Filter contracts

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
<thead class="bg-slate-200 text-xs">
<tr>
<th class="p-2">#</th>
<th class="p-2">Wire</th>
<th class="p-2">Operation</th>
<th class="p-2">Request</th>
<th class="p-2">Response</th>
<th class="p-2">Safety / activation</th>
<th class="p-2">zipmi / evidence</th>
</tr>
</thead>
<tbody id="contract-rows">
<tr class="border-b align-top" data-contract="reset xcc to default reset xcc configuration to defaults unsafe legacy oem admission route">
<td class="p-2 text-xs">1</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0a 01 ff 00 00 00 @ 0</td>
<td class="p-2 min-w-72"><strong>Reset XCC to Default</strong>
<p>Reset XCC configuration to defaults</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>9 bytes:</strong> exact magic request 5e 2b 00 0a 01 ff 00 00 00
Fields
<ul>
<li><code>iana_0</code>: u8 = 0x5e</li>
<li><code>iana_1</code>: u8 = 0x2b</li>
<li><code>iana_2</code>: u8 = 0x00</li>
<li><code>magic_0</code>: u8 = 0x0a</li>
<li><code>magic_1</code>: u8 = 0x01</li>
<li><code>magic_2</code>: u8 = 0xff</li>
<li><code>magic_3</code>: u8 = 0x00</li>
<li><code>magic_4</code>: u8 = 0x00</li>
<li><code>magic_5</code>: u8 = 0x00</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes after CC:</strong> echoes 5e 2b 00 0a 01 followed by status (0 success)
Fields
<ul>
<li><code>iana_0</code>: u8 = 0x5e</li>
<li><code>iana_1</code>: u8 = 0x2b</li>
<li><code>iana_2</code>: u8 = 0x00</li>
<li><code>magic_0</code>: u8 = 0x0a</li>
<li><code>magic_1</code>: u8 = 0x01</li>
<li><code>status</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> documented for IPMI<br />
<strong>Activation:</strong> legacy OEM admission route<br />
<strong>Side effects:</strong> destructive persistent configuration reset
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo XCC public contract; exact 6.92 admission identity<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="firmware version read firmware major and minor version safe registered by libcore">
<td class="p-2 text-xs">2</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x00<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Firmware Version</strong>
<p>Read firmware major and minor version</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> major, minor
Fields
<ul>
<li><code>major</code>: u8</li>
<li><code>minor</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libcore<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract, 6.92 handler decompilation and live response 06 92<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="firmware version with revision read firmware major, minor and revision safe registered by libcore">
<td class="p-2 text-xs">3</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x00<br />
selector 00 @ 0</td>
<td class="p-2 min-w-72"><strong>Firmware Version with Revision</strong>
<p>Read firmware major, minor and revision</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> selector 00
Fields
<ul>
<li><code>selector</code>: u8 = 0x00</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes after CC:</strong> major, minor, revision
Fields
<ul>
<li><code>major</code>: u8</li>
<li><code>minor</code>: u8</li>
<li><code>revision</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libcore<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 201,
    &quot;meaning&quot;: &quot;invalid selector&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> public optional-byte contract plus 6.92 selector validation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="board information read system id and planar revision safe registered by libmodules">
<td class="p-2 text-xs">4</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x0d<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Board Information</strong>
<p>Read system ID and planar revision</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> system ID, board revision
Fields
<ul>
<li><code>system_id</code>: u8</li>
<li><code>board_revision</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmodules<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract and 6.92 handler decompilation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="power restore delay get read ac-restore delay option safe rack-server platforms">
<td class="p-2 text-xs">5</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1e<br />
selector 01 @ 0</td>
<td class="p-2 min-w-72"><strong>Power Restore Delay Get</strong>
<p>Read AC-restore delay option</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> selector 01
Fields
<ul>
<li><code>selector</code>: u8 = 0x01</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes after CC:</strong> option: 00 disabled, 01 random
Fields
<ul>
<li><code>option</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> rack-server platforms<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;unsupported platform&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract and 6.92 handler decompilation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="power restore delay set set ac-restore delay option unsafe rack-server platforms">
<td class="p-2 text-xs">6</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1e<br />
selector 00 @ 0</td>
<td class="p-2 min-w-72"><strong>Power Restore Delay Set</strong>
<p>Set AC-restore delay option</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> selector 00, option 00 disabled or 01 random
Fields
<ul>
<li><code>selector</code>: u8 = 0x00</li>
<li><code>option</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> rack-server platforms<br />
<strong>Side effects:</strong> persistent restore-policy change and EPO update
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;unsupported platform&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;reserved option&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract and 6.92 handler decompilation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="nmi and reset assert nmi and optionally reset the host after a delay unsafe registered by libmod_reset">
<td class="p-2 text-xs">7</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x38<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>NMI and Reset</strong>
<p>Assert NMI and optionally reset the host after a delay</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>1..2 bytes:</strong> delay seconds; optional reset type 00 soft or 01 power-cycle
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmod_reset<br />
<strong>Side effects:</strong> host NMI, reset or power cycle
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract corrects prior byte-1 interpretation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="initiate data collection start service-data collection unsafe admitted but inactive on xcc 6.92 newyork; dispatch returns c1">
<td class="p-2 text-xs">8</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x49<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Initiate Data Collection</strong>
<p>Start service-data collection</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes:</strong> XCC payload unresolved; XCC3 uses type and optional flags
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> XCC payload unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> documented for IPMI<br />
<strong>Activation:</strong> admitted but inactive on XCC 6.92 Newyork; dispatch returns c1<br />
<strong>Side effects:</strong> starts resource-heavy diagnostic collection
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (unresolved)<br />
<strong>Evidence:</strong> identity and privilege public; payload only documented for XCC3<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="push file push a service-data file unsafe admitted but inactive on xcc 6.92 newyork; dispatch returns c1">
<td class="p-2 text-xs">9</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4a<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Push File</strong>
<p>Push a service-data file</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes:</strong> payload unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> payload unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> documented for IPMI<br />
<strong>Activation:</strong> admitted but inactive on XCC 6.92 Newyork; dispatch returns c1<br />
<strong>Side effects:</strong> writes a file through the service-data path
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (unresolved)<br />
<strong>Evidence:</strong> Lenovo publishes identity and privilege but no payload contract<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="data collection status read service-data collection status unsafe admitted but inactive on xcc 6.92 newyork; dispatch returns c1">
<td class="p-2 text-xs">10</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4d<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Data Collection Status</strong>
<p>Read service-data collection status</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes:</strong> XCC payload unresolved; XCC3 uses collection type
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> XCC payload unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> documented for IPMI<br />
<strong>Activation:</strong> admitted but inactive on XCC 6.92 Newyork; dispatch returns c1<br />
<strong>Side effects:</strong> schema unresolved; execution remains fail-closed
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (unresolved)<br />
<strong>Evidence:</strong> identity and privilege public; payload only documented for XCC3<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="build information read firmware build name, date and time safe registered by libmodules">
<td class="p-2 text-xs">11</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x50<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Build Information</strong>
<p>Read firmware build name, date and time</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>30 bytes after CC:</strong> 9-byte ASCIIZ build name, 13-byte ASCIIZ date, 8-byte ASCII time
Fields
<ul>
<li><code>build_name</code>: bytes[9]</li>
<li><code>build_date</code>: bytes[13]</li>
<li><code>build_time</code>: bytes[8]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmodules<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 206,
    &quot;meaning&quot;: &quot;response buffer too small&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract resolves 6.92 handler framing<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="host name get or set read or persist the xcc host name unsafe registered by libcore">
<td class="p-2 text-xs">12</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x55<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Host Name Get or Set</strong>
<p>Read or persist the XCC host name</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>0..64 bytes:</strong> empty gets; 1..64-byte NUL-terminated ASCIIZ sets
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0..64 bytes after CC:</strong> public docs allocate 64-byte ASCIIZ; 6.92 handler appears variable and disagrees on termination
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libcore<br />
<strong>Side effects:</strong> empty request reads; nonempty request changes persistent network identity
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (conflicting-evidence)<br />
<strong>Evidence:</strong> public-doc versus exact-6.92 binary conflict retained explicitly<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="fpga firmware revision read fpga firmware revision safe registered by libmod_fpga">
<td class="p-2 text-xs">13</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6b<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>FPGA Firmware Revision</strong>
<p>Read FPGA firmware revision</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0..1 bytes:</strong> empty defaults local active; optional target 00..06; 07 is a 6.92 extension
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes after CC:</strong> major, minor, sub-minor/test
Fields
<ul>
<li><code>major</code>: u8</li>
<li><code>minor</code>: u8</li>
<li><code>subminor</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmod_fpga<br />
<strong>Side effects:</strong> externally read-only; targets 05/06 use temporary internal register writes
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (partial)<br />
<strong>Evidence:</strong> Lenovo public target set plus exact-6.92 extension<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="board hardware revision read fpga board hardware revision safe registered by libmod_fpga">
<td class="p-2 text-xs">14</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6c<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Board Hardware Revision</strong>
<p>Read FPGA board hardware revision</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes after CC:</strong> revision byte
Fields
<ul>
<li><code>revision</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmod_fpga<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract and 6.92 handler decompilation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="psoc firmware inventory read revisions of detected psoc devices safe registered by libmod_psoc">
<td class="p-2 text-xs">15</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6d<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>PSoC Firmware Inventory</strong>
<p>Read revisions of detected PSoC devices</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0..? bytes after CC:</strong> zero or more 5-byte records: bin, APID, revision, FRU ID; FRU-ID endian unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmod_psoc<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> public field list has byte-overlap typo and omits FRU-ID endian<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="front usb owner get read front-panel usb owner safe platform-dependent front usb">
<td class="p-2 text-xs">16</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
selector 01 @ 0</td>
<td class="p-2 min-w-72"><strong>Front USB Owner Get</strong>
<p>Read front-panel USB owner</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> selector 01
Fields
<ul>
<li><code>selector</code>: u8 = 0x01</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes after CC:</strong> owner: 00 host, 01 BMC
Fields
<ul>
<li><code>owner</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> platform-dependent front USB<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public selector contract<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="front usb configuration get read front-panel usb configuration safe platform-dependent front usb">
<td class="p-2 text-xs">17</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
selector 02 @ 0</td>
<td class="p-2 min-w-72"><strong>Front USB Configuration Get</strong>
<p>Read front-panel USB configuration</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> selector 02
Fields
<ul>
<li><code>selector</code>: u8 = 0x02</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>4..5 bytes after CC:</strong> mode, timeout minutes (big-endian), ID-button enable, optional hysteresis seconds
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> platform-dependent front USB<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public selector contract<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="front usb configuration set set front-panel usb mode and timeout unsafe platform-dependent front usb">
<td class="p-2 text-xs">18</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
selector 03 @ 0</td>
<td class="p-2 min-w-72"><strong>Front USB Configuration Set</strong>
<p>Set front-panel USB mode and timeout</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>5..6 bytes:</strong> selector 03, mode, timeout BE, ID-button, optional hysteresis
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> platform-dependent front USB<br />
<strong>Side effects:</strong> persistent USB configuration change
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 214,
    &quot;meaning&quot;: &quot;unsupported on SD530&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public selector contract<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="front usb owner set switch front-panel usb owner unsafe platform-dependent front usb">
<td class="p-2 text-xs">19</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
selector 04 @ 0</td>
<td class="p-2 min-w-72"><strong>Front USB Owner Set</strong>
<p>Switch front-panel USB owner</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> selector 04, owner 00 host or 01 BMC
Fields
<ul>
<li><code>selector</code>: u8 = 0x04</li>
<li><code>owner</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> platform-dependent front USB<br />
<strong>Side effects:</strong> changes USB routing
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 214,
    &quot;meaning&quot;: &quot;unsupported on SD530&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC sequence and XCC3 explicit selector label<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="front usb enable set enable or disable front-panel usb unsafe platform-dependent front usb">
<td class="p-2 text-xs">20</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
selector 05 @ 0</td>
<td class="p-2 min-w-72"><strong>Front USB Enable Set</strong>
<p>Enable or disable front-panel USB</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> selector 05, enabled 00/01
Fields
<ul>
<li><code>selector</code>: u8 = 0x05</li>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> platform-dependent front USB<br />
<strong>Side effects:</strong> changes USB availability
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 214,
    &quot;meaning&quot;: &quot;unsupported on non-SD530&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public selector contract<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="front usb enable get read front-panel usb enable state safe platform-dependent front usb">
<td class="p-2 text-xs">21</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
selector 06 @ 0</td>
<td class="p-2 min-w-72"><strong>Front USB Enable Get</strong>
<p>Read front-panel USB enable state</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> selector 06
Fields
<ul>
<li><code>selector</code>: u8 = 0x06</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes after CC:</strong> enabled 00/01
Fields
<ul>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> platform-dependent front USB<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 214,
    &quot;meaning&quot;: &quot;unsupported on non-SD530&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public selector contract<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="native node manager bridge get read native node manager bridge state safe active libipmi core request-table row 0xc9f08; successful nm bridging remains platform/node-manager dependent">
<td class="p-2 text-xs">22</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc7<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Native Node Manager Bridge Get</strong>
<p>Read native Node Manager bridge state</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes after CC:</strong> enabled 00/01
Fields
<ul>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> LAN documented<br />
<strong>Activation:</strong> active libipmi core request-table row 0xc9f08; successful NM bridging remains platform/Node-Manager dependent<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;request longer than one byte&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid set value&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo OEM and Node Manager documentation<br />
<a href="https://pubs.lenovo.com/xcc/oem_ipmi_commands">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="native node manager bridge disable disable native node manager bridging unsafe active libipmi core request-table row 0xc9f08; successful nm bridging remains platform/node-manager dependent">
<td class="p-2 text-xs">23</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc7<br />
selector 00 @ 0</td>
<td class="p-2 min-w-72"><strong>Native Node Manager Bridge Disable</strong>
<p>Disable native Node Manager bridging</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> 00
Fields
<ul>
<li><code>enabled</code>: u8 = 0x00</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> LAN documented<br />
<strong>Activation:</strong> active libipmi core request-table row 0xc9f08; successful NM bridging remains platform/Node-Manager dependent<br />
<strong>Side effects:</strong> changes runtime command-routing exposure
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;request longer than one byte&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid set value&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo OEM and Node Manager documentation<br />
<a href="https://pubs.lenovo.com/xcc/nn1jo_c_node_mgr_cmds">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="native node manager bridge enable enable native node manager bridging unsafe active libipmi core request-table row 0xc9f08; successful nm bridging remains platform/node-manager dependent">
<td class="p-2 text-xs">24</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc7<br />
selector 01 @ 0</td>
<td class="p-2 min-w-72"><strong>Native Node Manager Bridge Enable</strong>
<p>Enable native Node Manager bridging</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> 01
Fields
<ul>
<li><code>enabled</code>: u8 = 0x01</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> LAN documented<br />
<strong>Activation:</strong> active libipmi core request-table row 0xc9f08; successful NM bridging remains platform/Node-Manager dependent<br />
<strong>Side effects:</strong> changes runtime command-routing exposure
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;request longer than one byte&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid set value&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo OEM and Node Manager documentation<br />
<a href="https://pubs.lenovo.com/xcc/nn1jo_c_node_mgr_cmds">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa get firmware info read osa firmware information safe active libipmi outer and inner tables">
<td class="p-2 text-xs">25</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 00 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Get Firmware Info</strong>
<p>Read OSA firmware information</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa get firmware id read osa firmware identifier safe active libipmi outer and inner tables">
<td class="p-2 text-xs">26</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 01 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Get Firmware ID</strong>
<p>Read OSA firmware identifier</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa set system guid set system guid unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">27</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 40 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Set System GUID</strong>
<p>Set system GUID</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>21 bytes:</strong> fixed 5-byte route plus 16-byte GUID
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> persistent system identity change
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa set bmc slave address set bmc slave address unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">28</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 41 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Set BMC Slave Address</strong>
<p>Set BMC slave address</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> changes BMC addressing
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa get bmc slave address read bmc slave address safe active libipmi outer and inner tables">
<td class="p-2 text-xs">29</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 42 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Get BMC Slave Address</strong>
<p>Read BMC slave address</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa graceful reset request graceful reset unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">30</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 43 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Graceful Reset</strong>
<p>Request graceful reset</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> resets managed system or controller path
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa get dcmi mode read dcmi mode safe active libipmi outer and inner tables">
<td class="p-2 text-xs">31</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 44 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Get DCMI Mode</strong>
<p>Read DCMI mode</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa power manager activation status read power-manager activation status safe active libipmi outer and inner tables">
<td class="p-2 text-xs">32</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 45 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Power Manager Activation Status</strong>
<p>Read power-manager activation status</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa power manager activate or deactivate activate or deactivate power manager unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">33</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 46 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Power Manager Activate or Deactivate</strong>
<p>Activate or deactivate power manager</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> changes power-management control
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa power manager power reading read power-manager power data safe active libipmi outer and inner tables">
<td class="p-2 text-xs">34</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 47 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Power Manager Power Reading</strong>
<p>Read power-manager power data</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>9 bytes:</strong> fixed 5-byte route plus 4-byte query
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa power manager power limit get read power-manager power limit safe active libipmi outer and inner tables">
<td class="p-2 text-xs">35</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 48 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Power Manager Power Limit Get</strong>
<p>Read power-manager power limit</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>9 bytes:</strong> fixed 5-byte route plus 4-byte query
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa power manager power limit set set power-manager power limit unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">36</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 49 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Power Manager Power Limit Set</strong>
<p>Set power-manager power limit</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>16 bytes:</strong> fixed 5-byte route plus 11-byte policy
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> changes power cap policy
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa get nmpt mode read nmpt mode safe active libipmi outer and inner tables">
<td class="p-2 text-xs">37</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 06 50 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Get NMPT Mode</strong>
<p>Read NMPT mode</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa sensor test run sensor test operation unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">38</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 04 40 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Sensor Test</strong>
<p>Run sensor test operation</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6..? bytes:</strong> fixed 5-byte route plus at least 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> diagnostic sensor control; schema incomplete
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa get power supply info read power-supply information safe active libipmi outer and inner tables">
<td class="p-2 text-xs">39</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 04 41 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Get Power Supply Info</strong>
<p>Read power-supply information</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa present sensor count read present-sensor count safe active libipmi outer and inner tables">
<td class="p-2 text-xs">40</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 04 54 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Present Sensor Count</strong>
<p>Read present-sensor count</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa present sensor number read a present sensor number safe active libipmi outer and inner tables">
<td class="p-2 text-xs">41</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 04 55 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Present Sensor Number</strong>
<p>Read a present sensor number</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 index byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa reset to default reset configuration to defaults unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">42</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0a 01 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Reset to Default</strong>
<p>Reset configuration to defaults</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>9 bytes:</strong> fixed 5-byte route plus exact 4-byte body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes after CC:</strong> prefix and zero status on success
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> destructive persistent configuration reset
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 192,
    &quot;meaning&quot;: &quot;reset scheduling failure&quot;
  },
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;wrong leaf length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid zero fields&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 CmdResetToDefaultOSA leaf decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa nic teaming mode set set nic teaming mode unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">43</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 01 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA NIC Teaming Mode Set</strong>
<p>Set NIC teaming mode</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> changes network configuration
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa nic teaming mode get read nic teaming mode safe active libipmi outer and inner tables">
<td class="p-2 text-xs">44</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 02 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA NIC Teaming Mode Get</strong>
<p>Read NIC teaming mode</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa ipv6 configuration set set ipv6 configuration parameter unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">45</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 09 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA IPv6 Configuration Set</strong>
<p>Set IPv6 configuration parameter</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>7..? bytes:</strong> fixed 5-byte route plus at least 2 body bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> changes network configuration; schema incomplete
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa ipv6 configuration get read ipv6 configuration parameter safe active libipmi outer and inner tables">
<td class="p-2 text-xs">46</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 0a @ 0</td>
<td class="p-2 min-w-72"><strong>OSA IPv6 Configuration Get</strong>
<p>Read IPv6 configuration parameter</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>9..? bytes:</strong> fixed 5-byte route plus at least 4 body bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only; schema incomplete
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa total shared loms get read total shared lom count safe active libipmi outer and inner tables">
<td class="p-2 text-xs">47</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 06 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Total Shared LOMs Get</strong>
<p>Read total shared LOM count</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa total shared loms set set total shared lom count unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">48</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 07 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Total Shared LOMs Set</strong>
<p>Set total shared LOM count</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> changes network hardware configuration
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa channel number get read mapped channel number safe active libipmi outer and inner tables">
<td class="p-2 text-xs">49</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 0c 08 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Channel Number Get</strong>
<p>Read mapped channel number</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> fixed 5-byte route plus 1 body byte
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa memory check run osa memory check unsafe active libipmi outer and inner tables">
<td class="p-2 text-xs">50</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 10 00 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Memory Check</strong>
<p>Run OSA memory check</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>13 bytes:</strong> fixed 5-byte route plus 8-byte body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> outer route is User despite inner Admin metadata<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> memory diagnostic/control operation
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="osa dynamic allocation size get read dynamically allocated memory size safe active libipmi outer and inner tables">
<td class="p-2 text-xs">51</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
selector 5e 2b 00 10 01 @ 0</td>
<td class="p-2 min-w-72"><strong>OSA Dynamic Allocation Size Get</strong>
<p>Read dynamically allocated memory size</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> fixed 5-byte route; empty body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> unresolved
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any admitted IPMI channel<br />
<strong>Activation:</strong> active libipmi outer and inner tables<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 libipmi G_asOSAOEMHandleTable<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ip address source get read ip address source including lenovo dhcp-with-static-failover mode safe ">
<td class="p-2 text-xs">52</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN IP Address Source Get</strong>
<p>Read IP address source including Lenovo DHCP-with-static-failover mode</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, parameter 04, set selector 00, block selector 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision and source low nibble
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>source</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ip address source set set ip address source unsafe ">
<td class="p-2 text-xs">53</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN IP Address Source Set</strong>
<p>Set IP address source</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, parameter 04, source 00..04
Fields
<ul>
<li><code>source</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes management-network addressing
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ethernet interface get read selected ethernet package and optional ncsi channel safe ">
<td class="p-2 text-xs">54</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Ethernet Interface Get</strong>
<p>Read selected Ethernet package and optional NCSI channel</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C0, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2..3 bytes after CC:</strong> revision, package, optional NCSI channel
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ethernet interface set select ethernet package and optional ncsi channel unsafe ">
<td class="p-2 text-xs">55</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Ethernet Interface Set</strong>
<p>Select Ethernet package and optional NCSI channel</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3..4 bytes:</strong> channel, C0, package, optional NCSI channel; FF disables all external ports
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> can sever management connectivity
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;requested port is not connected&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ethernet over usb get read ethernet-over-usb enable state safe ">
<td class="p-2 text-xs">56</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Ethernet over USB Get</strong>
<p>Read Ethernet-over-USB enable state</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C1, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision, enabled
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ethernet over usb set enable or disable ethernet over usb unsafe ">
<td class="p-2 text-xs">57</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Ethernet over USB Set</strong>
<p>Enable or disable Ethernet over USB</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, C1, enabled 00/01
Fields
<ul>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes internal management-network interface
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan duid-llt get read dhcpv6 duid-llt safe ">
<td class="p-2 text-xs">58</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN DUID-LLT Get</strong>
<p>Read DHCPv6 DUID-LLT</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C2, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2..? bytes after CC:</strong> revision, length, DUID bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only; parameter is read-only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan autonegotiation get read ethernet autonegotiation state safe ">
<td class="p-2 text-xs">59</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Autonegotiation Get</strong>
<p>Read Ethernet autonegotiation state</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C3, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision, enabled
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan autonegotiation set set ethernet autonegotiation unsafe ">
<td class="p-2 text-xs">60</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Autonegotiation Set</strong>
<p>Set Ethernet autonegotiation</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, C3, enabled 00/01
Fields
<ul>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes Ethernet link negotiation; unsupported on some platforms
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan data rate get read ethernet data rate safe ">
<td class="p-2 text-xs">61</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Data Rate Get</strong>
<p>Read Ethernet data rate</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C4, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision, speed 00=10M or 01=100M
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>speed</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan data rate set set ethernet data rate unsafe ">
<td class="p-2 text-xs">62</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Data Rate Set</strong>
<p>Set Ethernet data rate</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, C4, speed
Fields
<ul>
<li><code>speed</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes Ethernet link rate
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan duplex get read ethernet duplex mode safe ">
<td class="p-2 text-xs">63</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Duplex Get</strong>
<p>Read Ethernet duplex mode</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C5, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision, duplex 00 half or 01 full
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>duplex</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan duplex set set ethernet duplex mode unsafe ">
<td class="p-2 text-xs">64</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Duplex Set</strong>
<p>Set Ethernet duplex mode</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, C5, duplex
Fields
<ul>
<li><code>duplex</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes Ethernet duplex mode
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan mtu get read ethernet mtu safe ">
<td class="p-2 text-xs">65</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN MTU Get</strong>
<p>Read Ethernet MTU</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C6, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes after CC:</strong> revision and two MTU bytes; endian unresolved
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>mtu_raw</code>: bytes[2]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (partial)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan mtu set set ethernet mtu unsafe ">
<td class="p-2 text-xs">66</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN MTU Set</strong>
<p>Set Ethernet MTU</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C6, two MTU bytes; endian unresolved
Fields
<ul>
<li><code>mtu_raw</code>: bytes[2]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes Ethernet MTU
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (partial)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan locally administered mac get read locally administered mac address safe ">
<td class="p-2 text-xs">67</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Locally Administered MAC Get</strong>
<p>Read locally administered MAC address</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C7, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>7 bytes after CC:</strong> revision and six MAC bytes
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>mac</code>: bytes[6]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan locally administered mac set set locally administered mac address unsafe ">
<td class="p-2 text-xs">68</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Locally Administered MAC Set</strong>
<p>Set locally administered MAC address</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>8 bytes:</strong> channel, C7, six MAC bytes
Fields
<ul>
<li><code>mac</code>: bytes[6]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes management MAC address
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ipv6 link local get read ipv6 link-local address safe ">
<td class="p-2 text-xs">69</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN IPv6 Link Local Get</strong>
<p>Read IPv6 link-local address</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C8, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>18 bytes after CC:</strong> revision, prefix length, 16 address bytes
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>prefix_length</code>: u8</li>
<li><code>address</code>: bytes[16]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only; parameter is read-only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ipv6 enable get read ipv6 enable state safe ">
<td class="p-2 text-xs">70</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN IPv6 Enable Get</strong>
<p>Read IPv6 enable state</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, C9, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision, enabled
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan ipv6 enable set enable or disable ipv6 unsafe ">
<td class="p-2 text-xs">71</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN IPv6 Enable Set</strong>
<p>Enable or disable IPv6</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, C9, enabled 00/01
Fields
<ul>
<li><code>enabled</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes management IPv6 configuration
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan usb external pass-through get read ethernet-over-usb external pass-through safe ">
<td class="p-2 text-xs">72</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN USB External Pass-through Get</strong>
<p>Read Ethernet-over-USB external pass-through</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, CA, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>7..22 bytes after CC:</strong> revision, reserved, LE USB/external ports and 1/4/16-byte address or mode
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan usb external pass-through set set ethernet-over-usb external pass-through unsafe ">
<td class="p-2 text-xs">73</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN USB External Pass-through Set</strong>
<p>Set Ethernet-over-USB external pass-through</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>8..23 bytes:</strong> channel, CA, reserved, LE ports and 1/4/16-byte address or mode
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes external management pass-through routing
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 128,
    &quot;meaning&quot;: &quot;parameter unsupported&quot;
  },
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;command unsupported&quot;
  },
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan usb xcc ipv4 get read xcc-side lan-over-usb ipv4 address and netmask safe ">
<td class="p-2 text-xs">74</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN USB XCC IPv4 Get</strong>
<p>Read XCC-side LAN-over-USB IPv4 address and netmask</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, CB, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>9 bytes after CC:</strong> revision, IPv4 address, netmask in network byte order
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>address</code>: bytes[4]</li>
<li><code>netmask</code>: bytes[4]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan usb xcc ipv4 set set xcc-side lan-over-usb ipv4 address and netmask unsafe ">
<td class="p-2 text-xs">75</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN USB XCC IPv4 Set</strong>
<p>Set XCC-side LAN-over-USB IPv4 address and netmask</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>10 bytes:</strong> channel, CB, IPv4 address and netmask in network byte order
Fields
<ul>
<li><code>address</code>: bytes[4]</li>
<li><code>netmask</code>: bytes[4]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes LAN-over-USB addressing
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan usb host ipv4 get read host-side lan-over-usb ipv4 address safe ">
<td class="p-2 text-xs">76</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN USB Host IPv4 Get</strong>
<p>Read host-side LAN-over-USB IPv4 address</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, CC, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes after CC:</strong> revision and IPv4 address in network byte order
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>address</code>: bytes[4]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan usb host ipv4 set set host-side lan-over-usb ipv4 address unsafe ">
<td class="p-2 text-xs">77</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN USB Host IPv4 Set</strong>
<p>Set host-side LAN-over-USB IPv4 address</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>6 bytes:</strong> channel, CC, IPv4 address in network byte order
Fields
<ul>
<li><code>address</code>: bytes[4]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes host-side LAN-over-USB addressing
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan logical package inventory get read logical package and ncsi channel inventory safe ">
<td class="p-2 text-xs">78</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Logical Package Inventory Get</strong>
<p>Read logical package and NCSI channel inventory</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, D3, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>1..? bytes after CC:</strong> revision and packed channel-count/package entries
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only; parameter is read-only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan logical package priority get read logical package priority list safe ">
<td class="p-2 text-xs">79</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Logical Package Priority Get</strong>
<p>Read logical package priority list</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, D4, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>1..? bytes after CC:</strong> revision and packed priority/package entries
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan logical package priority set set logical package priority list unsafe ">
<td class="p-2 text-xs">80</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Logical Package Priority Set</strong>
<p>Set logical package priority list</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3..? bytes:</strong> channel, D4, one or more packed priority/package entries; priority-zero meaning is ambiguous
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes interface failover priority
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (raw-exact)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan dedicated shared synchronization get read dedicated/shared networking synchronization mode safe ">
<td class="p-2 text-xs">81</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Dedicated Shared Synchronization Get</strong>
<p>Read dedicated/shared networking synchronization mode</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, D5, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision and mode 00 synchronized or 01 independent
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>mode</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan dedicated shared synchronization set set dedicated/shared networking synchronization mode unsafe ">
<td class="p-2 text-xs">82</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Dedicated Shared Synchronization Set</strong>
<p>Set dedicated/shared networking synchronization mode</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, D5, mode 00/01
Fields
<ul>
<li><code>mode</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes network configuration coupling
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan networking mode get read applied networking mode and package/channel safe ">
<td class="p-2 text-xs">83</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Networking Mode Get</strong>
<p>Read applied networking mode and package/channel</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4..5 bytes:</strong> channel, D6, 00, 00, optional mode to query
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes after CC:</strong> revision, applied mode, package ID, channel ID
Fields
<ul>
<li><code>revision</code>: u8</li>
<li><code>mode</code>: u8</li>
<li><code>package_id</code>: u8</li>
<li><code>channel_id</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> read only; mode enum remains opaque
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (partial)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan networking mode set set networking mode unsafe ">
<td class="p-2 text-xs">84</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Networking Mode Set</strong>
<p>Set networking mode</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, D6, opaque mode byte
Fields
<ul>
<li><code>mode</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 OEMLANInit channel-data handler<br />
<strong>Side effects:</strong> changes active management-network mode
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (partial)<br />
<strong>Evidence:</strong> Lenovo public contract + XCC 6.92 handler activation<br />
<a href="https://pubs.lenovo.com/xcc/get_set_lan_config_parameter">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan unnamed oem value get read firmware-only one-byte oem lan value safe xcc 6.92 firmware-only selector; purpose is not named by the binary">
<td class="p-2 text-xs">85</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Unnamed OEM Value Get</strong>
<p>Read firmware-only one-byte OEM LAN value</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, D2, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes after CC:</strong> revision 11 and stored value
Fields
<ul>
<li><code>revision</code>: u8 = 0x11</li>
<li><code>value</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 firmware-only selector; purpose is not named by the binary<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;feature inactive or nonzero set/block selector&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> OEMLANGetParam and Set_LANConfigParams_OEM_bytes decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan unnamed oem value set set firmware-only one-byte oem lan value unsafe xcc 6.92 firmware-only selector; no value-range validation">
<td class="p-2 text-xs">86</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Unnamed OEM Value Set</strong>
<p>Set firmware-only one-byte OEM LAN value</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3 bytes:</strong> channel, D2, value
Fields
<ul>
<li><code>value</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 firmware-only selector; no value-range validation<br />
<strong>Side effects:</strong> changes an unnamed internal OEM LAN configuration value
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> OEMLANSetParam and Set_LANConfigParams_OEM_bytes decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan on-board package inventory get read firmware-only on-board package identifiers safe xcc 6.92 firmware-only selector">
<td class="p-2 text-xs">87</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN On-board Package Inventory Get</strong>
<p>Read firmware-only on-board package identifiers</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, D7, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>2..10 bytes after CC:</strong> revision 11 and 1..9 packed slot/package bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 firmware-only selector<br />
<strong>Side effects:</strong> read only; parameter is read-only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;nonzero set/block selector&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;OSInet inventory failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> OEMLANGetAllOnBoardPkgData decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan test ncsi mapping get read test-only ncsi internal-channel mapping safe xcc 6.92 firmware-only test hook">
<td class="p-2 text-xs">88</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x02<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Test NCSI Mapping Get</strong>
<p>Read test-only NCSI internal-channel mapping</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> channel, D8, 00, 00
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>1..? bytes after CC:</strong> revision 11 and zero or more two-byte mapping records; may append 09 00 for a second port
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 firmware-only test hook<br />
<strong>Side effects:</strong> read only; firmware labels the selector fake auxiliary data for testing only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;nonzero set/block selector&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> OEMLANUTGetNCSIChannelInfo decompilation and firmware diagnostic string<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="lan test ncsi mapping set set test-only ncsi internal-channel mapping unsafe xcc 6.92 firmware-only test hook; records beginning 01 are skipped">
<td class="p-2 text-xs">89</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0c/0x01<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>LAN Test NCSI Mapping Set</strong>
<p>Set test-only NCSI internal-channel mapping</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2..? bytes:</strong> channel, D8, zero or an even number of mapping bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> standard Get=User / Set=Admin<br />
<strong>Channel:</strong> standard LAN configuration channel<br />
<strong>Activation:</strong> XCC 6.92 firmware-only test hook; records beginning 01 are skipped<br />
<strong>Side effects:</strong> changes internal NCSI mapping through a firmware test hook
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;odd mapping-data length&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend-set failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response yes (raw-exact)<br />
<strong>Evidence:</strong> OEMLANSetParam NCSI mapping path and firmware diagnostic string<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="auxiliary log status read current auxiliary-log status safe registered by libmod_logging">
<td class="p-2 text-xs">90</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0a/0x5a<br />
selector 01 @ 0</td>
<td class="p-2 min-w-72"><strong>Auxiliary Log Status</strong>
<p>Read current auxiliary-log status</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> selector 01
Fields
<ul>
<li><code>selector</code>: u8 = 0x01</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>11 bytes after CC:</strong> LE timestamp, Lenovo IANA 66 4a 00, LE entry count, LE free space
Fields
<ul>
<li><code>timestamp</code>: u32le</li>
<li><code>iana</code>: bytes[3]</li>
<li><code>entry_count</code>: u16le</li>
<li><code>free_space</code>: u16le</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> registered by libmod_logging<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid selector&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 aux_log_cmd decompilation<br />
<a href="firmware:sha256:3559e34d94a0021941361226505a16c6e53e0501ce89e3f155331eeb86ca7800">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="terminal sys serial-terminal boot, channel, power, health and tunnel operations unsafe active libipmi core table cmdterminalsys">
<td class="p-2 text-xs">91</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xa0<br />
selector 5e 2b 00 @ 0</td>
<td class="p-2 min-w-72"><strong>Terminal SYS</strong>
<p>Serial-terminal boot, channel, power, health and tunnel operations</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>4..? bytes:</strong> 5e 2b 00, operation selector and selector-specific body
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> selector-specific
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> serial terminal protocol type 9 only<br />
<strong>Activation:</strong> active libipmi core table CmdTerminalSYS<br />
<strong>Side effects:</strong> mixed serial boot, channel and power control
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 193,
    &quot;meaning&quot;: &quot;not serial-terminal channel&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid selector&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 CmdTerminalSYS decompilation resolves formerly prefixless identity<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="active session get read active-session records by selector safe legacy direct handler">
<td class="p-2 text-xs">92</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x34/0xb0<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Active Session Get</strong>
<p>Read active-session records by selector</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> one selector byte 00..05
Fields
<ul>
<li><code>selector</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>1..? bytes after CC:</strong> count followed by count 4-byte records
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 130,
    &quot;meaning&quot;: &quot;invalid selector&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 GetActiveSession decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="active session delete terminate an active session unsafe legacy direct handler">
<td class="p-2 text-xs">93</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x34/0xb1<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Active Session Delete</strong>
<p>Terminate an active session</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> one session selector or ID byte
Fields
<ul>
<li><code>session</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> terminates an authenticated session
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 130,
    &quot;meaning&quot;: &quot;no such session&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 DeleteActiveSession decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="sessionless privilege set set sessionless privilege for a channel unsafe legacy direct handler">
<td class="p-2 text-xs">94</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x03<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Sessionless Privilege Set</strong>
<p>Set sessionless privilege for a channel</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> channel 0..0f (0e current), privilege low nibble 1..5
Fields
<ul>
<li><code>channel</code>: u8</li>
<li><code>privilege</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes channel authorization state
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 128,
    &quot;meaning&quot;: &quot;unsupported&quot;
  },
  {
    &quot;code&quot;: 192,
    &quot;meaning&quot;: &quot;backend failure&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid value&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 SetSessionlessPrivilege decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="sessionless privilege get read sessionless privilege for a channel safe legacy direct handler">
<td class="p-2 text-xs">95</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x04<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Sessionless Privilege Get</strong>
<p>Read sessionless privilege for a channel</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> channel byte
Fields
<ul>
<li><code>channel</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes after CC:</strong> privilege byte
Fields
<ul>
<li><code>privilege</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 128,
    &quot;meaning&quot;: &quot;unsupported&quot;
  },
  {
    &quot;code&quot;: 192,
    &quot;meaning&quot;: &quot;backend failure&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid channel&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 GetSessionlessPrivilege decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="sol configuration get read sol configuration through channel-data callback safe legacy direct handler">
<td class="p-2 text-xs">96</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x88<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>SOL Configuration Get</strong>
<p>Read SOL configuration through channel-data callback</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> exactly two selector bytes
Fields
<ul>
<li><code>selector</code>: bytes[2]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> callback-defined
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> channel-data handler must be active<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 GetSOLConfig decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="sol configuration set selector 1 set sol configuration selector 1 unsafe legacy direct handler">
<td class="p-2 text-xs">97</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x89<br />
selector 01 @ 0</td>
<td class="p-2 min-w-72"><strong>SOL Configuration Set Selector 1</strong>
<p>Set SOL configuration selector 1</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>5 bytes:</strong> selector 01 plus four bytes
Fields
<ul>
<li><code>selector</code>: u8 = 0x01</li>
<li><code>data</code>: bytes[4]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> callback-defined
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> channel-data handler must be active<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes SOL configuration
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 128,
    &quot;meaning&quot;: &quot;unsupported selector&quot;
  },
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 SetSOLConfig decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="sol configuration set selector 2 set sol configuration selector 2 unsafe legacy direct handler">
<td class="p-2 text-xs">98</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x89<br />
selector 02 @ 0</td>
<td class="p-2 min-w-72"><strong>SOL Configuration Set Selector 2</strong>
<p>Set SOL configuration selector 2</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> selector 02 plus three bytes
Fields
<ul>
<li><code>selector</code>: u8 = 0x02</li>
<li><code>data</code>: bytes[3]</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>?..? bytes after CC:</strong> callback-defined
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> channel-data handler must be active<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes SOL configuration
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 128,
    &quot;meaning&quot;: &quot;unsupported selector&quot;
  },
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 SetSOLConfig decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="oem i2c master write read perform oem i2c master write/read transaction unsafe legacy direct handler">
<td class="p-2 text-xs">99</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x94<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>OEM I2C Master Write Read</strong>
<p>Perform OEM I2C master write/read transaction</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>3..34 bytes:</strong> bus, slave address, read count, then 0..31 write bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>0..? bytes after CC:</strong> read bytes
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 2<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> performs arbitrary hardware-bus write/read
Completion codes
<pre><code>[]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request no, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 OEMMasterWriteRead decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="nic status get read network mode and interface status safe legacy direct handler">
<td class="p-2 text-xs">100</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9b<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>NIC Status Get</strong>
<p>Read network mode and interface status</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>1..? bytes after CC:</strong> network mode and packed per-interface status
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> read only
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response no (raw-exact)<br />
<strong>Evidence:</strong> XCC 6.92 NICStatusWR decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="nic 1 status set set interface 1 status unsafe legacy direct handler">
<td class="p-2 text-xs">101</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9b<br />
selector 01 @ 0</td>
<td class="p-2 min-w-72"><strong>NIC 1 Status Set</strong>
<p>Set interface 1 status</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> interface 01, status bit 0
Fields
<ul>
<li><code>interface</code>: u8 = 0x01</li>
<li><code>status</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes NIC status
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;reserved status bits&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 NICStatusWR decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="nic 2 status set set interface 2 status unsafe legacy direct handler">
<td class="p-2 text-xs">102</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9b<br />
selector 02 @ 0</td>
<td class="p-2 min-w-72"><strong>NIC 2 Status Set</strong>
<p>Set interface 2 status</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> interface 02, status bit 0
Fields
<ul>
<li><code>interface</code>: u8 = 0x02</li>
<li><code>status</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes NIC status
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;reserved status bits&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 NICStatusWR decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="nic 3 status set set interface 3 status unsafe legacy direct handler">
<td class="p-2 text-xs">103</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9b<br />
selector 03 @ 0</td>
<td class="p-2 min-w-72"><strong>NIC 3 Status Set</strong>
<p>Set interface 3 status</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> interface 03, status bit 0
Fields
<ul>
<li><code>interface</code>: u8 = 0x03</li>
<li><code>status</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes NIC status
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;reserved status bits&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 NICStatusWR decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="nic 4 status set set interface 4 status unsafe legacy direct handler">
<td class="p-2 text-xs">104</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9b<br />
selector 04 @ 0</td>
<td class="p-2 min-w-72"><strong>NIC 4 Status Set</strong>
<p>Set interface 4 status</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>2 bytes:</strong> interface 04, status bit 0
Fields
<ul>
<li><code>interface</code>: u8 = 0x04</li>
<li><code>status</code>: u8</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> legacy direct handler<br />
<strong>Side effects:</strong> changes NIC status
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;reserved status bits&quot;
  },
  {
    &quot;code&quot;: 255,
    &quot;meaning&quot;: &quot;backend failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 NICStatusWR decompilation<br />
<a href="firmware:XCC-6.92">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="node manager reading read gated node manager telemetry safe active core row; operation runtime-gated by nmptcheckenable and nmptcmdhook">
<td class="p-2 text-xs">105</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0xe2<br />
selector — @ None</td>
<td class="p-2 min-w-72"><strong>Node Manager Reading</strong>
<p>Read gated Node Manager telemetry</p>
safe</td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes:</strong> 4 bytes: operation/selector, selector 2, reserved 00 00
Fields
<ul>
<li><code>operation_selector</code>: u8</li>
<li><code>selector_2</code>: u8</li>
<li><code>reserved</code>: u16le = 0x00</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>4 bytes after CC:</strong> echo, reserved/indeterminate, little-endian u16 reading
Fields
<ul>
<li><code>operation_echo</code>: u8</li>
<li><code>reserved_indeterminate</code>: u8</li>
<li><code>reading</code>: u16le</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> active core row; operation runtime-gated by NMPTCheckEnable and NMPTCmdHook<br />
<strong>Side effects:</strong> read only; runtime requires NMPT enabled and a registered hook
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid selector or reserved word&quot;
  },
  {
    &quot;code&quot;: 213,
    &quot;meaning&quot;: &quot;NMPT disabled, hook unavailable or hook failure&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 core row and CmdOEMGetReading decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="node manager pass-through enable enable volatile node manager pass-through unsafe active libipmi core row">
<td class="p-2 text-xs">106</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0xe3<br />
selector 00 @ 0</td>
<td class="p-2 min-w-72"><strong>Node Manager Pass-through Enable</strong>
<p>Enable volatile Node Manager pass-through</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> 00
Fields
<ul>
<li><code>control</code>: u8 = 0x00</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> active libipmi core row<br />
<strong>Side effects:</strong> enables in-memory Node Manager pass-through state
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid value&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 CmdOEMMEPowerStateChange decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
<tr class="border-b align-top" data-contract="node manager pass-through disable disable volatile node manager pass-through unsafe active libipmi core row">
<td class="p-2 text-xs">107</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0xe3<br />
selector 02 @ 0</td>
<td class="p-2 min-w-72"><strong>Node Manager Pass-through Disable</strong>
<p>Disable volatile Node Manager pass-through</p>
unsafe</td>
<td class="p-2 min-w-96 text-xs"><strong>1 bytes:</strong> 02
Fields
<ul>
<li><code>control</code>: u8 = 0x02</li>
</ul></td>
<td class="p-2 min-w-96 text-xs"><strong>0 bytes after CC:</strong> empty
Fields
opaque or empty</td>
<td class="p-2 min-w-96 text-xs"><strong>Privilege:</strong> 4<br />
<strong>Channel:</strong> any IPMI channel<br />
<strong>Activation:</strong> active libipmi core row<br />
<strong>Side effects:</strong> disables in-memory Node Manager pass-through state
Completion codes
<pre><code>[
  {
    &quot;code&quot;: 199,
    &quot;meaning&quot;: &quot;invalid length&quot;
  },
  {
    &quot;code&quot;: 204,
    &quot;meaning&quot;: &quot;invalid value&quot;
  }
]</code></pre></td>
<td class="p-2 min-w-72 text-xs"><strong>Codec:</strong> request yes, response yes (verified)<br />
<strong>Evidence:</strong> XCC 6.92 CmdOEMMEPowerStateChange decompilation<br />
<a href="firmware:sha256:b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485">source</a></td>
</tr>
</tbody>
</table>

## Top-level identity inventory

Filter identities

<table style="width:100%;">
<colgroup>
<col style="width: 16%" />
<col style="width: 16%" />
<col style="width: 16%" />
<col style="width: 16%" />
<col style="width: 16%" />
<col style="width: 16%" />
</colgroup>
<thead class="bg-slate-200 text-xs">
<tr>
<th class="p-2">#</th>
<th class="p-2">Wire</th>
<th class="p-2">Identity</th>
<th class="p-2">Handler / admission</th>
<th class="p-2">Decoded operations</th>
<th class="p-2">Effect / evidence</th>
</tr>
</thead>
<tbody id="command-rows">
<tr class="border-b align-top" data-row="xccpower_00_01 sys_pwr_device::get_chassis_status(sys_pwr_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">1</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x00/0x01<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_00_01</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">sys_pwr_device::get_chassis_status(sys_pwr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>chassis status</strong> [base]: empty → 3-byte standard chassis status; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccled_00_04 identify_led_device::chassis_identify(identify_led_device*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">2</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x00/0x04<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLed_00_04</strong><br />
cpp_registration · privilege 2
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">identify_led_device::chassis_identify(identify_led_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>chassis identify</strong> [base]: empty starts identify; 1 byte sets timeout/off; 2 bytes add force-identify bit → empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_00_06 sys_pwr_device::cmdsetpowerrestorepolicy(sys_pwr_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">3</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x00/0x06<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_00_06</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">sys_pwr_device::CmdSetPowerRestorePolicy(sys_pwr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>power restore policy</strong> [base]: exactly 1 byte; low 3 bits 00..02 set policy, 03 queries supported-policy mask; bit 2 must be clear → set: supported-policy mask byte; query: supported-policy mask byte; CC c1 unsupported platform/policy; c7 length; cc reserved bit</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_06_07 sys_pwr_device::get_acpi_state_dcmi(sys_pwr_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">4</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x06/0x07<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_06_07</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">sys_pwr_device::get_acpi_state_dcmi(sys_pwr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>DCMI ACPI state</strong> [base]: empty → 2 bytes; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_0a_10 planar_controller::get_fru_inventory_area_info_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">5</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0a/0x10<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_0A_10</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::get_fru_inventory_area_info_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FRU inventory area info</strong> [base]: 1-byte FRU id → 2-byte little-endian area size plus 1-byte access type; CC cc id ff; cb absent; 81 not ready</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_0a_11 planar_controller::read_fru_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">6</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0a/0x11<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_0A_11</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::read_fru_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>platform FRU read</strong> [base]: FRU device id, 16-bit little-endian offset, 1-byte count; device ff rejected and count must be nonzero → requested FRU bytes; on one deferred-read path returns dc plus progress notification; CC cc device; c7 zero count; c9 offset/count range; cb absent/read failure; 81 not initialized</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_0a_12 planar_controller::write_fru_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">7</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0a/0x12<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_0A_12</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::write_fru_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>platform FRU write</strong> [base]: FRU id, 16-bit little-endian offset, then data; only FRU 00 and the platform-advertised exact offset/block size are writable → 1-byte written count; CC 80 write protected/framing; cb absent; cc device; ff short write</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_0a_5a virtual_gpio_logical_device::aux_log_cmd(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">8</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x0a/0x5a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLogging_0A_5A</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::aux_log_cmd(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>aux log cmd</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_00_d0_51_00 amm_logical_device::get_blade_descriptor(amm_logical_device*, ipmi_message*) | cmm_logical_device::get_blade_descriptor(cmm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">9</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x00<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_00_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::get_blade_descriptor(amm_logical_device*, ipmi_message*) | cmm_logical_device::get_blade_descriptor(cmm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>blade descriptor</strong> [base]: IANA d0 51 00; handler consumes no request body → platform-dependent descriptor, approximately 20 bytes; CMM variant may publish a discovery event; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_01_4d_4f_00 planar_controller::mfg_check_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">10</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x01<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_01_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::mfg_check_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>manufacturing check alias</strong> [00..07]: IANA 4d 4f 00 with same body as Lenovo-IANA registration → same as Lenovo-IANA registration; CC same as Lenovo-IANA registration</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_01_66_4a_00 planar_controller::mfg_check_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">11</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x01<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_01_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::mfg_check_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>manufacturing check</strong> [00..07]: IANA 66 4a 00 with empty body returns eMMC result; selectors 01..07 run tests/actions; selector 03 additionally carries 32-bit little-endian SPI offset and length byte → selector-dependent status/data; CC c0 busy; c1 framing; cc SPI failure</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_02_66_4a_00 smm_logical_device::set_power_permission(smm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">12</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x02<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_02_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">smm_logical_device::set_power_permission(smm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMM power permission set</strong> [base]: IANA 66 4a 00 followed by permission bit field → empty; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_02_d0_51_00 amm_logical_device::set_power_permission(amm_logical_device*, ipmi_message*) | cmm_logical_device::set_power_permission(cmm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">13</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x02<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_02_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::set_power_permission(amm_logical_device*, ipmi_message*) | cmm_logical_device::set_power_permission(cmm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>chassis power permission set</strong> [base]: IANA d0 51 00 followed by permission bit field; CMM additionally accepts a fifth override byte → empty; CC c7 platform-specific length</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_03_66_4a_00 smm_logical_device::get_power_permission(smm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">14</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x03<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_03_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">smm_logical_device::get_power_permission(smm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMM power permission</strong> [base]: IANA 66 4a 00; handler consumes no additional request body → 1-byte power-permission state; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_03_d0_51_00 pwr_permission_device::get_power_permission(pwr_permission_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">15</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x03<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_03_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">pwr_permission_device::get_power_permission(pwr_permission_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>power permission</strong> [base]: IANA prefix; no handler-local length check → 1-byte permission bit field; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_04_d0_51_00 amm_logical_device::set_kvm_mt(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">16</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x04<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_04_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::set_kvm_mt(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>KVM management transport set</strong> [base]: IANA d0 51 00 followed by mode byte → empty; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_07_d0_51_00 amm_logical_device::get_blade_system_info(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">17</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x07<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_07_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::get_blade_system_info(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>blade system information</strong> [base]: IANA d0 51 00; handler consumes no request body → 5-byte platform system-information record; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_09_d0_51_00 planar_controller::vpd_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">18</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x09<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_09_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::vpd_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPD write alias</strong> [base]: IANA d0 51 00, 16-bit little-endian offset, VPD device id, data → empty; CC c9 range; cb absent; d5 unavailable; 80 write protected</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_0a_d0_51_00 planar_controller::vpd_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">19</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x0a<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_0A_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::vpd_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPD read alias</strong> [base]: IANA d0 51 00, 16-bit little-endian offset, VPD device id, 1-byte length (max f1) → requested raw VPD bytes; CC c9 range; cb absent/read failure; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccled_2e_0b_d0_51_00 led_controller::led_set(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">20</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x0b<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCLed_2E_0B_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_set(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>LED set</strong> [base]: IANA d0 51 00 followed by 16-bit LED id and delegated LED-specific body; exactly 6 request bytes including IANA → delegated LED-specific response; CC c7 length; c9 unknown LED; cb unavailable; d5 controller disabled</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccled_2e_0c_d0_51_00 led_controller::led_get(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">21</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x0c<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCLed_2E_0C_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_get(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>LED get</strong> [base]: wire body is IANA d0 51 00 plus 16-bit LED id (5 bytes total) → delegated device-specific LED response; exact bytes unknown; CC c7 length; c9 unknown LED; cb unavailable LED</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_15_d0_51_00 dem_logical_device::set_dem_enable(dem_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">22</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x15<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_15_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">dem_logical_device::set_DEM_enable(dem_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>DEM enable set</strong> [base]: IANA d0 51 00 followed by selector byte: low 7 bits device, bits 7/8 encode control flags as interpreted by handler → empty; CC cc unknown DEM target</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_16_d0_51_00 dem_logical_device::get_dem_enable(dem_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">23</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x16<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_16_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">dem_logical_device::get_DEM_enable(dem_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>DEM enabled state</strong> [base]: IANA d0 51 00 followed by one selector byte; bit 7 is ignored → 1 byte: 00 disabled or 01 enabled; CC cc unavailable/invalid selector</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_2e_18_d0_51_00 virtual_gpio_logical_device::event_aux_info_cmd(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">24</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x18<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCLogging_2E_18_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::event_aux_info_cmd(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>event aux info cmd</strong> [base]: IANA d0 51 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_1a_d0_51_00 cmm_logical_device::set_service_location(cmm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">25</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x1a<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_1A_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">cmm_logical_device::set_service_location(cmm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>service-location configuration</strong> [base]: IANA d0 51 00 followed by operation, location selector, 16-bit field and variable location data; platform- and mode-specific → status bytes or location record; CC c7 framing; cc fields; d4 privilege/backend</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_20_d0_51_00 ite_fpm_logical_device::fpm_ipmi_setacousticmode(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">26</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x20<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_20_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_SetAcousticMode(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM acoustic mode set</strong> [base]: IANA d0 51 00 followed by enable byte; handler requires at least one post-IANA byte → empty; CC c7 short request; d5 unavailable/conflicting state</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_21_d0_51_00 ite_fpm_logical_device::fpm_ipmi_getacousticmode(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">27</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x21<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_21_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_GetAcousticMode(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM acoustic mode</strong> [base]: IANA d0 51 00; trailing bytes accepted and ignored → 1 byte acoustic-mode flag; CC c7 body shorter than IANA</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_22_d0_51_00 ite_fpm_logical_device::fpm_ipmi_getwattsusage(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">28</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x22<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_22_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_GetWattsUsage(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM watts usage</strong> [base]: IANA prefix; handler requires request length at least 3 but consumes no additional payload → 3-byte aggregate prefix followed by 5 bytes per populated power entry; exact field identities partially decoded; CC c7 short request; c1 unsupported; 01/02 transitional state; d2 data unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_23_d0_51_00 ite_fpm_logical_device::fpm_ipmi_getthrottle(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">29</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x23<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_23_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_GetThrottle(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM throttle telemetry</strong> [base]: IANA d0 51 00; trailing bytes accepted and ignored → 4-byte header, variable per-PSU bytes, and 2-byte trailer; CC c7 body shorter than IANA</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_24_d0_51_00 ite_fpm_logical_device::fpm_ipmi_setpresetwatts(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">30</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x24<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_24_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_SetPresetWatts(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM preset watts set</strong> [base]: IANA d0 51 00 followed by three control bytes and two-byte big-endian watt presets; at least 8 total bytes including IANA → empty; CC c7 short request; d2 unavailable; d5 conflicting state</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_27_d0_51_00 ite_fpm_logical_device::fpm_ipmi_getwattinventory(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">31</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x27<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_27_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_GetWattInventory(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM watt inventory</strong> [base]: IANA d0 51 00; trailing bytes accepted and ignored → 4-byte header, eight 16-bit watt entries, variable PSU bytes, and variable preset records; CC c7 body shorter than IANA; c4 record count; d2 data unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_2e_29 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">32</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x29<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_2E_29</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_2b_d0_51_00 ite_fpm_logical_device::fpm_ipmi_setthrottleoverride(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">33</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x2b<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_2B_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_SetThrottleOverride(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM throttle override set</strong> [base]: IANA d0 51 00; handler ignores payload → empty; CC d5 unconditionally</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_2e_2c_d0_51_00 ite_fpm_logical_device::fpm_ipmi_getthrottleoverride(ite_fpm_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">34</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x2c<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCPower_2E_2C_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">ite_fpm_logical_device::fpm_ipmi_GetThrottleOverride(ite_fpm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPM throttle override</strong> [base]: IANA d0 51 00; handler has no local length check → 3 bytes: override status fields; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_30_d0_51_00 amm_logical_device::chassis_information(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">35</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x30<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_30_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::chassis_information(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>chassis information</strong> [base]: IANA d0 51 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_2e_32_d0_51_00 properties_device::property_cmd(properties_device*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">36</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x32<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCCore_2E_32_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">properties_device::property_cmd(properties_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>property protocol alias</strong> [00..07]: IANA d0 51 00 followed by the same operation, 16-bit length, and body as 3a/c4; declared length must exactly match → same as 3a/c4 operation; CC c7 framing; cc subselector; d5 operation</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_2e_41 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">37</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x41<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_2E_41</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_42_d0_51_00 amm_logical_device::get_port_configuration(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">38</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x42<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_42_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::get_port_configuration(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>AMM port configuration stub</strong> [base]: IANA d0 51 00; handler ignores body → empty; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_46_d0_51_00 cmm_logical_device::chassis_fan_status(cmm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">39</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x46<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_46_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">cmm_logical_device::chassis_fan_status(cmm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>chassis fan control</strong> [base]: IANA d0 51 00 followed by mode 00 or 01; exactly 4 request bytes including IANA → empty; CC c7 length; c9 mode</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_2e_50 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">40</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x50<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_2E_50</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_51_d0_51_00 planar_controller::vpd_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">41</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x51<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_51_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::vpd_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>mapped VPD extension</strong> [01 or 02]: IANA d0 51 00, 16-bit offset, map mode 01/02, FRU/device id, transfer mode, 16-bit length, body → mapped raw VPD data or delegated device-family response; CC c9 range/map; cb absent; d5 unavailable; 80 write protected</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccinventory_2e_53_d0_51_00 vpdc_logical_device::get_vpd_counter(vpdc_logical_device*, ipmi_message*) cpp_registration platform inventory">
<td class="p-2 text-xs">42</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x53<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCInventory_2E_53_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>platform inventory</p></td>
<td class="p-2 min-w-80 text-xs">vpdc_logical_device::get_vpd_counter(vpdc_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPD master counter</strong> [01]: IANA d0 51 00 plus selector 01 → 1-byte tag plus 32-bit native-width master counter; CC cc selector</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_61_d0_51_00 cmm_logical_device::get_redirection_token(cmm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">43</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x61<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_61_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">cmm_logical_device::get_redirection_token(cmm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>redirection token</strong> [base]: IANA d0 51 00, 16-bit big-endian token type/id, then a nonempty length-delimited string; total post-IANA body length must equal string length plus 6 → length-delimited token string; CC c7 framing; 01 token service failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_80_02_00_00 ipmi::find_firmware_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">44</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x80<br />
prefix 02 00 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_80_02_00_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::find_firmware_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>find firmware proc</strong> [base]: IANA 02 00 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_80_66_4a_00 ipmi::find_firmware_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">45</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x80<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_80_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::find_firmware_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>find firmware proc</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccopenbmc_2e_80_cf_c2_00 openbmc_logical_device::blob_cmd(openbmc_logical_device*, ipmi_message*) cpp_registration openbmc compatibility">
<td class="p-2 text-xs">46</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x80<br />
prefix cf c2 00</td>
<td class="p-2 min-w-72"><strong>XCCOpenbmc_2E_80_CF_C2_00</strong><br />
cpp_registration · privilege 2
<p>OpenBMC compatibility</p></td>
<td class="p-2 min-w-80 text-xs">openbmc_logical_device::blob_cmd(openbmc_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>OpenBMC blob protocol</strong> [base]: IANA cf c2 00 plus phosphor-host-ipmid blob payload → delegated blob response; CC delegated blob completion code</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_81_02_00_00 ipmi::invoke_element_method_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">47</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x81<br />
prefix 02 00 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_81_02_00_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::invoke_element_method_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>invoke element method proc</strong> [base]: IANA 02 00 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_81_66_4a_00 ipmi::invoke_element_method_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">48</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x81<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_81_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::invoke_element_method_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>invoke element method proc</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_82_02_00_00 ipmi::find_firmware_instance_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">49</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x82<br />
prefix 02 00 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_82_02_00_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::find_firmware_instance_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>find firmware instance proc</strong> [base]: IANA 02 00 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_82_66_4a_00 ipmi::find_firmware_instance_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">50</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x82<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_82_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::find_firmware_instance_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>find firmware instance proc</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_90_4d_4f_00 planar_controller::datastore_access(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">51</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x90<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_90_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::datastore_access(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>datastore protocol alias</strong> [01..11,ff]: IANA 4d 4f 00 followed by the same selector and body as Lenovo-IANA 2e/90 → same as Lenovo-IANA registration; CC same as Lenovo-IANA registration</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_90_66_4a_00 planar_controller::datastore_access(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">52</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x90<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_90_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::datastore_access(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>datastore open</strong> [01]: IANA 66 4a 00, 01, flags, mode, 32-bit offset, privilege byte, timeout byte, path; at least 9 bytes after selector → 4-byte little-endian handle; CC c9 framing; d4 privilege; negative datastore errno<br />
<strong>datastore read</strong> [02]: IANA 66 4a 00, 02, 32-bit handle, 32-bit offset, 16-bit little-endian length (max ef) → 16-bit little-endian returned length plus bytes; CC c9 framing/range; cb handle; negative datastore errno<br />
<strong>datastore write</strong> [03]: IANA 66 4a 00, 03, 32-bit handle, 32-bit offset, data → 16-bit little-endian written length; CC c9 framing; d4 privilege; negative datastore errno<br />
<strong>datastore set default</strong> [04]: IANA 66 4a 00, 04, datastore path → empty; CC negative datastore errno<br />
<strong>datastore close</strong> [05]: IANA 66 4a 00, 05, 32-bit handle → empty; CC c9 framing; cb handle; negative datastore errno<br />
<strong>datastore query</strong> [06]: IANA 66 4a 00, 06, datastore path → 4-byte little-endian size; CC negative datastore errno<br />
<strong>datastore delete</strong> [07]: IANA 66 4a 00, 07, datastore path → empty; CC negative datastore errno<br />
<strong>secured datastore open</strong> [10]: IANA 66 4a 00, 10, flags, mode, 32-bit offset, privilege byte, timeout byte, 32-bit security token, path; at least 13 bytes after selector → 4-byte little-endian handle; CC c9 framing; d4 privilege; negative datastore errno<br />
<strong>secured datastore delete</strong> [11]: IANA 66 4a 00, 11, 32-bit security token, path → empty; CC c9 framing; negative datastore errno<br />
<strong>datastore debug</strong> [ff]: IANA 66 4a 00, ff, debug level → empty; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_2e_92_4d_4f_00 virtual_gpio_logical_device::vgpio_cmd(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">53</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x92<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCLogging_2E_92_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::vgpio_cmd(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>vgpio cmd</strong> [base]: IANA 4d 4f 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_2e_92_66_4a_00 virtual_gpio_logical_device::vgpio_cmd(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">54</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x92<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCLogging_2E_92_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::vgpio_cmd(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>vgpio cmd</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_2e_93_4d_4f_00 virtual_gpio_logical_device::aux_log_cmd(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">55</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x93<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCLogging_2E_93_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::aux_log_cmd(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>aux log cmd</strong> [base]: IANA 4d 4f 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_2e_93_66_4a_00 virtual_gpio_logical_device::aux_log_cmd(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">56</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x93<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCLogging_2E_93_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::aux_log_cmd(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>aux log cmd</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_2e_94_4d_4f_00 io_controller::vid_burst(io_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">57</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x94<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCCore_2E_94_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">io_controller::vid_burst(io_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VID burst alias</strong> [00..02]: IANA 4d 4f 00 plus mode 00..02 → 1 byte command result 00/01; CC c7 length/channel; c9 selector; c1 result unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_2e_94_66_4a_00 io_controller::vid_burst(io_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">58</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x94<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCCore_2E_94_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">io_controller::vid_burst(io_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VID burst alias</strong> [00..02]: IANA 66 4a 00 plus mode 00..02 → 1 byte command result 00/01; CC c7 length/channel; c9 selector; c1 result unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfod_2e_95_4d_4f_00 fod_device::oem_fod_cmd(fod_device*, ipmi_message*) cpp_registration feature-on-demand licensing">
<td class="p-2 text-xs">59</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x95<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCFod_2E_95_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>feature-on-demand licensing</p></td>
<td class="p-2 min-w-80 text-xs">fod_device::oem_fod_cmd(fod_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>oem fod cmd</strong> [base]: IANA 4d 4f 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfod_2e_95_66_4a_00 fod_device::oem_fod_cmd(fod_device*, ipmi_message*) cpp_registration feature-on-demand licensing">
<td class="p-2 text-xs">60</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x95<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCFod_2E_95_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>feature-on-demand licensing</p></td>
<td class="p-2 min-w-80 text-xs">fod_device::oem_fod_cmd(fod_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>oem fod cmd</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfod_2e_95_d0_51_00 fod_device::oem_fod_cmd(fod_device*, ipmi_message*) cpp_registration feature-on-demand licensing">
<td class="p-2 text-xs">61</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x95<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCFod_2E_95_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>feature-on-demand licensing</p></td>
<td class="p-2 min-w-80 text-xs">fod_device::oem_fod_cmd(fod_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>oem fod cmd</strong> [base]: IANA d0 51 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_96_4d_4f_00 ipmi::sanitization_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">62</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x96<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_96_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::sanitization_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>sanitization proc</strong> [base]: IANA 4d 4f 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_2e_96_66_4a_00 ipmi::sanitization_proc(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">63</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x96<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_2E_96_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::sanitization_proc(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>sanitization proc</strong> [base]: IANA 66 4a 00 plus operation-specific body; delegated framing remains unresolved → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_97_4d_4f_00 tklm_logical_device::tklm_ipmi_command(tklm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">64</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x97<br />
prefix 4d 4f 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_97_4D_4F_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">tklm_logical_device::tklm_ipmi_command(tklm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>TKLM command alias</strong> [base]: IANA 4d 4f 00 plus same delegated payload as Lenovo-IANA registration → same as Lenovo-IANA registration; CC same as Lenovo-IANA registration</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_2e_97_66_4a_00 tklm_logical_device::tklm_ipmi_command(tklm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">65</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x97<br />
prefix 66 4a 00</td>
<td class="p-2 min-w-72"><strong>XCCModules_2E_97_66_4A_00</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">tklm_logical_device::tklm_ipmi_command(tklm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>TKLM command</strong> [base]: IANA 66 4a 00 plus delegated TKLM/TK-shield payload → delegated TKLM response; CC 12 unsupported TK-shield/platform state</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_2e_98_d0_51_00 bios_device::ipmi_uefi_event(bios_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">66</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0x98<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_2E_98_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">bios_device::ipmi_uefi_event(bios_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>UEFI audit event</strong> [base]: IANA d0 51 00 plus at least 6 bytes: two 16-bit little-endian fields, boolean field, and event data → 2-byte little-endian status; CC c7 short request</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdterminalsys_2e_a0 cmdterminalsys legacy_admission_only local special handler">
<td class="p-2 text-xs">67</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xa0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdTerminalSYS_2E_A0</strong><br />
legacy_admission_only · privilege 2
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdTerminalSYS<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccled_2e_c0_d0_51_00 led_controller::led_status(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">68</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xc0<br />
prefix d0 51 00</td>
<td class="p-2 min-w-72"><strong>XCCLed_2E_C0_D0_51_00</strong><br />
cpp_registration · privilege 2
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_status(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>LED status</strong> [base]: IANA d0 51 00 followed by 16-bit LED id; exactly 5 request bytes including IANA → delegated LED-type-specific status response; exact bytes vary by device implementation; CC c7 length; c9 unknown LED; cb unavailable LED</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdosaoemcmdhandler_2e_cc_5e_2b_00 cmdosaoemcmdhandler legacy_admission_only local special handler">
<td class="p-2 text-xs">69</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xcc<br />
prefix 5e 2b 00</td>
<td class="p-2 min-w-72"><strong>XCCCmdOSAOEMCmdHandler_2E_CC_5E_2B_00</strong><br />
legacy_admission_only · privilege 2
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdOSAOEMCmdHandler<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 5}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_2e_ff avocent_ipmi_command_proc legacy_wildcard legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">70</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x2e/0xff<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_2E_FF</strong><br />
legacy_wildcard · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_50 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">71</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x50<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_50</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_51 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">72</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x51<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_51</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_52 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">73</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x52<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_52</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_60 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">74</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x60<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_60</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_62 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">75</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x62<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_62</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_63 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">76</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x63<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_63</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_67 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">77</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x67<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_67</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_68 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">78</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x68<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_68</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_6a avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">79</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x6a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_6A</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_72 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">80</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x72<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_72</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_73 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">81</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x73<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_73</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_74 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">82</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x74<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_74</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_75 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">83</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0x75<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_75</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_30_e9 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">84</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0xe9<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_30_E9</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdoemgetactivesession_34_b0 cmdoemgetactivesession legacy_admission_only local special handler">
<td class="p-2 text-xs">85</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x34/0xb0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdOEMGetActiveSession_34_B0</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdOEMGetActiveSession<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdoemdelactivesession_34_b1 cmdoemdelactivesession legacy_admission_only local special handler">
<td class="p-2 text-xs">86</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x34/0xb1<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdOEMDelActiveSession_34_B1</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdOEMDelActiveSession<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_00 system_controller::get_firmware_version(system_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">87</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x00<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_00</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">system_controller::get_firmware_version(system_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>firmware version</strong> [base]: 0 or 1 byte; optional selector 00 or 01 → 2 bytes for empty request; 3 bytes when selector is present; major, minor, then 00; CC c7 length; c9 selector</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_01 system_controller::get_bmc_slave_addr(system_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">88</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x01<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_01</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">system_controller::get_bmc_slave_addr(system_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BMC slave address</strong> [base]: empty → 1 byte; configured address or 20 when property is absent; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_02 system_controller::set_bmc_slave_addr(system_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">89</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x02<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_02</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">system_controller::set_bmc_slave_addr(system_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>set BMC slave address</strong> [base]: exactly 1 byte; address bit 0 must be clear → empty; CC c7 length; c9 odd address</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdsetsessionlesschannelprivilege_3a_03 cmdsetsessionlesschannelprivilege legacy_admission_only local special handler">
<td class="p-2 text-xs">90</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x03<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdSetSessionLessChannelPrivilege_3A_03</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdSetSessionLessChannelPrivilege<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdgetsessionlesschannelprivilege_3a_04 cmdgetsessionlesschannelprivilege legacy_admission_only local special handler">
<td class="p-2 text-xs">91</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x04<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdGetSessionLessChannelPrivilege_3A_04</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdGetSessionLessChannelPrivilege<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccthermal_3a_06 common_thermal_manager::debug_thermal(common_thermal_manager*, ipmi_message*) cpp_registration thermal, fan and power-limit services">
<td class="p-2 text-xs">92</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x06<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCThermal_3A_06</strong><br />
cpp_registration · privilege 2
<p>thermal, fan and power-limit services</p></td>
<td class="p-2 min-w-80 text-xs">common_thermal_manager::debug_thermal(common_thermal_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>thermal debug/control</strong> [00..03,80,c0,c1]: first byte selector: 00..03 enable debug families, 80 loads algorithm, c0 gets/sets TGP with total length 2/4, c1 gets/sets EDPP with total length 2/3 → selector-dependent thermal values or empty; CC ca selector-specific length; cc missing selector</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccthermal_3a_07 common_thermal_manager::set_fan_speed(common_thermal_manager*, ipmi_message*) cpp_registration thermal, fan and power-limit services">
<td class="p-2 text-xs">93</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x07<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCThermal_3A_07</strong><br />
cpp_registration · privilege 2
<p>thermal, fan and power-limit services</p></td>
<td class="p-2 min-w-80 text-xs">common_thermal_manager::set_fan_speed(common_thermal_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>fan speed override</strong> [base]: empty lists current PWM for every fan; 3..8 byte body sets or queries override tuple (fan, zone, selector, optional 16-bit bounds and mode) → empty request: one PWM byte per fan; sentinel query returns 5-byte override record; set returns empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccled_3a_08 led_controller::led_request(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">94</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x08<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLed_3A_08</strong><br />
cpp_registration · privilege 2
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_request(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>LED request</strong> [base]: 2 bytes select request-LED index; 3 bytes select 16-bit big-endian LED id; delegated device body → delegated LED-specific response; CC c7 length; c9 id; cb unavailable; d5 LED test active</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcciomodules_3a_09 i2c_bus_tester::i2c_bus_test(i2c_bus_tester*, ipmi_message*) cpp_registration planar and shared hardware modules; platform i/o">
<td class="p-2 text-xs">95</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x09<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCIoModules_3A_09</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules; platform I/O</p></td>
<td class="p-2 min-w-80 text-xs">i2c_bus_tester::i2c_bus_test(i2c_bus_tester*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>I2C bus test</strong> [base]: empty runs static tests and returns one result byte per configured test; nonempty body begins bus/test selector and response length followed by transaction bytes → static-test vector or transaction response bytes; CC c7 malformed one-byte body; d2 port unavailable; d3 test failure; d4 disabled; d5 unknown test</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccled_3a_0a led_controller::led_test(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">96</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x0a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLed_3A_0A</strong><br />
cpp_registration · privilege None
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_test(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> []<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>LED test</strong> [base]: exactly 1 delegated test byte → empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_0b planar_controller::vpd_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">97</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x0b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_0B</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::vpd_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPD read</strong> [base]: 16-bit little-endian offset, VPD device id, 1-byte length → requested raw VPD bytes; CC c9 range; cb absent/read failure; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_0c planar_controller::vpd_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">98</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x0c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_0C</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::vpd_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPD write</strong> [base]: 16-bit little-endian offset, VPD device id, data → empty; CC c9 range; cb absent; d5 unavailable; 80 write protected</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_0d board_info_device::get_board_info(board_info_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">99</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x0d<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_0D</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">board_info_device::get_board_info(board_info_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>board information</strong> [base]: empty → 2 bytes: system revision and board level; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccled_3a_0e led_controller::led_lit_count(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">100</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x0e<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLed_3A_0E</strong><br />
cpp_registration · privilege None
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_lit_count(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> []<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>lit LED count</strong> [base]: 2-byte LED id → delegated device-specific count response; exact bytes unknown; CC c7 length; c9 unknown LED; cb unavailable LED</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_3a_10 bios_device::ipmi_uefi_performance(bios_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">101</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x10<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_3A_10</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">bios_device::ipmi_uefi_performance(bios_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>ipmi uefi performance</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_13 system_controller::deactivate_userid(system_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">102</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x13<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_13</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">system_controller::deactivate_userid(system_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>deactivate USERID</strong> [base]: empty → empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_14 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">103</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x14<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_14</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_3a_15 bios_device::ipmi_media_control(bios_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">104</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x15<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_3A_15</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">bios_device::ipmi_media_control(bios_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BIOS media control</strong> [01..04]: three-byte header selects media family, operation, and flags; selectors 01..04 provide inventory/configuration, mount/unmount and status operations with variable strings → selector-dependent status, media records, or command output; CC c7 framing; c9 fields; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsensors_3a_17 sensor_test_device::ipmi_sensor_test_control(sensor_test_device*, ipmi_message*) cpp_registration sensor test and control">
<td class="p-2 text-xs">105</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x17<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSensors_3A_17</strong><br />
cpp_registration · privilege 2
<p>sensor test and control</p></td>
<td class="p-2 min-w-80 text-xs">sensor_test_device::ipmi_sensor_test_control(sensor_test_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>sensor-test control</strong> [00..0d]: first byte operation: 00 begin, 01 set reading, 02 end, 03 version, 04 state, 05 scan off, 06 scan on, 07 scan status, 08 reconnect, 09 poll, 0b last closed, 0c current session, 0d counts; trailing body is operation-specific → operation-specific; CC c1 selector; c7 missing selector; d5 invalid for current session/channel</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccreset_3a_19 smi_device::ipmi_smi_state(smi_device*, ipmi_message*) cpp_registration virtual reset and reseat services">
<td class="p-2 text-xs">106</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x19<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCReset_3A_19</strong><br />
cpp_registration · privilege 2
<p>virtual reset and reseat services</p></td>
<td class="p-2 min-w-80 text-xs">smi_device::ipmi_smi_state(smi_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMI queued-state read</strong> [base]: empty → 1 byte dequeued state; empty queue produces one default byte; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccreset_3a_1a smi_device::ipmi_smi_enable(smi_device*, ipmi_message*) cpp_registration virtual reset and reseat services">
<td class="p-2 text-xs">107</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCReset_3A_1A</strong><br />
cpp_registration · privilege 2
<p>virtual reset and reseat services</p></td>
<td class="p-2 min-w-80 text-xs">smi_device::ipmi_smi_enable(smi_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMI enable/configure</strong> [base]: empty gets state; 1 byte enables/disables; 2-byte big-endian nonzero value enables with periodic interval → get returns 1 byte; set returns empty; CC c7 length; c9 zero interval; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccreset_3a_1b smi_device::smi_timeout_action(smi_device*, ipmi_message*) cpp_registration virtual reset and reseat services">
<td class="p-2 text-xs">108</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCReset_3A_1B</strong><br />
cpp_registration · privilege 2
<p>virtual reset and reseat services</p></td>
<td class="p-2 min-w-80 text-xs">smi_device::smi_timeout_action(smi_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMI timeout action</strong> [00..07]: selector 00..07; selector 01 additionally takes 16-bit little-endian timeout &gt;=31; others are operation-specific → selector 00 returns 2 bytes; 02/05 return 1 byte; others empty; CC c7 framing; c9 timeout; ce selector; d2 port unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccrecovery_3a_1c arr_device::ipmi_arr_control(arr_device*, ipmi_message*) cpp_registration imm, secure-update and root-of-trust recovery">
<td class="p-2 text-xs">109</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCRecovery_3A_1C</strong><br />
cpp_registration · privilege 2
<p>IMM, secure-update and root-of-trust recovery</p></td>
<td class="p-2 min-w-80 text-xs">arr_device::ipmi_arr_control(arr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>automated recovery control</strong> [00..07]: 1..5 bytes; primary selector 00..07 and secondary operation control timeout, start/stop/restart helpers, configuration strings, status and counters → selector-dependent timeout, string, status or empty response; CC c7 length; c9 field; cc selector</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_1d sys_pwr_device::get_set_acpi_state(sys_pwr_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">110</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1d<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_1D</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">sys_pwr_device::get_set_acpi_state(sys_pwr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>ACPI state get</strong> [01]: selector with low nibble 01 → 1-byte ACPI state; CC c7 length; d5 state unavailable<br />
<strong>ACPI state set</strong> [00]: selector with low nibble 00 followed by state 00..04 → empty; CC c1 platform gate; c7 length; cc selector/state/transition</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_1e sys_pwr_device::get_set_ac_restore_options(sys_pwr_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">111</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x1e<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_1E</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">sys_pwr_device::get_set_ac_restore_options(sys_pwr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>AC restore options get</strong> [01]: selector with low nibble 01 → 1-byte restore-options state; CC c1 unsupported platform; c7 length<br />
<strong>AC restore options set</strong> [00]: selector with low nibble 00 followed by options byte; only bit 0 may be set → empty; CC c1 unsupported platform; c7 length; cc reserved bits</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccpu_3a_20 cpu_controller::set_tcontrol(cpu_controller*, ipmi_message*) cpp_registration cpu management">
<td class="p-2 text-xs">112</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x20<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCpu_3A_20</strong><br />
cpp_registration · privilege 2
<p>CPU management</p></td>
<td class="p-2 min-w-80 text-xs">cpu_controller::set_tcontrol(cpu_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>CPU T-control set</strong> [base]: exactly 2 bytes: control value and CPU/target value → empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_21 enm_logical_device::enm_ipmi_cmd(enm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">113</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x21<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_21</strong><br />
cpp_registration · privilege 4
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">enm_logical_device::enm_ipmi_cmd(enm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>enm ipmi cmd</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_22 bmc_authen_device::mfg_config(bmc_authen_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">114</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x22<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_22</strong><br />
cpp_registration · privilege 4
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">bmc_authen_device::mfg_config(bmc_authen_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>manufacturing configuration</strong> [01..0a]: selector plus operation/body; covers manufacturing flags, files, string blobs, platform modes and readback; selectors 01..0a → selector-dependent status/blob; CC c7 length; cc selector/body; ff backend failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_2a avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">115</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x2a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_2A</strong><br />
legacy_admission_only · privilege 4
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcciomodules_3a_2b i2c_bus_tester::pcie_slot_i2c_master_read_write(i2c_bus_tester*, ipmi_message*) cpp_registration planar and shared hardware modules; platform i/o">
<td class="p-2 text-xs">116</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x2b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCIoModules_3A_2B</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules; platform I/O</p></td>
<td class="p-2 min-w-80 text-xs">i2c_bus_tester::pcie_slot_i2c_master_read_write(i2c_bus_tester*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>PCIe-slot I2C transfer</strong> [base]: at least 3 bytes: slot selector, read length, then write bytes; remaining bytes after first two are sent to the configured slot bus → requested read bytes; CC c7 short request; cc slot disabled; d3 transaction failure; d5 unknown slot</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_30 amm_logical_device::query_chassis_info(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">117</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x30<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_30</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::query_chassis_info(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>chassis information</strong> [base]: empty → 1 byte: ec; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_31 bmc_therm_history_logical_device::get_realtime_thermal_data(bmc_therm_history_logical_device*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">118</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x31<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_31</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">bmc_therm_history_logical_device::get_realtime_thermal_data(bmc_therm_history_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>real-time thermal data format 1</strong> [base]: empty or selector 01 → 108 bytes: 8-byte fixed prefix, 96 sensor bytes, two 16-bit trailers; CC c7 length/selector<br />
<strong>real-time thermal data format 2</strong> [02]: selector 02 → 144 bytes: 4-byte format header, 8-byte fixed prefix, 128 sensor bytes, two 16-bit trailers; CC c7 length/selector</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccorepower_3a_32 power_apml_logical_device::pwrmgt_oemcmd_handle(power_apml_logical_device*, ipmi_message*) | zarkon_pwrmgt_logical_device::zarkon_pwrmgt_interface(zarkon_pwrmgt_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services; property database and core controller services">
<td class="p-2 text-xs">119</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x32<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCorePower_3A_32</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services; property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">power_apml_logical_device::pwrmgt_oemcmd_handle(power_apml_logical_device*, ipmi_message*) | zarkon_pwrmgt_logical_device::zarkon_pwrmgt_interface(zarkon_pwrmgt_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>power-management interface</strong> [01..06,09,ff]: first byte operation: 01 telemetry, 02 cap set, 03 cap get, 04 FPGA meter, 05 reserved, 06 settings, 09 platform utilization, ff debug; trailing fields delegated → selector-specific power records/status; CC handler-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpanel_3a_33 pong_lcd_fp_ldev::ipmi_function(pong_lcd_fp_ldev*, ipmi_message*) cpp_registration operator panel">
<td class="p-2 text-xs">120</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x33<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPanel_3A_33</strong><br />
cpp_registration · privilege 2
<p>operator panel</p></td>
<td class="p-2 min-w-80 text-xs">pong_lcd_fp_ldev::ipmi_function(pong_lcd_fp_ldev*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>front-panel development dump</strong> [0a]: first byte must be 0a; trailing bytes ignored → empty; CC cc selector</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_34 bmc_therm_history_logical_device::get_realtime_thermal_data_deluxe(bmc_therm_history_logical_device*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">121</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x34<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_34</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">bmc_therm_history_logical_device::get_realtime_thermal_data_deluxe(bmc_therm_history_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>deluxe thermal group</strong> [01..09,0b..0d]: 1-byte group selector; 0a is rejected → count byte followed by count pairs of sensor-id and reading; variable length; CC c9 selector; d6 no matching readings</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_37 sys_pwr_device::trigger_virtual_reseat(sys_pwr_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">122</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x37<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_37</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">sys_pwr_device::trigger_virtual_reseat(sys_pwr_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>virtual reseat</strong> [base]: handler ignores request body → empty; CC d5 port unavailable; ff thread/port failure</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccreset_3a_38 nmi_state_sensor::ibmcmd_nmi(nmi_state_sensor*, ipmi_message*) cpp_registration virtual reset and reseat services">
<td class="p-2 text-xs">123</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x38<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCReset_3A_38</strong><br />
cpp_registration · privilege 2
<p>virtual reset and reseat services</p></td>
<td class="p-2 min-w-80 text-xs">nmi_state_sensor::ibmcmd_nmi(nmi_state_sensor*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>NMI request</strong> [base]: 1 byte NMI source; optional second byte 00/01 controls follow-up state → empty; CC c7 length; cc flag</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_3a_39 bios_device::ac_decouple_control(bios_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">124</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x39<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_3A_39</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">bios_device::ac_decouple_control(bios_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>AC decouple control</strong> [01..82]: first byte operation; 01..0a/0c and broad 10..80 range are reads, 02/0b/0d..0f/81 are writes, 82 returns internal status; exact operation-specific fields vary → operation-specific configuration/status blobs; CC c7 length; cc selector/body; d5 unavailable; ff backend failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_49 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">125</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x49<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_49</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_4a avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">126</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_4A</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_3a_4b debug_logical_device::set_logging_flags(debug_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">127</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLogging_3A_4B</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">debug_logical_device::set_logging_flags(debug_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>logging flags get/set</strong> [base]: get: 1-byte facility index 00..1b; set: facility 00..1b or ff plus 32-bit flags → get: platform ulong flags; set: empty; CC c7 length; c9 facility</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_3a_4c debug_logical_device::debug_cmd(debug_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">128</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLogging_3A_4C</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">debug_logical_device::debug_cmd(debug_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>debug cmd</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_4d avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">129</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4d<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_4D</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccilma_3a_4e ilma_device::config_bootpart(ilma_device*, ipmi_message*) cpp_registration ilma platform management">
<td class="p-2 text-xs">130</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4e<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCIlma_3A_4E</strong><br />
cpp_registration · privilege 2
<p>ILMA platform management</p></td>
<td class="p-2 min-w-80 text-xs">ilma_device::config_bootpart(ilma_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>boot partition get</strong> [00]: operation 00; total request shorter than 3 bytes → 1-byte active IMM bank; CC c7 length; cc operation/bank<br />
<strong>boot partition set</strong> [01 or 02]: operation 01/02 followed by bank 02/03; operation 02 additionally invokes platform activation helper → empty; CC c7 length; cc operation/bank</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccilma_3a_4f ilma_device::shutdown_bmc(ilma_device*, ipmi_message*) cpp_registration ilma platform management">
<td class="p-2 text-xs">131</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x4f<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCIlma_3A_4F</strong><br />
cpp_registration · privilege 2
<p>ILMA platform management</p></td>
<td class="p-2 min-w-80 text-xs">ilma_device::shutdown_bmc(ilma_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BMC shutdown</strong> [base]: mode 00 or 01; handler accepts total length below 3 → empty; CC c7 length; cc mode</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_50 board_info_device::query_build_info(board_info_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">132</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x50<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_50</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">board_info_device::query_build_info(board_info_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>build information</strong> [base]: empty → three stored build-information fields; handler requires at least 31 response-buffer bytes; field framing unresolved; CC ce response buffer too small</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccreset_3a_51 reset_cause_logical_device::reset_cause_cmd(reset_cause_logical_device*, ipmi_message*) cpp_registration virtual reset and reseat services">
<td class="p-2 text-xs">133</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x51<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCReset_3A_51</strong><br />
cpp_registration · privilege 2
<p>virtual reset and reseat services</p></td>
<td class="p-2 min-w-80 text-xs">reset_cause_logical_device::reset_cause_cmd(reset_cause_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>reset cause</strong> [base]: handler consumes no request body → reset-cause byte, auxiliary byte, then optional reset-cause string capped at 16 bytes; CC ce primary property unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpldm_3a_52 pldm_alert_device::ipmi_pldm_debug(pldm_alert_device*, ipmi_message*) cpp_registration pldm bridge">
<td class="p-2 text-xs">134</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x52<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPldm_3A_52</strong><br />
cpp_registration · privilege 2
<p>PLDM bridge</p></td>
<td class="p-2 min-w-80 text-xs">pldm_alert_device::ipmi_pldm_debug(pldm_alert_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>ipmi pldm debug</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccstorage_3a_53 raidlink_logical_device::raid_event_handler(raidlink_logical_device*, ipmi_message*) cpp_registration storage management">
<td class="p-2 text-xs">135</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x53<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCStorage_3A_53</strong><br />
cpp_registration · privilege 2
<p>storage management</p></td>
<td class="p-2 min-w-80 text-xs">raidlink_logical_device::raid_event_handler(raidlink_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>raid event handler</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpldm_3a_54 monterey_logical_device::monterey_oem_ipmi_handler(monterey_logical_device*, ipmi_message*) cpp_registration pldm bridge">
<td class="p-2 text-xs">136</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x54<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPldm_3A_54</strong><br />
cpp_registration · privilege 2
<p>PLDM bridge</p></td>
<td class="p-2 min-w-80 text-xs">monterey_logical_device::monterey_oem_ipmi_handler(monterey_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>monterey oem ipmi handler</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_55 system_controller::hostname_cmd(system_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">137</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x55<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_55</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">system_controller::hostname_cmd(system_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>host name get/set</strong> [base]: empty gets; 1..64 bytes set the host name → get returns the nonempty host name, including its terminating newline when present; set returns empty; CC c7 length or set failure; ce get failure</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_3a_56 debug_logical_device::perf_metrics_cmd(debug_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">138</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x56<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLogging_3A_56</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">debug_logical_device::perf_metrics_cmd(debug_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>performance-metrics state get</strong> [00]: exactly 1 byte 00 → 1 byte current enable state; CC c7 length<br />
<strong>performance-metrics state set</strong> [01]: exactly 2 bytes: 01 and state → empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_57 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">139</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x57<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_57</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_3a_58 virtual_gpio_logical_device::vpdd_smbios_update(virtual_gpio_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">140</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x58<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLogging_3A_58</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">virtual_gpio_logical_device::vpdd_smbios_update(virtual_gpio_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPDD SMBIOS update notification</strong> [base]: handler ignores request body → empty; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccflash_3a_59 syncrep_device::syncrep_op(syncrep_device*, ipmi_message*) cpp_registration flash, wipe, credential and replication services">
<td class="p-2 text-xs">141</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x59<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFlash_3A_59</strong><br />
cpp_registration · privilege 2
<p>flash, wipe, credential and replication services</p></td>
<td class="p-2 min-w-80 text-xs">syncrep_device::syncrep_op(syncrep_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>syncrep op</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccflash_3a_5a syncrep_device::syncrep_init(syncrep_device*, ipmi_message*) cpp_registration flash, wipe, credential and replication services">
<td class="p-2 text-xs">142</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x5a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFlash_3A_5A</strong><br />
cpp_registration · privilege 2
<p>flash, wipe, credential and replication services</p></td>
<td class="p-2 min-w-80 text-xs">syncrep_device::syncrep_init(syncrep_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>syncrep init</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccinventory_3a_5c syslock_device::syslock_cmd(syslock_device*, ipmi_message*) cpp_registration platform inventory">
<td class="p-2 text-xs">143</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x5c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCInventory_3A_5C</strong><br />
cpp_registration · privilege 2
<p>platform inventory</p></td>
<td class="p-2 min-w-80 text-xs">syslock_device::syslock_cmd(syslock_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>syslock cmd</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_60 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">144</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x60<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_60</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_62 planar_controller::lock_vpd_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">145</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x62<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_62</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::lock_vpd_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VPD lock</strong> [00,01]: one-byte body 00 unlocks or 01 locks for caller channel; OEM alias form may include IANA d0 51 00 before selector → OEM form echoes three IANA bytes; otherwise empty; CC c1 IANA; c9 selector; d5 lock unavailable/owned</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_63 planar_controller::mac_cmd(planar_controller*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">146</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x63<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_63</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">planar_controller::mac_cmd(planar_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>system MAC read/write</strong> [base]: empty reads entry 1; 1-byte selector 01..05 reads selected 6-byte MAC; 6-byte body writes entry 1; 7-byte body starts with selector 01..05 then writes 6-byte MAC → read returns 6 bytes; write returns empty; CC cc selector; ce storage read/write failure</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_64 bmc_authen_device::private_account_request(bmc_authen_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">147</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x64<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_64</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">bmc_authen_device::private_account_request(bmc_authen_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>private account enable/query</strong> [00 or empty]: empty or 00; system-interface channel only → 4 bytes: two bytes and one 16-bit value; CC c7 length; c1 selector; d5 non-system channel<br />
<strong>private account disable</strong> [01]: 01; system-interface channel only → empty; CC c7 length; d5 non-system channel</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_65 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">148</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x65<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_65</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_66 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">149</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x66<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_66</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_67 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">150</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x67<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_67</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_69 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">151</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x69<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_69</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_6a avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">152</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_6A</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 12}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccfpga_3a_6b fpga_logical_device::oem_read_fpga_rev_cmd(fpga_logical_device*, ipmi_message*) cpp_registration fpga register and revision services">
<td class="p-2 text-xs">153</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFpga_3A_6B</strong><br />
cpp_registration · privilege 2
<p>FPGA register and revision services</p></td>
<td class="p-2 min-w-80 text-xs">fpga_logical_device::oem_read_fpga_rev_cmd(fpga_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPGA revision, local default</strong> [base]: empty → 3 revision bytes; CC d2 FPGA unavailable; ce read failure<br />
<strong>FPGA revision by target</strong> [00..07]: 1-byte target selector 00..07 → 3 revision bytes; CC c7 length; cc selector; cb target absent; d2 FPGA unavailable; ce read failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfpga_3a_6c fpga_logical_device::oem_get_hardware_rev_cmd(fpga_logical_device*, ipmi_message*) cpp_registration fpga register and revision services">
<td class="p-2 text-xs">154</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFpga_3A_6C</strong><br />
cpp_registration · privilege 2
<p>FPGA register and revision services</p></td>
<td class="p-2 min-w-80 text-xs">fpga_logical_device::oem_get_hardware_rev_cmd(fpga_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPGA hardware revision</strong> [base]: empty → 1 byte hardware revision; CC c7 length; ce FPGA read failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpsoc_3a_6d psoc_logical_device::oem_read_psoc_rev_cmd(psoc_logical_device*, ipmi_message*) cpp_registration psoc management">
<td class="p-2 text-xs">155</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6d<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPsoc_3A_6D</strong><br />
cpp_registration · privilege 2
<p>PSoC management</p></td>
<td class="p-2 min-w-80 text-xs">psoc_logical_device::oem_read_psoc_rev_cmd(psoc_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>PSOC revision inventory</strong> [base]: empty; handler has no local length check → 5 bytes per active PSOC: three bytes then one 16-bit value; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccrecovery_3a_6e pfr_logical_device::pfr_cmd(pfr_logical_device*, ipmi_message*) cpp_registration imm, secure-update and root-of-trust recovery">
<td class="p-2 text-xs">156</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x6e<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCRecovery_3A_6E</strong><br />
cpp_registration · privilege 2
<p>IMM, secure-update and root-of-trust recovery</p></td>
<td class="p-2 min-w-80 text-xs">pfr_logical_device::pfr_cmd(pfr_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>pfr cmd</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_70 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">157</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x70<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_70</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_71 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">158</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x71<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_71</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_72 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">159</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x72<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_72</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_73 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">160</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x73<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_73</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_74 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">161</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x74<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_74</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_75 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">162</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x75<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_75</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_77 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">163</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x77<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_77</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_78 aaa_device::configure_eddc(aaa_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">164</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x78<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_78</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">aaa_device::configure_eddc(aaa_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>EDDC configuration</strong> [00]: 00 plus enable byte; exactly 2 bytes → empty; CC c7 length; ff file creation failure<br />
<strong>EDDC event</strong> [01]: 01, event id, two 32-bit values; exactly 10 bytes → empty; CC c7 length; c9 selector</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_79 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">165</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x79<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_79</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccflash_3a_7a bmu_device::ipmi_bmu_app_ready(bmu_device*, ipmi_message*) cpp_registration flash, wipe, credential and replication services">
<td class="p-2 text-xs">166</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x7a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFlash_3A_7A</strong><br />
cpp_registration · privilege 2
<p>flash, wipe, credential and replication services</p></td>
<td class="p-2 min-w-80 text-xs">bmu_device::ipmi_bmu_app_ready(bmu_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BMU application-ready get</strong> [00]: 00 → 1 byte current ready value; CC c7 length; cc selector<br />
<strong>BMU application-ready set</strong> [01]: 01 value → empty; CC c7 length; cc selector</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccflash_3a_7b bmu_device::ipmi_get_bmu_cred(bmu_device*, ipmi_message*) cpp_registration flash, wipe, credential and replication services">
<td class="p-2 text-xs">167</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x7b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFlash_3A_7B</strong><br />
cpp_registration · privilege 2
<p>flash, wipe, credential and replication services</p></td>
<td class="p-2 min-w-80 text-xs">bmu_device::ipmi_get_bmu_cred(bmu_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BMU credentials get</strong> [base]: empty; system-interface channel only → two stored credential strings; wire string framing not yet decoded; CC d5 non-system channel<br />
<strong>BMU credentials set</strong> [variable]: two length-delimited strings; total at least 4 bytes; system-interface channel only → empty; CC c7 malformed; d5 non-system channel</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_3a_7c ipmi::config_remote_pp(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">168</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x7c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_3A_7C</strong><br />
cpp_registration · privilege None
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::config_remote_pp(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> []<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>remote physical-presence configuration</strong> [base]: UEFI-interface only; empty gets two configuration bytes, 2-byte body sets them → get: 2 bytes; set: empty; CC c1 non-UEFI channel; c7 length; ff configuration backend failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccbmcemerson_3a_7d ipmi::assert_remote_pp(ipmi_manager*, ipmi_message*) cpp_registration bmc core, firmware and physical-presence services">
<td class="p-2 text-xs">169</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x7d<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCBmcEmerson_3A_7D</strong><br />
cpp_registration · privilege None
<p>BMC core, firmware and physical-presence services</p></td>
<td class="p-2 min-w-80 text-xs">IPMI::assert_remote_pp(ipmi_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> []<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>remote physical-presence assertion</strong> [base]: empty gets assertion state; 1-byte value 00/01 asserts event on an allowed interface → get: 1 byte; set: empty; CC c1 channel; c7 length; c9 value; d5 disabled; ff backend failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_7e next_boot_device::ipmi_next_boot_handler(next_boot_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">170</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x7e<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_7E</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">next_boot_device::ipmi_next_boot_handler(next_boot_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>next-boot record get/set</strong> [base]: empty gets; exactly 3 bytes set a 16-bit big-endian value and one flag → get returns the same 3-byte record; set returns empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_3a_7f uefi_progress_device::pcie_mbox_control(uefi_progress_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">171</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x7f<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_3A_7F</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">uefi_progress_device::pcie_mbox_control(uefi_progress_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>PCIe mailbox control</strong> [base]: exactly 1 flag byte; bits 0..2 select mailbox/file shared-memory operations → operation-specific status including 32-bit little-endian value; CC ca length; ce shared-memory failure; d4 platform gate; d6 operation failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdoemgetsolconfiguration_3a_88 cmdoemgetsolconfiguration legacy_admission_only local special handler">
<td class="p-2 text-xs">172</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x88<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdOemGetSOLConfiguration_3A_88</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdOemGetSOLConfiguration<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdoemsetsolconfiguration_3a_89 cmdoemsetsolconfiguration legacy_admission_only local special handler">
<td class="p-2 text-xs">173</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x89<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdOemSetSOLConfiguration_3A_89</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdOemSetSOLConfiguration<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccfpga_3a_90 fpga_logical_device::oem_read_fpga_data_cmd(fpga_logical_device*, ipmi_message*) | scm_fpga_logical_device::oem_read_fpga_data_cmd(scm_fpga_logical_device*, ipmi_message*) cpp_registration fpga register and revision services">
<td class="p-2 text-xs">174</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x90<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFpga_3A_90</strong><br />
cpp_registration · privilege 2
<p>FPGA register and revision services</p></td>
<td class="p-2 min-w-80 text-xs">fpga_logical_device::oem_read_fpga_data_cmd(fpga_logical_device*, ipmi_message*) | scm_fpga_logical_device::oem_read_fpga_data_cmd(scm_fpga_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>local FPGA data read</strong> [base]: normal: 16-bit selector plus 1-byte length (01..10); selector bits 11:4 are register byte, bits 3:0 block, bit 14 clear; ADI: selector with bit 14 set plus 16-bit offset → normal: requested 1..16 bytes; ADI: 16 bytes; CC c7 framing/length; ce FPGA read failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfpga_3a_91 fpga_logical_device::oem_write_fpga_data_cmd(fpga_logical_device*, ipmi_message*) | scm_fpga_logical_device::oem_write_fpga_data_cmd(scm_fpga_logical_device*, ipmi_message*) cpp_registration fpga register and revision services">
<td class="p-2 text-xs">175</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x91<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFpga_3A_91</strong><br />
cpp_registration · privilege 2
<p>FPGA register and revision services</p></td>
<td class="p-2 min-w-80 text-xs">fpga_logical_device::oem_write_fpga_data_cmd(fpga_logical_device*, ipmi_message*) | scm_fpga_logical_device::oem_write_fpga_data_cmd(scm_fpga_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>local FPGA data write</strong> [base]: 16-bit selector, 1-byte length 00..10, then exactly that many bytes; selector bits 11:4 register, bits 3:0 block, bit 14 selects ADI → empty; CC c7 framing; c8 length above 16; ce FPGA failure; d5 protected register/channel combination</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfpga_3a_92 fpga_logical_device::oem_read_fpga_data_cmd(fpga_logical_device*, ipmi_message*) | fpga_logical_device::oem_read_remote_fpga_data_cmd(fpga_logical_device*, ipmi_message*) cpp_registration fpga register and revision services">
<td class="p-2 text-xs">176</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x92<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFpga_3A_92</strong><br />
cpp_registration · privilege 2
<p>FPGA register and revision services</p></td>
<td class="p-2 min-w-80 text-xs">fpga_logical_device::oem_read_fpga_data_cmd(fpga_logical_device*, ipmi_message*) | fpga_logical_device::oem_read_remote_fpga_data_cmd(fpga_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>remote FPGA data read</strong> [base]: 1-byte one-based remote target, 16-bit selector, 1-byte length (01..10); selector bits 11:4 are register byte, bits 3:0 block; bit 14 selects ADI → requested 1..16 bytes; CC c7 framing/length; cb remote target absent; ce FPGA read failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccfpga_3a_93 fpga_logical_device::oem_write_fpga_data_cmd(fpga_logical_device*, ipmi_message*) cpp_registration fpga register and revision services">
<td class="p-2 text-xs">177</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x93<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCFpga_3A_93</strong><br />
cpp_registration · privilege 2
<p>FPGA register and revision services</p></td>
<td class="p-2 min-w-80 text-xs">fpga_logical_device::oem_write_fpga_data_cmd(fpga_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>remote/platform FPGA data write alias</strong> [base]: 16-bit selector, 1-byte length 00..10, then exactly that many bytes; selector bit 14 selects ADI → empty; CC c7 framing; c8 length above 16; ce FPGA failure; d5 protected register/channel combination</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccmdoemmasterwriteread_3a_94 cmdoemmasterwriteread legacy_admission_only local special handler">
<td class="p-2 text-xs">178</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x94<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCmdOEMMasterWriteRead_3A_94</strong><br />
legacy_admission_only · privilege 2
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">CmdOEMMasterWriteRead<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 3}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_95 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">179</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x95<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_95</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_96 me_logical_device::me_update_cmd(me_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">180</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x96<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_96</strong><br />
cpp_registration · privilege 4
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">me_logical_device::me_update_cmd(me_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>management-engine update control</strong> [base]: first two bytes select target and operation; optional third byte; selectors query/update ME state through device-specific ports → selector-dependent one-byte status or empty; CC c1 unsupported selector/target; c7 short request</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_97 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">181</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x97<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_97</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccpanel_3a_98 fp_usb_port_ldev::fp_usb_port_control(fp_usb_port_ldev*, ipmi_message*) cpp_registration operator panel">
<td class="p-2 text-xs">182</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x98<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPanel_3A_98</strong><br />
cpp_registration · privilege 2
<p>operator panel</p></td>
<td class="p-2 min-w-80 text-xs">fp_usb_port_ldev::fp_usb_port_control(fp_usb_port_ldev*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>front-panel USB control</strong> [01..06]: selector 01 status, 02 configuration, 03 set configuration, 04 attach/detach, 05 service toggle, 06 property status; selector-specific trailing fields → selector 01/06: 1 byte; 02: configuration record; mutating selectors usually empty; CC c7 missing/short body; c9 selector; d5 state; d6 unsupported platform</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_3a_99 bios_device::ipmi_usb_reset(bios_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">183</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x99<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_3A_99</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">bios_device::ipmi_usb_reset(bios_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BIOS USB reset</strong> [base]: 1-byte mode 00 or 01 → empty; CC c9 mode</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_9a board_info_device::retimer_control(board_info_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">184</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9a<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_9A</strong><br />
cpp_registration · privilege 4
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">board_info_device::retimer_control(board_info_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>retimer control</strong> [00]: operation 00 followed by state 00 or 01; total length below 3 → empty; CC c7 length; cc operation/state</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccnicstatuswr_3a_9b nicstatuswr legacy_admission_only local special handler">
<td class="p-2 text-xs">185</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9b<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCNICStatusWR_3A_9B</strong><br />
legacy_admission_only · privilege 4
<p>Local special handler</p></td>
<td class="p-2 min-w-80 text-xs">NICStatusWR<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xcclegolandhv_3a_9c hv_planar_logical_device::fpga_fast_throttle_callback(hv_planar_logical_device*, ipmi_message*) cpp_registration legoland hypervisor integration">
<td class="p-2 text-xs">186</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0x9c<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLegolandHv_3A_9C</strong><br />
cpp_registration · privilege 2
<p>Legoland hypervisor integration</p></td>
<td class="p-2 min-w-80 text-xs">hv_planar_logical_device::fpga_fast_throttle_callback(hv_planar_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>FPGA fast-throttle control</strong> [00,01]: 00 plus enable byte 00/01 sets state; 01 gets current FPGA state → get returns 2-byte state value; set returns empty; CC c9 missing/invalid selector</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpanel_3a_a3 front_panel_button_disable_logical_device::fp_button_power_permission(front_panel_button_disable_logical_device*, ipmi_message*) cpp_registration operator panel">
<td class="p-2 text-xs">187</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xa3<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPanel_3A_A3</strong><br />
cpp_registration · privilege 2
<p>operator panel</p></td>
<td class="p-2 min-w-80 text-xs">front_panel_button_disable_logical_device::fp_button_power_permission(front_panel_button_disable_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>front-panel power-button permission</strong> [base]: empty gets two state bytes; 1-byte 00/01 sets primary permission; 2-byte 00/01 pair sets primary and disable state → get returns 2 bytes; set returns empty; CC c7 length; c9 value; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_a4 dp_logical_device::get_agentless_inventory_status(dp_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">188</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xa4<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_A4</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">dp_logical_device::get_agentless_inventory_status(dp_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>agentless inventory status</strong> [base]: empty → 9 status bytes; CC c7 length<br />
<strong>stop inventory refresh</strong> [any-byte]: any single byte → empty; CC c7 length; ff stop failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccpu_3a_a5 disable_cpu_device::cpu_instance_control(disable_cpu_device*, ipmi_message*) cpp_registration cpu management">
<td class="p-2 text-xs">189</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xa5<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCpu_3A_A5</strong><br />
cpp_registration · privilege 2
<p>CPU management</p></td>
<td class="p-2 min-w-80 text-xs">disable_cpu_device::cpu_instance_control(disable_cpu_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>CPU instance control</strong> [base]: empty returns two CPU availability/disabled masks; 2-byte body contains action 00/01 and a one-hot CPU mask → get: 2 mask bytes; set: empty; CC c7 length; c9 action/mask; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_a8 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">190</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xa8<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_A8</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccstorage_3a_aa rt_logical_device::ipmi_cmd_retimer_dbg_dump(rt_logical_device*, ipmi_message*) cpp_registration storage management">
<td class="p-2 text-xs">191</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xaa<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCStorage_3A_AA</strong><br />
cpp_registration · privilege 2
<p>storage management</p></td>
<td class="p-2 min-w-80 text-xs">rt_logical_device::ipmi_cmd_retimer_dbg_dump(rt_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>retimer debug dump</strong> [00..02]: 00 plus 3 bytes starts a dump and returns 2 status bytes; 01 alone returns 2 status bytes; 02 alone restarts retimer polling after dump → selector-dependent 2 status bytes or empty; CC c7 length; cc selector; d5 retimer unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_b0 network_configuration_logical_device::config_bmc_service(network_configuration_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">192</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xb0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_B0</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">network_configuration_logical_device::config_bmc_service(network_configuration_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BMC service state get</strong> [00]: 00 followed by service id; exactly 2 bytes → 1-byte service state; CC c7 length; backend completion code<br />
<strong>BMC service state set</strong> [01]: 01, service id, enable byte; exactly 3 bytes → empty; CC c7 length; d5 operation; backend completion code</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_b3 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">193</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xb3<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_B3</strong><br />
legacy_admission_only · privilege 4
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccled_3a_c0 led_controller::led_status(led_controller*, ipmi_message*) cpp_registration led control and status">
<td class="p-2 text-xs">194</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLed_3A_C0</strong><br />
cpp_registration · privilege 2
<p>LED control and status</p></td>
<td class="p-2 min-w-80 text-xs">led_controller::led_status(led_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>LED status</strong> [base]: 2-byte LED id → delegated device-specific status response; exact bytes unknown; CC c7 length; c9 unknown LED; cb unavailable LED</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_c1 board_info_device::get_bmc_cap(board_info_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">195</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc1<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_C1</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">board_info_device::get_bmc_cap(board_info_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BMC capabilities</strong> [base]: empty → 3 capability bytes; CC c7 length; c1 capabilities unset</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_c2 board_info_device::set_bios_cap(board_info_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">196</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc2<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_C2</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">board_info_device::set_bios_cap(board_info_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 2}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BIOS capability set</strong> [base]: exactly 2 capability bytes → empty; CC c7 length</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccsysfw_3a_c3 bios_device::ipmi_bios_state(bios_device*, ipmi_message*) cpp_registration bios, uefi, media and pcie mailbox services">
<td class="p-2 text-xs">197</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc3<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCSysfw_3A_C3</strong><br />
cpp_registration · privilege 2
<p>BIOS, UEFI, media and PCIe mailbox services</p></td>
<td class="p-2 min-w-80 text-xs">bios_device::ipmi_bios_state(bios_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>BIOS state/progress</strong> [00,01,10]: 00 returns one cached BIOS-state byte; 01 plus progress byte posts a UEFI progress code; 10 triggers MCTP rediscovery; total length 1 or 2 → selector 00 returns 1 byte; others empty; CC c7 length; c9 selector/progress</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_c4 properties_device::property_cmd(properties_device*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">198</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc4<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_C4</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">properties_device::property_cmd(properties_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>property get</strong> [00]: 00, 16-bit payload length, TLV string property path → missing: 03 00; found: 00, 16-bit value length, value TLV; CC c7 framing; cc subselector; d5 operation<br />
<strong>property get-multiple bundling</strong> [01]: 01, 16-bit payload length, subselector 00, delegated body → delegated bundled property records; CC c7 framing; cc subselector; d5 operation<br />
<strong>property get-multiple all</strong> [02]: 02, 16-bit payload length, subselector 00 or 01, delegated body → delegated property records; CC c7 framing; cc subselector; d5 operation<br />
<strong>property add</strong> [03]: 03, 16-bit payload length, property type 00..03, encoded property → 2 status bytes; CC c7 framing; cc type; d5 operation<br />
<strong>property set-multiple bundling</strong> [04]: 04, 16-bit payload length, subselector 00 or 01, delegated body → delegated status; CC c7 framing; cc subselector; d5 operation<br />
<strong>property set-multiple group</strong> [05]: 05, 16-bit payload length, subselector 00..03, delegated body → delegated status; CC c7 framing; cc subselector; d5 operation<br />
<strong>property directory</strong> [06]: 06, 16-bit payload length, subselector 00, delegated body → delegated directory records; CC c7 framing; cc subselector; d5 operation<br />
<strong>property delete</strong> [07]: 07, 16-bit payload length, subselector 00, TLV string property path → 1-byte delete status; CC c7 framing; cc subselector; d5 operation</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_c5 io_controller::vid_burst(io_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">199</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc5<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_C5</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">io_controller::vid_burst(io_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>VID burst</strong> [00..02]: exactly 1 byte mode 00..02 → 1 byte command result 00/01; CC c7 length/channel; c9 selector; c1 result unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodulespower_3a_c6 cff3_pwrctrl_logical_device::get_power_supply_data(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::get_power_supply_data(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::get_power_supply_data(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::get_power_supply_data(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*) | smm_logical_device::get_power_supply_data(smm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules; power, apml, node manager and psu services">
<td class="p-2 text-xs">200</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc6<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModulesPower_3A_C6</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules; power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">cff3_pwrctrl_logical_device::get_power_supply_data(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::get_power_supply_data(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::get_power_supply_data(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::get_power_supply_data(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*) | smm_logical_device::get_power_supply_data(smm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>power-supply data/status</strong> [00,01,f0]: 1-byte selector → 1 byte; CC cc selector<br />
<strong>power-supply polling control</strong> [f1,f2]: f1 stops polling; f2 resumes polling → 1 byte; CC generic<br />
<strong>power-supply target data</strong> [01..04]: 2 or 3 bytes: PSU target plus fragmented-data selector/length → 2 to 7 bytes depending data selector; CC c7 length; c9 range; cb target absent; cc selector; c0 busy</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_c8 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">201</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc8<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_C8</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_c9 cff3_pwrctrl_logical_device::set_voltage_out(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::set_voltage_out(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::set_voltage_out(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::set_voltage_out(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">202</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc9<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_C9</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">cff3_pwrctrl_logical_device::set_voltage_out(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::set_voltage_out(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::set_voltage_out(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::set_voltage_out(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>PSU output voltage set</strong> [base]: exactly 3 bytes: PSU index 00..03 and 16-bit big-endian millivolts 900..1300 → 1 status byte; CC c7 length; ff PMBus/validation failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_cd mem_register_logical_device::mem_register_interface(mem_register_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">203</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xcd<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_CD</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">mem_register_logical_device::mem_register_interface(mem_register_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>mem register interface</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccrfusb_3a_ce rf_usb_device_manager::rf_usb_oem_cmd(rf_usb_device_manager*, ipmi_message*) cpp_registration remote-function usb management">
<td class="p-2 text-xs">204</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xce<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCRfUsb_3A_CE</strong><br />
cpp_registration · privilege 4
<p>remote-function USB management</p></td>
<td class="p-2 min-w-80 text-xs">rf_usb_device_manager::rf_usb_oem_cmd(rf_usb_device_manager*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>remote-flash USB bundle control</strong> [09]: 09, family 01, operation: 01 gets state, 03 gets completion percent, 04 plus timeout updates timeout; start form carries family 01, operation 02, then decimal-digit bundle id → selector-dependent 1-byte state/progress or empty; CC c0 busy; c9 digit; cc framing/selector; ce timeout failure</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_cf cff3_pwrctrl_logical_device::update_psu_fw(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::update_psu_fw(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::update_psu_fw(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::update_psu_fw(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">205</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xcf<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_CF</strong><br />
cpp_registration · privilege 4
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">cff3_pwrctrl_logical_device::update_psu_fw(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::update_psu_fw(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::update_psu_fw(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::update_psu_fw(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>PSU firmware update</strong> [00..07]: exactly 2 bytes: PSU index and operation 00..07; operation 06 applies a constrained PSU selector range → operation-dependent status/ulong; CC c7 length; c9 index; ca hardware; cc operation; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_d0 amm_logical_device::rs485_legacy_packet(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">206</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xd0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_D0</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::rs485_legacy_packet(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>RS-485 legacy packet</strong> [base]: at least 6 bytes; first four are echoed, next two select optional response → echoes first four request bytes; selector 02 f2 appends ten platform bytes; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_d1 amm_logical_device::rs485_bsc_response(amm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">207</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xd1<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_D1</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">amm_logical_device::rs485_BSC_response(amm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>RS-485 BSC response clear</strong> [base]: first byte indexes response slots; trailing bytes ignored → empty; CC generic</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_d9 system_controller::secure_erase(system_controller*, ipmi_message*) cpp_registration property database and core controller services">
<td class="p-2 text-xs">208</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xd9<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_D9</strong><br />
cpp_registration · privilege 2
<p>property database and core controller services</p></td>
<td class="p-2 min-w-80 text-xs">system_controller::secure_erase(system_controller*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>secure erase</strong> [00]: exactly 1 byte 00 → empty; CC c7 invalid framing or helper failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccrecovery_3a_da rot_master_logical_device::command_handle(rot_master_logical_device*, ipmi_message*) cpp_registration imm, secure-update and root-of-trust recovery">
<td class="p-2 text-xs">209</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xda<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCRecovery_3A_DA</strong><br />
cpp_registration · privilege 2
<p>IMM, secure-update and root-of-trust recovery</p></td>
<td class="p-2 min-w-80 text-xs">rot_master_logical_device::command_handle(rot_master_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>command handle</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccstorage_3a_db gpu_logical_device::command_handle(gpu_logical_device*, ipmi_message*) cpp_registration storage management">
<td class="p-2 text-xs">210</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xdb<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCStorage_3A_DB</strong><br />
cpp_registration · privilege 2
<p>storage management</p></td>
<td class="p-2 min-w-80 text-xs">gpu_logical_device::command_handle(gpu_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>command handle</strong> [base]: operation-specific body; framing remains unresolved after top-level handler decompilation → operation-specific; unresolved; CC operation-specific</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_e0 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">211</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xe0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_E0</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_f0 avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">212</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf0<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_F0</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_f1 smm_logical_device::set_network_mcontrol(smm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">213</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf1<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_F1</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">smm_logical_device::set_network_mcontrol(smm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMM network management control</strong> [base]: 1 byte; low 3 bits select 00,01,02,04 → selector 00 returns 1-byte network status; others empty; CC cc selector</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_f2 lockdown_device::ipmi_ldm_control(lockdown_device*, ipmi_message*) | lockdown_local_device::ipmi_ldm_control(lockdown_local_device*, ipmi_message*) | zarkon_lockdown_local_device::ipmi_ldm_control(zarkon_lockdown_local_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">214</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf2<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_F2</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">lockdown_device::ipmi_ldm_control(lockdown_device*, ipmi_message*) | lockdown_local_device::ipmi_ldm_control(lockdown_local_device*, ipmi_message*) | zarkon_lockdown_local_device::ipmi_ldm_control(zarkon_lockdown_local_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}, {'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>lockdown control</strong> [01..10]: first byte operation; selector-specific second byte and optional 8/32-byte tokens; includes status, forced-lockdown, intrusion, policy, key/nonce and local-control operations → selector-dependent flags, strings, policy records, or empty; CC c0 busy; c1/cc selector; c2 state; c7 framing; d5 channel/state; ff backend</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_f3 smm_logical_device::set_network_ip_method(smm_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">215</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf3<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_F3</strong><br />
cpp_registration · privilege None
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">smm_logical_device::set_network_ip_method(smm_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> []<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMM network IP method</strong> [base]: 1 byte; low 3 bits must be 01,02,04 → empty; CC cc selector</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcclogging_3a_f4 debug_logical_device::oem_host_screen_shot(debug_logical_device*, ipmi_message*) cpp_registration ffdc, diagnostics, vgpio and account support">
<td class="p-2 text-xs">216</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf4<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCLogging_3A_F4</strong><br />
cpp_registration · privilege 2
<p>FFDC, diagnostics, VGPIO and account support</p></td>
<td class="p-2 min-w-80 text-xs">debug_logical_device::oem_host_screen_shot(debug_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>host screenshot capture</strong> [00..03]: exactly 1 selector byte 00..03 choosing capture source/path → empty; CC c7 length; c9 selector; ff capture command failure</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_f5 smmless_logical_device::oem_cmd_set_smmless_dev_ctrl(smmless_logical_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">217</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf5<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_F5</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">smmless_logical_device::oem_cmd_set_smmless_dev_ctrl(smmless_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SMM-less device control</strong> [01..06]: 01 node mode, 02 timeout, 03 reseat, 04 reset, 05 PSOC VPD read, 06 PSOC VPD write; selector-specific body; VPD window max 16 bytes within 0x400 → selector-dependent status byte and optional VPD bytes; CC c9 range; cc selector; d4 privilege; d5 hardware; ff thread failure</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccmodules_3a_f6 bmc_sdsi_device::sdsi_config_request(bmc_sdsi_device*, ipmi_message*) cpp_registration planar and shared hardware modules">
<td class="p-2 text-xs">218</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf6<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCModules_3A_F6</strong><br />
cpp_registration · privilege 2
<p>planar and shared hardware modules</p></td>
<td class="p-2 min-w-80 text-xs">bmc_sdsi_device::sdsi_config_request(bmc_sdsi_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>SDSi configuration request</strong> [00]: exactly one byte 00 → 1 status byte; CC c7 length; c9 selector</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpcieswitch_3a_f7 pcieswitch_logical_device::oem_read_pcieswitch_version_cmd(pcieswitch_logical_device*, ipmi_message*) cpp_registration pcie switch management">
<td class="p-2 text-xs">219</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xf7<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPcieswitch_3A_F7</strong><br />
cpp_registration · privilege 2
<p>PCIe switch management</p></td>
<td class="p-2 min-w-80 text-xs">pcieswitch_logical_device::oem_read_pcieswitch_version_cmd(pcieswitch_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>PCIe-switch version read</strong> [00]: 00 switch-index; exactly 2 bytes → version record read from cached file; variable layout not yet decoded; CC c7 length; c9 index; c0 cache unavailable<br />
<strong>PCIe-switch rediscover</strong> [01]: 01 switch-index; exactly 2 bytes → 2 status bytes; CC c7 length; c9 index<br />
<strong>PCIe-switch action/status</strong> [02]: 02 switch-index; exactly 2 bytes → 1 status byte for index 00; other indices may return empty; CC c7 length; c9 index; d5 unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccavocentipmicommandproc_3a_fd avocent_ipmi_command_proc legacy_admission_only legacy admission with no recovered c++ registration">
<td class="p-2 text-xs">220</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xfd<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCAvocentIpmiCommandProc_3A_FD</strong><br />
legacy_admission_only · privilege 2
<p>Legacy admission with no recovered C++ registration</p></td>
<td class="p-2 min-w-80 text-xs">avocent_ipmi_command_proc<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs">No decoded leaf contract; activation is retained explicitly.</td>
<td class="p-2 min-w-64 text-xs"><strong>unknown</strong><br />
decoded / high<br />
XCC 6.92 libipmi.so default OEM admission table</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_fe cff3_pwrctrl_logical_device::get_baidu_power_supply_as_mode(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::get_baidu_power_supply_as_mode(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::get_baidu_power_supply_as_mode(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::get_baidu_power_supply_as_mode(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">221</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xfe<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_FE</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">cff3_pwrctrl_logical_device::get_baidu_power_supply_AS_mode(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::get_baidu_power_supply_AS_mode(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::get_baidu_power_supply_AS_mode(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::get_baidu_power_supply_AS_mode(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>power-supply AS mode</strong> [base]: empty → 1 property byte; CC d5 property unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xccpower_3a_ff cff3_pwrctrl_logical_device::set_baidu_power_supply_as_mode(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::set_baidu_power_supply_as_mode(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::set_baidu_power_supply_as_mode(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::set_baidu_power_supply_as_mode(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*) cpp_registration power, apml, node manager and psu services">
<td class="p-2 text-xs">222</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xff<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCPower_3A_FF</strong><br />
cpp_registration · privilege 2
<p>power, APML, Node Manager and PSU services</p></td>
<td class="p-2 min-w-80 text-xs">cff3_pwrctrl_logical_device::set_baidu_power_supply_AS_mode(cff3_pwrctrl_logical_device*, ipmi_message*) | cff4_psu::cff4_pwrctrl_logical_device::set_baidu_power_supply_AS_mode(cff4_psu::cff4_pwrctrl_logical_device*, ipmi_message*) | cff5_psu::cff5_pwrctrl_logical_device::set_baidu_power_supply_AS_mode(cff5_psu::cff5_pwrctrl_logical_device*, ipmi_message*) | crps_psu::crps_pwrctrl_logical_device::set_baidu_power_supply_AS_mode(crps_psu::crps_pwrctrl_logical_device*, ipmi_message*)<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>power-supply AS mode</strong> [base]: exactly 1 byte 00 or 01 → empty; CC c7 length; cc value; d5 unsupported/unavailable</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 C++ IPMI::register_command static registration</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_30_e2 cmdoemgetreading core_static_table node manager power telemetry">
<td class="p-2 text-xs">223</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0xe2<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_30_E2</strong><br />
core_static_table · privilege 4
<p>Node Manager power telemetry</p></td>
<td class="p-2 min-w-80 text-xs">CmdOEMGetReading<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 4}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>Node Manager reading</strong> [high nibble 0,1,2]: 4 bytes; high nibble selects hook op 1/2/3, low nibble and byte 1 are selectors for op 3, bytes 2..3 must be 00 00 → 4 bytes: request byte 0 echo, reserved/indeterminate byte, little-endian u16 reading; CC c7 length; cc selector/reserved; d5 NMPT disabled or hook unavailable/failure</td>
<td class="p-2 min-w-64 text-xs"><strong>likely-read-only</strong><br />
decoded / high<br />
XCC 6.92 libipmi consolidated request table</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_30_e3 cmdoemmepowerstatechange core_static_table node manager pass-through enable control">
<td class="p-2 text-xs">224</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x30/0xe3<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_30_E3</strong><br />
core_static_table · privilege 4
<p>Node Manager pass-through enable control</p></td>
<td class="p-2 min-w-80 text-xs">CmdOEMMEPowerStateChange<br />
<strong>Length admission:</strong> [{'length_kind': 'exact', 'request_length': 1}]<br />
<strong>Remote:</strong> unknown</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>NMPT enable state</strong> [00,02]: 1 byte: 00 enable or 02 disable → empty; CC c7 length; cc invalid value</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 libipmi consolidated request table</td>
</tr>
<tr class="border-b align-top" data-row="xcccore_3a_c7 cmdoemnativenminterfaceswitch core_static_table native node manager ipmi bridge switch">
<td class="p-2 text-xs">225</td>
<td class="p-2 font-mono text-xs whitespace-nowrap">0x3a/0xc7<br />
prefix —</td>
<td class="p-2 min-w-72"><strong>XCCCore_3A_C7</strong><br />
core_static_table · privilege 4
<p>Native Node Manager IPMI bridge switch</p></td>
<td class="p-2 min-w-80 text-xs">CmdOEMNativeNMInterfaceSwitch<br />
<strong>Length admission:</strong> [{'length_kind': 'minimum', 'request_length': 0}]<br />
<strong>Remote:</strong> remote-supported</td>
<td class="p-2 min-w-[36rem] text-xs"><strong>native Node Manager bridge get/set</strong> [empty,00,01]: empty get; 00 disable; 01 enable → get 1 byte; set empty; CC c1 length; cc value</td>
<td class="p-2 min-w-64 text-xs"><strong>state-changing-or-control</strong><br />
decoded / high<br />
XCC 6.92 libipmi consolidated request table and Lenovo public documentation</td>
</tr>
</tbody>
</table>

## Primary sources

- [Lenovo XCC OEM IPMI commands](https://pubs.lenovo.com/xcc/oem_ipmi_commands)
- [Lenovo XCC LAN parameters](https://pubs.lenovo.com/xcc/get_set_lan_config_parameter)
- [IPMI v2.0 standard LAN framing](https://www.intel.com/content/dam/www/public/us/en/documents/specification-updates/ipmi-intelligent-platform-mgt-interface-spec-2nd-gen-v2-0-spec-update.pdf)
- Exact XCC 6.92 binaries named in each evidence row.
