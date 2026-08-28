# Dynatrace PII Patterns and Host Inventory

```
Expanded HostNames spreadsheet in hand?
  │
  ├─ Step 0: Confirm logs arrive (inventory count by host.name)
  │     └─ zero logs → fix OneAgent / log path before PII hunt
  │
  ├─ Step 1: Combined keyword sweep (count by host + log.source)
  │     └─ hit_count > 0 → drill into that app
  │
  ├─ Step 2: Per high-risk app (HR → MDM → Tax → imageWARE → Filenet → ETL)
  │     ├─ APP row → application logs (stdout, app log files)
  │     └─ DB row → database / listener / audit logs (different log.source)
  │
  ├─ Step 3: Per PII pattern (email, EMPLID, My Number, insurance fields)
  │     └─ count first → sample limit 10 only
  │
  ├─ Step 4: Escalate to Magaki (app owner) + apply masking (seq 5 / seq 7)
  │
  └─ Safety: read-only DQL, no broad export, restricted notebook
```

```
Where to run DQL?
  │
  ├─ Logs and Events → Advanced mode  ← correct (seq 8)
  ├─ Notebooks → DQL cell
  └─ Data explorer  ← WRONG for fetch logs (metrics only)
```

| Question | Answer |
| --- | --- |
| What is this guide? | **Discovery** — find what PII is in logs on the expanded production host list |
| Where to run DQL? | **Logs and Events → Advanced mode** (not Data explorer — see seq 8) |
| Highest-risk apps? | People Soft HR, Customer MDM (two host groups), Tax Payment, Filenet |
| New host group? | `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE` (MDM cluster) |
| APP vs DB? | Same app, different servers — check **both** log sources |
| After discovery? | Mask with seq 5 (host group rules) and seq 7 (insurance field names) |

## Summary

This guide maps every visible row from your expanded **HostNames** spreadsheet to **likely PII types** and **copy-paste DQL** you can run in Dynatrace. Start with an inventory count (do logs arrive?), run a **combined keyword sweep**, then drill into **high-risk apps** (HR, MDM, Tax) and **per-pattern regex** (email, EMPLID, My Number, insurance fields from seq 7). Always **count before you sample** — use `limit 10` on sample queries only. When you find leaks, apply masking from seq 5 and re-run verification.

**DQL is read-only for discovery.** Treat results as sensitive. Do not screenshot or export raw PII to shared channels.

---

## Full host inventory (extracted from screenshot)

All rows are **PRD**, owner **Magaki**. Hostnames use `CEAA` prefix; casing varies between `.PRPRIVMGMT.intra` and `.prprivmgmt.intra` — Dynatrace may store either; include both in filters if needed.

