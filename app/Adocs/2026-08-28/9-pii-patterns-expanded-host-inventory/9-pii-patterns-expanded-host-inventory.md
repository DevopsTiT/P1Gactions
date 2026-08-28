# PII Patterns For Expanded Host Inventory

```
Expanded spreadsheet row (APP or DB)?
  │
  ├─ APP + HR / Customer MDM / Tax / Filenet / imageWARE?
  │     └─ HIGH PII → run per-host discovery DQL (seq 6) → mask (seq 5)
  │
  ├─ APP + HULFT / ETL / UDM / EIP?
  │     └─ MEDIUM → file paths, column names, payload snippets in errors
  │
  ├─ APP + Load Runner?
  │     └─ MEDIUM → test scripts may embed credentials or sample PII
  │
  ├─ Type = DB?
  │     └─ HIGH at rest → SQL audit logs, bind variables, connection strings
  │
  └─ Insurance field names in log? (seq 7)
        └─ Combined keyword sweep → per-category → mask keys + values
```

```
Discovery workflow (always this order)
  │
  ├─ 1. Inventory count — do logs arrive for every host?
  ├─ 2. Broad keyword sweep — which host.name + log.source leaks?
  ├─ 3. Per-app PII regex — email, EMPLID, My Number, etc.
  ├─ 4. Insurance fields — insuredPerson, loginId, etc. (seq 7)
  ├─ 5. Sample limit 10 — confirm real PII (do not export)
  └─ 6. Apply mask → re-run same DQL → hits should show *** not raw values
```

```
Where to run DQL?
  │
  ├─ Logs and Events → Advanced mode  ← correct (seq 8)
  ├─ Notebooks → DQL cell
  └─ Data explorer  ← WRONG for fetch logs (seq 8)
```

| Question | Answer |
| --- | --- |
| What is PII? | Data that identifies a person — name, ID, address, phone, tax ID, insurance details |
| How do I find it? | DQL discovery queries in **Logs and Events → Advanced** (seq 6, this guide) |
| How do I remove it from logs? | OneAgent masking + OpenPipeline processors scoped by `host.name` (seq 5) |
| Insurance-specific keys? | 20 field names from Excel — seq 7 combined sweep |
| Wrong screen error? | `Metric selector parse error at 'logs'` → use seq 8 fix |
| App owner for validation | Magaki (all visible rows) |

## Summary

Your expanded inventory adds **ETL, UDM, Load Runner, Filenet, more Customer MDM hosts, and six DB servers**. Each application type leaks different PII shapes in logs. Start with an **inventory count** across all host groups, then run **per-app discovery DQL** using the pattern tables below. DB hosts need extra attention because SQL audit logs often echo `SELECT` column lists and bind-variable values. After discovery, apply masking from seq 5 scoped by `host.name`, then re-run the same queries to verify raw values are gone.

**PII** (Personally Identifiable Information) is any data that can identify a specific person. In Japan this often includes My Number (12-digit national ID), Kanji/Kana names, addresses, and phone numbers starting with 090/080/070.

---

## Full inventory from screenshot (all visible rows)

