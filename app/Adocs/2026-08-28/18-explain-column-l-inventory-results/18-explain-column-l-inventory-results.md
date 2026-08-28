# Explain Column L Inventory Results

```
Column L inventory screenshot
  │
  ├─ Many rows with per-app dt.host_group.id?
  │     └─ YES → column L migration working (no single INFRA bucket dominating)
  │
  ├─ log_count > 0 for a row?
  │     └─ logs ARE arriving for that app group in last 24h
  │
  ├─ log_count very high (21M)?
  │     └─ chatty app — NOT proof of PII — run Master query next
  │
  ├─ Group in filter but missing from table?
  │     └─ log_count = 0 — host not migrated, ID typo, or no logs
  │
  ├─ ID spelling differs from Excel (ALI vs ALJ, DATAENGI vs DATAENGLF)?
  │     └─ copy EXACT string from Dynatrace Hosts screen or this table
  │
  └─ 313 GB scanned in 44s?
        └─ normal — more groups now have logs; broader scan than seq 16
```

| Question | Answer |
| --- | --- |
| Did the column L update work? | **Yes** — you see **separate app groups** (Filenet, MDM, HR, EIP, ETL, imageWARE) |
| What query is this? | Same **inventory** query — count logs per `dt.host_group.id`, no PII filter |
| What changed vs seq 16? | Seq 16 showed **INFRA** (~5M) mixed with MDM; this table shows **per-app** buckets |
| Top row meaning? | **Filenet** (~21M lines) is the noisiest app in 24h |
| Does 21M mean PII leak? | **No** — only counts lines; PII needs Master / keyword queries |
| Why 313 GB / 44s? | More host groups now return data; Grail scanned more storage |
| ID prefix ALI or ALJ? | Your screenshot shows **`C_ALI_BU_`** — use **exact** IDs from Dynatrace, not guesses |

## Summary

Your screenshot is the **inventory query after switching to column L host groups** (seq 17). It worked. Instead of one big shared **INFRA** bucket, Dynatrace now reports **one row per application group** — Filenet, Customer MDM, EIP, ETL, imageWARE, HR, and others. Each `log_count` is how many log **lines** that app sent in the last 24 hours. High numbers mean **verbose logging**, not automatic proof of personal data. Next step: run the **Master PII query** (seq 13 / 15) on the top rows.

**Important:** Copy host group IDs **exactly** as they appear in this table or on the **Hosts** screen. Your results use `C_ALI_BU_` and spellings like `DATAENGI` and `MIDLWARE` — they may differ slightly from Excel column L or our earlier `C_ALJ_BU_` examples.

---

## What this query does

Same three-step inventory as seq 13 and seq 16:

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { ... column L IDs ... })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

| Step | Meaning |
| --- | --- |
| `fetch logs` | Read log records from Grail (Dynatrace log store) |
| `filter in(dt.host_group.id, { ... })` | Only logs from servers in your column L groups |
| `summarize log_count = count()` | Count lines per group |
| `sort log_count desc` | Loudest apps first |

This query does **not** open log `content`. It does **not** search for names, insurance fields, or `rawDataList`.

---

## What your top rows mean

Values read from your screenshot (approximate — verify in UI):

