# Explain PII DQL Queries

```
Need to run PII discovery in Dynatrace?
  │
  ├─ Step 0: Right UI?
  │     Logs and Events → Advanced mode (NOT Data explorer — seq 8)
  │
  ├─ Step 1: Inventory query (seq 13)
  │     log_count per dt.host_group.id — no PII filter
  │     └─ log_count = 0 → fix host group ID or OneAgent before blaming "no PII"
  │
  ├─ Step 2: Master query (seq 13)
  │     One table: hits_keyword_pii + hits_hats_style + hits_rawDataList_jp
  │     └─ sort by highest column → pick groups to drill
  │
  ├─ Step 3: Drill by signal type
  │     ├─ HATS-style hits? → A-all → B-all → C-all → D-all (sample limit 10)
  │     └─ Keyword PII hits? → E-all → seq 11 Query 2A/2B on that group
  │
  ├─ Step 4: Earlier sessions still useful
  │     ├─ seq 6 — general discovery (email, EMPLID, taxpayer_id)
  │     ├─ seq 7 — insurance field names from Excel
  │     ├─ seq 11 — keyword dashboard (42 groups, now extended to 44 in seq 13)
  │     └─ seq 12 — HATS rawDataList on 2 groups (prototype for A-all)
  │
  └─ Step 5: After confirmed leak
        seq 5 masking (OneAgent + OpenPipeline) → re-run Master → counts should drop
```

| Question | Answer |
| --- | --- |
| What is DQL? | Dynatrace Query Language — how you search logs stored in Grail |
| What is PII? | Personally Identifiable Information — names, addresses, IDs, phone numbers |
| Where to run these? | **Logs and Events → Advanced mode** |
| First query every time? | **Inventory** — confirms logs arrive before you hunt PII |
| Best single dashboard? | **Master query** (seq 13) — keyword PII + HATS-style in one table |
| Count before sample? | Always — use `summarize` first, `fields content` + `limit 10` last |

## Summary

Today's PII discovery session built a **layered set of DQL queries** that evolved from a small AXA host list (seq 6) to a **44-host-group audit** (seq 13). Every query follows the same pipeline shape: **fetch** logs in a time window → **filter** to the right servers and content → **summarize** counts → **sort** by risk → **limit** or **fields** only when you need to read raw lines. The **inventory query** answers "are logs arriving?" The **master query** answers "which groups have keyword PII or HATS-style payloads?" Drill queries (A-all through E-all) narrow down **which host and log file** leak data. Seq 12 proved the HATS `rawDataList` pattern on two groups; seq 13 scaled that to all servers. Seq 5 is where masking happens after you confirm a real leak.

**Safety:** Discovery DQL is read-only. Treat `content` as sensitive. Always `limit 10` when sampling.

---

## Short takeaway — which query when

| Query name | What it does | When to use | What you learn |
| --- | --- | --- | --- |
| **Inventory** (seq 13) | Counts **all** log lines per host group — no PII filter | **First**, every audit | Whether Dynatrace receives logs from each of the 44 groups |
| **Master** (seq 13) | One row per group with `countIf` columns for keyword PII, HATS-style, and rawDataList+Japanese | **Second** — prioritization dashboard | Which groups have the most PII signals without reading raw content |
| **A-all** (seq 13) | Counts HATS-style signatures (`ProcessNdServiceImpl`, `HatsProcessResponse`, `rawDataList`) per group | After master shows `hits_hats_style > 0` | Which groups log HATS-like payloads (not only the HATS server) |
| **B-all** (seq 13) | Same as A-all but broken down by `host.name` and `log.source` | After A-all finds hits | **Which server** and **which log file** produce HATS-style lines |
| **C-all** (seq 13) | `rawDataList` lines that also contain Japanese characters | Strong PII signal in JP insurance logs | Whether the payload likely contains customer/policy text, not just IDs |
| **D-all** (seq 13) | Shows up to 10 full log lines (`fields content`) for one host group | **Last** — only after counts are non-zero | What the actual log line looks like (for escalation to app owner) |
| **E-all** (seq 13) | Counts insurance + HULFT keyword field names per group | Confirm or drill keyword PII column from master | Same as seq 11 Query 1A but with all 44 IDs |
| **Seq 12 A–D** | HATS prototype on **2 groups** (HATS + CUSTMDMGM), includes `SystemOut` filter | When you have a HATS screenshot and want the exact pattern | How to find `rawDataList` on the middleware host before scaling to all servers |
| **Seq 11 1A–2B** | Keyword PII dashboard on **42 groups** (now 44 in seq 13) | Keyword-only audit across many groups | `hit_count` per group, then which field names matched, then sample |
| **Seq 7 combined sweep** | Insurance mail-service **20 field names** from Excel | When you know the exact JSON/key names from the app | Whether `insuredPerson`, `loginId`, `telNumberOld`, etc. appear in logs |
| **Seq 6 inventory + per-type** | General PII discovery (email, EMPLID, My Number, passwords) | **Before** you have app-specific field lists | Baseline audit on the original AXA spreadsheet hosts |
| **Seq 8 UI fix** | Not a query — tells you **where** to paste queries | When Data explorer shows "parse error at logs" | Use Logs Advanced, not Data explorer |

