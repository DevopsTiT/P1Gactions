# Why DQL No Result Vs Classic

## Decision tree

```
Classic Logs shows MDM address lines, but Advanced DQL says No data?
  │
  ├─ Did DQL use matchesPhrase("AXACleansingAddress")?
  │     YES → likely FAIL
  │     Real class token is AXACleansingAddressBP (longer word)
  │     matchesPhrase matches whole tokens → use contains / regex / full class name
  │
  ├─ Run host-group-only count in Advanced (no content filter)
  │     No data → host group string wrong OR logs not in Grail path
  │     Has data → only the content filter was wrong
  │
  └─ Fix content filter
        contains(content, "AXACleansingAddress")
        OR matchesPhrase(content, "axacleansingservice")
        OR matchesPhrase(content, "AXACleansingAddressBP")
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Classic UI | Real logs exist for `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` |
| Class in log | `AXACleansingAddressBP` (and package `axacleansingservice`) |
| Your DQL filter | `matchesPhrase(content, "AXACleansingAddress")` |
| Why empty | `matchesPhrase` looks for a **whole token**; `AXACleansingAddress` ≠ `AXACleansingAddressBP` |
| Fix | Use `contains`, regex, package name, or the **full** class name |

---

## Summary

Side-by-side: Classic proves the data is there. Advanced DQL returned empty because the content filter did not match the real token in the log line. Switch from a partial `matchesPhrase` to `contains` / full class name / package phrase, after confirming the host-group-only count works.

---

## Main content

### What each screen shows

| Screen | What it proves |
| --- | --- |
| Classic Logs (first picture) | Thousands of INFO lines; class `...AXACleansingAddressBP`; host group `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` |
| Advanced DQL (second picture) | Query with `matchesPhrase(..., "AXACleansingAddress")` → **No data** |

So this is not “Dynatrace has no logs.” It is “this DQL filter matched zero lines.”

### Root cause (most likely)

| Item | Value |
| --- | --- |
| In the log | `jp.co.axa.mdm.ws.composite.axacleansingservice.bp.AXACleansingAddressBP` |
| You searched | phrase `AXACleansingAddress` |
| How `matchesPhrase` works | Case-insensitive **whole-word / whole-token** match |
| Result | Token is `AXACleansingAddressBP` → partial phrase does not match |

### Secondary checks

| Check | If true | What to do |
| --- | --- | --- |
| Host group typo / trailing space | `matchesValue` matches nothing | Copy ID from Classic **Fields** panel |
| Only Classic has the stream | Host-group-only DQL also empty | Confirm Grail ingest for that OneAgent / log source |
| Time range | Unlikely here (Classic 30m ⊂ DQL 24h) | Keep `now()-24h` |

### Fixed queries — paste one at a time

**A) Host group only (must return a big number)**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| summarize hit_count = count(), by: { dt.host_group.id }
```

**B) Package name (whole lowercase token — good for matchesPhrase)**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
```

**C) Full class name**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "AXACleansingAddressBP")
| summarize hit_count = count(), by: { dt.host_group.id }
```

**D) Partial class — use contains (recommended)**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "AXACleansingAddress")
| summarize hit_count = count(), by: { dt.host_group.id }
```

**E) Address Value pattern**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "address, Value =")
| summarize hit_count = count(), by: { dt.host_group.id }
```

**F) If `contains` is not allowed in your tenant — regex**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)AXACleansingAddress")
| summarize hit_count = count(), by: { dt.host_group.id }
```

### Phrase vs contains (remember this)

| Function | Matches `AXACleansingAddressBP` when you search `AXACleansingAddress`? |
| --- | --- |
| `matchesPhrase` | Often **no** (whole token) |
| `contains` | **Yes** (substring) |
| `matchesRegex(...AXACleansingAddress...)` | **Yes** |
| `matchesPhrase("AXACleansingAddressBP")` | **Yes** (full token) |
| `matchesPhrase("axacleansingservice")` | **Yes** (package token in the line) |

---

## Data flow map

```
Classic UI filter: host group only
  → sees AXACleansingAddressBP lines  ✓

Advanced DQL:
  host group OK?
    run A (count only)
  content filter:
    matchesPhrase("AXACleansingAddress")  ✗ token mismatch
    contains("AXACleansingAddress")       ✓
    matchesPhrase("axacleansingservice")  ✓
    matchesPhrase("AXACleansingAddressBP")✓
```

---

## Related files

| File | Purpose |
| --- | --- |
| [24.sh](./24.sh) | Open this note |
| [24-why-dql-no-result-vs-classic-follow.txt](./24-why-dql-no-result-vs-classic-follow.txt) | Chat-ready |
| Prior fix pack | `2026-08-31/23-fix-mdm-pii-dql-no-data/` |

---

## Commands

See [24.sh](./24.sh).
