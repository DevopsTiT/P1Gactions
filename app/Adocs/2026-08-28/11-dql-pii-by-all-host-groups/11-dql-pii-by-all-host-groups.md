# DQL PII By All Host Groups

```
Need PII hits across all host groups?
  │
  ├─ Step 0: Verify host group IDs in Dynatrace
  │     Hosts → pick one host → Properties → dt.host_group.id
  │     └─ string must match unique.sh exactly (hyphens, CamelCase)
  │
  ├─ Step 1: Run Query 1A (dashboard)
  │     summarize by dt.host_group.id only
  │     └─ hit_count = 0 for a group? → ID typo OR no logs in 24h
  │
  ├─ Step 2: Run Query 1B (drill-down table)
  │     same filter + summarize by host.name + log.source
  │     └─ see which host and log file drive the count
  │
  ├─ Step 3: Pick host group with hit_count > 0
  │     └─ Run Query 2A (which keywords matched)
  │           └─ Run Query 2B (sample lines, limit 10)
  │
  ├─ Regex error "Unclosed group"?
  │     └─ see seq 10 — close ) before closing "
  │
  └─ Regex too long?
        ├─ Use split: insurance (seq 7) OR HULFT (seq 10)
        └─ Merge results by dt.host_group.id in a notebook
```

| Question | Answer |
| --- | --- |
| How many host groups? | **42 unique** (44 lines in screenshot minus 2 duplicates) |
| What changed from before? | One query for **all** groups instead of 44 separate queries |
| Dashboard metric | `hit_count` per `dt.host_group.id` |
| Detail view | Keyword breakdown (Query 2A) + sample `content` (Query 2B) |
| PII patterns | Combined seq 7 (insurance mail, 20 keys) + seq 10 (HULFT/holder/bank, 65 keys) |
| Where to run? | **Logs and Events → Advanced mode** (not Data explorer — seq 8) |
| Safety | Count first. Sample with `limit 10` only. Do not bulk-export raw PII. |

## Summary

You were running **one DQL query per host group** — slow and hard to compare. These new queries scan **all 42 unique host groups** in a single run, then tell you **how many PII keyword hits** each group has. Start with **Query 1A** (summary by `dt.host_group.id`). For any group with `hit_count > 0`, run **Query 2A** to see **which field names** appeared, then **Query 2B** to read a small sample of log lines (`limit 10`). The PII regex combines insurance field names from seq 7 and HULFT/holder fields from seq 10. If the combined regex is too long, use the split version (Part A + Part B) and add the counts mentally or in a notebook.

**Important:** Host group IDs are case-sensitive and hyphen-sensitive. Copy them from `unique.sh` or verify in Dynatrace Hosts UI before running.

---

## Host group inventory (deduped)

Your `unique.sh` had **44 lines** with **2 duplicates**:

| Duplicate removed | Count in file |
| --- | --- |
| `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | appeared twice (lines 1 and 39) |
| `C_ALJ_BU_MIDDLEWARE-A_SITEMINDER_E_PRD_T_RESERVEPROXY` | appeared twice (lines 10 and 11) |

**Result: 42 unique host group IDs.** Full list is in `unique.sh` in this folder.

### Verify IDs in Dynatrace

1. Open **Hosts**.
2. Click any host in the group you care about.
3. Open **Properties** (or host metadata).
4. Find `dt.host_group.id` — the string must match `unique.sh` **exactly**.
5. Watch for `CLAIMS-RECEPTION-A` (hyphen before `A`) vs `_A_` elsewhere.
6. ADL names mix styles: `OracleDB`, `CoreFileServer`, `Web-AP-Server`, `EventLogManagement`.

---

## PII regex — combined from seq 7 + seq 10

### Part A — Insurance mail-service keys (seq 7, 20 fields)

```text
(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\bdob\b|telNumberOld)
```

### Part B — HULFT / holder / bank keys (seq 10, 65 fields, deduped)

```text
(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)
```

**Note:** `holder_name` (underscore) is from your HULFT screenshot; seq 10 uses `holderName` — both are included.

### Combined filter (use in queries below)

```text
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
```

If Dynatrace rejects regex length, run Part A and Part B as **separate queries** and merge by `dt.host_group.id`.

---

## All 42 host groups — `in(dt.host_group.id, { ... })` block

Copy this block into every query below:

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
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB"
  })
```

---

