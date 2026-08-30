# DQL Common Cases How To

```
Which DQL case do you need?
  │
  ├─ Case 1: Logs arriving? → inventory (count all, no text filter)
  ├─ Case 2: One app group → matchesValue(dt.host_group.id, "...")
  ├─ Case 3: Many app groups → in(dt.host_group.id, { ... })
  ├─ Case 4: Find a keyword → matchesPhrase or matchesRegex
  ├─ Case 5: Dashboard per group → summarize count(), by: { ... }
  ├─ Case 6: Several hit types one table → summarize { countIf ... }, by: { }
  ├─ Case 7: Which server/file → by: { host.name, log.source }
  ├─ Case 8: Read raw lines → fields content + limit 10 (last)
  └─ Case 9: Error / no data → UI, braces, ID spelling, time window
```

| Question | Answer |
| --- | --- |
| Where to run? | **Logs and Events → Advanced mode** |
| First query always? | **Case 1 — inventory** (confirms data exists) |
| Safest pattern? | **Count first** (`summarize`), **sample last** (`fields` + `limit 10`) |
| Most used filter fields? | `dt.host_group.id`, `content`, `log.source`, `host.name` |
| Hardest syntax? | Multiple `countIf` needs `summarize { }, by: { }` |

## Summary

DQL is a **pipeline**: you pull logs with `fetch`, narrow with `filter`, aggregate with `summarize`, then optionally show raw text with `fields`. The nine cases below cover almost everything you do in log audits — especially PII discovery on host groups. Learn the order: **inventory → count hits → drill host/file → sample lines**. Never skip straight to `content` when hunting sensitive data.

**UI:** Logs and Events → **Advanced** (not Data explorer).

---

## Before you start — open the right screen

| Step | Action |
| --- | --- |
| 1 | Dynatrace menu → **Logs** (or **Logs and Events**) |
| 2 | Switch to **Advanced** / **DQL** mode |
| 3 | Set time range (top right) — e.g. **Last 24 hours** |
| 4 | Paste query → **Run** (Ctrl+Enter / Cmd+Enter) |

If you see **"parse error at logs"**, you are in **Data explorer** (metrics). Move to Logs → Advanced.

---

## Case 1 — Inventory: are logs arriving?

**When:** First query every audit. Before any PII search.

**Question it answers:** Does Dynatrace receive log lines from each host group?

**How it works:**

1. `fetch logs` — get all log lines in the time window
2. `filter in(...)` — optional, scope to your app groups
3. `summarize count()` — count lines per group
4. **No** search on `content` — you are not looking for PII yet

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP"
  })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

**How to read results:**

| Result | Meaning |
| --- | --- |
| Row with high `log_count` | Logs are flowing — chatty app |
| Row missing | No logs for that ID — check spelling or OneAgent |
| `log_count = 0` for all | Wrong IDs or no logs in time window |

**Next step:** If inventory looks good → Case 4 or Case 5.

---

## Case 2 — One host group only

**When:** Drill into a single app (Filenet, MDM, HATS).

**Use:** `matchesValue` for exact match on one ID.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| summarize log_count = count(), by: { dt.host_group.id }
```

**Why `matchesValue` not `in`?** One group — shorter and clear. Same result as `in` with one entry.

---

## Case 3 — Many host groups (column L list)

**When:** Audit all apps at once (56 groups).

**Use:** `in(dt.host_group.id, { "ID1", "ID2", ... })`

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP",
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP"
  })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

**Tip:** Copy IDs exactly from inventory results (`C_ALI_BU_*`). Wrong spelling → zero rows.

---

## Case 4 — Find text in log lines

**When:** Search for keywords, field names, errors, PII patterns.

### 4a — Fixed string → `matchesPhrase`

Use when the text is **exact and stable** (class name, JSON key, error message).

```text
fetch logs, from: now()-24h
| filter matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

**Examples:** `ProcessNdServiceImpl`, `SystemOut`, `insuredPerson`, `TXID`

### 4b — Pattern / many keywords → `matchesRegex`

Use when you need **case-insensitive** or **many alternatives** in one filter.

```text
fetch logs, from: now()-24h
| filter matchesRegex(content, "(?i)(insuredPerson|loginId|customer_id|EMPLID)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

**Regex tips:**

| Pattern | Finds |
| --- | --- |
| `(?i)loginId` | loginId, LoginId, LOGINID |
| `\\b0[789]0\\d{8}\\b` | Japan mobile 090/080/070 |
| `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}` | Email shape |

**Do not use** `\x{3040}` for Japanese Unicode — DQL does not support it. Use `matchesPhrase(content, "保険金")` instead.

### 4c — Stack filters (AND)

Each `filter` line must pass — narrows results.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP")
| filter matchesValue(log.source, "SystemOut")
| filter matchesPhrase(content, "rawDataList")
| summarize hit_count = count()
```

### 4d — OR inside one filter

```text
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
```

---

## Case 5 — Dashboard: count hits per group

**When:** Priority list — which apps have the most matching lines.

