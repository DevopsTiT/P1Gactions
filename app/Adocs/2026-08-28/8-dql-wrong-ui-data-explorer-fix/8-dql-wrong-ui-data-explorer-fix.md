# Dynatrace DQL Wrong UI Fix

```
Metric selector parse error at 'logs'?
  │
  ├─ You are in Data explorer?
  │     └─ YES → wrong screen. Data explorer = metrics only
  │              Go to Logs and Events → Advanced mode
  │
  ├─ Need DQL for fetch logs?
  │     ├─ Option A: Logs and Events → Advanced mode (best for log queries)
  │     ├─ Option B: Notebooks → new DQL cell
  │     └─ Option C: Log viewer → switch to Grail / DQL tab (if shown)
  │
  ├─ No Advanced mode / no fetch logs in tenant?
  │     └─ Fallback: classic Log viewer text search (no DQL)
  │
  └─ Query runs but zero hits?
        ├─ Fix regex typo: njiFullAddress → kanjiFullAddress
        └─ Add missing keys: kanaFullAddress, contractPerson*, subscriberZipCode
```

| Question | Answer |
| --- | --- |
| Why the error? | **Data explorer** expects a metric selector (e.g. `builtin:host.cpu.usage`), not DQL `fetch logs` |
| Where to run log DQL? | **Logs and Events → Advanced mode** (primary), or **Notebooks → DQL cell** |
| Typo in your query? | `njiFullAddress` → `kanjiFullAddress` |
| Missing keys? | `kanaFullAddress`, `contractPersonKanjiName`, `contractPersonKanaName`, `subscriberZipCode` |
| No Grail yet? | Use classic **Log viewer** text search with field names as keywords |

## Summary

The error is not a bug in your DQL syntax — you pasted a **log query into the metrics screen**. Dynatrace **Data explorer** only understands metric selectors (things like `builtin:host.cpu.usage:splitBy("dt.entity.host")`). When it sees `fetch logs`, it tries to parse `logs` as a metric name and fails at character 6.

Move the same query to **Logs and Events → Advanced mode**, fix the regex typo (`njiFullAddress` → `kanjiFullAddress`), and add the four missing field names. If your tenant does not have Grail log DQL yet, use the classic Log viewer keyword search instead.

---

## What went wrong (plain English)

| Term | What it means |
| --- | --- |
| **Data explorer** | Dynatrace screen for **metrics** (CPU, memory, request rates). Uses metric selector language, not full DQL. |
| **DQL** | Dynatrace Query Language — full query language for logs, spans, events on Grail. Starts with `fetch logs`, `fetch spans`, etc. |
| **Grail** | Dynatrace's log and analytics storage layer. Log DQL needs Grail enabled. |
| **Metric selector** | Short syntax for one metric, e.g. `builtin:host.cpu.usage`. What Data explorer expects. |

Your screenshot shows **Data explorer** with subtitle *"Query for metrics and transform results"*. That confirms you are on the metrics screen. `fetch logs` belongs on a **logs** screen.

---

## Where to run log DQL (step-by-step)

### Option A — Logs and Events → Advanced mode (recommended)

1. Open the **Dynatrace** left menu (hamburger icon, top left).
2. Go to **Logs** (or **Logs and Events**, depending on your tenant version).
3. At the top of the log screen, look for a mode switch:
   - **Simple** / **Log viewer** — keyword search only
   - **Advanced** / **DQL** — full `fetch logs` queries
4. Click **Advanced** (or **Open with DQL**).
5. Paste the corrected query below into the editor.
6. Set time range (e.g. last 24 hours) if not already set.
7. Click **Run query** (or press **Ctrl+Enter** / **Cmd+Enter**).

**What you should see:** A results table with columns like `host.name`, `log.source`, `hit_count` — not a metric selector error.

### Option B — Notebooks → DQL cell

1. Left menu → **Notebooks** (under **Apps** or **Observability**, depending on version).
2. Click **+ New notebook** (or open an existing audit notebook).
3. Click **+ Add cell** → choose **DQL**.
4. Paste the corrected query.
5. Run the cell.

**Good for:** Saving repeatable PII audit queries, sharing with your team, adding charts.

### Option C — Log viewer with Grail tab

Some tenants show a **DQL** or **Query** tab inside the Log viewer itself:

1. Left menu → **Logs**.
2. Open any log stream or the main Log viewer.
3. Look for tabs: **Search** | **DQL** | **Advanced**.
4. Switch to **DQL** and paste the query.

If you only see a plain text search box with no DQL tab, your tenant may not have Grail log DQL — use the fallback below.

---

## Corrected query (copy-paste)

Paste this into **Logs and Events → Advanced mode** (not Data explorer):

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

