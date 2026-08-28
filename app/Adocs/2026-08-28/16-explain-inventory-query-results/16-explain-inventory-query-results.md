# Explain Inventory Query Results

```
Screenshot shows inventory query SUCCESS?
  │
  ├─ YES → pipeline works (fetch + filter + summarize)
  │     │
  │     ├─ log_count > 0 → logs ARE arriving for that host group
  │     │     └─ next: run Master query (seq 13) for PII hits
  │     │
  │     ├─ log_count very high (14M) → chatty app, NOT proof of PII
  │     │     └─ prioritize for PII hunt, but count ≠ leak
  │     │
  │     └─ group in filter but NOT in table → log_count = 0
  │           └─ check ID typo, OneAgent, or widen time range
  │
  ├─ Scanned 171 GB in 3s → normal for broad fetch; you pay scan cost
  │
  └─ Master query next?
        └─ use summarize ... by: { dt.host_group.id } syntax (seq 15 fix if error)
```

| Question | Answer |
| --- | --- |
| What query is this? | **Inventory** — counts all log lines per host group, no PII filter |
| Did it work? | **Yes** — 3 groups returned counts; query ran in 3 seconds |
| What is `dt.host_group.id`? | Dynatrace tag that groups servers by application or environment |
| What is `log_count`? | How many log lines that group sent in the last 24 hours |
| Does 14M mean PII leak? | **No** — it means the app is very chatty; PII needs a separate query |
| What is 171 GB scanned? | How much log data Dynatrace read in Grail to answer your question |
| What next? | Run **Master query** (seq 13) on groups with `log_count > 0` |
| Groups with 0 logs? | Missing from table — fix ID or agent before blaming "no PII" |

## Summary

Your screenshot shows the **inventory query** from seq 13 working correctly. It answers one simple question: **"Are logs arriving from each host group in the last 24 hours?"** It does **not** search for PII yet. The three rows mean three applications are actively sending logs. The missing rows mean the other host groups in your filter sent **zero** logs in that window. High `log_count` values tell you which apps are the noisiest — useful for prioritizing the next PII hunt, but **not** proof that personal data is in those logs.

This is a **good result**. You confirmed the pipeline (UI, DQL syntax, host group IDs, Grail access) before running heavier PII queries.

---

## What this query does (inventory, not PII)

The inventory query has three steps:

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { "ID1", "ID2", ... "ID44" })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

| Step | What it means |
| --- | --- |
| `fetch logs, from: now()-24h` | Get every log record from the last 24 hours |
| `filter in(dt.host_group.id, { ... })` | Keep only logs from servers in your host group list |
| `summarize log_count = count(), by: { dt.host_group.id }` | Count how many log lines each group produced |
| `sort log_count desc` | Show the noisiest groups first |

**What it does NOT do:** It does not read log `content`. It does not search for names, addresses, insurance fields, or `rawDataList`. That is the **Master query** and drill queries in seq 13.

Think of inventory as checking whether water is flowing through each pipe before you test whether the water is dirty.

---

## What each column means

| Column | What it is | Plain English |
| --- | --- | --- |
| `dt.host_group.id` | Dynatrace metadata field on each log record | The **application bucket** this server belongs to — like a label on every log line |
| `log_count` | Result of `count()` in summarize | **Total number of log lines** from that bucket in 24 hours — any severity, any message |

`dt.` is a Dynatrace prefix meaning "this field comes from Dynatrace tagging," not from your app's log text.

---

## What your three rows mean

| `dt.host_group.id` | `log_count` | Plain English |
| --- | ---: | --- |
| `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` | 14,506,149 | **Customer MDM** app — about **14.5 million** log lines in 24h (~168 per second average) |
| `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | 5,057,736 | **Shared infrastructure** bucket — about **5 million** lines (many apps share this group) |
| `C_ALJ_BU_AG-PORTAL-CLOUD_A_AGPORTALAPI_E_PRD_T_PROXY` | 1,159,856 | **Agency Portal API proxy** — about **1.2 million** lines |

### What the big numbers mean

| Point | Detail |
| --- | --- |
| 14 million logs | The app logs **a lot** — debug traces, batch jobs, integration calls, heartbeats |
| Not automatically PII | You counted **lines**, not **content**. Most lines may be "request started" or stack traces with no customer data |
| Why prioritize CUSTMDMGM? | Customer Master Data Management handles customer records — high volume **plus** sensitive domain = run PII queries here first |
| Compare to zero | Groups not in the table had `log_count = 0` — either no logs, wrong ID, or agent gap |

**Rule of thumb:** Inventory `log_count` = **how loud** the app is. Master query `hits_keyword_pii` = **whether sensitive field names appear**.

---

## What "171 GB scanned" means

When Dynatrace runs `fetch logs`, it searches the **Grail** log store. **Scanned data** is how much raw log storage it had to read to produce your answer.

| Stat | Your value | What it means |
| --- | --- | --- |
| Execution time | 3 seconds | Query engine is fast — result is trustworthy |
| Scanned data | 171 GB | Dynatrace read 171 GB of log payloads/metadata to count your rows |
| Why so much for 3 rows? | Broad `fetch` with no content filter | It still touches all logs in the time window that match your host group filter |
| Cost implication | Scan-based | Wider time range or more groups = more GB scanned |

This is **normal** for inventory. You are paying scan cost once to confirm the pipe works. Narrower drill queries (one group, one hour) scan less.

---

## Host group ID → application name

Host group IDs follow a naming pattern. Read them left to right:

```text
C_ALJ_BU_<business-unit>_A_<app-id>_E_PRD_T_<layer>