| Hostname | Host group (`dt.host_group.id`) | Application | Dept | Code | Env | Type | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `CEAA0059.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | People Soft Human Resources Management | HR | PSOFT HRMG | PRD | APP | Magaki |
| `CEAA006B.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Customer Master Data Management | DATAENGLF | CUSTMDMGM | PRD | APP | Magaki |
| `CEAA006F.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Enterprise Integration Platform | MIDLWARE | EIP | PRD | APP | Magaki |
| `CEAA007F.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | MIDLWARE | HULFT | PRD | APP | Magaki |
| `CEAA0080.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | MIDLWARE | HULFT | PRD | APP | Magaki |
| `CEAA0081.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | MIDLWARE | HULFT | PRD | APP | Magaki |
| `CEAA0088.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` | Tax Payment Report Management | DATA | TAXRPRTMG | PRD | APP | Magaki |
| `CEAA008F.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | MIDLWARE | IWFM | PRD | APP | Magaki |
| `CEAA0090.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | MIDLWARE | IWFM | PRD | APP | Magaki |
| `CEAA0091.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | MIDLWARE | IWFM | PRD | APP | Magaki |
| `CEAA0092.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | MIDLWARE | IWFM | PRD | APP | Magaki |
| `CEAA101D.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | BC calc | DAMPOSHIN | BCCALC | PRD | DB | Magaki |
| `CEAA204E.prprivmgmt.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | ETL (Power Center and Batch) | MIDLWARE | ETLPCBTCH | PRD | APP | Magaki |
| `CEAA204F.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | ETL (Power Center and Batch) | MIDLWARE | ETLPCBTCH | PRD | APP | Magaki |
| `CEAA2050.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | UDM [TS] | MIDLWARE | UDM | PRD | APP | Magaki |
| `CEAA20BB.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Load Runner [TS] | PLATFARCH | LOADRUNNR | PRD | APP | Magaki |
| `CEAA20CC.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Load Runner [TS] | PLATFARCH | LOADRUNNR | PRD | APP | Magaki |
| `CEAA20F7.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Filenet Foundations (Common with NBWF) | DATAENGLF | FILENETFN | PRD | APP | Magaki |
| `CEAA2115.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP` | Customer Master Data Management | DATAENGLF | CUSTMDMGM | PRD | APP | Magaki |
| `CEAA2116.prprivmgmt.intra` | `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP` | Customer Master Data Management | MIDLWARE | CUSTMDMGM | PRD | APP | Magaki |
| `CEAA309A.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | ETL (Power Center and Batch) | PLATFARCH | ETLPCBTCH | PRD | DB | Magaki |
| `CEAA309B.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | Filenet Foundations (Common with NBWF) | PLATFARCH | FILENETFN | PRD | DB | Magaki |
| `CEAA309C.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | Filenet Foundations (Common with NBWF) | PLATFARCH | FILENETFN | PRD | DB | Magaki |
| `CEAA30B3.prprivmgmt.intra` | `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB` | Tax Payment Report Management | DATA | TAXRPRTMG | PRD | DB | Magaki |
| `CEAA30A6.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | BI CCI Performance Simulation | DATADA | BICCIPSIM | PRD | DB | Magaki |
| `CEAA30AB.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | CANweb | DAMPOSHIN | CANWEB | PRD | DB | Magaki |

**Note:** Hostname casing may vary in Dynatrace (`PRPRIVMGMT` vs `prprivmgmt`). Use `matchesValue(host.name, "CEAA0059*")` or normalize when building filters.

### Unique host groups (expanded)

| Host group | Hosts (count) | Primary apps |
| --- | --- | --- |
| `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | 10 | HR, MDM, EIP, BC calc DB, ETL, UDM, Load Runner, Filenet APP, ETL DB, BI CCI DB, CANweb DB |
| `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | 3 | Hulft |
| `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` | 1 | Tax Payment APP |
| `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB` | 1 | Tax Payment DB |
| `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | 5 | imageWARE, ETL APP |
| `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP` | 1 | Customer MDM |
| `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP` | 1 | Customer MDM |
| `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | 2 | Filenet DB |

**Important:** `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` mixes high-PII apps (HR, MDM) with infra and DB hosts. Always scope masking by **`host.name`**, not host group alone.

---

## Per-application PII map