| `dt.host_group.id` (as shown) | `log_count` | Likely application |
| --- | ---: | --- |
| `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | 21,184,749 | **Filenet Foundations** — document / claims platform (APP tier) |
| `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | 14,509,815 | **Customer Master Data Management** — customer records |
| `C_ALI_BU_MIDLWARE_A_EIP_E_PRD_T_APP` | 10,760,764 | **Enterprise Integration Platform** — message bus / integration |
| `C_ALI_BU_MIDLWARE_A_ETLPCBTCH_E_PRD_T_APP` | 8,370,338 | **ETL Power Center and Batch** |
| `C_ALI_BU_ISDIST_A_OEM_E_PRD_T_DB` | 5,808,434 | **OEM database** (distribution / ISDIST dept) |
| `C_ALI_BU_MIDLWARE_A_IWFM_E_PRD_T_APP` | (visible, lower) | **imageWARE Form Manager** |
| `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | (visible, lower) | **People Soft Human Resources** |
| `C_ALI_BU_DATA_A_POLICYODS_E_PRD_T_DB` | (visible, lower) | **Policy ODS database** |

### How to read the numbers

| Point | Detail |
| --- | --- |
| 21 million Filenet logs | The app logs very frequently — batch jobs, document processing, integration traces |
| ~14.5M MDM | Similar to seq 16 (~14.5M) but now under **DATAENGI…CUSTMDMGM**, not mixed with INFRA |
| Per-app rows | **Column L goal achieved** — you can scope PII rules per application |
| Missing groups | Any ID in your filter with no row = zero logs in 24h (not migrated, typo, or silent app) |

---

## Comparison: seq 16 (before) vs this screenshot (after column L)

| Aspect | Seq 16 (old IDs) | This screenshot (column L) |
| --- | --- | --- |
| Shared INFRA bucket | **5,057,736** logs under `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | **Not in top rows** — apps split out |
| Customer MDM | One row under `DATAENGLF…CUSTMDMGM` | Still ~14.5M under `DATAENGI…CUSTMDMGM` |
| Filenet | Not visible in top 3 | **#1 at ~21M** — now visible as its own group |
| HR (People Soft) | Hidden inside INFRA | Own row: `HR_A_PSOFTHRMG` |
| Scanned data | 171 GB in 3 s | **313 GB in 44 s** — more groups + more volume counted |
| Rows returned | 3 prominent groups | **Many** per-app groups |

---

## ID spelling — copy from Dynatrace, not from memory

Your screenshot shows IDs that differ from some Excel / seq 17 examples:

| What you might expect | What Dynatrace shows | Action |
| --- | --- | --- |
| `C_ALJ_BU_` | `C_ALI_BU_` | Use **`ALI`** if that is what Hosts screen shows |
| `DATAENGLF` | `DATAENGI` | Copy exact dept segment from table |
| `MIDDLEWARE` | `MIDLWARE` | Excel hidden column D value — trust Dynatrace |
| `…FILENETFN…_APP` vs `…_DB` | Filenet APP row at top | Run separate DB row queries for `…FILENETFN…_DB` if needed |

**Rule:** For every DQL filter and masking rule, paste the ID from **this inventory table** or **Hosts → Host group**.

---

## What "313 GB scanned" and "44 s" mean

| Metric | Meaning |
| --- | --- |
| **313 GB scanned** | How much log data Grail read to answer the query |
| **44 s execution** | Wall-clock time — longer than seq 16 because more groups match and return counts |
| Cost / performance | Inventory over 24h on many chatty apps is expensive — use **1h window** for quick checks after changes |

---

## What to do next

| Priority | Action | Why |
| --- | --- | --- |
| 1 | Run **Master query** on top 5 groups (Filenet, MDM, EIP, ETL, OEM DB) | Find PII **keyword** and **HATS-style** hits per group |
| 2 | High PII apps first | MDM, HR, Filenet, Tax — even if not #1 by volume |
| 3 | Per-host verify | `host.name` + `dt.host_group.id` for one server per row |
| 4 | Update `unique-col-l.sh` | Replace any guessed IDs with **exact strings from this screenshot** |
| 5 | Sample only after counts | `limit 10` on `fields content` — never bulk-export raw PII |

Master query: use seq 15 brace syntax; swap `in(dt.host_group.id, { ... })` to IDs copied from this table.

---

## Data flow map

```
Column L host group migration (Dynatrace Hosts)
  each hostname ──► own dt.host_group.id (FILENETFN, CUSTMDMGM, HR, …)

Log ingest (OneAgent)
  every log line tagged with dt.host_group.id

Inventory DQL (this screenshot)
  fetch 24h ──► filter column L IDs ──► count by dt.host_group.id ──► sort desc

Your table
  FILENETFN 21M | CUSTMDMGM 14.5M | EIP 10.7M | …

Next: Master PII query
  same groups ──► countIf(keyword PII) + countIf(HATS rawDataList)
```

---

## Related files

| File | Role |
| --- | --- |
| `18-explain-column-l-inventory-results.md` | This guide |
| `17-dql-hostgroup-column-l-update/` | Column L migration + DQL ID list |
| `16-explain-inventory-query-results/` | Before migration (INFRA bucket) |
| `13-dql-pii-all-servers/` | Master + drill queries |
| `15-dql-summarize-by-syntax-fix/` | Master query `summarize { }` brace fix |

## Commands

No new DQL required — re-run inventory or Master using exact IDs from screenshot. See `18.sh`.
