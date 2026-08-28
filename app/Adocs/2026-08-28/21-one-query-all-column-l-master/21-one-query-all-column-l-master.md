# One Query All Column L Master

```
Need ONE query for all column L host groups?
  │
  ├─ First time / not sure logs flow?
  │     → Query 0 Inventory (log_count only, no PII)
  │
  ├─ PII audit across all apps?  ← USE THIS
  │     → Query 1 Master (this file)
  │
  ├─ Where to run?
  │     Logs and Events → Advanced mode
  │
  └─ After Master shows hits > 0
        → drill queries 2–27 from seq 19, sample limit 10 only
```

| Question | Answer |
| --- | --- |
| Best one query for all column L? | **Master PII dashboard (Query 1)** |
| How many groups? | **56** IDs — full column L list inline |
| What you get | One row per app: keyword PII, HATS, rawDataList JP, total logs |
| UI | **Logs and Events → Advanced mode** |
| If you only need log volume | Query 0 Inventory — not PII |

## Summary

If you can only run **one** query across all column L host groups, use the **Master PII dashboard**. It scans all **56** `C_ALI_BU_*` groups in a single run and returns four numbers per app — without showing raw log content. Sort by `hits_keyword_pii` or `hits_hats_style` to see which apps need drill-down. Run Inventory (Query 0) first only if you have not confirmed logs are arriving.

---

## Why Master is the best single query

| Query | Good for | Why not as the one query |
| --- | --- | --- |
| **Master (Query 1)** | PII priority across all apps | **Best choice** — keyword + HATS + Japanese rawDataList in one table |
| Inventory (Query 0) | Confirm logs arrive | Does not search for PII |
| E combined (Query 2) | Keyword PII only | Misses HATS and rawDataList JP signals |
| Per-app (21–27) | One app deep dive | You must run many queries |

---

## Result columns — how to read

| Column | Meaning |
| --- | --- |
| `dt.host_group.id` | Column L app group name |
| `hits_keyword_pii` | Lines mentioning insurance or HULFT field names |
| `hits_hats_style` | Lines with HATS middleware signatures |
| `hits_rawDataList_jp` | `rawDataList` lines with Japanese characters |
| `total_logs` | All log lines in 24h for that group |

High `hits_*` with low `total_logs` ratio = worth drilling. High `total_logs` alone = chatty app, not automatic PII.

---

## Master query — copy-paste

Paste into **Logs and Events → Advanced mode**. Full text also in `21-one-query-all-column-l-master-master.dql`.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_ADL_A_AgencyFeeAuto-Send_E_PRD",
    "C_ALI_BU_ADL_A_Backup_E_DR",
    "C_ALI_BU_ADL_A_CoreFileServer_E_PRD",
    "C_ALI_BU_ADL_A_CoreStor_E_PRD",
    "C_ALI_BU_ADL_A_DataExtractionTool_E_PRD",
    "C_ALI_BU_ADL_A_DocUpload_E_PRD",
    "C_ALI_BU_ADL_A_DomainController_E_PRD",
    "C_ALI_BU_ADL_A_EventLogManagement_E_PRD",
    "C_ALI_BU_ADL_A_GitRedmine_E_OA",
    "C_ALI_BU_ADL_A_Hulft_E_PRD",
    "C_ALI_BU_ADL_A_ILMT_E_PRD",
    "C_ALI_BU_ADL_A_InformationManagement_E_PRD",
    "C_ALI_BU_ADL_A_JP1-AJS3_E_DR",
    "C_ALI_BU_ADL_A_MQ-PDF-Mail_E_PRD",
    "C_ALI_BU_ADL_A_ORA-WFA_E_PRD",
    "C_ALI_BU_ADL_A_OracleDB_E_PRD",
    "C_ALI_BU_ADL_A_Payment_E_PRD",
    "C_ALI_BU_ADL_A_Proxy_E_PRD",
    "C_ALI_BU_ADL_A_Rism_E_PRD",
    "C_ALI_BU_ADL_A_SMTP_E_PRD",
    "C_ALI_BU_ADL_A_Satellite_E_OA",
    "C_ALI_BU_ADL_A_Terminal_E_OA",
    "C_ALI_BU_ADL_A_WSUS_E_PRD",
    "C_ALI_BU_ADL_A_Web-AP-Server_E_PRD",
    "C_ALI_BU_ADL_A_Web_E_PRD",
    "C_ALI_BU_AG-PORTAL-CLOUD_A_AGPORTALAPI_E_PRD_T_PROXY",
    "C_ALI_BU_CLAIMS-RECEPTION-A_ICM_E_PRD_T_DOCHUB",
    "C_ALI_BU_DAMPOSHIN_A_BCCALC_E_PRD_T_DB",
    "C_ALI_BU_DAMPOSHIN_A_CANWEB_E_PRD_T_DB",
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_DATA_A_POLICYODS_E_PRD_T_DB",
    "C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP",
    "C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB",
    "C_ALI_BU_DATADA_A_BICCIPSIM_E_PRD_T_DB",
    "C_ALI_BU_GIC-TOUCHPOINT_A_CANWEB_E_PRD_T_PROXY",
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP",
    "C_ALI_BU_ISDIST_A_OEM_E_PRD_T_DB",
    "C_ALI_BU_MIDDLEWARE-A_SITEMINDER_E_PRD_T_RESERVEPROXY",
    "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_ETL_E_PRD_T_APP",
    "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_DFS_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_EIP_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_EIP_E_PRD_T_DB",
    "C_ALI_BU_MIDLWARE_A_ETLPCBTCH_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_FTPSSBTB_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_IWFM_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_MQ_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_UDM_E_PRD_T_APP",
    "C_ALI_BU_MSP_A_OUD_E_PRD_T_OUD",
    "C_ALI_BU_NEW-BUSINESS_A_NBWF_E_PRD_T_BATCH",
    "C_ALI_BU_PLATFARCH_A_ETLPCBTCH_E_PRD_T_DB",
    "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP",
    "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB",
    "C_ALI_BU_PLATFARCH_A_LOADRUNNR_E_PRD_T_APP"
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

---

## Data flow map

```
Column L Excel IDs
  → filter in(dt.host_group.id, { 56 IDs })
  → summarize countIf per pattern
  → one row per app group
  → sort by hits_keyword_pii desc
  → pick top apps → seq 19 drill queries → sample limit 10
```

---

## Related files

| File | Role |
| --- | --- |
| `21-one-query-all-column-l-master.md` | This answer |
| `21-one-query-all-column-l-master-master.dql` | Master query file |
| `19-dql-pii-all-queries-column-l-full.md` | Full 28-query pack |
| `20-explain-column-l-pii-queries/` | Plain-English query guide |

## Commands

Open the DQL file in your editor — see `21-one-query-all-column-l-master-master.dql`. Paste into Dynatrace Logs Advanced mode.
