# DQL Regex Unclosed Group Fix

```
DQL matchesRegex error "Unclosed group"?
  │
  ├─ Check end of regex string
  │     ├─ Wrong: ...lastName")     ← quote before closing paren
  │     └─ Right: ...lastName)"     ← close group, then close string
  │
  ├─ Count opening ( vs closing ) inside the "(?i)(...)" pattern
  │     └─ mismatch → parser reports position near end
  │
  ├─ Query runs after fix?
  │     ├─ YES → count first (summarize), sample second (limit 10)
  │     └─ NO "regex too long" → use split strategy (Option A/B/C below)
  │
  └─ Still zero hits?
        ├─ Confirm UI: Logs and Events → Advanced (not Data explorer — seq 8)
        ├─ Confirm host group: C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP
        └─ Broad key `name` may need per-field drill-down
```

| Question | Answer |
| --- | --- |
| What broke? | Extra `"` before the regex closing `)` — `lastName")` instead of `lastName)` |
| Why "Unclosed group"? | The `(` after `(?i)` never got a matching `)` inside the string |
| How many fields in screenshot? | **71 tokens** in regex, **65 unique** after dedupe |
| Where to run? | **Logs and Events → Advanced mode** (see seq 8 if you get metric selector error) |
| Prior work | Seq 7 (insurance field names), seq 9 (expanded host inventory + patterns) |

## Summary

Your DQL query is structurally fine — host group filter, `matchesRegex`, summarize, sort, limit. The only bug is a **typo at the very end of the regex string**: an extra double-quote before the closing parenthesis. Dynatrace's regex parser opened a group with `(` after `(?i)` and never found the closing `)`, so it reports **Unclosed group at position 1249** (near `lastName`).

Fix: change `lastName")` to `lastName)` inside the string, then close the DQL argument with `")`. The corrected query below deduplicates repeated keys (`mail` ×3, `holderName` ×2, `holderAddress1` ×2, `branchCode` ×2). If the full regex hits Dynatrace length limits, use the split strategies in Option A–C.

**DQL discovery is read-only.** Count before you sample. Use `limit 10` only on sample queries.

---

## What went wrong (plain English)

| Term | What it means |
| --- | --- |
| **Regex** | Pattern language for "find text that looks like X". Your query uses `|` (OR) to match any of 65+ field names in log `content`. |
| **Capture group** | Parentheses `(...)` in regex. Your pattern starts `(?i)(field1|field2|...)` — the `(` after `(?i)` must close with `)` before the string ends. |
| **Unclosed group** | Parser saw `(` but no matching `)` inside the regex string. |
| **matchesRegex** | DQL function: `matchesRegex(content, "your-pattern-here")`. The pattern lives between the outer quotes. |

### The typo visualized

```text
WRONG (your screenshot):
matchesRegex(content, "(?i)(uketorininName1|...|lastName")
                                              ↑
                                    string ends HERE — group still open

RIGHT:
matchesRegex(content, "(?i)(uketorininName1|...|lastName)")
                                              ↑            ↑
                                    close group    close string + function
```

The `"` after `lastName` ended the DQL string **before** the regex group closed. Everything after that confused the parser.

---

## All field names extracted from screenshot regex

**71 tokens total. 65 unique** after removing duplicates.

### Duplicates removed

| Field | Times in original regex | Kept |
| --- | --- | --- |
| `mail` | 3 | 1 |
| `holderName` | 2 | 1 |
| `holderAddress1` | 2 | 1 |
| `branchCode` | 2 | 1 |

`given_name`, `family_name`, and `bankName` each appeared only once in the screenshot regex.

### Full unique list (65 fields, alphabetical)

```
bankCode
bankName
bankOwnerNameKana
bhidertVouzaNo
branchCode
BranchName
branchName
cleansingMojiName
displayName
employeeNameKana
family_name
ginkouName
given_name
holderAddress1
holderAddress2
holderAddress3
holderAddress4
holderKaddress
holderKaddress1
holderKaddress2
holderKaddress3
holderKaddress4
holderKname
holderName
holderNameKana
holderTel
holderZipCode
insuredDOB
insuredGender
insuredKname
insuredName
kanaFullAddress
kanjiFullAddress
lastName
locationAddress1
locationAddress2
loginId
mail
marketStrategyCustomer
name
odsUserId
oneGenAgoName
oneGenAgoOdsUserId
personKanaName
policyHolderBirthDate
policyHolderName
policyOwnerDateOfBirth
policyOwnerNameKana
requesterId
requesterName
salesSupervisorEmployeeName
sourceIp
subscriberAddr
subscriberDOB
subscriberGender
subscriberPh
subscriberZipCode
systemKbn
telephoneNumber
twoGenAgoName
twoGenAgoOdsUserId
uketorininKname1
uketorininKname2
uketorininName1
uketorininName2
yokishaKname
yokishaName
```

---

## Field categories

### Names (Kanji / Kana / general)

