# DQL Summarize By Syntax Fix

```
Master query shows 'by isn't allowed here'?
  │
  ├─ Inventory query works (single count + by)?
  │     └─ Yes → problem is NOT missing summarize — it's the multi-countIf shape
  │
  ├─ Multiple countIf columns + by: { field }?
  │     └─ Wrap aggregations in { } before by:
  │           summarize { col1 = countIf(...), col2 = count() }, by: { dt.host_group.id }
  │
  ├─ Still red underline on countIf?
  │     └─ Check every countIf( ... ) has closing )
  │     └─ Multiline and / or inside countIf is OK when parentheses are balanced
  │
  └─ Master still fails after braces fix?
        Run fallback: Query E-all (keyword PII) + Query A-all (HATS-style) separately
        Join rows on dt.host_group.id in a spreadsheet
```

| Question | Answer |
| --- | --- |
| What broke? | Multiple `countIf` columns with `by:` — missing `{ }` around the aggregation block |
| Why did inventory work? | Single `count()` + `by:` does not need braces |
| One-line fix | Add `{` after `summarize` and `},` before `by:` |
| Host group prefix? | Use **C_ALJ** (not C_ALI) — matches seq 13 inventory |

## Summary

Your **inventory query worked** because it has only one aggregation: `summarize log_count = count(), by: { dt.host_group.id }`. The **Master query failed** because it defines **four** aggregations (`hits_keyword_pii`, `hits_hats_style`, `hits_rawDataList_jp`, `total_logs`) and then groups by host group. In Dynatrace DQL, when you combine **multiple named aggregations** (especially multiple `countIf`) **with a `by:` clause**, you must wrap the aggregation list in **curly braces** `{ }`. Without those braces, the parser reaches `by:` in the wrong place and reports `'by' isn't allowed here`. This is a syntax rule, not a problem with your regex or `countIf` logic.

---

## Plain English — what the error means

Think of `summarize` as a spreadsheet pivot:

1. You tell DQL **what to count** (the aggregation columns).
2. You tell DQL **how to group rows** (the `by:` field — here `dt.host_group.id`).

When you have **one** count column, DQL accepts this shape:

```text
| summarize log_count = count(), by: { dt.host_group.id }
```

When you have **several** count columns (your Master query), DQL wants the counts bundled in a block:

```text
| summarize {
    hits_keyword_pii = countIf(...),
    hits_hats_style = countIf(...),
    total_logs = count()
  },
  by: { dt.host_group.id }
```

The `{` opens the "bundle of counts." The `},` closes it **before** `by:`. If you skip the braces, DQL thinks `by:` belongs inside the last `countIf(...)` call — and that is invalid. Hence the error on the `by` line.

**What did NOT cause this error:**

| Checked item | Verdict |
| --- | --- |
| Missing `summarize` keyword | No — `summarize` is present |
| Spaces in `by: { dt.host_group.id }` | Fine — spacing does not matter |
| Multiline `and` inside `countIf` | Fine — parentheses are balanced |
| Wrong host group prefix | Unrelated to parse error — but verify **C_ALJ** in filters |

---

## Broken vs fixed — the one change

**Broken (seq 13 as written):**

```text
| summarize
    hits_keyword_pii = countIf(...),
    hits_hats_style = countIf(...),
    hits_rawDataList_jp = countIf(...),
    total_logs = count()
  by: { dt.host_group.id }    ← parser error here
```

**Fixed:**

```text
| summarize {
    hits_keyword_pii = countIf(...),
    hits_hats_style = countIf(...),
    hits_rawDataList_jp = countIf(...),
    total_logs = count()
  },
  by: { dt.host_group.id }
```

Official Dynatrace example (same pattern): [DQL aggregation commands — summarize with countIf and by](https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language/commands/aggregation-commands)

---

