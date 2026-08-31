# Fix Regex Empty Use Contains

## Decision tree

```
Scanned GB > 0 but "No data matches"?
  │
  ├─ You still have matchesRegex(... \s ...)?
  │     YES → DELETE that line. Regex with \s is the failure.
  │
  ├─ Prove host group has any rows (no content filter)
  │     Step A below → should show 5 sample lines
  │
  ├─ Content only, no host filter (30m) — same as Q1 that worked
  │     contains(content, "axacleansingservice")
  │
  └─ Then pin host group + contains (never matchesRegex / matchesPhrase for class names)
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What your screen proves | Host filter works (scanned ~39 GB). Content filter returns 0. |
| Why 0 rows | Line 3 is still `matchesRegex` with `\s` / giant OR list. That pattern does not match real lines. |
| What already worked | `contains(content, "axacleansingservice")` and `contains(content, "address, Value =")` |
| Timerange | All steps use `now()-24h` |
| What to paste | Steps A → B → C below. Do not paste any `matchesRegex` block. |

---

## Summary

Your host group ID is fine. The empty result is the **content** step. Stop using `matchesRegex` with `\s`. Use short `contains` filters with **24h**, content-first if needed.

---

## Investigation

| Check | Your screen | Meaning |
| --- | --- | --- |
| Host group | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | Correct MDM APP ID |
| Scanned data | ~39.4 GB | Logs exist for that host group |
| Content filter | `matchesRegex` + `\s` + long OR list | This is what returns 0 |
| Earlier proof | Q1–Q4 with `contains` / 30m | Data and PII were confirmed |

Class name in logs is often `AXACleansingAddressBP`. Prefer `contains`, not `matchesPhrase` / fragile regex.

---

## Result

Run **A → B → C** in order. Clear the query box each time. Do not keep the old regex line.

### Step A — any lines from this host group

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| fields timestamp, dt.host_group.id, host.name, content
| limit 5
```

If A is empty at 24h, ingest/time or wrong ID — not PII words.

### Step B — package name only (worked before)

```text
fetch logs, from: now()-24h
| filter contains(content, "axacleansingservice")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Step C — address leak lines (worked before)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "address, Value =")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Step D — address class substring (optional)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "AXACleansingAddress")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Do not paste

| Avoid | Why |
| --- | --- |
| `matchesRegex(... address\\s*,\\s*Value ...)` | `\s` often fails after copy/paste; whole filter returns 0 |
| `matchesPhrase(content, "AXACleansingAddress")` | Real token is often `AXACleansingAddressBP` |
| Giant one-line OR regex from old `.dql` / follow files | That is what your screenshot still shows |

---

## Data flow map

```
Grail logs (MDM APP host group)
  → filter host group   OK (39 GB scanned)
  → filter matchesRegex+\s   FAIL (0 rows)   ← your screen
  → filter contains("axacleansingservice")   OK path
  → filter contains("address, Value =")      OK path → show lines (limit 20)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `30-fix-regex-empty-use-contains-follow.txt` | Chat-ready paste steps |
| `30.sh` | Command placeholders (UI only; no CLI) |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Evidence from screenshot |
| `2-result.md` | What to run |
| `3-glossary.md` | Terms |
| Seq 26 / 28 | Queries that previously returned rows |

Commands: see `30.sh`.