| Row | Hostname | host_group.id | Application | App ID | Type |
| --- | --- | --- | --- | --- | --- |
| 3 | (partial — DFS host) | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | DFS [TS] | DFS | APP |
| 4 | `CEAA0059.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | People Soft Human Resources Management | PSOFTHRMG | APP |
| 5 | `CEAA006B.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Customer Master Data Management | CUSTMDMGM | APP |
| 6 | `CEAA006F.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Enterprise Integration Platform | EIP | APP |
| 7 | `CEAA007F.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | HULFT | APP |
| 8 | `CEAA0080.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | HULFT | APP |
| 9 | `CEAA0081.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | HULFT | APP |
| 10 | `CEAA0088.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_APP` | Tax Payment Report Management | TAXRPRTMG | APP |
| 11 | `CEAA008F.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | IWFM | APP |
| 12 | `CEAA0090.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | IWFM | APP |
| 13 | `CEAA0091.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | IWFM | APP |
| 14 | `CEAA0092.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE Form Manager | IWFM | APP |
| — | `CEAA101D.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | BC calc | BICCALC | DB |
| 15 | `CEAA204E.prprivmgmt.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | ETL (Power Center and Batch) | ETLPCBTCH | APP |
| 16 | `CEAA204F.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | ETL (Power Center and Batch) | ETLPCBTCH | APP |
| 17 | `CEAA2090.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | ETL (Power Center and Batch) | ETLPCBTCH | APP |
| 18 | `CEAA20B8.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | UDM [TS] | UDM | APP |
| 19 | `CEAA20CB.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Load Runner [TS] | LOADRUNNR | APP |
| 20 | `CEAA20CC.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Load Runner [TS] | LOADRUNNR | APP |
| 21 | `CEAA20F7.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP` | Filenet Foundations (Common with NBWF) | FILENETFN | APP |
| 22 | `CEAA2115.prprivmgmt.intra` | `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE` | Customer Master Data Management | CUSTMDMGM | APP |
| 23 | `CEAA2116.prprivmgmt.intra` | `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE` | Customer Master Data Management | CUSTMDMGM | APP |
| 24 | `CEAA309A.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | ETL (Power Center and Batch) | ETLPCBTCH | DB |
| 25 | `CEAA309B.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | Filenet Foundations (Common with NBWF) | FILENETFN | DB |
| 26 | `CEAA309C.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | Filenet Foundations (Common with NBWF) | FILENETFN | DB |
| 27 | `CEAA30A3.prprivmgmt.intra` | `C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_DB` | Tax Payment Report Management | TAXRPRTMG | DB |
| 28 | `CEAA30A6.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | BI CCI Performance Simulation | BICCIPSIM | DB |
| — | `CEAA30AB.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | CANweb | CANWEB | DB |

**Red-highlighted rows in spreadsheet:** imageWARE (`CEAA008F`–`CEAA0092`), Filenet APP (`CEAA20F7`), Filenet DB (`CEAA309B`, `CEAA309C`) — treat as priority validation targets.

### Unique host groups (expanded list)

| host_group.id | Apps on this group |
| --- | --- |
| `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | DFS, People Soft HR, Customer MDM (legacy), EIP, ETL, UDM, Load Runner, BC calc, BICCIPSIM, CANweb |
| `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] |
| `C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_APP` | Tax Payment (APP) |
| `C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_DB` | Tax Payment (DB) |
| `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | imageWARE, ETL |
| `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE` | Customer MDM (dedicated cluster) |
| `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP` | Filenet Foundations (APP) |
| `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | Filenet Foundations (DB) |

**Note:** Earlier seq 5 used `EAA` prefix and slightly different host group spellings (e.g. `TAXPAYMENT` without hyphen). Verify actual values in Dynatrace **Hosts** screen before locking rules.

---

## Per-application PII map

