# DQL PII All Servers

```
Need PII + HATS-style hits on every server?
  │
  ├─ Step 0: Right UI?
  │     Logs and Events → Advanced mode (NOT Data explorer — seq 8)
  │
  ├─ Step 1: Inventory check (no PII filter)
  │     Run Inventory query → log_count per dt.host_group.id
  │     └─ log_count = 0 → ID typo OR no logs in 24h OR agent gap
  │
  ├─ Step 2: Master dashboard (one table)
  │     Run Master query → hits_keyword_pii + hits_hats_style per group
  │     └─ sort by highest column first
  │
  ├─ Step 3: HATS-style sweep (all servers)
  │     Query A-all → count ProcessNdServiceImpl / rawDataList per group
  │     Query B-all → drill-down host.name + log.source
  │     Query C-all → rawDataList + Japanese chars (PII signal)
  │
  ├─ Step 4: Keyword PII sweep (all servers)
  │     Query E-all → insurance + HULFT field names (seq 7 + seq 10)
  │
  ├─ Step 5: Sample one group only
  │     Query D-all → fields content, limit 10
  │     └─ replace YOUR_HOST_GROUP_ID with row from step 2 or 3
  │
  └─ Regex error or query too long?
        ├─ Run Query E-all split (insurance OR HULFT) — see seq 11
        └─ Run Master fallback (two separate queries)
```

| Question | Answer |
| --- | --- |
| How many host groups? | **44** (seq 11 list + HATS + CUSTMDMGM) |
| Where to run? | **Logs and Events → Advanced mode** |
| First query? | **Inventory** — confirm every group sends logs |
| Best dashboard? | **Master query** — keyword PII + HATS-style in one table |
| HATS-only before? | Seq 12 used 2 groups; this seq uses **all 44** |
| Keyword PII before? | Seq 11 Query 1A used 42 groups; this seq adds HATS + CUSTMDMGM |
| Safety | Count first. Sample with `limit 10` only. Do not bulk-export raw PII. |

## Summary

Seq 12 showed how to find **HATS `rawDataList`** logs on two host groups. Seq 11 counted **insurance + HULFT keyword PII** across 42 groups. This guide combines both patterns for **all 44 servers** in `unique.sh`. Start with the **inventory query** to confirm each host group is sending logs. Then run the **master query** for a single dashboard with two hit columns: keyword PII and HATS-style signatures. Drill down with Query A-all through E-all, and sample with Query D-all (`limit 10`) only after you see non-zero counts.

**Safety:** DQL discovery is read-only. Treat `content` as sensitive. Do not bulk-export.

---

## Host group inventory — 44 IDs

Full list in `unique.sh` (one ID per line). Copy the block below into every query.

**New since seq 11:**

| Short name | `dt.host_group.id` |
| --- | --- |
| HATS | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP` |
| CUSTMDMGM | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` |

**Do not confuse:** `C_ALJ_BU_DATA-INNOVATION-A_MDM_E_PRD_T_APP` (MDM) is **not** the same as `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` (CUSTMDMGM).

### `in(dt.host_group.id, { ... })` — all 44

```text
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
```

---

## Inventory query — log count per host group (no PII filter)

Run this **first**. Confirms Dynatrace is receiving logs from each server group in the last 24 hours.

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
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

| Column | Meaning |
| --- | --- |
| `dt.host_group.id` | Host group tag on the log record |
| `log_count` | Total log lines in the last 24h (any content) |

If a group shows `log_count = 0`, check ID spelling in Dynatrace Hosts UI or widen the time range.

---

## Master query — keyword PII + HATS-style hits (one table)

Uses `countIf` to count two different patterns **without filtering rows out**. Each row is one host group.

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
| summarize
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
  by: { dt.host_group.id }