| Application | Host(s) | PII types (plain English) | Example field names or patterns | Risk tier |
| --- | --- | --- | --- | --- |
| People Soft HR | `CEAA0059` | Employee name, employee ID, email, phone, My Number risk, address | `EMPLID`, `employee_name`, `個人番号` | **High** |
| Customer MDM | `CEAA006B`, `CEAA2115`, `CEAA2116` | Customer name, customer ID, address, phone, email | `customer_id`, `CUST_NAME`, `CUST_ID` | **High** |
| Tax Payment Report | `CEAA0088` (APP), `CEAA30B3` (DB) | Taxpayer ID, bank account numbers, My Number, report refs | `taxpayer_id`, `法人番号`, `TIN`, `account_no` | **High** |
| Filenet Foundations | `CEAA20F7` (APP), `CEAA309B`, `CEAA309C` (DB) | Document metadata, customer refs on scanned forms, claim numbers | `document_id`, `insuredPerson`, policy refs | **High** |
| imageWARE Form Manager | `CEAA008F`–`CEAA0092` | Form field values, applicant name, address, barcode tied to person | `form_data`, `applicant_name`, `postal_code` | **High** |
| Hulft [TS] | `CEAA007F`, `CEAA0080`, `CEAA0081` | File paths with person names, transfer credentials | `password=`, `/data/hr/*.csv` | **Medium** |
| ETL Power Center | `CEAA204E`, `CEAA204F`, `CEAA309A` (DB) | Column names with PII, row data in debug logs, file paths | `CUST_NAME`, `INSERT INTO`, `/etl/customer/` | **Medium** |
| UDM [TS] | `CEAA2050` | Unified data model fields, staging table names, sync payloads | `subscriberAddr`, `insuredPerson` | **Medium** |
| Load Runner [TS] | `CEAA20BB`, `CEAA20CC` | Hardcoded test users, passwords, sample customer data in scripts | `web_set_user`, `lr_save_string`, `password` | **Medium** |
| Enterprise Integration Platform | `CEAA006F` | Message payloads in error logs with customer or employee IDs | XML/JSON fragments, `customer_id` in body | **Medium** |
| BC calc | `CEAA101D` (DB) | Calculation inputs may reference customer or policy IDs | numeric IDs, `customer_id` | **Low–Medium** |
| BI CCI Performance Simulation | `CEAA30A6` (DB) | Simulated customer metrics — may use realistic sample names | `customer_id`, name columns in SQL | **Low–Medium** |
| CANweb | `CEAA30AB` (DB) | Web portal user data if SQL logging enabled | `loginId`, email, phone in queries | **Medium** |

---

## Pattern reference table

| PII category | Regex or DQL pattern | Example value | Notes |
| --- | --- | --- | --- |
| Japanese name (Kanji) | `[一-龯々]{2,8}[　\s][一-龯々]{2,8}` | `青柳 聡` | High false-positive rate — pair with field key |
| Japanese name (Kana) | `[ァ-ヶー]{2,20}` | `ミキ コウタロウ` | Often in `lastNameKana`, `kanaFullAddress` |
| My Number (12-digit) | `\b\d{12}\b` | `123456789012` | Legal review before treating as My Number |
| Email | `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}` | `user@example.co.jp` | Baseline mask on all hosts |
| Japan mobile phone | `\b0[789]0\d{8}\b` | `09077759609` | 090, 080, 070 prefixes |
| Japan landline | `\b0\d{1,4}-\d{1,4}-\d{4}\b` | `03-1234-5678` | Optional — more false positives |
| Employee ID (PeopleSoft) | `(?i)EMPLID[=:\s]+[A-Z0-9]+` | `EMPLID=00012345` | HR host `CEAA0059` |
| Customer ID | `(?i)customer_id[=:\s]+\S+` | `customer_id=C1234567` | MDM hosts |
| Tax ID / TIN | `(?i)taxpayer_id[=:\s]+\S+` | `taxpayer_id=1234567890` | Tax APP and DB |
| Corporate number (法人番号) | `\b\d{13}\b` | `1234567890123` | 13 digits — verify context |
| Japan zip (〒) | `\b\d{3}-?\d{4}\b` | `100-0001` | Often near address fields |
| Address (Kanji) | `kanjiFullAddress[=:\s]+` or key phrase | `東京都千代田区…` | Search key first (seq 7) |
| Address (Kana) | `kanaFullAddress[=:\s]+` | `トウキョウト…` | seq 7 field |
| DOB | `\b(19|20)\d{2}/\d{1,2}/\d{1,2}\b` | `1997/4/30` | `dob`, `subscriberDOB`, `insuredDOB` |
| Insurance — insured name | `insuredPerson[=:\s]+` | `照沼　日菜乃` | seq 7 |
| Insurance — login | `loginId[=:\s]+` | `mkmkktr12@outlook.jp` | seq 7 |
| Insurance — display name | `displayName[=:\s]+` | `三木　光太郎` | seq 7 |
| Insurance — zip | `subscriberZipCode[=:\s]+` | `1000001` | seq 7 |
| DB connection string | `(?i)(jdbc:|password=|user=)\S+` | `jdbc:oracle:thin:@host:1521/sid` | All DB hosts |
| SQL SELECT with names | `(?i)SELECT\s+.*\b(NAME|ADDR|PHONE|EMAIL)\b` | `SELECT CUST_NAME, ADDR FROM …` | DB audit logs |
| SQL bind variables | `(?i)bind\s*[#:]?\d+\s*[=:]\s*\S+` | `bind #1 = 田中太郎` | Oracle / DB2 audit |
| ETL column leak | `(?i)(CUST_NAME|EMPLID|insuredPerson)\b` | column name in Informatica log | ETL hosts |
| ETL file path | `/[^\s]+/(customer|hr|insured)[^\s]*\.(csv|dat|xml)` | `/etl/customer/export_2026.csv` | ETL and Hulft |
| Load Runner credential | `(?i)(web_set_user|lr_save_string|password)\s*[=,]` | `web_set_user("user","pass")` | Load Runner hosts |
| Filenet document ref | `(?i)(document_id|insuredPerson|policyNo)[=:\s]+` | metadata in CE logs | Filenet APP and DB |
| Password or token | `(?i)(password|passwd|token|Bearer)\s*[=:]\s*\S+` | `password=secret123` | All hosts — baseline |

