# All PII DQL Queries Full Column L

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
  │     ├─ A/B/C — HATS ProcessNdServiceImpl / rawDataList
  │     └─ email / phone / My Number / EMPLID / password
  │
  ├─ Step 4: HATS narrow — 2 groups + SystemOut
  │
  ├─ Step 5: Per high-risk app (single column L group)
  │     MDM → HR → Filenet APP → Filenet DB → Tax APP → Tax DB → HULFT
  │
  └─ Step 6: Sample limit 10 only after hit_count > 0
        never bulk-export raw content
```

| Question | Answer |
| --- | --- |
| Where to run? | **Logs and Events → Advanced mode** |
| Host group scope? | **Column L** — 56 IDs with `C_ALI_BU_` prefix |
| First query? | **Query 0 — Inventory** |
| Best dashboard? | **Query 1 — Master** — four columns per group |
| Full queries? | **This file** — every query is copy-paste complete |
| After discovery? | Apply masking scoped by column L group |

## Summary

This file contains **28 complete DQL queries** (0–27) for PII discovery on your AXA production hosts, scoped to **column L** `dt.host_group.id` values. Every query that scans all groups includes the full **56-ID** `in(dt.host_group.id, { ... })` block inline — no paste shortcuts. Run **inventory first**, then **Master**, then drill queries. Count before you sample — use `limit 10` on sample queries only.

**Safety:** Read-only DQL. Treat `content` as sensitive. Do not screenshot or export raw PII.

---

## Regex reference

**Insurance (20 fields):**

```text
(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\bdob\b|telNumberOld)
```

**HULFT (65 fields):**

```text
(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)
```

---

## Query 0 — Inventory (no PII)

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
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

## Query 1 — Master PII dashboard

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

## Query 2 — E-all combined (insurance OR full HULFT regex)

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
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 3 — E insurance only (20 fields)

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
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 4 — E HULFT only (full 65 fields)

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
| filter matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 5 — A-all HATS signatures (all 56 groups)

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
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 6 — B-all HATS drill-down (host + log source)

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
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

## Query 7 — C-all rawDataList + Japanese Unicode

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
| filter matchesPhrase(content, "rawDataList")
| filter matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

## Query 8 — C fallback rawDataList + 保険金/健保/TXID/OPID

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
| filter matchesPhrase(content, "rawDataList")
| filter matchesPhrase(content, "保険金")
  or matchesPhrase(content, "健保")
  or matchesPhrase(content, "TXID")
  or matchesPhrase(content, "OPID")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 9 — HATS Query A (2 groups + SystemOut)

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

## Query 10 — HATS Query B drill-down (2 groups)

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
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
```

## Query 11 — HATS Query C rawDataList + Japanese (2 groups)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP"
  })
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "rawDataList")
| filter matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
```

## Query 12 — HATS Query D sample HATS (limit 10)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP")
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "Finish ND processing")
| filter matchesPhrase(content, "HatsProcessResponse")
| filter matchesPhrase(content, "rawDataList")
| fields timestamp, dt.host_group.id, dt.security_context, host.name, log.source, content
| sort timestamp desc
| limit 10
```

## Query 13 — HATS Query D sample CUSTMDMGM (limit 10)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "Finish ND processing")
| filter matchesPhrase(content, "HatsProcessResponse")
| filter matchesPhrase(content, "rawDataList")
| fields timestamp, dt.host_group.id, dt.security_context, host.name, log.source, content
| sort timestamp desc
| limit 10
```

## Query 14 — Email regex (all 56 groups)

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
| filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 15 — Japan mobile phone 090/080/070 (all 56 groups)

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
| filter matchesRegex(content, "\\b0[789]0\\d{8}\\b")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

## Query 16 — My Number 12-digit shape (HR, MDM, Tax groups)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP",
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP",
    "C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB"
  })
| filter matchesRegex(content, "\\b\\d{12}\\b")
| summarize hit_count = count(), by: { dt.host_group.id, host.name }
| sort hit_count desc
```

## Query 17 — EMPLID, customer_id, taxpayer_id (MDM, HR, Filenet groups)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP"
  })
