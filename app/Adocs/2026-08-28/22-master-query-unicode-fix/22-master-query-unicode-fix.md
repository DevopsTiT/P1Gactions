# Master Query Unicode Fix

```
Master query red squiggle on line 72?
  │
  ├─ Error: \x{3040} not allowed in DQL regex
  │     Dynatrace only allows \x00–\xFF (two hex digits)
  │
  ├─ Fix hits_rawDataList_jp
  │     → replace Unicode regex with phrase fallback (保険金, TXID, OPID)
  │     OR drop that column — hits_hats_style still counts rawDataList
  │
  ├─ Still "No data" after fix?
  │     → run Inventory (Query 0) alone first
  │     → widen timeframe to now()-7d
  │     → confirm C_ALI_BU_* IDs from inventory table
  │
  └─ Master works?
        sort hits_keyword_pii desc → drill top apps
```

| Question | Answer |
| --- | --- |
| What is the red error? | DQL regex does **not** support `\x{3040}` Unicode ranges |
| What works instead? | **Phrase fallback** for Japanese labels, or remove `hits_rawDataList_jp` |
| Why "No data" with 87 GB scanned? | Invalid regex can break the whole `summarize` block |
| Quick test? | Run Inventory only — if that returns rows, host groups are OK |

## Summary

Your screenshot shows a syntax warning on **line 72**: `[\x{3040}-\x{309F}...]`. Dynatrace DQL regex only allows `\x00` through `\xFF` with **exactly two** hexadecimal digits. Code points above 255 (Japanese Hiragana, Katakana, Kanji) cannot use `\x{XXXX}` in this engine. That invalid pattern likely causes **"No data that matches your query"** even though 87 GB was scanned. Replace `hits_rawDataList_jp` with the **phrase fallback** below, or remove that column and rely on `hits_hats_style` (which already counts `rawDataList` lines).

---

## The broken line

```text
and matchesRegex(content, "[\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]")
```

**Tooltip meaning:** Only ASCII and Latin-1 (`\x00`–`\xFF`) work in `\xNN` form. Four-digit Unicode escapes are not supported.

---

## Fixed line — phrase fallback (use this)

Replace the whole `hits_rawDataList_jp` block with:

```text
hits_rawDataList_jp = countIf(
  matchesPhrase(content, "rawDataList")
  and (
    matchesPhrase(content, "保険金")
    or matchesPhrase(content, "健保")
    or matchesPhrase(content, "TXID")
    or matchesPhrase(content, "OPID")
  )
),
```

This matches the seq 19 **Query 8 fallback** approach. It finds `rawDataList` payloads that also contain known Japanese insurance label phrases.

---

## Option B — simpler Master (drop Japanese column)

If you want the shortest fix, **delete** the `hits_rawDataList_jp` block entirely. You still get:

| Column | Still works |
| --- | --- |
| `hits_keyword_pii` | Yes |
| `hits_hats_style` | Yes — includes all `rawDataList` lines |
| `total_logs` | Yes |

Run Query 7 or Query 8 separately later for Japanese drill-down.

---

## Full fixed Master query — copy-paste

Paste into **Logs and Events → Advanced mode**. Same as seq 21 Master with phrase fallback on line 72.

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
      and (
        matchesPhrase(content, "保険金")
        or matchesPhrase(content, "健保")
        or matchesPhrase(content, "TXID")
        or matchesPhrase(content, "OPID")
      )
    ),
    total_logs = count()
  },
  by: { dt.host_group.id }
| sort hits_keyword_pii desc, hits_hats_style desc
```

---

## If still "No data" after fix

| Check | Action |
| --- | --- |
| Host groups OK? | Run Query 0 Inventory only — expect one row per group with `log_count` |
| Time window | Try `from: now()-7d` if 24h is quiet |
| UI | Logs → Advanced mode, not Data explorer |
| Summarize braces | Multiple `countIf` need `summarize { ... }, by: { ... }` |

---

## Data flow map

```
Master query
  → filter 56 column L host groups
  → summarize countIf (keyword + HATS + rawDataList phrases)
  → by dt.host_group.id
  → sort hits_keyword_pii desc

Broken path (old):
  matchesRegex [\x{3040}-...]  → DQL parse error → no rows

Fixed path:
  matchesPhrase 保険金 / TXID / OPID  → runs clean
```

---

## Related files

| File | Role |
| --- | --- |
| `22-master-query-unicode-fix.md` | This fix |
| `22-master-query-unicode-fix-master.dql` | Fixed Master query file |
| `21-one-query-all-column-l-master/` | Original Master (update to use this fix) |
| `19-dql-pii-all-queries-column-l-full.md` | Query 8 = same phrase fallback |
