#!/usr/bin/env python3
"""Render the firmware-bound iRMC S6 OEM inventory from retained evidence."""
from __future__ import annotations

import csv
import html
import json
import sys
from pathlib import Path


BOX = Path(__file__).resolve().parent
EVIDENCE = BOX / "evidence"
OUTPUT = BOX / "irmc-s6-oem-reference.html"


def load_json(name: str) -> dict:
    return json.loads((EVIDENCE / name).read_text())


def esc(value: object) -> str:
    if isinstance(value, (dict, list)):
        value = json.dumps(value, ensure_ascii=False, separators=(", ", ": "))
    return html.escape(str(value), quote=True)


with (EVIDENCE / "irmc-s6-command-tables.tsv").open(newline="") as stream:
    table = [row for row in csv.DictReader(stream, delimiter="\t")
             if row["table"] and not row["table"].startswith("#")]
active = [row for row in table if row["handler"] != "?"]
c0d0 = load_json("c0d0-handler-audit.json")
standard = load_json("standard-overrides.json")
dispatch = load_json("fujitsu-selector-dispatch.json")
f1 = load_json("f1-selector-contracts.json")["selector_contracts"]
f5 = load_json("f5-selector-contracts.json")["selectors"]
scci = load_json("scci-selector-contracts.json")["commands"]
live = load_json("20260926T204500Z-safe-live-22.json")

assert len(table) == 160 and len(active) == 148
assert len({(r["netfn"], r["cmd"]) for r in active}) == 135
assert len(c0d0["handlers"]) == 104 and len(standard["records"]) == 24
assert sum(row["contractStatus"] == "direct" for row in c0d0["handlers"]) == 77
assert len(f1) == 93 and len(f5) == 99
assert sum(len(item["selectors"]) for item in scci.values()) == 36
assert sum(item["status"] == "decoded" for item in f1.values()) == 30
assert sum(item["status"] == "decoded" for item in f5.values()) == 21
assert sum(item["status"] == "unknown" for item in f5.values()) == 4
assert sum(item["selector_dispatch_candidate_count"]
           for item in dispatch["commands"].values()) == 192
assert len(live["results"]) == 22
assert sum(row.get("completionCode") == 0 for row in live["results"]) == 21
assert [row for row in live["results"] if row.get("completionCode") != 0][0]["cmd"] == "e0"

c0_by_wire = {(int(r["netfn"], 0), int(r["command"], 0)): r
              for r in c0d0["handlers"]}
std_by_wire = {(int(r["netfn"], 16), int(r["cmd"], 16), r["lun"]): r
               for r in standard["records"]}

top_rows = []
seen = set()
for row in active:
    netfn, cmd = int(row["netfn"], 0), int(row["cmd"], 0)
    if row["scope"] == "MSMM callback":
        continue  # exact duplicate registration, retained in the TSV
    lun = 3 if row["scope"] == "wire LUN 3" else 0
    key = (netfn, cmd, lun)
    assert key not in seen, key
    seen.add(key)
    audit = c0_by_wire.get((netfn, cmd)) or std_by_wire.get(key) or {}
    if netfn == 0x2E:
        count = len(f1) if cmd == 0xF1 else len(f5) if cmd == 0xF5 else len(scci[f"{cmd:02x}"]["selectors"])
        contract = f"{count} selector candidates; see operation table"
        response = "Selector-specific; see operation table"
        effect = "mixed or selector-specific"
        status = "selector map"
    else:
        contract = audit.get("request") or audit.get("request_length") or "Variable or delegated; exact payload unresolved"
        response = audit.get("response") or "Handler-specific; response unresolved"
        effect = audit.get("effect") or audit.get("side_effect") or "unknown"
        status = audit.get("contractStatus") or audit.get("certainty") or "static row"
    activation = audit.get("activation") or ("LAN LUN 3 unproved" if lun == 3 else "Registered; rack applicability varies")
    wire = f"{netfn:02x}/{cmd:02x}" + (" · LUN 3" if lun == 3 else "")
    top_rows.append(
        f'<tr class="border-b border-slate-700 align-top" data-search="{esc((wire + row["handler"] + str(effect)).lower())}">'
        f'<td class="p-2 font-mono whitespace-nowrap">{esc(wire)}</td>'
        f'<td class="p-2">{esc(row["handler"])}<div class="text-xs text-slate-400">{esc(row["table"])} · {esc(row["scope"])}</div></td>'
        f'<td class="p-2">{esc(row["min_priv"])} · {esc(row["req_len"])} length</td>'
        f'<td class="p-2">{esc(contract)}</td><td class="p-2">{esc(response)}</td><td class="p-2">{esc(effect)}</td>'
        f'<td class="p-2">{esc(status)}<div class="text-xs text-slate-400">{esc(activation)}</div></td></tr>'
    )
assert len(top_rows) == 138

