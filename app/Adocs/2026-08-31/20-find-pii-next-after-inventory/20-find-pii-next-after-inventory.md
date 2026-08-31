# Find PII Next After Inventory

## Decision tree

```
You already ran inventory (log_count by dt.host_group.id)
  │
  ├─ High log_count only?
  │     That means chatty apps — NOT proof of PII yet
  │
  ├─ NEXT (required): Query 1 — Master PII dashboard
  │     Counts keyword / HATS / Japanese rawDataList per group
  │     Still NO raw log lines
  │
  ├─ hits_* > 0 on a group?
  │     YES → drill that pattern (Queries 2–8 or 14–18)
  │           then host/file (Query 6 / B-style)
  │           then sample limit 10 ONLY
  │     NO  → try another pattern pack, or shorter time window
  │
  └─ After you confirm real leaks
        Apply masking (scoped by host group)
        Re-run Master — hit columns should drop
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Where you are now | **Query 0 — Inventory** done (your screenshot) |
| What to run next | **Query 1 — Master PII dashboard** |
| What Master does | Counts PII **signals** per host group without showing full log text |
| What Master does not do | Prove every hit is customer PII; it finds likely field names / HATS payloads |
| When to read raw lines | Only after a hit column is **> 0**, and only `limit 10` |
| Full copy-paste queries | `2026-08-28/19-dql-pii-all-queries-column-l/19-dql-pii-all-queries-column-l-full.md` |

---

## Summary

Your screenshot is inventory: Dynatrace counted **all** log lines per `dt.host_group.id`. High numbers (for example MDM ~9M, EIP ~6.8M, Filenet ~5.9M) mean those apps are loud. The next step is to search the **log text** for PII patterns and **count hits** — still without dumping content. Use the Master query from your column L pack, sort by hit columns, then drill only the groups that light up.

---

## Main content

### What PII means here

**PII** = personally identifiable information — data that can identify a person (name, address, phone, customer ID, My Number shape, policy holder fields, and similar).

In your Dynatrace audit, you look for:

| Signal type | Examples |
| --- | --- |
| Insurance / mail field **names** in logs | `insuredPerson`, `loginId`, `kanjiFullAddress` |
| HULFT / holder / bank field **names** | `holderName`, `bankCode`, `policyHolderName` |
| HATS-style middleware | `ProcessNdServiceImpl`, `HatsProcessResponse`, `rawDataList` |
| Japanese text inside `rawDataList` | Stronger customer/policy payload signal |
| Generic shapes | email, 090/080/070 phone, My Number-like 12 digits, password/token words |

### Safe order (do not skip)

| Step | Action | Safe? |
| --- | --- | --- |
| 0 | Inventory — `summarize log_count` (you did this) | Yes |
| 1 | Master — `countIf` PII patterns per group | Yes (counts only) |
| 2 | Drill one pattern / one group | Yes (still counts) |
| 3 | Which host + which log file | Yes (still counts) |
| 4 | `fields content` + `limit 10` | Careful — shows real data |
| 5 | Mask at source / OneAgent / pipeline | Fix |
| 6 | Re-run Master | Prove the fix |

**Rule:** Count first. Sample last. Never bulk-export `content`.

### Where to run

| Step | Action |
| --- | --- |
| 1 | Dynatrace → **Logs and Events** |
| 2 | Switch to **Advanced** / DQL (not Data explorer) |
| 3 | Time range: last **24 hours** (same as inventory) |
| 4 | Paste **Query 1** from the full pack → Run |

### Your inventory top groups (from screenshot) — prioritize these

| Rank | Host group | log_count (approx) | Why care next |
| --- | --- | --- | --- |
| 1 | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | ~9.0M | Customer MDM — high PII risk |
| 2 | `C_ALI_BU_MIDLWARE_A_EIP_E_PRD_T_APP` | ~6.9M | Middleware / integration chatter |
| 3 | `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | ~5.9M | Documents / claims content risk |
| 4 | `C_ALI_BU_ISDIST_A_OEM_E_PRD_T_DB` | ~5.2M | DB host group — check if text logs leak |
| 5 | `C_ALI_BU_MIDLWARE_A_ETLPCBTCH_E_PRD_T_APP` | ~4.3M | Batch ETL — often dumps payloads |
| 6 | `C_ALI_BU_MIDLWARE_A_IWFM_E_PRD_T_APP` | ~2.5M | Workflow middleware |
| 7 | `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | ~2.0M | HR — employee PII risk |
| 8 | `C_ALI_BU_DATA_A_POLICYODS_E_PRD_T_DB` | ~1.7M | Policy ODS |

Loud ≠ leak. Run Master to see which of these actually match PII patterns.

### Next query: Master (use the full pack)

Open and copy **Query 1** from:

`/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-28/19-dql-pii-all-queries-column-l/19-dql-pii-all-queries-column-l-full.md`

That query keeps your full column L `in(dt.host_group.id, { ... })` list and adds:

```text
| summarize {
    hits_keyword_pii = countIf( ... insurance OR HULFT field names ... ),
    hits_hats_style = countIf( ... ProcessNdServiceImpl / HatsProcessResponse / rawDataList ... ),
    hits_rawDataList_jp = countIf( rawDataList AND Japanese characters ),
    total_logs = count()
  },
  by: { dt.host_group.id }