## Corrected full Master query (paste into Logs → Advanced)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_IWFM_E_PRD_T_BE",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_ETL_E_PRD_T_APP",
    "C_ALJ_BU_CLAIMS-RECEPTION-A_ICM_E_PRD_T_DOCHUB",
    "C_ALJ_BU_DATA-INNOVATION-A_MDM_E_PRD_T_APP",
    "C_ALJ_BU_CLAIMS-RECEPTION-A_ICM_E_PRD_T_DB",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB",
    "C_ALJ_BU_MIDDLEWARE-A_SITEMINDER_E_PRD_T_RESERVEPROXY",
    "C_ALJ_BU_ADL_A_OracleDB_E_PRD",
    "C_ALJ_BU_ADL_A_Proxy_E_PRD",
    "C_ALJ_BU_ADL_A_CoreFileServer_E_PRD",
    "C_ALJ_BU_ADL_A_CoreStor_E_PRD",
    "C_ALJ_BU_ADL_A_JP1-AJS3_E_DR",
    "C_ALJ_BU_ADL_A_Web-AP-Server_E_PRD",
    "C_ALJ_BU_ADL_A_DataExtractionTool_E_PRD",
    "C_ALJ_BU_ADL_A_InformationManagement_E_PRD",
    "C_ALJ_BU_ADL_A_AgencyFeeAuto-Send_E_PRD",
    "C_ALJ_BU_ADL_A_Hulft_E_PRD",
    "C_ALJ_BU_ADL_A_Payment_E_PRD",
    "C_ALJ_BU_ADL_A_MQ-PDF-Mail_E_PRD",
    "C_ALJ_BU_ADL_A_Rism_E_PRD",
    "C_ALJ_BU_ADL_A_SMTP_E_PRD",
    "C_ALJ_BU_ADL_A_DocUpload_E_PRD",
    "C_ALJ_BU_ADL_A_Web_E_PRD",
    "C_ALJ_BU_ADL_A_ORA-WFA_E_PRD",
    "C_ALJ_BU_ADL_A_ILMT_E_PRD",
    "C_ALJ_BU_ADL_A_Satellite_E_OA",
    "C_ALJ_BU_ADL_A_Terminal_E_OA",
    "C_ALJ_BU_ADL_A_WSUS_E_PRD",
    "C_ALJ_BU_ADL_A_Backup_E_DR",
    "C_ALJ_BU_ADL_A_DomainController_E_PRD",
    "C_ALJ_BU_ADL_A_EventLogManagement_E_PRD",
    "C_ALJ_BU_ADL_A_GitRedmine_E_OA",
    "C_ALJ_BU_GIC-TOUCHPOINT_A_CANWEB_E_PRD_T_PROXY",
    "C_ALJ_BU_AG-PORTAL-CLOUD_A_AGPORTALAPI_E_PRD_T_PROXY",
    "C_ALJ_BU_NEW-BUSINESS_A_NBWF_E_PRD_T_BATCH",
    "C_ALJ_BU_MSP_A_OUD_E_PRD_T_OUD",
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_MQ_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP"
  })
| summarize {
    hits_keyword_pii = countIf(
      matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
      or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
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
| `hits_keyword_pii` | Lines matching insurance or HULFT field names |
| `hits_hats_style` | Lines with ProcessNdServiceImpl, HatsProcessResponse, or rawDataList |
| `hits_rawDataList_jp` | rawDataList lines that also contain Japanese characters |
| `total_logs` | All log lines for that group in the window |

**Note:** This query scans a large volume (your inventory run showed ~171 GB). Expect several seconds of runtime. Narrow `from:` to `now()-1h` while testing syntax.

---

## Simpler fallback Master — two queries instead of one

Use this if the corrected Master still fails (unlikely) or if the UI struggles with the long regex inside `countIf`.

**Query 1 — keyword PII per group (E-all from seq 13):** one `count()` after filters — no `countIf`, no braces needed.

**Query 2 — HATS-style per group (A-all from seq 13):** same shape.

Run both. Match rows on `dt.host_group.id`. You get the same prioritization table with two columns instead of four.

See `15.sh` for one-line copies of A-all and inventory. Full E-all block is in seq 13 `13-dql-pii-all-servers.md`.

---

## Data flow map

```
Logs (Grail, last 24h)
  │
  ▼
filter in(dt.host_group.id, { 44 C_ALJ IDs })
  │
  ▼
summarize {                          ← braces required for multi-countIf + by
    hits_keyword_pii  = countIf(regex field names),
    hits_hats_style   = countIf(HATS phrases),
    hits_rawDataList_jp = countIf(rawDataList + Japanese),
    total_logs        = count()
  },
  by: { dt.host_group.id }           ← one row per host group
  │
  ▼
sort hits_keyword_pii desc, hits_hats_style desc
  │
  ▼
Table: which groups have the most PII signals
```

---

## Related files

| File | Purpose |
| --- | --- |
| `15-dql-summarize-by-syntax-fix.md` | This answer |
| `15-dql-summarize-by-syntax-fix-question.md` | Original question |
| `15-dql-summarize-by-syntax-fix-follow.txt` | Chat-ready copy |
| `15.sh` | One-line fallback queries |
| `../13-dql-pii-all-servers/13-dql-pii-all-servers.md` | Original Master + drill queries |
| `../14-explain-pii-dql-queries/14-explain-pii-dql-queries.md` | Plain-English walkthrough of all queries |

## Commands

Paste queries from `15.sh` into Dynatrace **Logs and Events → Advanced mode**. See `15.sh` for inventory and A-all one-liners.