selector_rows = []
for cmd, entries, source in (
    (0xF1, f1, "f1-selector-contracts.json"),
    (0xF5, f5, "f5-selector-contracts.json"),
):
    for selector, item in sorted(entries.items()):
        wire = f"2e/{cmd:02x} · 80 28 00 {selector}"
        name = item.get("name") or f"Selector {selector}"
        selector_rows.append(
            f'<tr class="border-b border-slate-700 align-top" data-search="{esc((wire + name + str(item.get("effect", ""))).lower())}">'
            f'<td class="p-2 font-mono whitespace-nowrap">{esc(wire)}</td><td class="p-2">{esc(name)}</td>'
            f'<td class="p-2">{esc(item.get("request", "unresolved"))}</td>'
            f'<td class="p-2">{esc(item.get("response", "unresolved"))}</td>'
            f'<td class="p-2">{esc(item.get("effect", "unknown"))}</td>'
            f'<td class="p-2">{esc(item["status"])} · <a class="text-cyan-300 underline" href="evidence/{source}">evidence</a></td></tr>'
        )
for command, info in sorted(scci.items()):
    for selector, item in sorted(info["selectors"].items()):
        wire = f"2e/{command} · 80 28 00 {selector}"
        name = item.get("name", f"Selector {selector}")
        selector_rows.append(
            f'<tr class="border-b border-slate-700 align-top" data-search="{esc((wire + name + str(item.get("effect", ""))).lower())}">'
            f'<td class="p-2 font-mono whitespace-nowrap">{esc(wire)}</td><td class="p-2">{esc(name)}</td>'
            f'<td class="p-2">{esc(item.get("request", "unresolved"))}</td>'
            f'<td class="p-2">{esc(item.get("response", "unresolved"))}</td>'
            f'<td class="p-2">{esc(item.get("effect", "unknown"))}</td>'
            f'<td class="p-2">{esc(item["status"])} · <a class="text-cyan-300 underline" href="evidence/scci-selector-contracts.json">evidence</a></td></tr>'
        )
assert len(selector_rows) == 228

