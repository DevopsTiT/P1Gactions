# Explain Column L PII Queries

```
Need to understand the column L PII query pack?
  │
  ├─ Step 0: Right UI?
  │     Logs and Events → Advanced mode (NOT Data explorer)
  │
  ├─ Query 0 — Inventory
  │     "Are logs arriving per app group?" — no PII search yet
  │
  ├─ Query 1 — Master
  │     One dashboard: keyword PII + HATS + rawDataList JP per group
  │
  ├─ Queries 2–8 — Drill by pattern
  │     insurance keys | HULFT keys | HATS | rawDataList Japanese
  │
  ├─ Queries 9–13 — HATS narrow (2 groups + SystemOut)
  │
  ├─ Queries 14–18 — Generic PII shapes (email, phone, My Number, IDs, passwords)
  │
  ├─ Queries 19–20 — Breakdown + sample (limit 10)
  │
  └─ Queries 21–27 — One app per query (MDM, HR, Filenet, Tax, HULFT)
        after masking → re-run Master → hit counts should drop
```

| Question | Answer |
| --- | --- |
| What are these queries for? | **Find** if personal data appears in logs — not to delete or mask yet |
| What is PII? | Names, addresses, IDs, phone numbers, account numbers — data that identifies a person |
| What is DQL? | Dynatrace Query Language — how you search logs in Grail |
| What is `dt.host_group.id`? | A tag on each log line showing which **application group** the server belongs to |
| Why column L? | Excel column L has the **correct** per-app host group ID after migration |
| First query? | **Query 0** — inventory (confirms logs flow before PII hunt) |
| Best dashboard? | **Query 1** — master (four numbers per app group) |
| When to read raw logs? | **Only after** counts are non-zero — queries 12, 13, 20 — **limit 10** |

## Summary

The seq 19 pack has **28 queries (0–27)** scoped to **column L** host groups (`C_ALI_BU_*` in your Dynatrace). They follow one pipeline: **fetch** logs in a time window → **filter** to the right servers and text patterns → **summarize** counts → **sort** → optionally **sample** a few lines. Query 0 checks the pipes are open. Query 1 tells you which app groups likely leak PII **without reading log content**. Drill queries narrow down **which pattern** (insurance field name, HATS payload, email, etc.) and **which host/file**. Per-app queries (21–27) target high-risk systems one at a time. After you apply masking (seq 5), re-run Query 1 — the hit columns should go down.

**Discovery is read-only.** Treat results as sensitive. Never bulk-export `content`.

---

## The pipeline every query shares

| Step | DQL keyword | Plain English |
| --- | --- | --- |
| 1 | `fetch logs, from: now()-24h` | Get log records from the last 24 hours from Grail |
| 2 | `filter in(dt.host_group.id, { ... })` | Keep only logs from servers in your column L app groups |
| 3 | `filter matchesRegex` / `matchesPhrase` | Keep only lines whose **text** matches a PII pattern |
| 4 | `summarize hit_count = count()` | Count how many lines matched — **does not show the line text** |
| 5 | `sort ... desc` | Show the loudest groups or hosts first |
| 6 | `fields content` + `limit 10` | **Sample only** — show up to 10 full log lines |

**Important:** Steps 1–5 are safe counting. Step 6 exposes raw data — use only when you already saw `hit_count > 0`.

---

## What `dt.host_group.id` means here

After your column L migration, each application gets its **own** host group ID instead of sharing one big INFRA bucket.

