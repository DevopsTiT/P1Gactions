# Filter Real PII Drop Noise

## Decision tree

```
Results show axacleansingservice but mostly CleansingResult=0 / counts?
  │
  ├─ Problem = keyword too wide (class name / "dob" / service name)
  │     Hits operational lines, not Value = PII
  │
  ├─ Fix 1 — require VALUE patterns
  │     address, Value = / person_fullname / phone… with Value =
  │
  ├─ Fix 2 — exclude noise
  │     not CleansingResult= / cleansingResult= / only counters
  │
  └─ Fix 3 — keep all PII kinds, but only “field + value” style lines
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you see now | Service logs + result codes (meaningless numbers/records) |
| What you want | Lines that look like real PII **values** (address, phone, name, …) |
| How | Require `Value =` / strong field labels; **exclude** `CleansingResult` noise |
| Still use | `contains` + `not contains`, 24h, `limit 20` |

---

## Summary

Yes. Keep all PII **kinds**, but only rows that look like field+value data. Drop cleansing counters and result codes with a negative filter.

---

## Investigation

| Noise on your screen | Why it matched |
| --- | --- |
| `AXACleansingServiceBP` / package path | Broad keywords like service name or short tokens |
| `CleansingResult=0` / `0.0` | Not customer PII — job status |
| APP_ / process ids | Operational IDs, not address/phone |

Real leak style (from earlier MDM find): `address, Value = …` with real text.

---

## Result — improved DQL

### Recommended (MDM APP) — all PII kinds, value-like only

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter (
    contains(content, "address, Value =")
    or contains(content, "AddressKana")
    or contains(content, "AddressKanji")
    or contains(content, "kanjiFullAddress")
    or contains(content, "PERSON_ADDRESS")
    or contains(content, "OFFICE_ADDRESS")
    or contains(content, "Type = address")
    or contains(content, "postalCode, Value =")
    or contains(content, "postal_code, Value =")
    or contains(content, "person_fullname, Value =")
    or contains(content, "person_fullname")
    or contains(content, "given_name, Value =")
    or contains(content, "family_name, Value =")
    or contains(content, "holderName, Value =")
    or contains(content, "displayName, Value =")
    or contains(content, "firstName, Value =")
    or contains(content, "lastName, Value =")
    or contains(content, "fullName, Value =")
    or contains(content, "customerName, Value =")
    or contains(content, "phoneNumber, Value =")
    or contains(content, "phone_number, Value =")
    or contains(content, "mobileNumber, Value =")
    or contains(content, "mobile_number, Value =")
    or contains(content, "telNo, Value =")
    or contains(content, "emailAddress, Value =")
    or contains(content, "email_address, Value =")
    or contains(content, "mailAddress, Value =")
    or contains(content, "birthDate, Value =")
    or contains(content, "dateOfBirth, Value =")
    or contains(content, "myNumber, Value =")
    or contains(content, "bankAccount, Value =")
    or contains(content, "accountNumber, Value =")
    or contains(content, "cardNumber, Value =")
    or contains(content, "氏名")
    or contains(content, "住所")
    or contains(content, "電話番号")
    or contains(content, "生年月日")
    or contains(content, "郵便番号")
    or contains(content, "メールアドレス")
  )
| filter not contains(content, "CleansingResult=")
| filter not contains(content, "cleansingResult=")
| filter not contains(content, "CleansingResult =")
| filter not contains(content, "cleansingResult =")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Stricter — must include `Value =` (least noise)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "Value =")
| filter (
    contains(content, "address")
    or contains(content, "Address")
    or contains(content, "postal")
    or contains(content, "zip")
    or contains(content, "person_fullname")
    or contains(content, "given_name")
    or contains(content, "family_name")
    or contains(content, "holderName")
    or contains(content, "displayName")
    or contains(content, "firstName")
    or contains(content, "lastName")
    or contains(content, "fullName")
    or contains(content, "customerName")
    or contains(content, "phone")
    or contains(content, "mobile")
    or contains(content, "tel")
    or contains(content, "email")
    or contains(content, "mail")
    or contains(content, "birth")
    or contains(content, "myNumber")
    or contains(content, "mynumber")
    or contains(content, "bankAccount")
    or contains(content, "accountNumber")
    or contains(content, "cardNumber")
  )
| filter not contains(content, "CleansingResult")
| filter not contains(content, "cleansingResult")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Address + phone only (if you want fewer name hits)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter (
    contains(content, "address, Value =")
    or contains(content, "AddressKana")
    or contains(content, "AddressKanji")
    or contains(content, "Type = address")
    or contains(content, "postalCode, Value =")
    or contains(content, "phoneNumber, Value =")
    or contains(content, "phone_number, Value =")
    or contains(content, "mobileNumber, Value =")
    or contains(content, "telNo, Value =")
    or contains(content, "電話番号")
    or contains(content, "住所")
    or contains(content, "郵便番号")
  )
| filter not contains(content, "CleansingResult")
| filter not contains(content, "cleansingResult")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Words to stop using (cause noise)

| Avoid | Why |
| --- | --- |
| `axacleansingservice` alone | Matches every cleansing log, including counts |
| `dob` alone | Too short; matches random text |
| `AXACleansingAddress` alone | Often class name without the address value line |
| Only `phoneNumber` without Value | May hit schema/docs without data |

---

## Data flow map

```
All MDM logs
  → keep lines with PII field + Value= (or JP PII label)
  → drop CleansingResult / cleansingResult counters
  → show content (limit 20)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `32-filter-real-pii-drop-noise-follow.txt` | Paste-ready queries |
| `32-real-pii-value-filter.dql` | Value-style filter + host template |
| `32.sh` | Open helpers |
| Seq 31 | Full keyword list (wider; more noise) |

Commands: see `32.sh`.