document = f'''<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Fujitsu iRMC S6 02.63S OEM IPMI reference</title>
<script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-slate-950 text-slate-100"><main class="mx-auto max-w-7xl px-5 py-10">
<p class="text-sm font-bold uppercase tracking-widest text-cyan-300">zBMC · RX2540 M7 · iRMC S6 02.63S</p>
<h1 class="mt-3 text-4xl font-bold">Fujitsu OEM IPMI command reference</h1>
<p class="mt-4 max-w-4xl leading-7 text-slate-300">A firmware-bound dispatch and selector inventory. A registration, a decoded wrapper, and a live-reachable wire contract are different levels of proof; the tables say which level each entry has reached.</p>
<div class="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-4"><div class="rounded bg-slate-800 p-4"><strong class="text-2xl">148</strong><div>active table records</div></div><div class="rounded bg-slate-800 p-4"><strong class="text-2xl">138</strong><div>LUN-aware identities (135 pairs)</div></div><div class="rounded bg-slate-800 p-4"><strong class="text-2xl">228</strong><div>2e selector candidates</div></div><div class="rounded bg-slate-800 p-4"><strong class="text-2xl">10</strong><div>duplicate MSMM callbacks</div></div></div>
<section class="mt-7 rounded border border-amber-500/50 bg-amber-950/30 p-5"><h2 class="text-xl font-semibold text-amber-200">Proof boundary</h2><p class="mt-2 leading-7">The 160-row recovered table has 12 terminators. Ten MSMM entries duplicate the normal 2e handlers; three LUN-3 FRU identities share command numbers with different LUN-0 handlers and are not proved over LAN (prior probe returned C0). Of 104 C0/D0 handlers, 77 have direct wrapper contracts and 27 retain partial backend or field semantics. Rack-relevant power paths and blade-gated paths coexist; the table name alone does not decide applicability. F1/F5 jump tables identify 192 candidate leaves, but partial or unknown leaf contracts are not runnable codecs.</p></section>
<section class="mt-5 rounded border border-emerald-500/50 bg-emerald-950/25 p-5"><h2 class="text-xl font-semibold text-emerald-200">Safe live proof</h2><p class="mt-2 leading-7">The fresh Debby cold run <code>{esc(live['runId'])}</code> reached required-service READY in 27m34s after initial host CPU contention. A cipher-17 Admin session sent 22 statically reviewed four-byte read requests, serialized. Twenty-one returned CC00; 2e/e0 selector 00 returned CC01, showing a device-side rejection. No request had a transport error. One named zipmi power-read command was also exercised successfully. <a class="text-emerald-300 underline" href="evidence/20260926T204500Z-safe-live-22.json">Exact requests and responses</a> are retained; no changing selector was sent.</p></section>
<section class="mt-5 rounded border border-rose-500/50 bg-rose-950/25 p-5"><h2 class="text-xl font-semibold text-rose-200">Security and impact boundaries</h2><ul class="mt-3 list-disc space-y-2 pl-6 leading-7"><li>2e/01 is User-privileged yet includes state-changing power selectors 17, 1b, 1c, and 20; branch-specific short-request checks are weak.</li><li>2c/02 group 52 is an Admin/channel-0f credential-creation path, not a safe DCMI read; it has not been invoked live.</li><li>34/38–39 back up and restore persistent configuration. The restore wrapper can copy a 24-byte page from an undersized request; static-only finding.</li><li>2e/F5 selectors 52, a5, and f8 reach I2C write/read, persistent POH reset, and user deletion respectively; these are static findings, not live probes.</li><li>34/00–0c flash routes, 30/e6 raw PECI, F1/58, and F1/ff have high-impact or weak-length boundaries. No state-changing command was used for this reference.</li></ul></section>
<section class="mt-8"><h2 class="text-2xl font-semibold">Top-level dispatch identities</h2><p class="mt-2 text-slate-300">All 138 unique LUN-aware identities are below. Standard-NetFn rows are Fujitsu overrides, not newly assigned OEM opcodes. Full evidence: <a class="text-cyan-300 underline" href="evidence/irmc-s6-command-tables.tsv">exact table</a>, <a class="text-cyan-300 underline" href="evidence/c0d0-handler-audit.json">C0/D0 handlers</a>, <a class="text-cyan-300 underline" href="evidence/standard-overrides.json">standard/group overrides</a>.</p>
<label class="mt-4 block font-semibold" for="top-filter">Filter top-level commands</label><input id="top-filter" class="mt-2 w-full rounded bg-slate-800 p-3" placeholder="wire, handler, effect">
<div class="mt-4 overflow-auto" role="region" aria-label="Top-level command table" tabindex="0"><table class="min-w-full text-left text-sm"><thead class="bg-slate-800"><tr><th class="p-2">Wire</th><th class="p-2">Handler / source</th><th class="p-2">Privilege / admission</th><th class="p-2">Request</th><th class="p-2">Response</th><th class="p-2">Effect</th><th class="p-2">Proof / activation</th></tr></thead><tbody id="top-rows">{''.join(top_rows)}</tbody></table></div></section>
<section class="mt-10"><h2 class="text-2xl font-semibold">2e selector dispatch candidates</h2><p class="mt-2 text-slate-300">The 228 candidates include 93 BIOS F1, 99 BMC F5, and 36 other SCCI/blade leaves. Sixty-one are decoded, 163 partial, and four unknown; “partial” and “unknown” name real unresolved wire-contract boundaries, not tested success. <a class="text-cyan-300 underline" href="evidence/fujitsu-selector-dispatch.json">Exact F1/F5 jump-table map</a>.</p>
<label class="mt-4 block font-semibold" for="selector-filter">Filter selector operations</label><input id="selector-filter" class="mt-2 w-full rounded bg-slate-800 p-3" placeholder="wire, name, effect">
<div class="mt-4 overflow-auto" role="region" aria-label="Selector operation table" tabindex="0"><table class="min-w-full text-left text-sm"><thead class="bg-slate-800"><tr><th class="p-2">Wire</th><th class="p-2">Operation</th><th class="p-2">Request</th><th class="p-2">Response</th><th class="p-2">Effect</th><th class="p-2">Evidence state</th></tr></thead><tbody id="selector-rows">{''.join(selector_rows)}</tbody></table></div></section>
<section class="mt-10 rounded border border-slate-700 p-5"><h2 class="text-xl font-semibold">Source and applicability</h2><p class="mt-2 leading-7">Target: PRIMERGY RX2540 M7 iRMC S6 02.63S / SDR 03.67. <code>libipmipdkcmds.so.1.53.20</code> SHA-256 <code>35839f7ab40993898666425d50e18654d68791c7dfe3bb5a3c3496e4daa23804</code>; table SHA-256 <code>6c25538d508e398135855d59550148b3fd93cdcc045bc9556e4f79c335f72dfa</code>. Compare the <a class="text-cyan-300 underline" href="oem-power-map.html">power and transport map</a>, <a class="text-cyan-300 underline" href="https://support.ts.fujitsu.com/Search/SWP1267156.asp">Fujitsu iRMC S6 Concepts &amp; Interfaces</a>, and the <a class="text-cyan-300 underline" href="https://github.com/chu11/freeipmi-mirror">FreeIPMI Fujitsu definitions</a>. Public cross-generation selectors are not promoted without this library's dispatch proof.</p></section>
</main><script>for(const [input,body] of [['top-filter','top-rows'],['selector-filter','selector-rows']]){{document.getElementById(input).addEventListener('input',e=>{{const q=e.target.value.toLowerCase();for(const row of document.getElementById(body).rows)row.hidden=!row.dataset.search.includes(q)}})}}</script></body></html>
'''
if "--check" in sys.argv[1:]:
    assert OUTPUT.read_text() == document, "iRMC reference is out of sync"
    print(f"iRMC reference OK: {len(top_rows)} identities, {len(selector_rows)} selectors")
else:
    OUTPUT.write_text(document)
    print(f"wrote {OUTPUT}: {len(top_rows)} identities, {len(selector_rows)} selectors")
