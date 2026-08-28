# DQL Filter Insurance PII Keywords

```
Excel column E field names in logs?
  │
  ├─ Step 1: Combined keyword sweep (count by host + log.source)
  │     └─ hit_count > 0 → narrow to per-category query
  │
  ├─ Step 2: Sample with limit 10 (confirm real PII, not null)
  │     └─ value is null / 不明 → still log the key; mask anyway
  │
  ├─ Step 3: Check log format on sample
  │     ├─ key: value  (colon + space)  → discovery regex with [=:\\s]+
  │     ├─ key=value  (equals)          → same regex covers both
  │     └─ "key": "value" (JSON)        → add \"fieldName\" pattern
  │
  ├─ Step 4: Apply masking (seq 5)
  │     ├─ OneAgent on host → capture-time regex
  │     └─ OpenPipeline DQL → replacePattern after key
  │
  └─ Step 5: Re-run discovery — raw values should be gone
```

```
Which category first?
  │
  ├─ Names (Kanji/Kana)     → insuredPerson*, *KanjiName, *KanaName, displayName, lastName*
  ├─ Address                → subscriberAddr, kanaFullAddress, kanjiFullAddress
  ├─ DOB                    → subscriberDOB, insuredDOB, dob
  ├─ Phone                  → subscriberPh, telNumberOld
  ├─ Gender                 → subscriberGender, insuredGender
  ├─ Zip                    → subscriberZipCode
  └─ Login / email          → loginId
```

| Question | Answer |
| --- | --- |
| What are we filtering? | **20 unique field names** from insurance mail-service Excel (column E) |
| Log formats seen? | `key: value`, `key=value`, and JSON `"key":` |
| Discovery first? | Yes — seq 6 pattern: **count → sample → escalate** |
| Masking where? | OneAgent (capture) + OpenPipeline (ingest) — seq 5 rollout |
| Scope? | Optional AXA host filter from seq 5 (`dt.host_group.id`, `host.name`) |
| Japanese specifics? | Kanji/Kana names, 〒 zip, 090/080/070 phone, `YYYY/M/D` DOB |

## Summary

Your Excel lists **insurance PII field names** that appear in mail-service logs — names in Kanji and Kana, addresses, dates of birth, phone numbers, gender, zip codes, and login IDs. This guide shows how to **find** those keys in Dynatrace `content` with DQL, then **mask** the values after each key using OpenPipeline and OneAgent rules. Start with the **combined keyword sweep** to see which hosts and log files leak these fields, then drill into **per-category** queries. After masking from seq 5, re-run the same queries — you should see keys but masked values (`***`), not raw Japanese names or phone numbers.

**DQL discovery is read-only.** Do not export large result sets with raw PII.

---

## Field names extracted from Excel (column E)

### Sheet 1 — `logs_mailservice`

| # | Field name | Example value (column F) | PII category |
| --- | --- | --- | --- |
| 1 | `insuredPerson` | `青柳 聡` (Kanji name) | Name (Kanji) |
| 2 | `subscriberGender` | `不明（値がnull）` | Gender |
| 3 | `subscriberDOB` | `不明（値がnull）` | DOB |
| 4 | `subscriberAddr` | `不明（値がnull）` | Address |
| 5 | `subscriberPh` | `不明（値がnull）` | Phone |
| 6 | `insuredGender` | `不明（値がnull）` | Gender |
| 7 | `insuredDOB` | `不明（値がnull）` | DOB |
| 8 | `insuredPersonKanjiName` | (null in sample) | Name (Kanji) |
| 9 | `insuredPersonKanaName` | (null in sample) | Name (Kana) |
| 10 | `contractPersonKanjiName` | `null` | Name (Kanji) |
| 11 | `contractPersonKanaName` | `null` | Name (Kana) |
| 12 | `subscriberZipCode` | `null` | Zip |

### Sheet 2 — `s_mailservice`