| Field | Notes |
| --- | --- |
| `uketorininName1` | Recipient name (Kanji) |
| `uketorininKname1` | Recipient name (Kana) |
| `uketorininName2` | Second recipient name (Kanji) |
| `uketorininKname2` | Second recipient name (Kana) |
| `holderName` | Policy holder name |
| `holderKname` | Policy holder name (Kana) |
| `holderNameKana` | Policy holder name (Kana alt) |
| `insuredName` | Insured person name |
| `insuredKname` | Insured person name (Kana) |
| `yokishaKname` | Beneficiary name (Kana) |
| `yokishaName` | Beneficiary name |
| `cleansingMojiName` | Cleansed character name |
| `requesterName` | Requester name |
| `policyHolderName` | Policy holder full name |
| `employeeNameKana` | Employee name (Kana) |
| `salesSupervisorEmployeeName` | Sales supervisor name |
| `oneGenAgoName` | One-generation-ago agent name |
| `twoGenAgoName` | Two-generations-ago agent name |
| `name` | Generic name key — **high false-positive risk** |
| `given_name` | Given name (OAuth/identity style) |
| `family_name` | Family name (OAuth/identity style) |
| `policyOwnerNameKana` | Policy owner name (Kana) |
| `bankOwnerNameKana` | Bank account owner name (Kana) |
| `personKanaName` | Person name (Kana) |
| `displayName` | Display name |
| `lastName` | Last name / full name in some logs |

### Addresses

| Field | Notes |
| --- | --- |
| `holderAddress1` | Holder address line 1 |
| `holderAddress2` | Holder address line 2 |
| `holderAddress3` | Holder address line 3 |
| `holderAddress4` | Holder address line 4 |
| `holderKaddress1` | Holder address (Kana) line 1 |
| `holderKaddress2` | Holder address (Kana) line 2 |
| `holderKaddress3` | Holder address (Kana) line 3 |
| `holderKaddress4` | Holder address (Kana) line 4 |
| `holderKaddress` | Holder address (Kana) combined |
| `locationAddress1` | Location address line 1 |
| `locationAddress2` | Location address line 2 |
| `subscriberAddr` | Subscriber address |
| `kanaFullAddress` | Full address (Kana) |
| `kanjiFullAddress` | Full address (Kanji) |
| `holderZipCode` | Holder postal code |
| `subscriberZipCode` | Subscriber postal code |

### Phone

| Field | Notes |
| --- | --- |
| `telephoneNumber` | Generic telephone |
| `holderTel` | Holder telephone |
| `subscriberPh` | Subscriber phone |

### Email

| Field | Notes |
| --- | --- |
| `mail` | Email address field |

### Bank / financial

| Field | Notes |
| --- | --- |
| `ginkouName` | Bank name (Japanese: 銀行) |
| `bhidertVouzaNo` | Likely typo for bank account number field |
| `bankCode` | Bank institution code |
| `bankName` | Bank name (English key) |
| `branchCode` | Branch code |
| `BranchName` | Branch name (capital B) |
| `branchName` | Branch name (lowercase b) |

### IDs / technical / system

| Field | Notes |
| --- | --- |
| `sourceIp` | Source IP address |
| `requesterId` | Requester identifier |
| `systemKbn` | System classification code |
| `odsUserId` | ODS user ID |
| `oneGenAgoOdsUserId` | One-gen-ago agent ODS ID |
| `twoGenAgoOdsUserId` | Two-gen-ago agent ODS ID |
| `marketStrategyCustomer` | Market strategy customer ID |
| `loginId` | Login ID (often email format) |

### Date of birth

| Field | Notes |
| --- | --- |
| `policyHolderBirthDate` | Policy holder DOB |
| `policyOwnerDateOfBirth` | Policy owner DOB |
| `subscriberDOB` | Subscriber date of birth |
| `insuredDOB` | Insured person DOB |

### Gender

| Field | Notes |
| --- | --- |
| `subscriberGender` | Subscriber gender |
| `insuredGender` | Insured person gender |

---

## Corrected full DQL query (deduplicated, 65 fields)

**Where to run:** Logs and Events → Advanced mode (not Data explorer — see seq 8).

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holderKname|holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|insuredName|insuredKname|yokishaKname|yokishaName|ginkouName|bhidertVouzaNo|sourceIp|cleansingMojiName|requesterName|requesterId|policyHolderBirthDate|holderNameKana|telephoneNumber|holderKaddress|holderTel|holderZipCode|systemKbn|policyHolderName|mail|employeeNameKana|locationAddress1|locationAddress2|salesSupervisorEmployeeName|odsUserId|oneGenAgoName|oneGenAgoOdsUserId|twoGenAgoName|twoGenAgoOdsUserId|marketStrategyCustomer|name|given_name|family_name|branchCode|BranchName|policyOwnerNameKana|policyOwnerDateOfBirth|bankOwnerNameKana|bankCode|bankName|branchName|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|personKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**What changed from your screenshot:**

1. Fixed ending: `lastName)` inside the string (not `lastName"`)
2. Removed duplicate `mail`, `holderName`, `holderAddress1`, `branchCode`
3. Host group filter unchanged: `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` (HULFT app tier from seq 5)

---

## Sample query (limit 10 — inspect raw lines)

