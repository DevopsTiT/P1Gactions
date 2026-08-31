# Fix MDM PII DQL No Data

## Decision tree

```
Dynatrace: "No data that matches your query"
  │
  ├─ Trailing space in host group ID string?
  │     YES → remove space after ...PRD_T_APP"
  │
  ├─ Prove logs exist (no content filter)
  │     hit_count = 0 → wrong ID / wrong time / no ingest
  │     hit_count > 0 → host group OK; regex was the problem
  │
  ├─ Search simple phrase first
  │     address, Value =   OR   AXACleansingAddress
  │
  └─ Then add name/address field regex (short, clean)
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Why empty | Host group ID likely has a **trailing space**, and/or the giant regex is **broken/truncated** |
| Proof you have data | You already opened MDM address lines in the log viewer earlier |
| Fix order | (1) inventory one group → (2) phrase match → (3) short name/address regex |
| Do not | Paste a damaged multi-line regex with `|Name|` fragments mid-field |

---

## Summary

Your query scanned tens of GB but matched nothing because the filters never lined up with real log text. Fix the exact host group string, confirm volume without a content filter, then search with short reliable patterns (`AXACleansingAddress`, `address, Value =`, then a clean name/address regex).

---

## Main content

### Bugs in the query on your screen

| Bug | What went wrong | Fix |
| --- | --- | --- |
| Trailing space | `"...PRD_T_APP "` (space before closing quote) | Use exact `"C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP"` |
| Broken regex | Field names cut mid-word; stray `Name` pieces | Use the short clean regex below |
| Too strict + broken | `matchesValue` fails → zero rows before regex matters | Prove host group first |
| Execution 0s | Filter eliminated everything immediately | Step queries below |

### Step 1 — Prove MDM logs exist (must return a number)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| summarize hit_count = count(), by: { dt.host_group.id }
```

| Result | Meaning |
| --- | --- |
| Large `hit_count` | Host group ID is correct — continue |
| No data | Wrong ID spelling, wrong timeframe, or no logs |

### Step 2 — Address leak you already saw (phrase)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "AXACleansingAddress")
| summarize hit_count = count(), by: { dt.host_group.id }
```

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "address, Value =")
| summarize hit_count = count(), by: { dt.host_group.id }
```

### Step 3 — Name + address field words (short clean regex)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|displayName|holderName|holder_name|loginId|kanjiFullAddress|kanaFullAddress|subscriberAddr|subscriberPh|AXACleansingAddress|given_name|family_name|policyHolderName)")
| summarize hit_count = count(), by: { dt.host_group.id }
```

### Step 4 — Split columns (name vs address) for MDM only

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| summarize {
    hits_name = countIf(matchesRegex(content, "(?i)(insuredPerson|displayName|holderName|holder_name|given_name|family_name|policyHolderName|loginId)")),
    hits_address = countIf(
      matchesPhrase(content, "AXACleansingAddress")
      or matchesPhrase(content, "address, Value =")
      or matchesRegex(content, "(?i)(kanjiFullAddress|kanaFullAddress|subscriberAddr|holderAddress1)")
    ),
    total_logs = count()
  },
  by: { dt.host_group.id }
```

### Step 5 — Host + file (after hits > 0)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "AXACleansingAddress")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Copy checklist before Run

| Check | Required value |
| --- | --- |
| Host group | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` — **no space at end** |
| Mode | Logs and Events → **Advanced** |
| Time | `now()-24h` (or widen to `now()-7d` if Step 1 is empty) |
| Regex | One clean `(?i)(...)` line — no line breaks inside the pattern |
| First success | Step 1 then Step 2 — do not start with the giant HULFT list |

### If Step 2 works but Step 3 is empty

| Meaning | Action |
| --- | --- |
| Leak is phrase-based (`address, Value =`), not Excel field names | Use Step 2 / address phrases for counts |
| Field-name regex still useful for other apps | Keep NA-1 from seq 22 for all 56 groups |

---

## Data flow map

```
Broken query on screen
  trailing space in host group? → remove
  giant broken regex? → replace with Step 2/3
        |
        v
Step 1 count all MDM logs  → proves ID
Step 2 phrase AXACleansingAddress / address, Value =
Step 3 short name+address regex
Step 4 countIf columns
Step 5 host + log.source
```

---

## Related files

| File | Purpose |
| --- | --- |
| [23.sh](./23.sh) | Open this guide |
| [23-fix-mdm-pii-dql-no-data-follow.txt](./23-fix-mdm-pii-dql-no-data-follow.txt) | Chat-ready paste queries |
| Per-group pack | `2026-08-31/22-name-address-pii-per-host-group/` |
| Confirmed address finding | `2026-08-31/21-mdm-address-pii-confirmed-next-steps/` |

---

## Commands

See [23.sh](./23.sh).