### What changed vs your original

| Issue | Your query | Fixed |
| --- | --- | --- |
| Wrong screen | Data explorer | Logs and Events → Advanced mode |
| Typo | `njiFullAddress` | `kanjiFullAddress` |
| Missing keys | not present | `kanaFullAddress`, `contractPersonKanjiName`, `contractPersonKanaName`, `subscriberZipCode` |

### Sample query (after count > 0)

When the count query shows hits, pull a small sample to confirm format:

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE"
  })
| filter matchesRegex(content, "(?i)(insuredPersonKanjiName|displayName|loginId|telNumberOld)[=:\\s]+\\S+")
| fields timestamp, host.name, log.source, content
| limit 10
```

Use `limit 10` only — this returns raw PII. Do not export large result sets.

---

## Fallback — no Grail / no log DQL

If **Advanced mode**, **DQL tab**, or `fetch logs` is not available, your tenant may still be on **classic log monitoring** (OneAgent → log viewer, no Grail).

### How to check

| Sign | Meaning |
| --- | --- |
| Left menu shows **Log monitoring** (not **Logs and Events**) | Classic mode likely |
| Log viewer has only a text search box | No DQL |
| `fetch logs` returns "unknown command" or feature not found | Grail not enabled |
| Settings → **Log Monitoring** exists but no **Grail** / **OpenPipeline** | Classic only |

Ask your Dynatrace admin: *"Is Grail enabled for logs? Do we have Logs and Events with DQL?"*

### Classic Log viewer search (no DQL)

1. Left menu → **Log monitoring** → **Log viewer** (or **Logs** → Simple mode).
2. Set time range: last 24 hours.
3. In the search box, search for one field name at a time:

```text
"insuredPersonKanjiName"
```

Or combine with OR (syntax varies by version):

```text
insuredPerson OR displayName OR loginId OR telNumberOld
```

4. Add a **host** or **host group** filter in the filter panel on the left.
5. Select host group `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` if the filter is available.

**Limitation:** Classic search cannot do `summarize count() by host.name` in one step. You search keyword by keyword and note which hosts appear. For full PII audit across 20 field names, Grail DQL is much faster.

### API fallback (if UI has no DQL)

Dynatrace **Log Monitoring API v2** (`/api/v2/logs/search`) accepts a query string. Your admin or automation can search `content` for field names. This still requires log monitoring to be enabled on the hosts.

---

## Quick reference — which screen for what

| You want to… | Go here | Query type |
| --- | --- | --- |
| Query CPU, memory, request rate | **Data explorer** | Metric selector |
| Search logs for PII field names | **Logs and Events → Advanced** | DQL `fetch logs` |
| Build a saved audit report | **Notebooks → DQL cell** | DQL `fetch logs` |
| Quick keyword search (no Grail) | **Log viewer** (Simple) | Plain text search |
| Mask PII at ingest | **Settings → OpenPipeline** | DQL processor (seq 5) |
| Mask PII on host before send | **Settings → Log monitoring → Sensitive data masking** | OneAgent regex (seq 5) |

---

## Data flow map

```
Your DQL query (fetch logs + regex)
        │
        ▼
Wrong screen? ──YES──► Data explorer
        │                    │
        │                    └─► Metric selector parser
        │                         ERROR at 'logs'
        │
        NO (correct screen)
        │
        ▼
Logs and Events → Advanced mode
  OR Notebooks → DQL cell
        │
        ▼
Grail log store
  filter host_group.id
  filter matchesRegex(content, …)
  summarize count by host.name, log.source
        │
        ▼
Results table (hit_count per host + log.source)
        │
        ├─ hit_count > 0 → sample query limit 10
        │                    └─ escalate / apply masking (seq 5, seq 7)
        │
        └─ hit_count = 0 → check typo, time range, host group scope

No Grail?
        │
        ▼
Classic Log viewer keyword search
  (one field name at a time)
```

---

## Related files

| File | Role |
| --- | --- |
| `8-dql-wrong-ui-data-explorer-fix.md` | This guide |
| `8-dql-wrong-ui-data-explorer-fix-question.md` | User question (screenshot) |
| `8-dql-wrong-ui-data-explorer-fix-follow.txt` | Chat-ready copy |
| `8.sh` | DQL one-liners |
| `7-dql-filter-insurance-pii-keywords/` | Full 20-field discovery and masking (seq 7) |
| `6-dql-search-pii-discovery/` | General PII discovery (seq 6) |
| `5-dynatrace-pii-hostgroup-axa/` | AXA host scope (seq 5) |

## Commands

All DQL one-liners are in `8.sh`. Paste into **Logs and Events → Advanced mode** — not Data explorer.
