# Improve DQL From First Results

## Decision tree

```
Is it OK to only improve DQL (no JSON second pass)?
  │
  ├─ YES — preferred
  │     Use first result patterns → tighter contains / not contains
  │     Re-run in Dynatrace → export only if ticket needs evidence
  │
  ├─ When JSON second pass is still useful
  │     Huge export already downloaded
  │     Or need redacted summary file for ticket
  │
  └─ What to keep from your first MDM hits
        address, Value = / AddressKana / Person+Address dumps
        DROP CleansingResult / service counters
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Is DQL-only OK? | **Yes — best default** |
| Why | Filters at source; less PII copied to disk |
| How | Keep obvious value patterns from first hits; exclude noise |
| JSON later? | Optional, only if you already exported or need a redacted file |

---

## Summary

Improve DQL from the first successful result. That is enough for hunting. JSON post-filter is optional backup, not required.

---

## Investigation

| First-result pattern | Keep or drop |
| --- | --- |
| `address, Value =` / `AddressKana` | Keep |
| Person / AddressGroup / ContactMethod with values | Keep (if Value= style) |
| `AXACleansingServiceBP` + `CleansingResult=0` | Drop |
| Process/APP id only lines | Drop |

---

## Result — paste this improved DQL

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter (
    contains(content, "address, Value =")
    or contains(content, "AddressKana")
    or contains(content, "AddressKanji")
    or contains(content, "Type = address")
    or contains(content, "kanjiFullAddress")
    or contains(content, "person_fullname, Value =")
    or contains(content, "given_name, Value =")
    or contains(content, "family_name, Value =")
    or contains(content, "holderName, Value =")
    or contains(content, "phoneNumber, Value =")
    or contains(content, "mobileNumber, Value =")
    or contains(content, "emailAddress, Value =")
    or contains(content, "住所")
    or contains(content, "電話番号")
    or contains(content, "郵便番号")
    or contains(content, "氏名")
  )
| filter not contains(content, "CleansingResult")
| filter not contains(content, "cleansingResult")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

---

## Data flow map

```
First broad result (learn real patterns)
  → Improve DQL (keep Value= PII / drop CleansingResult)
  → Re-run in UI
  → (optional) export / ticket with redacted evidence
```

---

## Related files

| File | Purpose |
| --- | --- |
| `34-improve-dql-from-first-results-follow.txt` | Paste query |
| `34.sh` | Open helpers |
| Seq 32 | Same idea, longer packs |
| Seq 33 | JSON second pass (optional) |

Commands: see `34.sh`.