| Example ID | Application |
| --- | --- |
| `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | Customer Master Data Management |
| `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | People Soft HR |
| `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | Filenet (documents / claims) |
| `C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP` | HULFT file transfer |

Queries 0–8 and 14–15 filter **all 56** column L groups. Queries 21–27 filter **one** group each.

---

## Query-by-query guide

### Query 0 — Inventory

**Question it answers:** Are logs arriving from each column L app group in the last 24 hours?

**What it does NOT do:** Search for PII. It counts **every** log line per group.

**Result columns:**

| Column | Meaning |
| --- | --- |
| `dt.host_group.id` | App group name |
| `log_count` | Total log lines in 24h |

**How to read:** High `log_count` means a **chatty app**, not automatic PII. Zero or missing row means no logs — check host group spelling or OneAgent before running PII queries.

---

### Query 1 — Master PII dashboard

**Question it answers:** Which app groups have the most PII **signals** in one table?

**How it works:** Uses `countIf(...)` — counts lines matching a pattern **without** removing other lines from the total.

**Result columns:**

| Column | What it counts | What it means |
| --- | --- | --- |
| `hits_keyword_pii` | Insurance field names OR HULFT holder/bank field names in log text | Lines that mention keys like `insuredPerson`, `holderName`, `loginId` |
| `hits_hats_style` | `ProcessNdServiceImpl`, `HatsProcessResponse`, or `rawDataList` | Lines from HATS-style middleware logging |
| `hits_rawDataList_jp` | `rawDataList` plus Japanese characters | Strong signal that payload may contain customer/policy text in Japanese |
| `total_logs` | All lines in the group | Denominator — compare hit ratio to total |

**Syntax note:** Multiple `countIf` columns need `summarize { ... }, by: { dt.host_group.id }` with **curly braces** (seq 15 fix).

**How to read:** Sort by `hits_keyword_pii` first for keyword leaks. Sort by `hits_hats_style` for HATS payloads. A group can be high on `total_logs` but low on PII hits — that is good.

---

### Query 2 — E combined (insurance + HULFT keywords)

**Question it answers:** Which groups have **any** insurance or HULFT field **name** in logs?

**Filter:** Full insurance regex (20 fields) **OR** full HULFT regex (65 fields).

**Result:** `hit_count` per `dt.host_group.id`.

**When to use:** Same signal as `hits_keyword_pii` in Master, but as a standalone query if Master fails on syntax length.

---

### Query 3 — E insurance only

**Question it answers:** Which groups mention **insurance mail-service field names** from Excel (seq 7)?

**Examples matched:** `insuredPerson`, `displayName`, `loginId`, `kanjiFullAddress`, `telNumberOld`.

**When to use:** When you care about **policy/customer mail** fields, not HULFT file-transfer fields.

---

### Query 4 — E HULFT only

**Question it answers:** Which groups mention **HULFT / holder / bank** field names?

**Examples matched:** `holderName`, `uketorininName1`, `bankCode`, `policyHolderName`, `mail`.

**When to use:** File transfer and payment-related apps (HULFT, some BAP flows).

**Note:** Regex must end with `personKanaName)` — not `lastName")` (seq 10 typo fix).

---

### Query 5 — A-all HATS signatures

**Question it answers:** Which groups log HATS-style middleware signatures?

**Filter:** `ProcessNdServiceImpl` OR `HatsProcessResponse` OR `rawDataList`.

**When to use:** After Master shows `hits_hats_style > 0`, or to find HATS-like logs outside the dedicated HATS host group.

---

### Query 6 — B-all HATS drill-down

**Question it answers:** **Which server** and **which log file** produce HATS-style lines?

**Extra grouping:** `host.name` and `log.source`.

**When to use:** After Query 5 shows hits — pinpoints the exact host and log path for masking scope.

---

### Query 7 — C-all rawDataList + Japanese

**Question it answers:** Where does `rawDataList` contain **Japanese text** (Kanji/Kana)?

**Why it matters:** IDs alone are less sensitive than Japanese names or addresses embedded in the payload.

**Filter:** `rawDataList` plus Unicode regex for Hiragana, Katakana, Kanji.

---

### Query 8 — C fallback (phrase labels)

**Question it answers:** Same as Query 7 if Unicode regex fails in your tenant.

**Filter:** `rawDataList` plus phrases `保険金`, `健保`, `TXID`, or `OPID`.

---

### Queries 9–13 — HATS narrow (2 groups)

These scope to only:

- `C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP`
- `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP`

Plus **`log.source == "SystemOut"`** — Java stdout, matching your HATS screenshot (seq 12).

| Query | Purpose |
| --- | --- |
| 9 | Count HATS-style lines per group |
| 10 | Same, broken down by host and log source |
| 11 | `rawDataList` with Japanese characters |
| 12 | Sample full lines from **HATS** group — limit 10 |
| 13 | Sample full lines from **CUSTMDMGM** group — limit 10 |

---

### Query 14 — Email addresses

**Question it answers:** Which groups log strings that look like email addresses?

**Pattern:** Standard `@domain.com` shape.

**Caution:** Many apps log service accounts — not every hit is customer PII.

---

### Query 15 — Japan mobile phone

**Question it answers:** Which groups log mobile numbers starting 090, 080, or 070?

**Pattern:** `\b0[789]0` plus 8 digits.

---

### Query 16 — My Number shape (12 digits)

**Question it answers:** Which high-risk groups log 12-digit number sequences?

**Scoped groups:** HR, MDM, Tax APP/DB only.

**Caution:** 12 digits can be other IDs — legal review before treating every hit as My Number.