---

## DQL building blocks — five functions you will see everywhere

### `fetch logs, from: now()-24h`

**What it means:** Go to the log store (Grail) and pull log records from the last 24 hours.

**Why you care:** This is always line 1. The time window (`now()-24h`, `now()-1h`, `now()-7d`) controls how far back you search. Wider windows find rare leaks but cost more to scan.

### `filter`

**What it means:** Keep only rows that match a condition. Rows that fail the filter are dropped.

**Why you care:** You use `filter` to scope to the right servers (`in(dt.host_group.id, {...})`) and to match PII patterns in `content`.

### `summarize`

**What it means:** Group rows and compute aggregates — usually `count()` or `countIf(...)`.

**Why you care:** This is how you **count without reading PII**. One row per host group (or per host + log file) with a number instead of thousands of log lines.

### `sort` and `limit`

**What it means:** `sort` orders results (highest risk first). `limit` caps how many rows come back.

**Why you care:** `sort hit_count desc` puts the worst groups at the top. `limit 10` on sample queries stops too much raw PII from appearing on screen.

### `fields`

**What it means:** Choose which columns to display (e.g. `timestamp`, `host.name`, `content`).

**Why you care:** Only use `fields content` **after** you have counts. This is the step that shows actual PII text.

---

## Five match functions — how filtering actually works

| Function | What it does | Example | When to use |
| --- | --- | --- | --- |
| `in(field, { "A", "B" })` | Field equals **any** value in the list | `in(dt.host_group.id, { "C_ALJ_BU_...", ... })` | Scope to many host groups in one query |
| `matchesValue(field, "exact")` | Field equals **one exact string** | `matchesValue(log.source, "SystemOut")` | Single host group, single log file name |
| `matchesPhrase(field, "text")` | Field **contains** the phrase (substring, case-sensitive by default) | `matchesPhrase(content, "rawDataList")` | Java class names, JSON keys, fixed labels |
| `matchesRegex(field, "pattern")` | Field matches a **regular expression** | `matchesRegex(content, "(?i)loginId")` | Many field names in one pattern, Japanese Unicode ranges, email shapes |
| `countIf(condition)` | Inside `summarize` — count rows where condition is true | `countIf(matchesPhrase(content, "rawDataList"))` | Multiple hit types in **one table** without filtering rows out |

### `countIf` — the master query trick

Normal `filter` **removes** rows that do not match. That means you can only count one pattern per query.

`countIf` keeps **every** row in the group but counts how many match each pattern:

```text
| summarize
    hits_keyword_pii = countIf(matchesRegex(content, "(?i)(insuredPerson|loginId|...)")),
    hits_hats_style = countIf(matchesPhrase(content, "rawDataList") or matchesPhrase(content, "ProcessNdServiceImpl")),
    total_logs = count()
  by: { dt.host_group.id }
```

- `hits_keyword_pii` — how many lines mention insurance or HULFT field names
- `hits_hats_style` — how many lines mention HATS app signatures
- `total_logs` — all lines for that group (denominator for "how noisy is this app?")

Each row in the result is still **one host group**, but you get multiple count columns side by side.

### `matchesRegex` vs `matchesPhrase`

| | `matchesPhrase` | `matchesRegex` |
| --- | --- | --- |
| Speed | Faster for simple text | More flexible, slightly heavier |
| Best for | `rawDataList`, `ProcessNdServiceImpl` | 20+ field names in one `(?i)(field1\|field2\|...)` |
| Pitfall | Cannot do "field1 OR field2" in one call without two filters | Typos break the pattern (seq 10: unclosed `)` ) |

`(?i)` at the start of a regex means **case-insensitive** — `loginId` matches `LOGINID`.