**Pattern:** `fetch` → `filter` (text match) → `summarize` → `sort`

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|loginId|holderName)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

**How to read:**

| Column | Meaning |
| --- | --- |
| `hit_count` | Lines whose **text** matched — not proof of real PII leak until you sample |
| Sort desc | Worst / loudest group at top |

This is your **PII-only** query pattern (seq 23).

---

## Case 6 — Master table: several hit types in one query

**When:** One row per group with multiple columns (keyword PII, HATS, total logs).

**Problem:** If you `filter` for PII first, you lose the total log count.

**Solution:** `countIf` inside `summarize { }` — counts each pattern without removing rows.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP"
  })
| summarize {
    hits_keyword = countIf(
      matchesRegex(content, "(?i)(insuredPerson|loginId)")
    ),
    hits_hats = countIf(
      matchesPhrase(content, "rawDataList")
      or matchesPhrase(content, "ProcessNdServiceImpl")
    ),
    total_logs = count()
  },
  by: { dt.host_group.id }
| sort hits_keyword desc
```

**Critical syntax:** The `{ }` around the `countIf` block. Without braces you get `'by' isn't allowed here`.

**How to read:**

| Column | Meaning |
| --- | --- |
| `hits_keyword` | Lines matching insurance/HULFT field names |
| `hits_hats` | Lines with HATS-style signatures |
| `total_logs` | All lines in group (denominator) |

---

## Case 7 — Drill down: which server and log file

**When:** Case 5 or 6 shows hits — you need **where** they come from.

**Add** `host.name` and `log.source` to `by:`.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**How to read:**

| Column | Use for |
| --- | --- |
| `host.name` | Which VM/pod |
| `log.source` | Which log file (e.g. `SystemOut`, `/var/log/app.log`) |
| `hit_count` | How many lines from that host+file |

Give this to the app owner for masking scope.

---

## Case 8 — Sample raw log lines (last step only)

**When:** Counts are non-zero and you need to **see** what matched.

**Risk:** Shows real PII on screen. Always `limit 10`.

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)loginId")
| fields timestamp, dt.host_group.id, host.name, log.source, content
| sort timestamp desc
| limit 10
```

**Order matters:**

```
summarize hit_count  →  if hit_count > 0  →  fields content limit 10
```

Never export or screenshot bulk `content` results.

---

## Case 9 — Change time window

**When:** 24h returns nothing but you know logs exist.

Edit the first line only:

```text
fetch logs, from: now()-7d
fetch logs, from: now()-1h
```

| Window | Tradeoff |
| --- | --- |
| `now()-1h` | Fast, small scan — good for testing syntax |
| `now()-24h` | Default for daily audit |
| `now()-7d` | Finds rare events — slower, more GB scanned |

Time range in the UI (top right) should match your `from:` clause.

---

## Case 10 — Troubleshooting

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| Parse error at `logs` | Data explorer | Logs → Advanced |
| `'by' isn't allowed here` | Missing `{ }` on countIf | See Case 6 |
| GB scanned, no rows | Wrong host group ID | Run Case 1 inventory |
| Red squiggle on regex | Invalid escape (Unicode) | Use matchesPhrase for Japanese |
| All groups 0 hits | Filter too strict | Remove text filter; inventory only |
| Query slow | Wide time + all groups | Narrow time or fewer IDs first |

---

## Recommended workflow (PII audit)

```
Step 1  Case 1  Inventory per host group
          ↓
Step 2  Case 5 or 6  Count PII signals per group
          ↓
Step 3  Case 7  Drill host.name + log.source on worst group
          ↓
Step 4  Case 8  Sample 10 lines — confirm with app owner
          ↓
Step 5  Apply masking → re-run Step 2 → hits should drop
```

---

## Quick reference — which function when

| Goal | Function |
| --- | --- |
| One exact host group | `matchesValue(dt.host_group.id, "...")` |
| Many host groups | `in(dt.host_group.id, { ... })` |
| Exact substring in log | `matchesPhrase(content, "...")` |
| Pattern / many keywords | `matchesRegex(content, "...")` |
| Count per group | `summarize x = count(), by: { ... }` |
| Multiple counts one table | `summarize { countIf(...), ... }, by: { ... }` |
| Show columns | `fields timestamp, content, ...` |
| Cap rows | `limit 10` |

---

## Data flow map

```
User opens Logs → Advanced
  → fetch logs, from: now()-24h
  → filter scope (host groups)
  → filter match (content)     ← optional for inventory
  → summarize count / countIf
  → sort hit_count desc
  → (optional) fields content + limit 10
  → Results table or log lines
```

---

## Related files

| File | Role |
| --- | --- |
| `27-dql-common-cases-how-to.md` | This guide |
| `27-dql-common-cases-how-to.dql` | All example queries |
| `27.sh` | One-liner copies |
| `26-common-dql-syntax-examples/` | Syntax cheat sheet |
| `23-pii-only-all-column-l/` | Full PII query |

## Commands

Paste queries from `27-dql-common-cases-how-to.dql` into **Logs → Advanced**. See `27.sh` for one-liners.
