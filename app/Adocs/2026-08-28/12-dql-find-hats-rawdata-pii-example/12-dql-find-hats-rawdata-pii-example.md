# Find HATS rawDataList PII Logs

```
Screenshot shows logs like this — how to find them?
  │
  ├─ Step 0: Right UI?
  │     Logs and Events → Advanced mode (NOT Data explorer — seq 8)
  │
  ├─ Step 1: Narrow by host group
  │     dt.host_group.id = HATS or CUSTMDMGM
  │     └─ these 2 IDs are NOT in seq 11 unique.sh — add them (see below)
  │
  ├─ Step 2: Narrow by log file
  │     log.source == "SystemOut"
  │
  ├─ Step 3: Narrow by app signature
  │     ProcessNdServiceImpl OR HatsProcessResponse OR rawDataList
  │
  ├─ Step 4: Count first (Query A)
  │     summarize hit_count by dt.host_group.id
  │     └─ hit_count > 0 → drill down
  │
  ├─ Step 5: Check for PII inside rawDataList (Query C)
  │     Japanese chars in content (Kanji/Kana)
  │     OR known field labels (TXID, OPID, PN, 保険金)
  │
  └─ Step 6: Sample full lines (Query D, limit 10)
        fields timestamp, dt.host_group.id, log.source, content
        └─ treat content as sensitive — no bulk export
```

| Question | Answer |
| --- | --- |
| What am I looking at? | HATS app logs on **SystemOut** with `HatsProcessResponse` JSON and a **`rawDataList`** field |
| Which host groups? | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP` (HATS) and `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` (CUSTMDMGM) |
| Missing from seq 11? | **Yes** — `unique.sh` has 42 IDs but **not** HATS or DATAENGLF/CUSTMDMGM. Add both before re-running Query 1A from seq 11 |
| First query to run? | **Query A** — count per host group with content filters |
| How to see full log like screenshot? | **Query D** — `fields content`, `limit 10` |
| Link to dashboard workflow? | Same pattern as seq 11: **1A count → 1B drill-down → 2A keywords → 2B sample** |

## Summary

Your screenshot shows Dynatrace **Logs** results (correct UI). Each row is a **SystemOut** line from the **HATS** middleware host group, written by Java class `ProcessNdServiceImpl`. The log body contains `HatsProcessResponse` with a **`rawDataList`** array — mixed alphanumeric IDs plus **Japanese text** (likely customer or policy data = PII).

To find logs like this with DQL, start narrow: filter by **`dt.host_group.id`**, then **`log.source`**, then **content keywords**. Count first (`summarize`), then sample (`limit 10`). The two host groups in your screenshot were **not** in seq 11's `unique.sh` — add them to the `in(...)` block when you run the all-host-group dashboard from seq 11.

**Safety:** DQL discovery is read-only. Do not bulk-export `content` that contains raw PII.

---

## What the screenshot fields mean

| Field | What it means | Value in your example |
| --- | --- | --- |
| `timestamp` | When the log line was written | ~12:19 JST |
| `log.source` | Which log file or stream | `SystemOut` (Java stdout) |
| `dt.host_group.id` | Dynatrace host group tag | HATS or CUSTMDMGM IDs (see table below) |
| `dt.security_context` | Security / ownership label | `ALJ-MIDDLEWARE-SHARED-PRODUCT-HATS-P`, `ALJ-DATAENGLF-CUSTMDMGM-PRD` |
| `content` | Full log line text | Java logger + JSON-like payload with `rawDataList` |

### Host group IDs from your screenshot

| Short name | `dt.host_group.id` | `dt.security_context` |
| --- | --- | --- |
| HATS | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP` | `ALJ-MIDDLEWARE-SHARED-PRODUCT-HATS-P` |
| CUSTMDMGM | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` | `ALJ-DATAENGLF-CUSTMDMGM-PRD` |

**Note:** seq 11 `unique.sh` lists `C_ALJ_BU_DATA-INNOVATION-A_MDM_E_PRD_T_APP` — that is a **different** host group from `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP`. Do not swap them.

---

## Where to run (seq 8 reminder)

1. Left menu → **Logs** (or **Logs and Events**).
2. Switch to **Advanced mode** (DQL editor).
3. Paste a query below.
4. Set time range to cover ~12:15–12:20 JST (or use `from: now()-24h` for a daily sweep).
5. Click **Run**.

Do **not** paste `fetch logs` into **Data explorer** — that screen is for metrics only.

---

## Query A — Count per host group (start here)

Finds SystemOut lines matching HATS signatures, grouped by host group.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

| Column | Meaning |
| --- | --- |
| `dt.host_group.id` | Which host group produced the logs |
| `hit_count` | How many matching lines in the time window |

If `hit_count = 0`, check: wrong host group spelling, time range too narrow, or logs not ingested.

---

## Query B — Drill-down: host + log source (seq 11 Query 1B pattern)

Same filters as Query A, but shows **which host** and confirms **SystemOut**.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
```

---

## Query C — PII inside rawDataList (Japanese + field labels)

**Step 1:** Require `rawDataList` in the line.