| sort hits_keyword_pii desc, hits_hats_style desc
```

### How to read Master results

| Column | Meaning | What you do |
| --- | --- | --- |
| `hits_keyword_pii` | Lines with insurance/HULFT field names | Sort here first for keyword leaks |
| `hits_hats_style` | HATS-style middleware lines | Drill HATS queries if high |
| `hits_rawDataList_jp` | `rawDataList` plus Japanese text | Highest sensitivity signal |
| `total_logs` | All lines (same idea as inventory) | Compare hit ratio vs volume |

| Reading tip | Detail |
| --- | --- |
| High total, low hits | Chatty but cleaner — good |
| Low total, high hits | Small volume but dirty — still urgent |
| Zero hits everywhere | Patterns may not match; try email/phone queries 14–15 next |

### After Master — pick the path

| If you see… | Run next (from same full pack) |
| --- | --- |
| High `hits_keyword_pii` | Query 2 (combined) or 3/4 (insurance vs HULFT) |
| High `hits_hats_style` | Query 5 → 6 (host + file) → 12/13 sample limit 10 |
| High `hits_rawDataList_jp` | Query 7 / 11 |
| Want email / phone shapes | Queries 14–15 |
| Want one loud app only | Queries 21–27 (MDM, HR, Filenet, Tax, HULFT) |

### Quick one-group starter (optional, after Master)

If Master is slow, test the noisiest MDM group alone for keyword hits:

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|holderName|loginId|kanjiFullAddress|displayName|customer_id|mail)")
| summarize hit_count = count(), by: { dt.host_group.id }
```

If `hit_count > 0`, then sample carefully:

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|holderName|loginId|kanjiFullAddress|displayName|customer_id|mail)")
| fields timestamp, host.name, log.source, content
| limit 10
```

Treat those 10 lines as sensitive. Do not paste them into chat, tickets, or screenshots.

### Safety

| Rule | Why |
| --- | --- |
| Count before sample | Avoids reading unnecessary personal data |
| `limit 10` only | Caps exposure |
| No bulk export of `content` | Prevents spreading PII outside Dynatrace |
| Prefer field-name hits first | Faster and often enough for masking scope |
| Re-run Master after masking | Proves the fix with numbers |

---

## Data flow map

```
[Your screenshot = Query 0 Inventory]
   log_count by dt.host_group.id
            |
            v
[Query 1 Master]  countIf keyword / HATS / JP rawDataList
            |
     hit_count > 0?
       /          \
     YES           NO
      |             |
      v             v
 Drill pattern    Try email/phone queries
 host + file      or shorter window
      |
      v
 Sample limit 10  -->  Mask  -->  Re-run Master
```

---

## Related files

| File | Purpose |
| --- | --- |
| [20.sh](./20.sh) | Open the full Query 1 pack |
| [20-find-pii-next-after-inventory-follow.txt](./20-find-pii-next-after-inventory-follow.txt) | Chat-ready steps |
| Full 28 queries | `2026-08-28/19-dql-pii-all-queries-column-l/19-dql-pii-all-queries-column-l-full.md` |
| Explain pack | `2026-08-28/20-explain-column-l-pii-queries/` |
| DQL how-to | `2026-08-28/27-dql-common-cases-how-to/` |

---

## Commands

See [20.sh](./20.sh). UI-only DQL — no live API calls.
