# MDM PII Search Results Worked

## Decision tree

```
Q1–Q4 worked, Q5 (matchesValue) empty?
  │
  ├─ You retyped the host group ID by hand?
  │     YES → typo risk (DATAENGI vs DATAENGLE, CUSTMDMGM vs CUSTHDMGM)
  │     Fix: copy-paste ID from Q4 result cell — do not retype
  │
  ├─ What you already proved
  │     axacleansingservice lines exist in Grail (30m)
  │     Address + person-name cleansing logs contain real PII values
  │     ~36,503 hits on MDM host group; 46 on Splunk-release group
  │
  └─ Next
        Pin MDM with copied ID → name vs address counts → host drill → ticket/mask
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Status | **Search path works** — content-first DQL is correct |
| Main host group | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` |
| Hits (30m, `axacleansingservice`) | **36,503** on MDM; **46** on `C_ALI_BU_APPRELEAS_A_SPLUNK_E_PRD_T_APP` |
| PII confirmed | Person-name cleansing + **address, Value =** with real address text |
| Why Q5 failed | `matchesValue` ID almost certainly mistyped — copy from Q4 table |
| Do not | Paste raw `content` (names/addresses) into chat or tickets |

---

## Summary

Your screenshots show the fixed approach succeeded: Grail returns cleansing logs, and the summarize-by-host-group query ranks MDM far above everything else. The last empty query is only a host-group string mismatch. Copy the ID from the result table, then run name/address split counts and masking follow-up.

---

## Main content

### What each of your runs proved

| Query | Result | Meaning |
| --- | --- | --- |
| `contains(axacleansingservice)` + fields | Rows returned | Grail sees MDM cleansing logs |
| `contains(AXACleansingAddress)` | Rows returned | Address BP logs present |
| `contains(address, Value =)` | Rows with address values | **Confirmed address PII in logs** |
| summarize by `dt.host_group.id` | MDM 36503; Splunk group 46 | Volume by group for last 30 minutes |

### Exact host group IDs from your Q4 table

| dt.host_group.id | hit_count (30m) |
| --- | --- |
| `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | 36503 |
| `C_ALI_BU_APPRELEAS_A_SPLUNK_E_PRD_T_APP` | 46 |

### Fix Q5 — copy-paste, do not retype

```text
fetch logs, from: now()-30m
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
```

Expected: one row, `hit_count` near **36503** (same window).

If it is empty again: in the Q4 result, click the host group cell → copy → paste between the quotes.

### Next queries (safe counts)

**Name vs address on MDM**

```text
fetch logs, from: now()-30m
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| summarize {
    hits_person_name_bp = countIf(contains(content, "AXACleansingPersonName")),
    hits_address_bp = countIf(contains(content, "AXACleansingAddress")),
    hits_address_value = countIf(contains(content, "address, Value =")),
    hits_person_value = countIf(contains(content, "person_fullname")),
    total_cleansing = countIf(contains(content, "axacleansingservice"))
  },
  by: { dt.host_group.id }
```

**Which host**

```text
fetch logs, from: now()-30m
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { host.name }
| sort hit_count desc
```

**24h volume (widen after 30m is trusted)**

```text
fetch logs, from: now()-24h
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

**Second group (46 hits) — check separately**

```text
fetch logs, from: now()-30m
| filter matchesValue(dt.host_group.id, "C_ALI_BU_APPRELEAS_A_SPLUNK_E_PRD_T_APP")
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
```

### Finding text for app owner (no raw PII)

```text
Finding: Customer MDM PRD logs personal name and address values via axacleansingservice INFO logs.
Host group: C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP
Host example: CEAA2116.piprivmgmt.intraxa (from search results)
Evidence (30m): ~36,503 log lines containing axacleansingservice; samples show
  AXACleansingPersonName* and AXACleansingAddress* with "Value =" parameters.
Also: C_ALI_BU_APPRELEAS_A_SPLUNK_E_PRD_T_APP had 46 matching lines.
Ask: Stop logging full name/address Value at INFO; mask at OneAgent/OpenPipeline until app fix.
```

### Safety

| Rule | Why |
| --- | --- |
| Share counts + class names only | Avoid spreading customer name/address text |
| Limit samples to confirm masking later | Caps exposure |
| Prefer `contains` for CamelCase BP names | Avoids matchesPhrase token traps |

---

## Data flow map

```
Q1 content-only     ✓ rows (names in cleansing)
Q2 Address BP       ✓ rows
Q3 address, Value=  ✓ rows (clear address PII)
Q4 summarize        ✓ MDM 36503 / Splunk-group 46
Q5 matchesValue     ✗ empty → ID mistyped
                      → copy ID from Q4 → retry
                      → name/address split counts → mask
```

---

## Related files

| File | Purpose |
| --- | --- |
| [26.sh](./26.sh) | Open this note |
| [26-mdm-pii-search-results-worked-follow.txt](./26-mdm-pii-search-results-worked-follow.txt) | Chat-ready |
| New Logs fix | `2026-08-31/25-fix-new-logs-ui-mdm-search/` |
| Masking | `2026-08-28/1-dynatrace-logs-pii-filter/` |

---

## Commands

See [26.sh](./26.sh).