| filter matchesRegex(content, "(?i)(EMPLID|customer_id|CUST_ID|taxpayer_id)")
| summarize hit_count = count(), by: { dt.host_group.id, host.name }
| sort hit_count desc
```

## Query 18 — Password and token (HULFT, FTP, EIP groups)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_FTPSSBTB_E_PRD_T_APP",
    "C_ALI_BU_MIDLWARE_A_EIP_E_PRD_T_APP"
  })
| filter matchesRegex(content, "(?i)(password|passwd|token|Bearer)\\s*[=:]\\s*\\S+")
| summarize hit_count = count(), by: { dt.host_group.id, host.name }
| sort hit_count desc
```

## Query 19 — Query 2A keyword breakdown (example: CUSTMDMGM)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize {
    hits_insuredPerson = countIf(matchesPhrase(content, "insuredPerson")),
    hits_holderName = countIf(matchesPhrase(content, "holderName")),
    hits_holder_name = countIf(matchesPhrase(content, "holder_name")),
    hits_uketorininName1 = countIf(matchesPhrase(content, "uketorininName1")),
    hits_holderKname = countIf(matchesPhrase(content, "holderKname")),
    hits_loginId = countIf(matchesPhrase(content, "loginId")),
    hits_mail = countIf(matchesPhrase(content, "mail")),
    hits_subscriberPh = countIf(matchesPhrase(content, "subscriberPh")),
    hits_kanjiFullAddress = countIf(matchesPhrase(content, "kanjiFullAddress")),
    hits_displayName = countIf(matchesPhrase(content, "displayName")),
    hits_customer_id = countIf(matchesPhrase(content, "customer_id")),
    total = count()
  },
  by: { dt.host_group.id, host.name, log.source }
| sort total desc
| limit 50
```

## Query 20 — Query 2B sample (example: CUSTMDMGM, limit 10)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| fields timestamp, dt.host_group.id, host.name, log.source, content
| sort timestamp desc
| limit 10
```

## Query 21 — MDM (Customer MDM APP)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(customer_id|CUST_ID|insuredPerson|kanjiFullAddress|loginId|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Query 22 — HR (People Soft)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(EMPLID|employee_id|displayName|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Query 23 — Filenet APP

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|document_id|policy|claim|loginId)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Query 24 — Filenet DB

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB")
| filter matchesRegex(content, "(?i)(customer_id|policy|password|user\\s*=|document_id)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Query 25 — Tax APP

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(taxpayer_id|account_no|法人番号)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Query 26 — Tax DB

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB")
| filter matchesRegex(content, "(?i)(taxpayer_id|account_no|法人番号|password)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Query 27 — HULFT

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_MIDLWARE_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(holderName|password|passwd|/[^\\s]+\\.(csv|txt|xml))")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

## Data flow map

```
Excel column L (manual change value)
  └──► dt.host_group.id on each log line

Inventory (query 0)
  └──► log_count per app group

Master (query 1)
  └──► hits_keyword_pii | hits_hats_style | hits_rawDataList_jp | total_logs

Drill (E, A, B, C, email, phone, My Number, EMPLID, password)
  └──► which host.name + log.source leak PII

HATS narrow (queries 9–13)
  └──► SystemOut + rawDataList on HATS and CUSTMDMGM

Per-app (queries 21–27)
  └──► single-group deep dive

Sample (queries 12, 13, 20 — limit 10)
  └──► confirm field shapes for masking rules

Masking apply
  └──► OneAgent + OpenPipeline scoped by column L group
```

---

## Related files

| File | Role |
| --- | --- |
| `19-dql-pii-all-queries-column-l-full.md` | This file — all 28 complete queries |
| `19-dql-pii-all-queries-column-l.md` | Short guide with query map |
| `19-host-group-filter-snippet.dql` | Reusable 56-ID filter block |
| `19.sh` | One-line DQL shortcuts |
| `unique-col-l-live.sh` | 56 column L IDs (one per line) |
| `17-dql-hostgroup-column-l-update/` | Excel L to Dynatrace ID migration |
| `18-explain-column-l-inventory-results/` | How to read inventory table |

## Commands

See `19.sh` for one-line versions. Verify ID count:

```bash
wc -l "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-28/19-dql-pii-all-queries-column-l/unique-col-l-live.sh"
```