| # | Field name | Example value (column F) | PII category |
| --- | --- | --- | --- |
| 1 | `insuredPerson` | `照沼　日菜乃` (Kanji, `=` separator) | Name (Kanji) |
| 2 | `kanaFullAddress` | `<null>` or Katakana address | Address (Kana) |
| 3 | `kanjiFullAddress` | `<null>` or Kanji address | Address (Kanji) |
| 4 | `displayName` | `三木　光太郎` | Name (Kanji) |
| 5 | `loginId` | `mkmkktr12@outlook.jp` | Login / email |
| 6 | `lastName` | `三木　光太郎` | Name (Kanji) |
| 7 | `lastNameKana` | `ミキ コウタロウ` | Name (Kana) |
| 8 | `dob` | `1997/4/30` | DOB |
| 9 | `telNumberOld` | `09077759609` | Phone |

### All unique field names (20)

```
contractPersonKanaName
contractPersonKanjiName
displayName
dob
insuredDOB
insuredGender
insuredPerson
insuredPersonKanaName
insuredPersonKanjiName
kanaFullAddress
kanjiFullAddress
lastName
lastNameKana
loginId
subscriberAddr
subscriberDOB
subscriberGender
subscriberPh
subscriberZipCode
telNumberOld
```

---

## Log format patterns (from your samples)

| Format | Example | When to match |
| --- | --- | --- |
| Colon + space | `displayName: 三木　光太郎` | `matchesRegex(..., "displayName[=:\\s]+")` |
| Equals | `insuredPerson=照沼　日菜乃` | Same regex — `[=:\\s]+` covers both |
| JSON key | `"loginId": "mkmkktr12@outlook.jp"` | `matchesPhrase(content, "\"loginId\"")` or regex |
| Null literal | `contractPersonKanjiName: null` | Key still present — mask rule still applies |
| Japanese null note | `不明（値がnull）` | Value is not PII but field name is in log |

**Discovery tip:** Search for the **key name** first (`matchesPhrase`). Then use regex to confirm a **non-null value** follows the key.

---

## Optional AXA host scope block

Add this filter to any query below when you want to limit to the AXA production inventory from seq 5.

```text
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
```

For high-PII apps on the shared infra group, also filter by hostname:

```text
| filter in(host.name, {
    "EAA0059.PRPRIVMGMT.intra",
    "EAA006B.PRPRIVMGMT.intra",
    "EAA0088.PRPRIVMGMT.intra"
  })
```

Mail-service logs may live on **Customer MDM** (`EAA006B`) or **imageWARE** (`EAA008F`–`EAA0092`) — check `log.source` in your count results.

---

## 1. Discovery DQL — find logs with these keys

### Single field — phrase match (fastest)

Find any log line that mentions the key:

```text
fetch logs, from: now()-24h
| filter matchesPhrase(content, "insuredPersonKanjiName")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

### Single field — key with value (regex)

Confirm the key is followed by a value (not just mentioned in docs):

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)insuredPersonKanjiName[=:\\s]+\\S+")
| fields timestamp, host.name, log.source, content
| limit 10
```

### JSON-style key

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "\"insuredPersonKanjiName\"\\s*:")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Sample after count > 0

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)insuredPerson[=:\\s]+[^,\\n\\}]+")
| fields timestamp, host.name, log.source, content
| limit 10
```

---

## 2. Combined keyword sweep (all 20 fields)

One query to find **any** insurance PII key from your Excel list.

**Count by host and log source:**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**Sample (after count > 0):**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(insuredPersonKanjiName|displayName|loginId|telNumberOld)[=:\\s]+\\S+")
| fields timestamp, host.name, log.source, content
| limit 10
```

**Note:** `\bdob\b` uses word boundary so you do not match unrelated words like `adobe`.

---

## 3. Per-category discovery queries

### Names — Kanji

Fields: `insuredPerson`, `insuredPersonKanjiName`, `contractPersonKanjiName`, `displayName`, `lastName`, `kanjiFullAddress`