---

## Discovery DQL (Logs and Events → Advanced mode)

Run in **Logs and Events → Advanced mode** — not Data explorer (see seq 8).

### Step 0 — Expanded inventory count (all host groups)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A",
    "C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP",
    "C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP",
    "C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"
  })
| summarize log_count = count(), by: { dt.host_group.id, host.name }
| sort log_count desc
```

**Interpret:** Every spreadsheet host should show `log_count > 0`. Zero → check OneAgent log monitoring on that server.

### Step 1 — All hosts in screenshot (hostname list)

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA0059.PRPRIVMGMT.intra",
    "CEAA006B.PRPRIVMGMT.intra",
    "CEAA006F.PRPRIVMGMT.intra",
    "CEAA007F.PRPRIVMGMT.intra",
    "CEAA0080.PRPRIVMGMT.intra",
    "CEAA0081.PRPRIVMGMT.intra",
    "CEAA0088.PRPRIVMGMT.intra",
    "CEAA008F.PRPRIVMGMT.intra",
    "CEAA0090.PRPRIVMGMT.intra",
    "CEAA0091.PRPRIVMGMT.intra",
    "CEAA0092.PRPRIVMGMT.intra",
    "CEAA101D.PRPRIVMGMT.intra",
    "CEAA204E.prprivmgmt.intra",
    "CEAA204F.prprivmgmt.intra",
    "CEAA2050.prprivmgmt.intra",
    "CEAA20BB.prprivmgmt.intra",
    "CEAA20CC.prprivmgmt.intra",
    "CEAA20F7.prprivmgmt.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra",
    "CEAA309A.prprivmgmt.intra",
    "CEAA309B.prprivmgmt.intra",
    "CEAA309C.prprivmgmt.intra",
    "CEAA30B3.prprivmgmt.intra",
    "CEAA30A6.prprivmgmt.intra",
    "CEAA30AB.prprivmgmt.intra"
  })
| summarize log_count = count(), by: { host.name, log.source }
| sort log_count desc
```

### Step 2 — Per-app PII sweeps

**People Soft HR (`CEAA0059`):**