| Application | Hostname(s) | host_group.id | What PII likely in logs | Dynatrace search patterns |
| --- | --- | --- | --- | --- |
| People Soft HR | `CEAA0059.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Employee names (Kanji/Kana), EMPLID, email, phone, address, My Number risk | `matchesPhrase(content, "EMPLID")`, `(?i)employee_id[=:\\s]+`, email regex, `\\b\\d{12}\\b` |
| Customer MDM (legacy) | `CEAA006B.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Customer name, customer_id, address, phone, email, insurance fields (seq 7) | `(?i)customer_id[=:\\s]+`, `CUST_ID`, `CUST_NAME`, `insuredPerson`, `kanjiFullAddress` |
| Customer MDM (cluster) | `CEAA2115`, `CEAA2116` | `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE` | Same as MDM — higher volume on dedicated hosts | Same as above, scoped to MDM host group |
| Tax Payment (APP) | `CEAA0088.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_APP` | Taxpayer ID, bank account numbers, report metadata, 12-digit IDs | `(?i)taxpayer_id[=:\\s]+`, `法人番号`, `\\b(?:\\d[ -]*?){13,19}\\b` |
| Tax Payment (DB) | `CEAA30A3.prprivmgmt.intra` | `C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_DB` | SQL audit logs, bind variables with taxpayer data, connection strings | `(?i)taxpayer_id`, `account_no`, `(?i)(password|user)\\s*[=:]`, Oracle/SQL error text |
| imageWARE Form Manager | `CEAA008F`–`CEAA0092` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A` | Form field values, applicant names, addresses, document IDs | `(?i)(form_data|applicant_name|address|postal_code)`, insurance keys from seq 7 |
| Filenet Foundations (APP) | `CEAA20F7.prprivmgmt.intra` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP` | Claimant names, policy numbers, document metadata, login IDs | `(?i)(policy|claim|insured|document_id|loginId)`, seq 7 insurance fields |
| Filenet Foundations (DB) | `CEAA309B`, `CEAA309C` | `C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB` | DB audit, SQL with customer/claim data, credentials | `(?i)(customer_id|policy|password|user\\s*=)`, long digit runs |
| Hulft [TS] | `CEAA007F`, `CEAA0080`, `CEAA0081` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | File paths with person names, transfer credentials, payload snippets | `(?i)(password|passwd|user\\s*=)`, `/[^\\s]+\\.(csv|txt|xml|dat)` |
| ETL (Power Center) | `CEAA204E`, `CEAA204F`, `CEAA2090`, `CEAA309A` | Mixed (APP and DB groups) | Source/target file paths, mapping logs with column names, DB connection strings | `(?i)(customer_id|EMPLID|password|jdbc)`, file path regex |
| Enterprise Integration Platform | `CEAA006F.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Message payloads in error logs (XML/JSON with IDs) | `(?i)(error|exception|payload|customer_id|EMPLID)` |
| UDM [TS] | `CEAA20B8.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | User directory sync data, login IDs | `(?i)(loginId|user_id|displayName|email)` |
| Load Runner [TS] | `CEAA20CB`, `CEAA20CC` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Test scripts may replay prod-like data — check carefully | `(?i)(password|customer_id|@)` |
| BC calc (DB) | `CEAA101D.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Usually low — numeric IDs, occasional email | `@`, `customer_id`, `\\b\\d{12}\\b` |
| BI CCI Performance Sim (DB) | `CEAA30A6.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Simulation data — may mirror customer shapes | `(?i)(customer_id|insuredPerson|@)` |
| CANweb (DB) | `CEAA30AB.prprivmgmt.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Web session data, user IDs | `(?i)(login|session|user_id|@)` |
| DFS [TS] | (partial hostname) | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | File paths — rarely direct PII | path regex, `@` baseline |

---

## PII pattern catalog (Japan / AXA context)

| PII type | What it is | Example pattern | DQL / regex |
| --- | --- | --- | --- |
| Names (Kanji) | Japanese person names in Kanji characters | `青柳 聡`, `三木　光太郎` | `matchesPhrase(content, "insuredPerson")`, `(?i)(displayName|lastName|KanjiName)[=:\\s]+[\\p{Han}　\\s]+` |
| Names (Kana) | Names in Katakana/Hiragana | `ミキ コウタロウ` | `(?i)(KanaName|lastNameKana|kanaFullAddress)[=:\\s]+` |
| My Number | Japan national ID — 12 digits | `123456789012` | `\\b\\d{12}\\b` (legal review required) |
| Employee ID (EMPLID) | People Soft employee identifier | `EMPLID=00012345` | `(?i)EMPLID[=:\\s]+[A-Z0-9]+` |
| Customer ID | MDM customer identifier | `customer_id=C123456` | `(?i)(customer_id|CUST_ID)[=:\\s]+\\S+` |
| Taxpayer ID | Tax reporting identifier | `taxpayer_id=...`, `法人番号` | `(?i)taxpayer_id[=:\\s]+\\S+`, `matchesPhrase(content, "法人番号")` |
| Email | Email addresses | `user@example.co.jp` | `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}` |
| Phone (Japan mobile) | Mobile numbers starting 090/080/070 | `09012345678` | `\\b0[789]0\\d{8}\\b` |
| Phone (general) | Any Japanese phone shape | `03-1234-5678` | `(?i)(phone|tel|subscriberPh|telNumberOld)[=:\\s]+[\\d\\-+\\s]+` |
| Address (Kanji) | Japanese street address | `東京都千代田区...` | `(?i)(address|subscriberAddr|kanjiFullAddress)[=:\\s]+` |
| Address (Kana) | Address in Katakana | `トウキョウト...` | `(?i)kanaFullAddress[=:\\s]+` |
| Zip code | Japanese postal code | `〒100-0001`, `subscriberZipCode` | `(?i)(zip|postal|subscriberZipCode)[=:\\s]+\\d{3}-?\\d{4}` |
| DOB | Date of birth | `1997/4/30`, `subscriberDOB` | `(?i)(dob|subscriberDOB|insuredDOB)[=:\\s]+\\d{4}[/-]\\d{1,2}[/-]\\d{1,2}` |
| Gender | Gender field | `subscriberGender`, `insuredGender` | `matchesPhrase` on field name — value may be `不明` |
| Insurance fields (seq 7) | 20 field names from mail-service Excel | `insuredPerson`, `loginId`, `displayName`, etc. | Combined regex in seq 7 — see copy-paste block below |
| File paths with PII filenames | Transfer logs echoing filenames | `/data/hr/田中太郎_2024.csv` | `/[^\\s]+\\.(csv|txt|xml|dat|pdf)` |
| DB connection strings | Credentials in app or ETL logs | `jdbc:oracle:thin:@//host:1521/sid user=...` | `(?i)(password|passwd|jdbc|user)\\s*[=:]\\s*\\S+` |
| Bearer / API tokens | Auth tokens in headers or logs | `Bearer eyJ...` | `(?i)(Bearer|token|apikey)\\s*[=:\\s]+\\S+` |
| Policy / claim numbers | Insurance identifiers | `policy_no=`, `claim_id=` | `(?i)(policy_no|claim_id|policyNumber)[=:\\s]+\\S+` |