**Count:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(insuredPerson|insuredPersonKanjiName|contractPersonKanjiName|displayName|lastName|kanjiFullAddress)[=:\\s]+")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**Sample with Japanese Kanji in value:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(insuredPersonKanjiName|displayName|lastName)[=:\\s]+[\\u4E00-\\u9FFF々〆ヵヶ\\s　]+")
| fields timestamp, log.source, content
| limit 10
```

### Names — Kana

Fields: `insuredPersonKanaName`, `contractPersonKanaName`, `lastNameKana`, `kanaFullAddress`

**Count:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(insuredPersonKanaName|contractPersonKanaName|lastNameKana|kanaFullAddress)[=:\\s]+")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Sample with Katakana/Hiragana value:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(lastNameKana|insuredPersonKanaName)[=:\\s]+[\\u30A0-\\u30FFァ-ヶー\\s　]+")
| fields timestamp, log.source, content
| limit 10
```

### Address

Fields: `subscriberAddr`, `kanaFullAddress`, `kanjiFullAddress`

**Count:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(subscriberAddr|kanaFullAddress|kanjiFullAddress)[=:\\s]+\\S+")
| filter not matchesPhrase(content, "<null>")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Date of birth

Fields: `subscriberDOB`, `insuredDOB`, `dob`

**Count:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(subscriberDOB|insuredDOB|\\bdob\\b)[=:\\s]+\\d{4}/\\d{1,2}/\\d{1,2}")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Sample:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)\\bdob[=:\\s]+\\d{4}/\\d{1,2}/\\d{1,2}")
| fields timestamp, log.source, content
| limit 10
```

### Phone

Fields: `subscriberPh`, `telNumberOld`

**Count (Japanese mobile prefixes 090, 080, 070):**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(subscriberPh|telNumberOld)[=:\\s]+0[789]0\\d{8}")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Gender

Fields: `subscriberGender`, `insuredGender`

**Count:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(subscriberGender|insuredGender)[=:\\s]+\\S+")
| filter not matchesPhrase(content, "null")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Zip code

Field: `subscriberZipCode`

**Count (7-digit or 〒 format):**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)subscriberZipCode[=:\\s]+(〒?\\d{3}-?\\d{4}|\\d{7})")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Login ID / email

Field: `loginId`

**Count:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)loginId[=:\\s]+[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Sample:**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)loginId[=:\\s]+\\S+")
| fields timestamp, log.source, content
| limit 10
```

---

## 4. Japanese-specific value patterns

Use these **after** you confirm the key exists, or as extra validation on samples.

| PII type | Pattern | Example from your Excel |
| --- | --- | --- |
| Kanji name | `[\u4E00-\u9FFF々〆ヵヶ]+[\s　]+[\u4E00-\u9FFF々〆ヵヶ]+` | `青柳 聡`, `三木　光太郎` |
| Katakana name | `[\u30A0-\u30FFァ-ヶー]+[\s　]+[\u30A0-\u30FFァ-ヶー]+` | `ミキ コウタロウ` |
| Katakana address | long Katakana string | `キヨウトフキヨウトシ...` |
| Kanji address | Kanji + numbers | `京都府京都市下京区...` |
| DOB | `\d{4}/\d{1,2}/\d{1,2}` | `1997/4/30` |
| Phone (mobile) | `0[789]0\d{8}` | `09077759609` |
| Phone (with hyphen) | `0\d{1,4}-\d{1,4}-\d{4}` | `090-7775-9609` |
| Zip | `〒?\d{3}-?\d{4}` | `〒600-8001` or `6008001` |
| Email (loginId) | standard email regex | `mkmkktr12@outlook.jp` |