`\bdob\b` uses **word boundaries** so you do not match unrelated words like `adobe`.

### `in()` vs `matchesValue()`

- `in(dt.host_group.id, { "A", "B", "C" })` — "this log belongs to group A **or** B **or** C"
- `matchesValue(dt.host_group.id, "YOUR_HOST_GROUP_ID")` — "this log belongs to **exactly** this one group" (used in D-all and seq 11 Query 2A/2B)

---

## Three discovery types — keyword PII vs HATS rawDataList vs inventory

| Type | What you search for | What a "hit" means | Example query |
| --- | --- | --- | --- |
| **Inventory** | Nothing PII-related — just "do logs exist?" | `log_count > 0` means OneAgent is sending logs for that group | Seq 13 inventory |
| **Keyword PII** | **Field names** from Excel or HULFT screenshots (`insuredPerson`, `holderName`, `loginId`) | The log line **mentions the key** — often `key: value` or JSON `"key": "value"` | Seq 7, seq 11 1A, seq 13 E-all, master `hits_keyword_pii` |
| **HATS rawDataList** | **App signatures** (`ProcessNdServiceImpl`, `HatsProcessResponse`, `rawDataList`) plus Japanese text in the payload | The log line is from the HATS middleware pattern and may contain a **blob of raw customer data** in `rawDataList` | Seq 12 A–D, seq 13 A-all/C-all, master `hits_hats_style` |

**Why three types matter:**

- **Inventory** tells you the pipeline works. Zero logs ≠ zero PII — it might mean the host group ID is wrong.
- **Keyword PII** catches structured leaks where the app logs `displayName: 三木　光太郎`.
- **HATS rawDataList** catches unstructured blobs where field names are **not** in your Excel list but Japanese names appear inside a JSON array.

Seq 13 **master query** combines keyword and HATS columns so you do not run two separate dashboards.

---

## Line-by-line walkthrough — seq 13 (all 44 servers)

### Inventory query

```text
fetch logs, from: now()-24h
```
Pull all log records from the last 24 hours.

```text
| filter in(dt.host_group.id, { "C_ALJ_BU_...", ... })
```
Keep only logs tagged with one of the 44 host group IDs from `unique.sh`.

```text
| summarize log_count = count(), by: { dt.host_group.id }
```
Group by host group. Count every log line — **no content filter**.

```text
| sort log_count desc
```
Show the busiest groups first (useful to spot silent groups at the bottom with `log_count = 0`).

**What you learn:** Dynatrace is receiving logs. If `log_count = 0`, fix the ID or check OneAgent — do not conclude "no PII."

---

### Master query

Same `fetch` and `in(...)` as inventory.

```text
| summarize
    hits_keyword_pii = countIf( matchesRegex(...) or matchesRegex(...) ),
    hits_hats_style = countIf( matchesPhrase(...) or ... ),
    hits_rawDataList_jp = countIf( matchesPhrase("rawDataList") and matchesRegex(Japanese) ),
    total_logs = count()
  by: { dt.host_group.id }
```
Four counters per group in one pass. Rows are **not** filtered out — every log in the group is counted in `total_logs`, and each `countIf` adds only matching lines to its column.

```text
| sort hits_keyword_pii desc, hits_hats_style desc
```
Prioritize groups with the most keyword PII, then HATS-style.

**What you learn:** A single prioritization table. High `hits_keyword_pii` → run E-all or seq 11 2A. High `hits_hats_style` → run A-all → B-all → C-all.

---

### Query A-all — HATS-style count per group

```text
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
```
**Now** rows are filtered — only HATS-signature lines remain (unlike master, which counted in place).

```text
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```
One row per group with HATS-style hits.

**Difference from seq 12 Query A:** A-all searches all 44 groups and does **not** require `log.source == "SystemOut"` (broader net). Seq 12 adds `matchesValue(log.source, "SystemOut")` to match the screenshot exactly.

---

### Query B-all — drill-down by host and log file

Same filters as A-all, then:

```text
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

**What you learn:** Within a hot group, which **hostname** (e.g. `EAA00xx`) and which **log file** (e.g. `SystemOut`, `server.log`) drive the count.

---

### Query C-all — rawDataList + Japanese characters

```text
| filter matchesPhrase(content, "rawDataList")
| filter matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
```
Two filters in sequence: must contain `rawDataList` **and** Hiragana, Katakana, or Kanji Unicode ranges.

```text
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

**What you learn:** Payloads that likely contain **Japanese customer text**, not just alphanumeric IDs.