Run the count query first. Only sample when `hit_count > 0`.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(holderName|insuredName|loginId|mail|subscriberPh)[=:\\s]+\\S+")
| fields timestamp, host.name, log.source, content
| limit 10
```

This samples lines where a **value** likely follows the key (`key: value`, `key=value`). Adjust the field list after you see which keys actually appear in HULFT logs.

---

## Split strategy (if full regex is too long)

Dynatrace regex engines can reject very long alternation lists. If you get a length or complexity error after fixing the typo, use one of these.

### Option A — Three smaller regex groups (recommended)

Run three count queries, then merge results mentally (or in a notebook).

**A1 — Names (28 fields):**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(uketorininName1|uketorininKname1|uketorininName2|uketorininKname2|holderName|holderKname|holderNameKana|insuredName|insuredKname|yokishaKname|yokishaName|cleansingMojiName|requesterName|policyHolderName|employeeNameKana|salesSupervisorEmployeeName|oneGenAgoName|twoGenAgoName|given_name|family_name|policyOwnerNameKana|bankOwnerNameKana|personKanaName|displayName|lastName|name)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**A2 — Addresses + zip (16 fields):**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(holderAddress1|holderAddress2|holderAddress3|holderAddress4|holderKaddress1|holderKaddress2|holderKaddress3|holderKaddress4|holderKaddress|locationAddress1|locationAddress2|subscriberAddr|kanaFullAddress|kanjiFullAddress|holderZipCode|subscriberZipCode)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**A3 — IDs, bank, phone, email, DOB, gender (21 fields):**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(ginkouName|bhidertVouzaNo|sourceIp|requesterId|systemKbn|odsUserId|oneGenAgoOdsUserId|twoGenAgoOdsUserId|marketStrategyCustomer|branchCode|BranchName|bankCode|bankName|branchName|telephoneNumber|holderTel|subscriberPh|mail|loginId|policyHolderBirthDate|policyOwnerDateOfBirth|subscriberDOB|insuredDOB|subscriberGender|insuredGender)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

### Option B — `or` chain with `matchesPhrase` (no giant regex)

DQL supports `or` in filter expressions. Chain high-value field names:

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesPhrase(content, "holderName")
    or matchesPhrase(content, "insuredName")
    or matchesPhrase(content, "loginId")
    or matchesPhrase(content, "mail")
    or matchesPhrase(content, "subscriberPh")
    or matchesPhrase(content, "kanjiFullAddress")
    or matchesPhrase(content, "policyHolderBirthDate")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

Add more `or matchesPhrase(...)` lines for remaining fields. Slower than one regex but avoids regex length limits and is easier to debug.

**Note:** `in()` works for discrete field values, not for "search content for phrase". Use `or matchesPhrase` for log body search.

### Option C — Per-field union (safest, most verbose)

One query per critical field — best for masking rule design:

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesPhrase(content, "holderName")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

Repeat for each field from the category tables above. Tedious but zero regex risk.

---

## Link to prior work

| Seq | Topic | How it connects |
| --- | --- | --- |
| **7** | `7-dql-filter-insurance-pii-keywords` | First insurance field-name sweep (20 Excel keys: `insuredPerson`, `displayName`, `loginId`, etc.) |
| **9** | `9-dynatrace-pii-patterns-host-inventory` | Expanded 26-host inventory, per-app patterns, combined regex for MDM/tax/mail |
| **8** | `8-dql-wrong-ui-data-explorer-fix` | If you see metric selector error instead of regex error — wrong UI screen |
| **5** | `5-dynatrace-pii-hostgroup-axa` | Host group IDs including `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` |
| **6** | `6-dql-search-pii-discovery` | Count → sample → escalate workflow |

Your screenshot regex is a **superset** of seq 7 fields (adds HULFT-specific holder/bank/beneficiary keys). Seq 9's per-host patterns still apply when HULFT logs also appear on shared infra hosts.

---

## Data flow map

```
Excel / app field inventory (column E keys)
  → build matchesRegex alternation list (field1|field2|...)
  → paste into DQL fetch logs (Logs and Events → Advanced)
  → filter dt.host_group.id = C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP
  → summarize hit_count by host.name + log.source
  → hit_count > 0 ?
        ├─ YES → sample query (limit 10) → confirm key:value format
        │         → design masking (OneAgent + OpenPipeline, seq 5)
        └─ NO  → try split strategy A/B/C or widen time range
  → post-mask: re-run same DQL → values should be ***
```

---

## Related files

| File | Role |
| --- | --- |
| `10-dql-regex-unclosed-group-fix-question.md` | Original question and screenshot context |
| `10-dql-regex-unclosed-group-fix-follow.txt` | Chat-ready copy-paste steps |
| `10.sh` | All DQL one-liners |
| `7-dql-filter-insurance-pii-keywords/` | Prior insurance keyword DQL (seq 7) |
| `9-dynatrace-pii-patterns-host-inventory/` | Expanded host + pattern inventory (seq 9) |

## Commands

See `10.sh` for copy-paste DQL one-liners (corrected full query, sample limit 10, split options A1–A3).