**Broad Japanese PII sweep (use with host scope):**

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "0[789]0\\d{8}|\\d{4}/\\d{1,2}/\\d{1,2}|〒?\\d{3}-?\\d{4}")
| filter matchesRegex(content, "(?i)(insuredPerson|loginId|telNumberOld|dob|subscriber)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

---

## 5. OpenPipeline DQL processor — mask values after keys

Add these processors to the appropriate pipeline from seq 5 (e.g. `pipeline-pii-customer-mdm` or a new `pipeline-pii-mailservice`). Run **sample data** with synthetic values before save.

**Full processor chain (all categories):**

```text
fieldsAdd content = replacePattern(content, "(?i)(insuredPersonKanjiName|contractPersonKanjiName|displayName|lastName|insuredPerson)[=:\\s]+[^,\\n\\}<>]+", "$1=***")
| fieldsAdd content = replacePattern(content, "(?i)(insuredPersonKanaName|contractPersonKanaName|lastNameKana)[=:\\s]+[^,\\n\\}<>]+", "$1=***")
| fieldsAdd content = replacePattern(content, "(?i)(subscriberAddr|kanaFullAddress|kanjiFullAddress)[=:\\s]+[^,\\n\\}<>]+", "$1=***")
| fieldsAdd content = replacePattern(content, "(?i)(subscriberDOB|insuredDOB|\\bdob\\b)[=:\\s]+\\d{4}/\\d{1,2}/\\d{1,2}", "$1=***")
| fieldsAdd content = replacePattern(content, "(?i)(subscriberPh|telNumberOld)[=:\\s]+0[789]0\\d{8}", "$1=***")
| fieldsAdd content = replacePattern(content, "(?i)(subscriberGender|insuredGender)[=:\\s]+\\S+", "$1=***")
| fieldsAdd content = replacePattern(content, "(?i)subscriberZipCode[=:\\s]+(〒?\\d{3}-?\\d{4}|\\d{7})", "subscriberZipCode=***")
| fieldsAdd content = replacePattern(content, "(?i)loginId[=:\\s]+[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "loginId=***@***.***")
```

### Per-category processor snippets

**Names Kanji only:**

```text
fieldsAdd content = replacePattern(content, "(?i)(insuredPersonKanjiName|contractPersonKanjiName|displayName|lastName)[=:\\s]+[^,\\n\\}]+", "$1=***")
```

**Names Kana only:**

```text
fieldsAdd content = replacePattern(content, "(?i)(insuredPersonKanaName|contractPersonKanaName|lastNameKana)[=:\\s]+[^,\\n\\}]+", "$1=***")
```

**Address:**

```text
fieldsAdd content = replacePattern(content, "(?i)(subscriberAddr|kanaFullAddress|kanjiFullAddress)[=:\\s]+[^,\\n\\}]+", "$1=***")
```

**DOB:**

```text
fieldsAdd content = replacePattern(content, "(?i)(subscriberDOB|insuredDOB|\\bdob\\b)[=:\\s]+\\d{4}/\\d{1,2}/\\d{1,2}", "$1=***")
```

**Phone:**

```text
fieldsAdd content = replacePattern(content, "(?i)(subscriberPh|telNumberOld)[=:\\s]+0[789]0\\d{8}", "$1=***")
```

**Gender:**

```text
fieldsAdd content = replacePattern(content, "(?i)(subscriberGender|insuredGender)[=:\\s]+\\S+", "$1=***")
```

**Zip:**

```text
fieldsAdd content = replacePattern(content, "(?i)subscriberZipCode[=:\\s]+\\S+", "subscriberZipCode=***")
```

**Login ID:**

```text
fieldsAdd content = replacePattern(content, "(?i)loginId[=:\\s]+\\S+", "loginId=***")
```

### Post-mask verification

After pipeline deploy, raw values should be gone:

```text
fetch logs, from: now()-1h
| filter matchesRegex(content, "(?i)insuredPersonKanjiName[=:\\s]+[\\u4E00-\\u9FFF]")
| fields timestamp, host.name, content
| limit 10
```

Expected: **zero hits** (Kanji still present after key means mask failed).

---

## 6. OneAgent sensitive data masking — regex rules

**Navigation:** Settings → Collect and capture → Log monitoring → Sensitive data masking

Scope to the host or host group where mail-service logs originate (see seq 5 inventory).

| Rule name | Regex expression | Replacement | Fields covered |
| --- | --- | --- | --- |
| `mask-insurance-names-kanji` | `(?i)(insuredPersonKanjiName\|contractPersonKanjiName\|displayName\|lastName\|insuredPerson)[=:\s]+[^,\n\}]+` | `$1=***` | Kanji names |
| `mask-insurance-names-kana` | `(?i)(insuredPersonKanaName\|contractPersonKanaName\|lastNameKana)[=:\s]+[^,\n\}]+` | `$1=***` | Kana names |
| `mask-insurance-address` | `(?i)(subscriberAddr\|kanaFullAddress\|kanjiFullAddress)[=:\s]+[^,\n\}]+` | `$1=***` | Addresses |
| `mask-insurance-dob` | `(?i)(subscriberDOB\|insuredDOB\|dob)[=:\s]+\d{4}/\d{1,2}/\d{1,2}` | `$1=***` | DOB |
| `mask-insurance-phone` | `(?i)(subscriberPh\|telNumberOld)[=:\s]+0[789]0\d{8}` | `$1=***` | Phone |
| `mask-insurance-gender` | `(?i)(subscriberGender\|insuredGender)[=:\s]+\S+` | `$1=***` | Gender |
| `mask-insurance-zip` | `(?i)subscriberZipCode[=:\s]+\S+` | `subscriberZipCode=***` | Zip |
| `mask-insurance-loginId` | `(?i)loginId[=:\s]+\S+` | `loginId=***` | Login |

**Example log line before mask:**

```text
insuredPersonKanjiName=青柳 聡, displayName: 三木　光太郎, telNumberOld: 09077759609
```

**After mask:**

```text
insuredPersonKanjiName=***, displayName: ***, telNumberOld: ***
```

OneAgent runs **before** logs leave the host. OpenPipeline is the **backstop** if a log path bypasses OneAgent rules.

---

## 7. How this fits seq 5 and seq 6

| Seq | Role | You use it for |
| --- | --- | --- |
| **6** | General PII discovery (email, EMPLID, taxpayer_id) | Baseline audit across AXA hosts |
| **7** (this guide) | Insurance mail-service **field names** from Excel | Targeted discovery + mask for Japanese insurance PII keys |
| **5** | Host group scoping, OneAgent + OpenPipeline rollout, verification | Apply masks; confirm leaks → 0 |

**Workflow:**

1. Run seq 6 inventory (logs arriving?).
2. Run seq 7 **combined keyword sweep** (this Excel list).
3. Per-category count + sample (`limit 10`).
4. Add OneAgent rules + OpenPipeline processors (seq 5 host scope).
5. Re-run seq 7 verification queries.

---

## Safety

| Rule | Why |
| --- | --- |
| Count before sample | Less raw PII on screen |
| `limit 10` on samples | Enough to confirm format |
| No bulk export | Spreads PII outside Dynatrace |
| Restricted notebook | Insurance PII audit team only |
| Redact screenshots | Blur names and phone numbers before sharing |

---

## Data flow map

```
Excel column E (20 field names)
        │
        ▼
Seq 7 discovery DQL
  ├─ combined keyword sweep (count)
  ├─ per-category queries (names, address, DOB, phone, …)
  └─ sample limit 10 → confirm key:value format
        │
        ├─ Confirmed leak → escalate to app owner (Magaki)
        │
        ▼
Seq 5 masking layer
  ├─ OneAgent regex (host / host group scope)
  └─ OpenPipeline replacePattern (ingest backstop)
        │
        ▼
Seq 7 verification DQL
  └─ keys present, values = *** → done
        │
        └─ raw Kanji/phone/email still visible → fix rule or stop at source
```

---

## Related files

| File | Role |
| --- | --- |
| `7-dql-filter-insurance-pii-keywords.md` | This guide |
| `7-dql-filter-insurance-pii-keywords-question.md` | User question |
| `7-dql-filter-insurance-pii-keywords-follow.txt` | Chat-ready copy |
| `7.sh` | All DQL one-liners |
| `6-dql-search-pii-discovery/` | General discovery before masking (seq 6) |
| `5-dynatrace-pii-hostgroup-axa/` | AXA host scope and masking rollout (seq 5) |

## Commands

All discovery and verification DQL one-liners are in `7.sh`. Paste each line into **Logs and Events → Advanced mode** or a **Notebook** DQL cell.