**Fallback (if Unicode regex fails):** Replace the regex filter with `matchesPhrase` for `保険金`, `TXID`, `OPID` (see seq 13 doc).

---

### Query D-all — sample full content

```text
| filter matchesValue(dt.host_group.id, "YOUR_HOST_GROUP_ID")
```
Replace placeholder with a group from master or A-all where counts were non-zero.

```text
| filter matchesPhrase(content, "ProcessNdServiceImpl") or ...
| fields timestamp, dt.host_group.id, dt.security_context, host.name, log.source, content
| sort timestamp desc
| limit 10
```

**What you learn:** What one real log line looks like — for ticket to app owner. **Never skip `limit 10`.**

Optional extra filters from seq 12: `matchesValue(log.source, "SystemOut")` and `matchesPhrase(content, "Finish ND processing")`.

---

### Query E-all — keyword PII sweep (all 44)

```text
| filter matchesRegex(content, "(?i)(insuredPerson|...20 fields...)")
  or matchesRegex(content, "(?i)(uketorininName1|...65 HULFT fields...)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

Same combined regex as seq 11 Query 1A, with HATS and CUSTMDMGM IDs added. Confirms the `hits_keyword_pii` column from master.

---

## Line-by-line walkthrough — earlier sessions

### Seq 8 — wrong UI (not a query)

**Problem:** Pasting `fetch logs` into **Data explorer** causes `Metric selector parse error at 'logs'`.

**Why:** Data explorer expects metrics like `builtin:host.cpu.usage`. Log DQL belongs in **Logs and Events → Advanced mode** or **Notebooks → DQL cell**.

**Fix:** Move to the correct screen. Also fix regex typo `njiFullAddress` → `kanjiFullAddress` (seq 8).

---

### Seq 6 — general PII discovery

**Purpose:** Find PII **before** you know app-specific field names.

**Inventory (seq 6 style):**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { ...4 AXA groups... })
| summarize log_count = count(), by: { dt.host_group.id, host.name }
| sort log_count desc
```

Adds `host.name` to inventory because `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` mixes HR, MDM, FTP on one group.

**Per-PII-type queries:** Separate count + sample pairs for email (`@` regex), `EMPLID`, `customer_id`, `taxpayer_id`, passwords, 12-digit My Number shape, etc.

**Pattern:** `summarize hit_count` first → if `> 0` → `fields content | limit 10`.

---

### Seq 7 — insurance keyword PII

**Purpose:** Target the **20 field names** from the insurance mail-service Excel (column E).

