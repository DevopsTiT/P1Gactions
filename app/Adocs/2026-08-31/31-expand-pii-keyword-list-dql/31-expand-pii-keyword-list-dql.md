# Expand PII Keyword List DQL

## Decision tree

```
Should the contains() list cover all kinds of PII keywords?
  │
  ├─ Goal = name/address leak only (MDM cleansing)?
  │     Keep short list (AddressKana, address Value, person_fullname…)
  │
  ├─ Goal = broad PII hunt across host groups?
  │     YES → use FULL keyword pack below (by category)
  │
  └─ Too many false positives?
        Split: run NAME / ADDRESS / CONTACT / ID packs separately
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Short list | Good for MDM address/name cleansing only |
| Full list | Use when hunting **all kinds of PII** across apps |
| How | Still `contains` + `or` — no `matchesRegex` / `\s` |
| Caution | Broader keywords = more noise and more sensitive hits; keep `limit 20` |

---

## Summary

Yes — expand if you want all PII types, not only name/address. Use the full pack (or category packs) with `contains`. Do not paste raw matching `content` into chat.

---

## Investigation

| Current keywords | Mostly catch |
| --- | --- |
| AddressKana, address Value, Type = address | Address |
| person_fullname, holderName, given_name, family_name | Person name |

Missing for a full hunt: phone, email, birth date, postal code, national ID / My Number style fields, bank/account, policy/customer identifiers that often sit next to PII.

---

## Result — recommended keyword packs

### A) Full pack (paste into any host-group query)

```text
| filter (
    contains(content, "axacleansingservice")
    or contains(content, "AXACleansingAddress")
    or contains(content, "AXACleansingPersonName")
    or contains(content, "AddressKana")
    or contains(content, "AddressKanji")
    or contains(content, "address, Value =")
    or contains(content, "Type = address")
    or contains(content, "kanjiFullAddress")
    or contains(content, "PERSON_ADDRESS")
    or contains(content, "OFFICE_ADDRESS")
    or contains(content, "holderAddress")
    or contains(content, "postalCode")
    or contains(content, "postal_code")
    or contains(content, "zipCode")
    or contains(content, "zip_code")
    or contains(content, "person_fullname")
    or contains(content, "insuredPerson")
    or contains(content, "holderName")
    or contains(content, "holder_name")
    or contains(content, "displayName")
    or contains(content, "given_name")
    or contains(content, "family_name")
    or contains(content, "firstName")
    or contains(content, "lastName")
    or contains(content, "fullName")
    or contains(content, "customerName")
    or contains(content, "policyHolderName")
    or contains(content, "uketorininName1")
    or contains(content, "employeeName")
    or contains(content, "phoneNumber")
    or contains(content, "phone_number")
    or contains(content, "mobileNumber")
    or contains(content, "mobile_number")
    or contains(content, "telNo")
    or contains(content, "tel_no")
    or contains(content, "emailAddress")
    or contains(content, "email_address")
    or contains(content, "mailAddress")
    or contains(content, "birthDate")
    or contains(content, "birth_date")
    or contains(content, "dateOfBirth")
    or contains(content, "birthday")
    or contains(content, "dob")
    or contains(content, "myNumber")
    or contains(content, "mynumber")
    or contains(content, "personalId")
    or contains(content, "nationalId")
    or contains(content, "passportNo")
    or contains(content, "passport_no")
    or contains(content, "bankAccount")
    or contains(content, "accountNumber")
    or contains(content, "account_number")
    or contains(content, "creditCard")
    or contains(content, "cardNumber")
    or contains(content, "loginId")
    or contains(content, "EMPLID")
    or contains(content, "taxpayer")
    or contains(content, "氏名")
    or contains(content, "住所")
    or contains(content, "電話")
    or contains(content, "生年月日")
    or contains(content, "郵便番号")
    or contains(content, "メール")
  )
```

### B) Category packs (cleaner when noise is high)

| Pack | What it means | When to use |
| --- | --- | --- |
| NAME | Person / holder / given / family names | Name leak check |
| ADDRESS | AddressKana, address Value, postal | Address leak check |
| CONTACT | phone, email, tel | Contact leak check |
| ID_DOB | birth, myNumber, passport, EMPLID | Identity leak check |
| FINANCE | bank, account, card | Payment data check |

---

## Data flow map

```
Host group pin
  → contains keyword pack (NAME / ADDRESS / CONTACT / ID / FINANCE / FULL)
  → fields + limit 20
  → review hit → ticket (class + host group; no raw PII paste)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `31-expand-pii-keyword-list-dql-follow.txt` | Chat-ready packs |
| `31-full-pii-keywords-per-host.dql` | All host groups + full pack |
| `31.sh` | Open paths |
| Seq 29 | Original per-host list (shorter keywords) |

Commands: see `31.sh`.