**Step 2:** Require Japanese characters (Hiragana, Katakana, or Kanji) — common sign of customer/policy text in JP insurance logs.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "rawDataList")
| filter matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
```

If the Unicode regex fails in your tenant, use phrase fallbacks instead:

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "rawDataList")
| filter matchesPhrase(content, "保険金")
  or matchesPhrase(content, "健保")
  or matchesPhrase(content, "TXID")
  or matchesPhrase(content, "OPID")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

| Pattern | What it catches |
| --- | --- |
| Unicode regex | Any Hiragana, Katakana, or Kanji in the log line |
| `保険金` | Insurance payment (visible in your screenshot context) |
| `TXID`, `OPID`, `PN` | Transaction / operator IDs inside rawDataList payloads |

---

## Query D — Sample full content (like screenshot sidebar)

Shows the full log line. **Use `limit 10` only.**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP")
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "Finish ND processing")
| filter matchesPhrase(content, "HatsProcessResponse")
| filter matchesPhrase(content, "rawDataList")
| fields timestamp, dt.host_group.id, dt.security_context, host.name, log.source, content
| sort timestamp desc
| limit 10
```

To sample **CUSTMDMGM** instead, replace the host group filter:

```text
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP")
```

---

## Query E — Find by security context (alternative filter)

If you know `dt.security_context` but want to double-check host group mapping:

```text
fetch logs, from: now()-24h
| filter in(dt.security_context, {
    "ALJ-MIDDLEWARE-SHARED-PRODUCT-HATS-P",
    "ALJ-DATAENGLF-CUSTMDMGM-PRD"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id, dt.security_context, log.source }
| sort hit_count desc
```

---

## Query F — Single keyword discovery (widest net)

Use when you are not sure which field name appears — finds **any** HATS-related line on SystemOut:

```text
fetch logs, from: now()-1h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP")
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "ProcessNdServiceImpl")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

Then add `HatsProcessResponse` or `rawDataList` filters once you confirm hits.

---

## Link to seq 11 workflow (1A dashboard + drill-down)

Seq 11 gives you a **repeatable audit loop** for all host groups. Use the same steps for HATS:

| Seq 11 step | What it does | HATS equivalent (this seq) |
| --- | --- | --- |
| Query 1A | Dashboard: `hit_count` per `dt.host_group.id` | **Query A** above (2 groups only) |
| Query 1B | Drill-down by `host.name` + `log.source` | **Query B** |
| Query 2A | Which PII keywords matched | **Query C** (rawDataList + Japanese) |
| Query 2B | Sample `content`, `limit 10` | **Query D** |

### Update seq 11 `unique.sh` — add 2 missing IDs

Seq 11's `unique.sh` has **42** host groups. Your screenshot adds **2 more**:

```text
C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP
C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP
```

Append these to `unique.sh`, then add them inside the `in(dt.host_group.id, { ... })` block in seq 11 Query 1A. Re-run the dashboard — HATS and CUSTMDMGM will appear as rows with their own `hit_count`.

For HATS-specific PII, seq 11's insurance + HULFT regex (seq 7 + seq 10) may **not** catch `rawDataList` payloads. Add this extra filter when auditing HATS:

```text
| filter matchesPhrase(content, "rawDataList")
  or matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
```

---

## Content patterns cheat sheet (from your screenshot)

| Pattern | Type | Use in DQL |
| --- | --- | --- |
| `ProcessNdServiceImpl` | Java class name | `matchesPhrase(content, "ProcessNdServiceImpl")` |
| `Finish ND processing` | Log message text | `matchesPhrase(content, "Finish ND processing")` |
| `HatsProcessResponse` | Response object name | `matchesPhrase(content, "HatsProcessResponse")` |
| `rawDataList` | JSON field with raw payload | `matchesPhrase(content, "rawDataList")` |
| `ndResponses` | Nested response key | `matchesPhrase(content, "ndResponses")` |
| Japanese Kanji/Kana | Likely PII text | `matchesRegex` Unicode range or phrase `保険金` |
| `TXID`, `OPID`, `PN` | ID labels in payload | `matchesPhrase` per label |

---

## Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Run in Data explorer | Parse error at `logs` | Use Logs → Advanced mode (seq 8) |
| Wrong host group ID | Zero hits | Copy exact string from screenshot or Hosts → Properties |
| Confuse MDM groups | Miss CUSTMDMGM logs | `DATA-INNOVATION-A_MDM` ≠ `DATAENGLF_A_CUSTMDMGM` |
| Sample with no limit | Too much PII on screen | Always `limit 10` on Query D |
| Skip count step | Hard to prioritize | Run Query A before Query D |

---

## Data flow map

```
HATS Java app (ProcessNdServiceImpl)
  → writes stdout → SystemOut log file on host
  → OneAgent collects log line
  → Dynatrace Grail stores record
       fields: timestamp, log.source, dt.host_group.id, dt.security_context, content
  → You run DQL in Logs Advanced mode
       Query A: count by dt.host_group.id
       Query B: count by host.name + log.source
       Query C: rawDataList + Japanese chars → PII signal
       Query D: fields content, limit 10 → read one line (like screenshot sidebar)
  → Escalate to app owner if rawDataList should not be logged
  → Optional: add HATS filters to seq 11 Query 1A after updating unique.sh
```

---

## Related files

| File | Role |
| --- | --- |
| `12-dql-find-hats-rawdata-pii-example-question.md` | Original question + screenshot notes |
| `12-dql-find-hats-rawdata-pii-example-follow.txt` | Copy-ready chat steps |
| `12.sh` | DQL one-liners |
| `../11-dql-pii-by-all-host-groups/` | Dashboard workflow (1A/1B/2A/2B) |
| `../11-dql-pii-by-all-host-groups/unique.sh` | Host group list — **add HATS + CUSTMDMGM** |
| `../8-dql-wrong-ui-data-explorer-fix/` | Correct UI for log DQL |

## Commands

See `12.sh` for copy-paste DQL one-liners (Query A through F).