## Query 1A — Dashboard: how many hits per host group?

**Use this first.** One row per `dt.host_group.id`. Groups with `hit_count = 0` either have no matching PII keys in the last 24 hours, or the host group ID does not match Dynatrace exactly.

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
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

**How to read the result:**

| Column | Meaning |
| --- | --- |
| `dt.host_group.id` | Which host group had matching logs |
| `hit_count` | Number of log lines with any PII keyword in the last 24h |
| Sorted desc | Highest-risk groups at the top |

---

## Query 1B — Drill-down: host group + host + log source

Same filters as 1A, but breaks down **which host** and **which log file** inside each group.

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
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 100
```

---

## Query 2A — Detail: which keywords matched? (one host group)

Replace `YOUR_HOST_GROUP_ID` with a value from Query 1A where `hit_count > 0` (for example `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP`).

This counts how many log lines mention each **high-value keyword** inside that group.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "YOUR_HOST_GROUP_ID")
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize
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
    total = count()
  by: { dt.host_group.id, host.name, log.source }
| sort total desc
| limit 50
```

**How to read:** Any column like `hits_holderName > 0` means that keyword appeared in logs from that host and log source. Add more `countIf(matchesPhrase(...))` lines for other fields from seq 7/10 as needed.

---

## Query 2B — Detail: sample log lines (one host group)

Run only after Query 2A shows hits. Shows **what** the log line looks like.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "YOUR_HOST_GROUP_ID")
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
  or matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| fields timestamp, dt.host_group.id, host.name, log.source, content
| limit 10
```

Optional: narrow to one keyword that Query 2A flagged:

```text
| filter matchesPhrase(content, "holderName")
```

---

## Split queries (if combined regex fails)

### Split 1A — Insurance keys only, all host groups

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
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

### Split 1B — HULFT/holder keys only, all host groups

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
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB"
  })
| filter matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holder_name|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|personKanaName)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

Add `hit_count` from Split 1A and Split 1B per host group for a combined total.

---

## Workflow vs old per-group queries

| Old way (screenshot) | New way (this guide) |
| --- | --- |
| 44 separate queries, one host group each | **1 query** covers all 42 groups |
| Compare results manually in a spreadsheet | Query 1A sorts by `hit_count` automatically |
| Regex different per app | Combined seq 7 + seq 10 regex (or split) |
| `summarize by host.name, log.source` only | Add `dt.host_group.id` to see **which group** |

---

## Safety

| Rule | Why |
| --- | --- |
| Run Query 1A before 2B | Count first, sample second |
| `limit 10` on samples | Less raw PII on screen |
| No bulk export | Spreads PII outside Dynatrace |
| Redact screenshots | Blur names and phone numbers before sharing |
| Verify host group IDs | Wrong string = zero hits (false negative) |

---

## Data flow map

```
unique.sh (44 lines, 42 unique host group IDs)
        │
        ▼
Verify IDs in Dynatrace Hosts UI (casing, hyphens)
        │
        ▼
Query 1A — summarize hit_count by dt.host_group.id
        │
        ├─ hit_count = 0 → check ID spelling OR widen time range
        │
        └─ hit_count > 0
              │
              ├─ Query 1B — breakdown by host.name + log.source
              │
              ├─ Query 2A — which keywords (countIf per field)
              │
              └─ Query 2B — sample content (limit 10)
                    │
                    ▼
              Escalate to app owner → masking (seq 5 OneAgent + OpenPipeline)
                    │
                    ▼
              Re-run Query 1A → values should be *** after mask
```

---

## Related files

| File | Role |
| --- | --- |
| `11-dql-pii-by-all-host-groups.md` | This guide |
| `11-dql-pii-by-all-host-groups-question.md` | User question |
| `11-dql-pii-by-all-host-groups-follow.txt` | Chat-ready copy |
| `11.sh` | Dedupe command + query pointers |
| `unique.sh` | 42 deduped host group IDs (one per line) |
| `7-dql-filter-insurance-pii-keywords/` | Insurance field regex (seq 7) |
| `10-dql-regex-unclosed-group-fix/` | HULFT field regex + typo fix (seq 10) |
| `8-dql-wrong-ui-data-explorer-fix/` | Use Logs Advanced, not Data explorer |

## Commands

Dedupe check and query file locations are in `11.sh`. Paste DQL blocks above into **Logs and Events → Advanced mode**.
