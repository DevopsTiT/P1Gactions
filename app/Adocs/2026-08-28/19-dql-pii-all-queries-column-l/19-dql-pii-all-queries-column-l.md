# All PII DQL Queries Column L

```
Need PII discovery on column L host groups?
  │
  ├─ Step 0: Logs and Events → Advanced mode (NOT Data explorer)
  │
  ├─ Step 1: Inventory — log_count per dt.host_group.id
  │     └─ confirms column L IDs match Dynatrace
  │
  ├─ Step 2: Master — keyword PII + HATS + rawDataList JP (one table)
  │     └─ use summarize { } braces (seq 15)
  │
  ├─ Step 3: Drill by pattern
  │     ├─ E — insurance + HULFT field names
  │     ├─ A/B — HATS ProcessNdServiceImpl / rawDataList
  │     ├─ C — rawDataList + Japanese chars
  │     └─ email / phone / EMPLID / password
  │
  ├─ Step 4: Per high-risk app (single column L group)
  │     MDM → HR → Filenet → Tax → HULFT
  │
  └─ Step 5: Sample limit 10 only after hit_count > 0
        never bulk-export raw content
```

| Question | Answer |
| --- | --- |
| Where to run? | **Logs and Events → Advanced mode** |
| Host group scope? | **Column L** — 56 IDs in `unique-col-l-live.sh` |
| ID prefix in your env? | **`C_ALI_BU_`** (from inventory screenshot) — copy exact strings |
| First query? | **Inventory** (query 0 in `19.sh`) |
| Best dashboard? | **Master** (query 1) — four columns per group |
| All one-liners? | **`19.sh`** — 18 copy-paste DQL commands |
| After discovery? | Apply masking (seq 5) scoped by column L group |

## Summary

This is the **complete PII discovery query pack** for your AXA production hosts, scoped to **column L** `dt.host_group.id` values. Every query uses the 56-ID list from `unique-col-l-live.sh` (live Dynatrace spelling: `C_ALI_BU_`, `MIDLWARE`, `DATAENGI`). Run **inventory first**, then **Master**, then drill queries. Count before you sample — use `limit 10` on sample queries only.

**Safety:** Read-only DQL. Treat `content` as sensitive. Do not screenshot or export raw PII.

---

## Host group list (column L — live Dynatrace)

One ID per line in `unique-col-l-live.sh`. Paste the comma-separated block from `19-host-groups-in.dql` into every `in(dt.host_group.id, { ... })`.

**Top groups from your inventory (seq 18):**

| `dt.host_group.id` | Application |
| --- | --- |
| `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | Filenet |
| `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | Customer MDM |
| `C_ALI_BU_MIDLWARE_A_EIP_E_PRD_T_APP` | EIP |
| `C_ALI_BU_MIDLWARE_A_ETLPCBTCH_E_PRD_T_APP` | ETL |
| `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | People Soft HR |
| `C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP` | HULFT |
| `C_ALI_BU_MIDLWARE_A_IWFM_E_PRD_T_APP` | imageWARE |

**Do not use:** `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` — replaced by per-app column L groups.

---

## Query map — run in this order

| # | Name | What it finds | When |
| --- | --- | --- | --- |
| 0 | Inventory | All log lines per group | First — confirm IDs |
| 1 | Master | Keyword PII + HATS + rawDataList JP + total | One dashboard |
| 2 | E insurance | 20 insurance field names (seq 7) | Keyword sweep |
| 3 | E HULFT | Holder / bank / mail field names | File transfer apps |
| 4 | A-all | HATS signatures all groups | Find rawDataList |
| 5 | B-all | A-all + host + log.source | Drill down |
| 6 | C-all | rawDataList + Japanese Unicode | Strong JP PII signal |
| 7 | HATS narrow | HATS + CUSTMDMGM + SystemOut | Match seq 12 screenshot |
| 8 | Email | `@` address regex | All groups |
| 9 | Phone JP | 090/080/070 mobile | All groups |
| 10 | EMPLID / customer_id | HR + MDM + Filenet | High PII apps |
| 11 | Password / token | HULFT + FTP + EIP | Credential leak |
| 12 | Sample | Full `content` | **limit 10** only |
| 13–17 | Per-app | Single column L group | Targeted hunt |

Full one-liners: **`19.sh`**

---

## Query 0 — Inventory (no PII)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { ... paste from 19-host-groups-in.dql ... })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

---

## Query 1 — Master PII dashboard

**Requires `{ }` around multiple countIf columns** (seq 15 fix).

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { ... column L IDs ... })
| summarize {
    hits_keyword_pii = countIf(
      matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
      or matchesRegex(content, "(?i)(uketorininName1|holderName|holderKname|insuredName|policyHolderName|mail|bankCode|bankName|branchName|telephoneNumber|holderTel|holderZipCode|odsUserId|personKanaName)")
    ),
    hits_hats_style = countIf(
      matchesPhrase(content, "ProcessNdServiceImpl")
      or matchesPhrase(content, "HatsProcessResponse")
      or matchesPhrase(content, "rawDataList")
    ),
    hits_rawDataList_jp = countIf(
      matchesPhrase(content, "rawDataList")
      and matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
    ),
    total_logs = count()
  },
  by: { dt.host_group.id }
| sort hits_keyword_pii desc, hits_hats_style desc
```

