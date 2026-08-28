# User question (verbatim)

need to filter name like these key words

## Context

User attached 2 Excel screenshots with PII field names (insurance/Japan context, mail-service logs). Column E lists the field keys; column F shows example values in `key: value` or `key=value` format.

### Sheet 1 — logs_mailservice (column E)

- insuredPerson
- subscriberGender
- subscriberDOB
- subscriberAddr
- subscriberPh
- insuredGender
- insuredDOB
- insuredPersonKanjiName
- insuredPersonKanaName
- contractPersonKanjiName
- contractPersonKanaName
- subscriberZipCode

### Sheet 2 — s_mailservice (column E)

- insuredPerson
- kanaFullAddress
- kanjiFullAddress
- displayName
- loginId
- lastName
- lastNameKana
- dob
- telNumberOld

Example values: Japanese names (Kanji/Kana), addresses, email loginId, DOB YYYY/MM/DD, phone numbers.

## Deliverable requested

Practical guide for filtering/searching these keyword field names in Dynatrace logs:

1. Discovery DQL — search logs where content contains these JSON/log keys
2. Combined keyword sweep — one query with all unique field names
3. Per-category queries — names (Kanji/Kana), address, DOB, phone, gender, zip, loginId
4. OpenPipeline DQL processor — mask values AFTER these keys
5. OneAgent regex — mask `insuredPersonKanjiName=...` style patterns
6. Scoped to AXA hosts from seq 5 (host.name, host_group) — optional filter block
7. Decision tree, takeaway table, data flow
8. Japanese-specific patterns: Kanji names, Kana names, zip 〒, phone 090/080/070, dob formats

Build on seq 6 (discovery) and seq 5 (masking).