```text
fetch logs, from: now()-24h
| filter matchesValue(host.name, "CEAA0059*")
| filter matchesRegex(content, "(?i)(EMPLID|employee_id|@|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Customer MDM (all three APP hosts):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA006B.PRPRIVMGMT.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(customer_id|CUST_ID|CUST_NAME|address|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Tax Payment (`CEAA0088` APP + `CEAA30B3` DB):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA0088.PRPRIVMGMT.intra",
    "CEAA30B3.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(taxpayer_id|account_no|TIN|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Filenet (`CEAA20F7` APP + `CEAA309B`, `CEAA309C` DB):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA20F7.prprivmgmt.intra",
    "CEAA309B.prprivmgmt.intra",
    "CEAA309C.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(document_id|insuredPerson|policyNo|customer_id)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**imageWARE (`CEAA008F`–`CEAA0092`):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA008F.PRPRIVMGMT.intra",
    "CEAA0090.PRPRIVMGMT.intra",
    "CEAA0091.PRPRIVMGMT.intra",
    "CEAA0092.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "(?i)(form_data|applicant_name|address|postal_code|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**ETL (`CEAA204E`, `CEAA204F`, `CEAA309A`):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA204E.prprivmgmt.intra",
    "CEAA204F.prprivmgmt.intra",
    "CEAA309A.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(CUST_NAME|EMPLID|insuredPerson|INSERT INTO|/etl/)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**UDM (`CEAA2050`):**

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA2050.prprivmgmt.intra"
| filter matchesRegex(content, "(?i)(subscriberAddr|insuredPerson|kanjiFullAddress|loginId)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Load Runner (`CEAA20BB`, `CEAA20CC`):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA20BB.prprivmgmt.intra",
    "CEAA20CC.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(web_set_user|lr_save_string|password|passwd)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Hulft (`CEAA007F`, `CEAA0080`, `CEAA0081`):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA007F.PRPRIVMGMT.intra",
    "CEAA0080.PRPRIVMGMT.intra",
    "CEAA0081.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Step 3 — Combined insurance keyword sweep (seq 7 link)

Searches all 20 insurance field names from the mail-service Excel in one pass:

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A",
    "C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP",
    "C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP",
    "C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|dob|telNumberOld)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**Sample after count > 0 (limit 10):**

```text
fetch logs, from: now()-24h
| filter matchesValue(host.name, "CEAA20F7*")
| filter matchesPhrase(content, "insuredPerson")
| fields timestamp, log.source, content
| limit 10
```

### Step 4 — DB hosts SQL PII sweep

All six DB hosts — look for SQL echoing names or bind values:

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA101D.PRPRIVMGMT.intra",
    "CEAA309A.prprivmgmt.intra",
    "CEAA309B.prprivmgmt.intra",
    "CEAA309C.prprivmgmt.intra",
    "CEAA30B3.prprivmgmt.intra",
    "CEAA30A6.prprivmgmt.intra",
    "CEAA30AB.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(SELECT\\s+.*\\b(NAME|ADDR|PHONE|EMAIL|CUST_)\\b|bind\\s*[#:]?\\d+|jdbc:|password=)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Sample SQL with bind variables:**

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA30B3.prprivmgmt.intra"
| filter matchesRegex(content, "(?i)(SELECT|INSERT|UPDATE).*")
| fields timestamp, log.source, content
| limit 10
```

---

## How to filter and mask after discovery

Apply rules from seq 5, scoped by `host.name` for shared infra group.

| Layer | Where | Scope example | What it does |
| --- | --- | --- | --- |
| OneAgent | Settings → Log monitoring → Sensitive data masking | Host name = `CEAA0059.PRPRIVMGMT.intra` | Masks PII before log leaves the server |
| OpenPipeline route | Settings → OpenPipeline → Logs → Routes | `matchesValue(host.name, "CEAA30B3*")` | Sends DB logs to a PII pipeline |
| OpenPipeline processor | Inside pipeline | DQL `replacePattern` on `content` | Central backstop at ingest |
| Management zone | Settings → Management zones | Members = high-PII hosts | Limits who can query — does not mask |

**OpenPipeline example — DB host tax (`CEAA30B3`):**

```text
fieldsAdd content = replacePattern(content, "(?i)taxpayer_id[=:\\s]+\\S+", "taxpayer_id=***")
| fieldsAdd content = replacePattern(content, "\\b\\d{12}\\b", "************")
| fieldsAdd content = replacePattern(content, "(?i)(SELECT\\s+)([^;]+)(\\bNAME\\b[^;]*)", "$1***masked_columns***")
| fieldsAdd content = replacePattern(content, "(?i)(password|user)[=:\\s]+\\S+", "$1=***")
```

**OpenPipeline example — Filenet DB (`CEAA309B`, `CEAA309C`):**

