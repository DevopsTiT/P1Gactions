# Why HR DQL Many Bad Results

## Decision tree

```
HR query returns perl/cron/EMPLID ops logs (not address/phone values)?
  │
  ├─ Keyword list too wide?
  │     YES — EMPLID, firstName, mail, dob, name match normal HR ops text
  │
  ├─ Copied MDM cleansing keywords to PeopleSoft?
  │     axacleansingservice / AXACleansing* rarely apply on HR
  │
  ├─ Missing Value= requirement?
  │     Field name alone ≠ dumped PII value
  │
  └─ Fix
        Require Value= (or strong JP labels)
        Drop short tokens (dob, mail, name alone)
        Drop EMPLID-only hits unless you want ID inventory
        Prefer C_ALI_… ID from Dynatrace, not Excel ALJ
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Why so many bad rows | Broad `contains` words match **normal HR/PeopleSoft ops logs** |
| Not a Dynatrace bug | Query is doing exactly what you asked (substring match) |
| Your table shows | EMPLID job messages, perl cron starts — not address Value dumps |
| Fix | Narrow to **field + Value =** (same lesson as MDM) |

---

## Summary

The giant keyword script is too loose for HR. Words like `EMPLID`, `firstName`, `mail`, `dob` appear in routine logs. Require `Value =` (or clear address/phone patterns) and drop short tokens.

---

## Investigation

| What your result shows | Likely matched by |
| --- | --- |
| `Find a primary job for the EMPLID:…` | `EMPLID` |
| `Started /usr/bin/perl …` | maybe `mail`, `name`, path fragments, or other short tokens |
| Process created / cron | ops text, not PII values |
| Almost no `address, Value =` | MDM-style leak pattern not present (or rare) on this host group |

| Keyword problem | Why |
| --- | --- |
| `EMPLID` | Common in every PeopleSoft job log |
| `dob` / `mail` / bare `name` | Too short; many false hits |
| `firstName` / `lastName` / `fullName` | Often in code/config without values |
| `axacleansingservice` | MDM cleansing package — wrong app for HR |

Host ID note: script used `C_ALJ_BU_HR_…`; live rows show `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP`. Prefer the live `ALI` ID.

---

## Result — tighter HR DQL

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP")
| filter contains(content, "Value =")
| filter (
    contains(content, "address")
    or contains(content, "Address")
    or contains(content, "postal")
    or contains(content, "phone")
    or contains(content, "mobile")
    or contains(content, "email")
    or contains(content, "birth")
    or contains(content, "given_name")
    or contains(content, "family_name")
    or contains(content, "employeeName")
    or contains(content, "氏名")
    or contains(content, "住所")
    or contains(content, "電話番号")
    or contains(content, "生年月日")
    or contains(content, "郵便番号")
  )
| filter not contains(content, "/usr/bin/perl")
| filter not contains(content, "Started /usr/bin")
| filter not contains(content, "A new process has been created")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

If this returns **No data**, HR may not log address/phone as `Value =` text (different from MDM). Then search one strong word at a time, e.g. only `AddressKana` or only `住所`, instead of the giant OR list.

---

## Data flow map

```
Giant keyword OR list
  → matches EMPLID / perl / cron ops  ← your bad results
Require Value= + address|phone|email|name fields
  → drop perl/process noise
  → real PII-like rows (or empty = no that pattern on HR)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `35-why-hr-dql-many-bad-results-follow.txt` | Paste-ready fix |
| `35.sh` | Open helpers |
| Seq 32 / 34 | Same Value= lesson for MDM |

Commands: see `35.sh`.
