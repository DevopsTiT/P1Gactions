# Name Address PII Per Host Group

## Decision tree

```
Need hit counts for name / address PII words per host group?
  │
  ├─ Want one table with all columns?
  │     → Run NA-1 Master (22-name-address-pii-per-host-group.dql)
  │
  ├─ Want name only?
  │     → Run NA-2 (22-name-only-per-host-group.dql)
  │
  ├─ Want address only (includes address, Value =)?
  │     → Run NA-3 (22-address-only-per-host-group.dql)
  │
  └─ After a group shows hits > 0
        Count by host.name + log.source
        Sample limit 10 only if needed
        Ticket owner / mask — do not export raw content
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you asked for | Search results **per `dt.host_group.id`** for name / address PII words |
| What I can give | Ready DQL that returns that table — **you run it in Dynatrace** |
| Why not live numbers here | No Dynatrace API from this chat; results change every hour |
| Main query | **NA-1** — columns: `hits_name`, `hits_address`, `hits_phone`, `hits_name_or_address`, `total_logs` |
| Scope | Same **56 column L** host groups as your inventory pack |

---

## Summary

These queries scan the last 24 hours of logs for **name-related** and **address-related** field words (plus the MDM `address, Value =` pattern you confirmed), then **count hits per host group**. Paste into Logs and Events → Advanced, run, and sort by the hit columns. That table is your “search result for each host group id.”

---

## Main content

### Where to run

| Step | Action |
| --- | --- |
| 1 | Dynatrace → **Logs and Events** |
| 2 | **Advanced** / DQL mode (not Data explorer) |
| 3 | Time: last **24 hours** (or change `now()-24h`) |
| 4 | Open the `.dql` file → copy all → Run |
| 5 | Visualization type: **Table** |

### Result columns (NA-1 Master)

| Column | What it counts |
| --- | --- |
| `dt.host_group.id` | Host group |
| `hits_name` | Lines with name field words (`holderName`, `insuredPerson`, `displayName`, …) |
| `hits_address` | Lines with address field words or `address, Value =` / `AXACleansingAddress` |
| `hits_phone` | Lines with phone field words or JP mobile shape |
| `hits_name_or_address` | Lines matching **either** name or address patterns |
| `total_logs` | All log lines in that group (denominator) |

### Words included (plain English)

| Category | Examples matched |
| --- | --- |
| Name | `insuredPerson`, `holderName`, `displayName`, `lastName`, `policyHolderName`, `given_name`, `family_name`, kana/kanji name fields |
| Address | `kanjiFullAddress`, `holderAddress1`, `subscriberAddr`, `AXACleansingAddress`, `address, Value =` |
| Phone | `subscriberPh`, `holderTel`, `telephoneNumber`, `090/080/070` style |

### Files to copy

| File | Query |
| --- | --- |
| [22-name-address-pii-per-host-group.dql](./22-name-address-pii-per-host-group.dql) | **NA-1 Master** (all columns) |
| [22-name-only-per-host-group.dql](./22-name-only-per-host-group.dql) | **NA-2** name only |
| [22-address-only-per-host-group.dql](./22-address-only-per-host-group.dql) | **NA-3** address only |

### How to read the table

| Reading | Meaning |
| --- | --- |
| High `hits_address` on MDM | Matches what you already saw (cleansing address logs) |
| High `hits_name`, low `hits_address` | Name fields leak more than addresses |
| High `total_logs`, near-zero hits | Chatty but cleaner for these words |
| Group missing from result (NA-2/NA-3) | Zero hits for that filter — good for that pattern |

### After a group lights up — drill (still counts)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "PASTE_HOST_GROUP_ID_HERE")
| filter matchesRegex(content, "(?i)(holderName|insuredPerson|displayName|kanjiFullAddress|AXACleansingAddress|address\\s*,\\s*Value\\s*=)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

Sample only if you must:

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "PASTE_HOST_GROUP_ID_HERE")
| filter matchesRegex(content, "(?i)(address\\s*,\\s*Value\\s*=)")
| fields timestamp, host.name, log.source, content
| limit 10
```

Treat samples as sensitive. Do not paste them into chat.

### Expected shape of your result (fill after you run)

| dt.host_group.id | hits_name | hits_address | hits_phone | hits_name_or_address | total_logs |
| --- | --- | --- | --- | --- | --- |
| *(run NA-1 — Dynatrace fills this)* | | | | | |
| `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | ? | expect high | ? | ? | ~loud from inventory |
| `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` | ? | ? | ? | ? | |
| `C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP` | ? | ? | ? | ? | |
| … | | | | | |

I cannot populate live numbers from here. After you run NA-1, you can paste **only the hit counts table** (no `content` column) if you want help ranking which groups to mask first.

### Safety

| Rule | Why |
| --- | --- |
| Use summarize / countIf | Search result without dumping PII |
| Export the **count table** only | Safe to share with app owners |
| Never export full `content` for all groups | Spreads addresses and names |
| `limit 10` on samples only | Caps personal viewing |

---

## Data flow map

```
All column L host groups (56 IDs)
        |
        v
filter name / address / phone words in content
        |
        v
summarize countIf → one row per dt.host_group.id
        |
        v
Sort by hits_name_or_address
        |
        +--> high hits → drill host/file → mask
        +--> zero hits → lower priority for these words
```

---

## Related files

| File | Purpose |
| --- | --- |
| [22.sh](./22.sh) | Open DQL files |
| [22-name-address-pii-per-host-group-follow.txt](./22-name-address-pii-per-host-group-follow.txt) | Chat-ready |
| MDM address finding | `2026-08-31/21-mdm-address-pii-confirmed-next-steps/` |
| Full column L pack | `2026-08-28/19-dql-pii-all-queries-column-l/` |

---

## Commands

See [22.sh](./22.sh).