**Combined sweep:**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { ... })
| filter matchesRegex(content, "(?i)(insuredPerson|displayName|loginId|...all 20...)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Per-category queries:** Names (Kanji/Kana), address, DOB, phone (`090/080/070`), gender, zip, loginId — each with tighter regex on the **value** after the key.

**Link to masking:** Seq 7 also documents OpenPipeline `replacePattern` and OneAgent rules — the **after-discovery** step in seq 5.

---

### Seq 11 — per host group dashboard (42 → 44 IDs)

| Query | Same as seq 13 | Grouping |
| --- | --- | --- |
| **1A** | Like E-all | `hit_count` by `dt.host_group.id` only |
| **1B** | Like E-all + drill | by `dt.host_group.id`, `host.name`, `log.source` |
| **2A** | Per-group keyword breakdown | `countIf(matchesPhrase(...))` per field name |
| **2B** | Sample | `fields content | limit 10` for one `YOUR_HOST_GROUP_ID` |

Seq 11 was the breakthrough: **one query for all groups** instead of 44 separate queries. Seq 13 renamed 1A→E-all and added HATS columns in master.

---

### Seq 12 — HATS queries A–D (2 groups only)

| Query | Role | Key filters beyond seq 13 |
| --- | --- | --- |
| **A** | Count per group | Only HATS + CUSTMDMGM IDs; **`log.source == "SystemOut"`** |
| **B** | Drill host + log source | Same as A |
| **C** | rawDataList + Japanese | Same as C-all but 2 groups + SystemOut |
| **D** | Sample like screenshot | `Finish ND processing`, `HatsProcessResponse`, `rawDataList` |

Seq 12 is the **prototype**. Seq 13 A-all/C-all/D-all scales the pattern to 44 groups.

**Also in seq 12:** Query E (filter by `dt.security_context`), Query F (widest net — `ProcessNdServiceImpl` only).

---

## How queries connect — full workflow

```
unique.sh (44 host group IDs)
        │
        ▼
Seq 8: Logs and Events → Advanced mode  (NOT Data explorer)
        │
        ▼
Inventory query
  log_count per dt.host_group.id
        │
        ├─ log_count = 0 → fix ID spelling / OneAgent / time range
        │
        └─ log_count > 0
              │
              ▼
        Master query
  hits_keyword_pii | hits_hats_style | hits_rawDataList_jp | total_logs
              │
              ├─ hits_hats_style > 0
              │     → A-all (which groups)
              │     → B-all (which host + log.source)
              │     → C-all (rawDataList + Japanese)
              │     → D-all (sample content, limit 10)
              │
              └─ hits_keyword_pii > 0
                    → E-all (confirm keyword counts)
                    → seq 11 Query 2A (which field names)
                    → seq 11 Query 2B (sample, limit 10)
                          │
                          ▼
                    Escalate to app owner (Magaki)
                          │
                          ▼
                    Seq 5: OneAgent masking + OpenPipeline replacePattern
                          │
                          ▼
                    Re-run Master query
                    counts should drop; values should show ***
```

**Seq 6 and seq 7** sit **before** or **beside** this flow when you are still mapping **what** PII types exist on the original AXA spreadsheet hosts. Once you have field names (seq 7) and all host groups (seq 11/13), the master → drill → sample path is your daily audit loop.

---

## Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Run in **Data explorer** | Parse error at `logs` | Logs and Events → Advanced mode (seq 8) |
| Skip **inventory** | Zero hits — you think there is no PII but logs never arrived | Run inventory first |
| Wrong **host group ID** | Zero hits for one group | Copy from `unique.sh` or Hosts → Properties; watch MDM vs CUSTMDMGM |
| Confuse `DATA-INNOVATION-A_MDM` with `DATAENGLF_A_CUSTMDMGM` | Miss customer MDM logs | Compare strings character by character |
| **Regex typo** (unclosed `)`) | DQL error at position NNNN | Seq 10 — close all groups before closing quote |
| **Regex too long** | Dynatrace rejects query | Split insurance (seq 7) and HULFT (seq 10) into two queries; merge counts |
| Sample **without limit** | Too much raw PII on screen | Always `limit 10` on D-all / 2B |
| Only keyword PII on HATS | Miss `rawDataList` blobs | Use `hits_hats_style` and C-all, not only E-all |
| Bulk **export** of `content` | PII leaves Dynatrace | Count in UI; share redacted samples only |

---

## Session map — how seq 6–13 built on each other

| Seq | What it added |
| --- | --- |
| **6** | General discovery pattern: inventory → count by PII type → sample |
| **7** | Insurance Excel field names (20 keys) + per-category regex + mask rules |
| **8** | Correct UI: Logs Advanced vs Data explorer |
| **9** | Expanded host inventory and PII pattern catalog |
| **10** | HULFT field regex (65 keys) + fix unclosed regex group |
| **11** | All-host-group keyword dashboard (1A/1B/2A/2B) — 42 IDs |
| **12** | HATS `rawDataList` pattern on 2 groups (A–D) |
| **13** | All 44 IDs; inventory + master `countIf` + A-all through E-all |

---

## Data flow map

```
App writes log line (stdout, log file)
  → OneAgent on host collects it
  → Dynatrace Grail stores record
       fields: timestamp, content, host.name, log.source, dt.host_group.id
  → You: Logs Advanced mode
       Inventory → Master → Drill (A/B/C/E) → Sample (D, limit 10)
  → Confirmed leak → seq 5 mask at capture + ingest
  → Re-run Master → lower counts, masked values
```

---

## Related files

| File | Role |
| --- | --- |
| `14-explain-pii-dql-queries.md` | This guide |
| `14-explain-pii-dql-queries-question.md` | User question |
| `14-explain-pii-dql-queries-follow.txt` | Chat-ready full explanation |
| `../13-dql-pii-all-servers/` | All 44-server query text |
| `../12-dql-find-hats-rawdata-pii-example/` | HATS 2-group prototype |
| `../11-dql-pii-by-all-host-groups/` | Keyword dashboard 1A–2B |
| `../7-dql-filter-insurance-pii-keywords/` | Insurance 20 field names |
| `../6-dql-search-pii-discovery/` | General PII discovery |
| `../8-dql-wrong-ui-data-explorer-fix/` | Correct Dynatrace UI |
| `../5-dynatrace-pii-hostgroup-axa/` | Masking rollout after discovery |