| sort hits_keyword_pii desc, hits_hats_style desc
```

| Column | Meaning |
| --- | --- |
| `hits_keyword_pii` | Lines matching insurance or HULFT field names (seq 7 + seq 10) |
| `hits_hats_style` | Lines with ProcessNdServiceImpl, HatsProcessResponse, or rawDataList |
| `hits_rawDataList_jp` | rawDataList lines that also contain Japanese characters |
| `total_logs` | All log lines for that group in the window |

### Master fallback — if `countIf` with long regex fails

Run **Query E-all** and **Query A-all** separately, then compare `dt.host_group.id` rows in a spreadsheet or notebook.

---

## Query A-all — HATS-style count per host group (all 44)

Counts logs matching HATS app signatures. Does **not** require `SystemOut` so you can discover the pattern on any log source. Add `| filter matchesValue(log.source, "SystemOut")` to match seq 12 exactly.

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
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

---

## Query B-all — HATS-style drill-down (host + log source)

Same content filters as Query A-all, broken down by host and log file.

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
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

---

## Query C-all — rawDataList + Japanese characters (all servers)

Finds `rawDataList` payloads that also contain Hiragana, Katakana, or Kanji — a strong PII signal in JP insurance logs.

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
| filter matchesPhrase(content, "rawDataList")
| filter matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

### Query C-all fallback — phrase labels if Unicode regex fails

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
| filter matchesPhrase(content, "rawDataList")
| filter matchesPhrase(content, "保険金")
  or matchesPhrase(content, "健保")
  or matchesPhrase(content, "TXID")
  or matchesPhrase(content, "OPID")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

---

## Query D-all — sample full content (limit 10)

Replace `YOUR_HOST_GROUP_ID` with a group from Query A-all or Master query where `hit_count > 0`.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "YOUR_HOST_GROUP_ID")
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| fields timestamp, dt.host_group.id, dt.security_context, host.name, log.source, content
| sort timestamp desc
| limit 10
```

Optional: narrow to HATS SystemOut pattern (seq 12 Query D):

```text
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "Finish ND processing")
```

Example host groups to try:

| Short name | Replace with |
| --- | --- |
| HATS | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP` |
| CUSTMDMGM | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` |
| HULFT | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` |

---

## Query E-all — combined keyword PII sweep (seq 11 Query 1A, all 44)

Insurance field names (seq 7) plus HULFT/holder field names (seq 10). Same as seq 11 Query 1A but includes HATS and CUSTMDMGM.

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
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

If regex length fails, use seq 11 split queries (insurance-only and HULFT-only) with this same 44-ID `in(...)` block.

---

## Query map — which query when

| Query | What it counts | When to use |
| --- | --- | --- |
| Inventory | All logs per group | Confirm agents and IDs are correct |
| Master | Keyword PII + HATS-style + rawDataList+JP | One dashboard for prioritization |
| A-all | HATS-style signatures | Find rawDataList outside HATS |
| B-all | A-all + host + log source | See which host/file drives hits |
| C-all | rawDataList + Japanese | Strong PII signal in JP payloads |
| D-all | Sample `content` | Read a few lines after counts |
| E-all | Insurance + HULFT keywords | Same as seq 11, now with 44 IDs |

---

## Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Run in Data explorer | Parse error at `logs` | Use Logs → Advanced mode (seq 8) |
| Wrong host group ID | Zero hits | Copy from `unique.sh` or Hosts UI |
| Confuse MDM vs CUSTMDMGM | Miss customer MDM logs | Check full string character by character |
| Sample with no limit | Too much PII on screen | Always `limit 10` on Query D-all |
| Skip inventory | Cannot tell "no PII" from "no logs" | Run inventory query first |

---

## Data flow map

```
unique.sh (44 host group IDs)
        │
        ▼
Inventory query → log_count per dt.host_group.id
        │
        ├─ log_count = 0 → fix ID or check OneAgent
        │
        └─ log_count > 0
              │
              ▼
        Master query → hits_keyword_pii + hits_hats_style + hits_rawDataList_jp
              │
              ├─ hits_hats_style > 0 → Query B-all → Query C-all → Query D-all (limit 10)
              │
              └─ hits_keyword_pii > 0 → Query E-all confirm → seq 11 Query 2A/2B on that group
                    │
                    ▼
              Escalate to app owner → masking (seq 5)
                    │
                    ▼
              Re-run Master → counts should drop after mask
```

---

## Related files

| File | Role |
| --- | --- |
| `13-dql-pii-all-servers.md` | This guide |
| `13-dql-pii-all-servers-question.md` | User question |
| `13-dql-pii-all-servers-follow.txt` | Chat-ready copy |
| `13.sh` | DQL one-liners |
| `unique.sh` | 44 host group IDs |
| `../11-dql-pii-by-all-host-groups/` | Keyword PII dashboard (42 → now 44) |
| `../12-dql-find-hats-rawdata-pii-example/` | HATS rawDataList example (2 groups) |
| `../8-dql-wrong-ui-data-explorer-fix/` | Correct UI for log DQL |

## Commands

See `13.sh` for copy-paste DQL one-liners. Paste multi-line blocks above into **Logs and Events → Advanced mode**.