### Insurance field names (from seq 7 — all 20)

Use this combined regex for a single sweep:

```text
(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\bdob\b|telNumberOld)
```

---

## Discovery workflow (step by step)

| Step | Action | Query type | Limit |
| --- | --- | --- | --- |
| 1 | Inventory — do logs arrive? | `summarize count()` by `host.name` | No sample yet |
| 2 | Combined keyword sweep | Broad regex across all hosts | `limit 50` on summary |
| 3 | Per high-risk app | Filter by `host.name` or `host_group.id` | Count first |
| 4 | Per PII pattern | One regex per type (email, EMPLID, etc.) | Count first |
| 5 | Sample confirmation | `fields content` | **`limit 10` only** |
| 6 | Escalate | App owner Magaki + masking team | — |
| 7 | Verify masking | Re-run same queries after seq 5 rules | Values should show `***` |

**Time window:** Start with `now()-24h`. Use `now()-1h` after a deploy. Use `now()-7d` for weekly sweep — summarize only, never bulk-sample.

---

## APP vs DB — different log sources

| Type | What it means | Typical log.source examples | What to look for |
| --- | --- | --- | --- |
| APP | Application server | `/var/log/app/*.log`, stdout, PeopleSoft `APP_*`, Informatica session logs | Field names, request payloads, stack traces with user data |
| DB | Database server | Oracle alert log, listener log, audit trail, PostgreSQL log | SQL text, bind variables, connection strings, failed login |

**Rule:** For every app that has both APP and DB rows (Filenet, Tax, ETL, MDM), run discovery on **both** hostnames. PII in the database audit log will not appear on the APP host.

Example pairs:

| Application | APP host | DB host |
| --- | --- | --- |
| Tax Payment | `CEAA0088.PRPRIVMGMT.intra` | `CEAA30A3.prprivmgmt.intra` |
| Filenet | `CEAA20F7.prprivmgmt.intra` | `CEAA309B`, `CEAA309C` |
| ETL | `CEAA204E`, `CEAA204F`, `CEAA2090` | `CEAA309A.prprivmgmt.intra` |
| Customer MDM | `CEAA006B` (legacy) + `CEAA2115`, `CEAA2116` (cluster) | Check if a DB row exists in full spreadsheet |

After count queries, compare `log.source` between APP and DB hosts to build your masking scope list.