Example: C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP
          │    │         │  │         │  │   │  │
          │    │         │  │         │  │   │  └─ APP = application tier
          │    │         │  │         │  │   └──── T = tenant/type tag
          │    │         │  │         │  └──────── PRD = production
          │    │         │  │         └─────────── E = environment marker
          │    │         │  └───────────────────── CUSTMDMGM = app short code
          │    │         └──────────────────────── A = asset marker
          │    └────────────────────────────────── DATAENGLF = Data Engineering BU
          └─────────────────────────────────────── ALJ company prefix
```

| Host group ID (from screenshot) | App short code | Application name |
| --- | --- | --- |
| `..._CUSTMDMGM_...` | CUSTMDMGM | Customer Master Data Management |
| `..._OS_A_INFRA_...` | INFRA | Shared OS / infrastructure base (HR, ETL, UDM, etc. live here) |
| `..._AGPORTALAPI_...` | AGPORTALAPI | Agency Portal Cloud API (proxy tier) |

**Do not confuse:** `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` (your top row) is **not** the same as `C_ALJ_BU_DATA-INNOVATION-A_MDM_E_PRD_T_APP` (different MDM cluster from seq 9).

---

## Groups with zero logs (missing from table)

Your filter listed many host group IDs. Only **three** returned rows. The rest had **zero** logs in the last 24 hours.

| Possible cause | What to check |
| --- | --- |
| ID typo | Compare ID in query vs Dynatrace **Hosts** UI — one wrong character = zero hits |
| No OneAgent / log ingest | Host exists but log monitoring not enabled or path wrong |
| App idle | Legitimately no logs in 24h (batch-only app between runs) |
| Wrong environment | ID is PRD but you are in a different Dynatrace environment |

**Before running PII queries on a zero-log group:** fix ingestion first. You cannot find PII in logs that never arrived.

---

## What to do next

| Step | Action | Reference |
| --- | --- | --- |
| 1 | **Done** — inventory succeeded for 3 groups | This screenshot |
| 2 | Run **Master query** on the same 44 host groups | seq 13 — adds `hits_keyword_pii`, `hits_hats_style` columns |
| 3 | Sort Master results by highest PII column | Prioritize CUSTMDMGM and INFRA (highest volume) |
| 4 | Drill one hot group | seq 13 Query A-all / B-all / E-all |
| 5 | Sample raw content only after counts | `fields content` + `limit 10` — never bulk export |
| 6 | Investigate zero-log groups separately | Widen to `now()-7d` or check OneAgent on one host |

### Note on pending seq 15 (Master query `by` syntax)

When you move to the **Master query**, use this summarize form:

```text
| summarize
    hits_keyword_pii = countIf(...),
    hits_hats_style = countIf(...),
    by: { dt.host_group.id }
```

If Dynatrace returns a parse error on `by`, see **seq 15** (pending) for the corrected `by:` brace syntax. Your inventory query already uses the correct form — that is why it succeeded.

---

## Why this is GOOD news

| Good sign | Why it matters |
| --- | --- |
| Query returned in 3 seconds | UI, permissions, and DQL syntax are correct |
| Three groups have millions of logs | Log pipeline from server → OneAgent → Grail is working |
| You ran inventory **before** PII | Standard SRE practice — confirm data exists before expensive content search |
| Table shows counts only | You did not pull raw PII into the UI yet |

You are at **Step 1 complete** in the discovery workflow from seq 13 and seq 14:

```text
Inventory (you are here) → Master query → drill → sample → mask (seq 5)
```

---

## Data flow map

```
Production servers (CEAA*.PRPRIVMGMT.intra)
  → OneAgent collects log files / stdout
  → Dynatrace tags each line with dt.host_group.id
  → Grail stores log records (171 GB touched in your scan)
  → You: fetch logs + filter in(host groups) + summarize count
  → Table: dt.host_group.id | log_count
  → Next: Master query adds countIf PII columns on same groups
```

---

## Related files

| File | Role |
| --- | --- |
| `16-explain-inventory-query-results-question.md` | Original question |
| `16-explain-inventory-query-results-follow.txt` | Chat-ready copy |
| `13-dql-pii-all-servers/13-dql-pii-all-servers.md` | Full inventory + Master + drill queries |
| `14-explain-pii-dql-queries/14-explain-pii-dql-queries.md` | Plain-English walkthrough of all queries |
| `9-dynatrace-pii-patterns-host-inventory/9-dynatrace-pii-patterns-host-inventory.md` | Host group ID → application mapping table |