---

### Query 17 — EMPLID / customer_id / taxpayer_id

**Question it answers:** Which MDM, HR, or Filenet groups log employee or customer identifiers?

**Patterns:** `EMPLID`, `customer_id`, `CUST_ID`, `taxpayer_id`.

---

### Query 18 — Password and token

**Question it answers:** Do HULFT, FTP, or EIP logs contain `password=`, `token=`, or `Bearer` values?

**Scoped groups:** HULFT, FTP SSTB, EIP.

**High severity** if non-zero — credentials in logs.

---

### Query 19 — Keyword breakdown (one group)

**Question it answers:** For **one** host group, which **specific field names** appear most?

**Example group:** `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP`.

**Result columns:** `hits_insuredPerson`, `hits_holderName`, `hits_loginId`, etc., plus `total`.

**When to use:** After Query 2 or Master shows hits on MDM — tells Magaki **which keys** to mask first.

---

### Query 20 — Sample lines (one group)

**Question it answers:** What do the log lines actually look like?

**Shows:** `timestamp`, `host.name`, `log.source`, full `content`.

**Rule:** **limit 10 only.** Run after Query 19 shows non-zero hits.

---

### Queries 21–27 — Per-app deep dive

Each query filters **one** column L group and app-specific patterns.

| Query | Host group | Application | Patterns searched |
| --- | --- | --- | --- |
| 21 | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | Customer MDM | customer_id, insuredPerson, address, loginId, email |
| 22 | `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | People Soft HR | EMPLID, employee_id, displayName, email |
| 23 | `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | Filenet APP | insuredPerson, document_id, policy, claim |
| 24 | `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB` | Filenet DB | customer_id, policy, password, SQL user |
| 25 | `C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP` | Tax payment APP | taxpayer_id, account_no, 法人番号 |
| 26 | `C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB` | Tax payment DB | same plus password in SQL logs |
| 27 | `C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP` | HULFT | holderName, passwords, file paths |

**When to use:** After Master prioritizes an app — run its per-app query before sampling.

---

## Recommended run order

| Order | Query | Why |
| --- | --- | --- |
| 1 | 0 | Confirm logs arrive for column L groups |
| 2 | 1 | One-table priority dashboard |
| 3 | 2 or 3+4 | Keyword drill if Master is unclear |
| 4 | 5 → 6 → 7 | HATS drill if `hits_hats_style > 0` |
| 5 | 9–11 | HATS SystemOut narrow match |
| 6 | 21–27 | Per high-risk app from step 2 |
| 7 | 19 → 20 | Breakdown then sample on worst group |
| 8 | 12 or 13 | HATS sample if that was the signal |

---

## Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Run in Data explorer | Parse error at `logs` | Logs → Advanced mode (seq 8) |
| Sample before count | See raw PII unnecessarily | Always `summarize` first |
| `log_count` = PII leak | False alarm | Inventory counts lines, not sensitive content |
| Master syntax error on `by:` | `'by' isn't allowed here` | Wrap countIf block in `{ }` (seq 15) |
| Wrong host group prefix | Zero hits | Copy exact ID from inventory table (`C_ALI_BU_`) |
| Export many sample rows | Data exposure | **limit 10** maximum |

---

## Data flow map

```
Excel column L → dt.host_group.id on each log line

Query 0 inventory
  └── log_count per app (pipes open?)

Query 1 master
  └── hits_keyword_pii | hits_hats_style | hits_rawDataList_jp | total_logs

Queries 2–8 pattern drill
  └── which pattern fires on which group

Queries 9–13 HATS + SystemOut
  └── rawDataList payloads on HATS / CUSTMDMGM

Queries 14–18 generic shapes
  └── email | phone | 12-digit | IDs | passwords

Queries 19–20 one group
  └── which field names → sample 10 lines

Queries 21–27 per app
  └── MDM | HR | Filenet | Tax | HULFT scoped hunt

Masking (seq 5) → re-run Query 1 → hits should drop
```

---

## Related files

| File | Role |
| --- | --- |
| `20-explain-column-l-pii-queries.md` | This guide |
| `19-dql-pii-all-queries-column-l-full.md` | All 28 complete copy-paste queries |
| `18-explain-column-l-inventory-results/` | How to read Query 0 results |
| `15-dql-summarize-by-syntax-fix/` | Master query brace fix |
| `14-explain-pii-dql-queries/` | Earlier session query explanations |

## Commands

No DQL commands required for this explanation guide. Queries are in seq 19 full file.