---

## Copy-paste DQL queries

**Where to paste:** Logs and Events → **Advanced mode** (see seq 8 if you get a metric selector error).

### Step 0 — Inventory (all hosts in spreadsheet)

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
    "CEAA2090.prprivmgmt.intra",
    "CEAA20B8.prprivmgmt.intra",
    "CEAA20CB.prprivmgmt.intra",
    "CEAA20CC.prprivmgmt.intra",
    "CEAA20F7.prprivmgmt.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra",
    "CEAA309A.prprivmgmt.intra",
    "CEAA309B.prprivmgmt.intra",
    "CEAA309C.prprivmgmt.intra",
    "CEAA30A3.prprivmgmt.intra",
    "CEAA30A6.prprivmgmt.intra",
    "CEAA30AB.prprivmgmt.intra"
  })
| summarize log_count = count(), by: { host.name, log.source }
| sort log_count desc
```

### Combined keyword sweep (all hosts)

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
    "CEAA2090.prprivmgmt.intra",
    "CEAA20B8.prprivmgmt.intra",
    "CEAA20CB.prprivmgmt.intra",
    "CEAA20CC.prprivmgmt.intra",
    "CEAA20F7.prprivmgmt.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra",
    "CEAA309A.prprivmgmt.intra",
    "CEAA309B.prprivmgmt.intra",
    "CEAA309C.prprivmgmt.intra",
    "CEAA30A3.prprivmgmt.intra",
    "CEAA30A6.prprivmgmt.intra",
    "CEAA30AB.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(EMPLID|customer_id|taxpayer_id|insuredPerson|loginId|displayName|password|passwd|Bearer)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

### Per high-risk app — People Soft HR

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA0059.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)(EMPLID|employee_id|@|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Sample (limit 10):**

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA0059.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)EMPLID[=:\\s]+[A-Z0-9]+")
| fields timestamp, log.source, content
| limit 10
```

### Per high-risk app — Customer MDM (all MDM hosts)

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA006B.PRPRIVMGMT.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(customer_id|CUST_ID|insuredPerson|kanjiFullAddress|loginId|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Per high-risk app — Tax Payment (APP + DB)

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA0088.PRPRIVMGMT.intra",
    "CEAA30A3.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(taxpayer_id|account_no|TIN|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Per high-risk app — imageWARE

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA008F.PRPRIVMGMT.intra",
    "CEAA0090.PRPRIVMGMT.intra",
    "CEAA0091.PRPRIVMGMT.intra",
    "CEAA0092.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "(?i)(form_data|applicant_name|address|postal_code|insuredPerson|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Per high-risk app — Filenet (APP + DB)

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA20F7.prprivmgmt.intra",
    "CEAA309B.prprivmgmt.intra",
    "CEAA309C.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(policy|claim|insured|document_id|loginId|customer_id)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Per high-risk app — ETL (APP + DB)

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA204E.prprivmgmt.intra",
    "CEAA204F.prprivmgmt.intra",
    "CEAA2090.prprivmgmt.intra",
    "CEAA309A.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(customer_id|EMPLID|password|jdbc|/[^\\s]+\\.(csv|txt|xml))")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Per host_group — MDM cluster (new)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE")
| filter matchesRegex(content, "(?i)(customer_id|CUST_ID|insuredPerson|kanjiFullAddress|loginId|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Per host_group — all groups (expanded)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAX-PAYMENT_E_PRD_T_DB",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A",
    "C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE",
    "C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP",
    "C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"
  })