| Column | Meaning |
| --- | --- |
| `hits_keyword_pii` | Lines with insurance or HULFT field **names** |
| `hits_hats_style` | HATS app signature in log text |
| `hits_rawDataList_jp` | rawDataList plus Japanese characters |
| `total_logs` | All lines (compare ratio to PII hits) |

---

## Query 2 — Insurance keywords (seq 7 — 20 fields)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { ... column L IDs ... })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

---

## Query 3 — HULFT holder keywords (seq 10)

Use full 65-field regex from seq 10 if shortened version misses hits. Short form in `19.sh` query 3.

---

## Queries 4–6 — HATS and rawDataList

**A-all** — count HATS signatures per group.

**B-all** — same plus `host.name` and `log.source`.

**C-all** — `rawDataList` plus Japanese Unicode range (Hiragana, Katakana, Kanji).

---

## Query 7 — HATS SystemOut (seq 12)

Only two column L groups:

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

---

## Queries 8–11 — Pattern sweeps

| Query | Pattern | Example regex |
| --- | --- | --- |
| Email | `@` in addresses | `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}` |
| Phone JP | Mobile 090/080/070 | `\\b0[789]0\\d{8}\\b` |
| EMPLID / customer_id | HR and MDM IDs | `(?i)(EMPLID|customer_id|CUST_ID|taxpayer_id)` |
| Password / token | Credentials in logs | `(?i)(password|passwd|token|Bearer)\\s*[=:]\\s*\\S+` |

---

## Query 12 — Sample (limit 10)

Only after `hit_count > 0` on the same filters.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|customer_id|loginId)")
| fields timestamp, dt.host_group.id, host.name, log.source, content
| sort timestamp desc
| limit 10
```

---

## Queries 13–17 — Per-app (single column L group)

| Query | `dt.host_group.id` | Focus |
| --- | --- | --- |
| 13 | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | customer_id, insuredPerson, address |
| 14 | `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | EMPLID, employee_id, email |
| 15 | `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | document, policy, claim |
| 16 | `C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP` | taxpayer_id, account |
| 17 | `C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP` | holderName, paths, passwords |

---

## Common mistakes

| Mistake | Fix |
| --- | --- |
| Data explorer | Use Logs → Advanced mode (seq 8) |
| Wrong ID prefix ALJ vs ALI | Copy from inventory table |
| Master `'by' isn't allowed here` | Add `{ }` around countIf block (seq 15) |
| Regex unclosed group on lastName | Use `lastNameKana` not broken `lastName")` (seq 10) |
| Sample before count | Always summarize first |
| Bulk export content | limit 10 only; treat as confidential |

---

## Data flow map

```
Excel column L (manual change value)
  └──► dt.host_group.id on each log line

Inventory (query 0)
  └──► log_count per app group

Master (query 1)
  └──► hits_keyword_pii | hits_hats_style | hits_rawDataList_jp | total_logs

Drill (E, A, B, C, per-app)
  └──► which host.name + log.source leak PII

Sample (query 12, limit 10)
  └──► confirm field shapes for masking rules (seq 5)

Masking apply
  └──► OneAgent + OpenPipeline scoped by column L group
```

---

## Related files

| File | Role |
| --- | --- |
| `19-dql-pii-all-queries-column-l.md` | This guide |
| `19.sh` | All 18 DQL one-liners |
| `unique-col-l-live.sh` | 56 column L IDs (live C_ALI_BU_) |
| `19-host-groups-in.dql` | Comma-separated ID block for paste |
| `17-dql-hostgroup-column-l-update/` | Excel L → B migration |
| `18-explain-column-l-inventory-results/` | How to read inventory table |

## Commands

All DQL in `19.sh`. Example local check:

```bash
wc -l "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-28/19-dql-pii-all-queries-column-l/unique-col-l-live.sh"
```