```text
fieldsAdd content = replacePattern(content, "(?i)insuredPerson[=:\\s]+[^,\\s]+", "insuredPerson=***")
| fieldsAdd content = replacePattern(content, "(?i)loginId[=:\\s]+\\S+", "loginId=***")
| fieldsAdd content = replacePattern(content, "[一-龯々]{2,8}[　\\s][一-龯々]{2,8}", "***")
```

**Verification:** Re-run the same discovery DQL. You should see keys like `EMPLID=***` or `taxpayer_id=***`, not raw values.

---

## DB hosts — why they need extra patterns

DB servers do not run business apps directly, but their **audit logs** and **listener logs** often leak PII:

| Log type | What leaks | Pattern to search |
| --- | --- | --- |
| SQL audit | Full `SELECT` column lists with `NAME`, `ADDR`, `PHONE` | `(?i)SELECT\s+.*\b(NAME\|ADDR)\b` |
| Bind variable trace | Actual values substituted for `?` or `:1` | `(?i)bind\s*[#:]?\d+\s*[=:]\s*\S+` |
| Connection log | JDBC URL, DB user, sometimes password | `(?i)jdbc:\|password=\|user=` |
| Slow query log | Full query text with literal values | `WHERE\s+\w+\s*=\s*'[^']+'` |
| Export/dump log | File paths to customer CSV exports | `/backup/.*\.(csv\|dmp)` |

| DB host | Application DB | Priority PII in SQL logs |
| --- | --- | --- |
| `CEAA101D` | BC calc | Customer or policy IDs |
| `CEAA309A` | ETL repository | Staging table names, column mappings |
| `CEAA309B`, `CEAA309C` | Filenet | Document metadata, insured person refs |
| `CEAA30B3` | Tax Payment | Taxpayer ID, account numbers |
| `CEAA30A6` | BI CCI simulation | Simulated customer metrics |
| `CEAA30AB` | CANweb | Portal login IDs, user profiles |

---

## Links to prior sequences

| Seq | Topic | Use when |
| --- | --- | --- |
| [5 — Dynatrace PII host group](../5-dynatrace-pii-hostgroup-axa/5-dynatrace-pii-hostgroup-axa.md) | OneAgent rules, OpenPipeline routes, masking rollout by host group | Ready to mask after discovery |
| [6 — DQL search PII discovery](../6-dql-search-pii-discovery/6-dql-search-pii-discovery.md) | Count → sample workflow, per-PII-type regex | First-time audit on original host set |
| [7 — Insurance PII keywords](../7-dql-filter-insurance-pii-keywords/7-dql-filter-insurance-pii-keywords.md) | 20 Excel field names, combined keyword sweep | Filenet, imageWARE, mail-service logs |
| [8 — DQL wrong UI fix](../8-dql-wrong-ui-data-explorer-fix/8-dql-wrong-ui-data-explorer-fix.md) | Data explorer vs Logs Advanced | You see `Metric selector parse error at 'logs'` |

---

## Data flow map

```
Prod-HostGroupUpdate spreadsheet (expanded rows)
  → host.name + dt.host_group.id in Dynatrace
  → OneAgent collects app/DB logs
  → Grail ingest (OpenPipeline optional mask by host.name)
  → DQL discovery in Logs Advanced (this guide + seq 6 + seq 7)
  → Find PII in content / log.source
  → Apply OneAgent + OpenPipeline mask (seq 5)
  → Re-run DQL → verify *** not raw values
  → Magaki sign-off per application
```

---

## Related files

| File | Role |
| --- | --- |
| `9-pii-patterns-expanded-host-inventory.md` | This answer |
| `9-pii-patterns-expanded-host-inventory-question.md` | User question |
| `9-pii-patterns-expanded-host-inventory-follow.txt` | Chat-ready copy |
| `9.sh` | All DQL one-liners |
| `../5-dynatrace-pii-hostgroup-axa/` | Masking rollout |
| `../6-dql-search-pii-discovery/` | Discovery workflow |
| `../7-dql-filter-insurance-pii-keywords/` | Insurance field sweep |
| `../8-dql-wrong-ui-data-explorer-fix/` | Correct UI for DQL |

## Commands

All discovery DQL one-liners are in `9.sh`. Paste into **Logs and Events → Advanced mode**.