| filter matchesPhrase(content, "@")
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
| sort hit_count desc
| limit 50
```

### Insurance field sweep (seq 7 — all 20 keys)

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA006B.PRPRIVMGMT.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra",
    "CEAA008F.PRPRIVMGMT.intra",
    "CEAA0090.PRPRIVMGMT.intra",
    "CEAA0091.PRPRIVMGMT.intra",
    "CEAA0092.PRPRIVMGMT.intra",
    "CEAA20F7.prprivmgmt.intra"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

### Japan mobile phone pattern

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "CEAA0059.PRPRIVMGMT.intra",
    "CEAA006B.PRPRIVMGMT.intra",
    "CEAA2115.prprivmgmt.intra",
    "CEAA2116.prprivmgmt.intra"
  })
| filter matchesRegex(content, "\\b0[789]0\\d{8}\\b")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

---

## How to filter and mask after discovery

Discovery tells you **where** PII leaks. Masking stops it from staying visible. Use these prior guides:

| Task | Guide | What it covers |
| --- | --- | --- |
| Host group masking rules | seq 5 (`5-dynatrace-pii-hostgroup-axa`) | OneAgent sensitive data masking, OpenPipeline routes, per-host rules for shared infra group |
| Insurance field masking | seq 7 (`7-dql-filter-insurance-pii-keywords`) | `replacePattern` after each field key, OneAgent regex per field name |
| Correct UI for DQL | seq 8 (`8-dql-wrong-ui-data-explorer-fix`) | Logs Advanced mode, not Data explorer |
| General PII concepts | seq 1 (`1-dynatrace-logs-pii-filter`) | Overview of capture-time vs ingest-time vs display-time masking |

**Quick masking pointer:**

1. **OneAgent** (capture-time): Settings → Collect and capture → Log monitoring → Sensitive data masking. Scope by `dt.host_group.id` or `host.name`.
2. **OpenPipeline** (ingest-time): Settings → OpenPipeline → Logs → Routes + DQL processors with `replacePattern`.
3. **Verify:** Re-run the same discovery query. Raw values should be gone; keys may remain with `***` values.

For the new MDM host group, add a dedicated rule:

- Scope: `dt.host_group.id` = `C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_BASE`
- Mask: `customer_id`, insurance fields, email, phone, Kanji/Kana name patterns

---

## Safety rules

| Rule | Why |
| --- | --- |
| Count before sample | Avoid pulling thousands of PII lines into the UI |
| `limit 10` on samples | Enough to confirm; not enough to create a data breach |
| Read-only DQL | Discovery does not mask or delete — it only searches |
| Restricted notebook | Save audit notebooks in a PII-team-only workspace |
| No screenshots to chat | Raw PII in Slack/Teams is a compliance incident |
| Legal review for My Number | `\\b\\d{12}\\b` has high false-positive rate |
| Verify hostname casing | Spreadsheet mixes `.PRPRIVMGMT.intra` and `.prprivmgmt.intra` |

---

## Data flow map

```
HostNames spreadsheet (Excel)
  │
  ├─ hostname + host_group.id + APP/DB type
  │
  ▼
Dynatrace OneAgent (per host)
  │
  ├─ APP logs → application log files, stdout
  ├─ DB logs  → database audit, listener, alert log
  │
  ▼
Grail log storage
  │
  ├─ Discovery DQL (this guide — read-only)
  │     ├─ Step 0: inventory count
  │     ├─ Step 1: combined sweep
  │     ├─ Step 2: per-app / per-pattern
  │     └─ Step 3: sample limit 10
  │
  ├─ Masking (seq 5 + seq 7)
  │     ├─ OneAgent capture-time regex
  │     └─ OpenPipeline ingest-time replacePattern
  │
  └─ Verification DQL (re-run discovery — expect ***)
        │
        ▼
      App owner sign-off (Magaki)
```

---

## Related files

| File | Role |
| --- | --- |
| `9-dynatrace-pii-patterns-host-inventory.md` | This guide |
| `9-dynatrace-pii-patterns-host-inventory-question.md` | Original user question |
| `9-dynatrace-pii-patterns-host-inventory-follow.txt` | Chat-ready copy |
| `9.sh` | All DQL one-liners |
| seq 5 | Host group masking rollout |
| seq 6 | General PII discovery patterns |
| seq 7 | Insurance field name keywords |
| seq 8 | Correct Dynatrace UI for DQL |

## Commands

All DQL queries are in `9.sh` — paste each line into **Logs and Events → Advanced mode**. See seq 8 if you get a metric selector error.
