# Common DQL Syntax and Examples

```
Need to write DQL in Dynatrace?
  │
  ├─ Step 0: Right UI?
  │     Logs and Events → Advanced mode (NOT Data explorer)
  │
  ├─ Step 1: fetch — pick data type + time window
  │
  ├─ Step 2: filter — scope servers + match text
  │
  ├─ Step 3: summarize — count (safe, no raw PII)
  │     multiple countIf? → use { } braces around block
  │
  ├─ Step 4: sort + limit — rank results
  │
  └─ Step 5: fields content — sample only, limit 10
```

| Question | Answer |
| --- | --- |
| What is DQL? | Dynatrace Query Language — query logs, spans, events on Grail |
| Where to run log DQL? | **Logs and Events → Advanced mode** |
| Basic shape? | `fetch` → `filter` → `summarize` → `sort` → `limit` |
| Count before sample? | Always — `summarize` first, `fields content` last |
| Pipe character? | `\|` separates stages (like SQL pipelines) |

## Summary

DQL reads top to bottom like a pipeline: each stage passes rows to the next. For log audits you almost always start with `fetch logs`, narrow with `filter`, then `summarize` to count without showing sensitive text. Use `matchesPhrase` for fixed strings, `matchesRegex` for patterns, and `countIf` when you need several hit types in one table. Run queries in **Logs → Advanced**, not Data explorer.

---

## 1. Where to run DQL

| UI | Good for | Log DQL? |
| --- | --- | --- |
| **Logs and Events → Advanced** | Log search, PII audits | **Yes** |
| **Notebooks → DQL cell** | Saved repeatable queries | **Yes** |
| **Data explorer** | Metrics only | **No** — `fetch logs` fails here |

---

## 2. Pipeline stages (the `\|` chain)

| Stage | Keyword | What it does |
| --- | --- | --- |
| 1 | `fetch` | Load records from Grail |
| 2 | `filter` | Keep rows matching a condition |
| 3 | `fields` | Pick columns to display |
| 4 | `summarize` | Group and aggregate (count) |
| 5 | `sort` | Order rows |
| 6 | `limit` | Cap row count |

**Minimal example — count all logs per host group:**

```text
fetch logs, from: now()-24h
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

---

## 3. `fetch` — time window and data type

```text
fetch logs, from: now()-24h
fetch logs, from: now()-1h
fetch logs, from: now()-7d
fetch spans, from: now()-24h
fetch events, from: now()-24h
```

| Expression | Meaning |
| --- | --- |
| `now()-24h` | Last 24 hours |
| `now()-7d` | Last 7 days |
| `fetch logs` | Log records (your PII work) |
| `fetch spans` | Distributed traces |
| `fetch events` | Dynatrace events |

---

## 4. `filter` — keep matching rows

### 4.1 Match one exact value

```text
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesValue(log.source, "SystemOut")
```

### 4.2 Match any value in a list

```text
| filter in(dt.host_group.id, {
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP",
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP"
  })
```

### 4.3 Substring (phrase)

Case-sensitive substring search. Good for class names and JSON keys.

```text
| filter matchesPhrase(content, "rawDataList")
| filter matchesPhrase(content, "ProcessNdServiceImpl")
```

### 4.4 Regular expression

Good for many keywords in one pattern or email/phone shapes.

```text
| filter matchesRegex(content, "(?i)loginId")
| filter matchesRegex(content, "(?i)(insuredPerson|displayName|loginId)")
| filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
```

| Regex tip | Meaning |
| --- | --- |
| `(?i)` | Case-insensitive |
| `\\b` | Word boundary |
| `\\d{12}` | Exactly 12 digits |

**Note:** DQL regex only supports `\x00`–`\xFF` (two hex digits). `\x{3040}` Unicode ranges **do not work** — use `matchesPhrase` for Japanese labels instead.

### 4.5 Combine conditions

```text
| filter matchesPhrase(content, "rawDataList")
| filter matchesValue(log.source, "SystemOut")
```

Both filters must pass (AND). For OR inside one filter:

```text
| filter matchesPhrase(content, "ProcessNdServiceImpl")
  or matchesPhrase(content, "HatsProcessResponse")
  or matchesPhrase(content, "rawDataList")
```

---

## 5. `summarize` — count without showing content

### 5.1 Simple count per group

```text
| summarize hit_count = count(), by: { dt.host_group.id }
```

### 5.2 Count with multiple breakdown columns

```text
| summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source }
```

### 5.3 `countIf` — several metrics in one table

Normal `filter` removes non-matching rows. `countIf` counts matches **without** dropping other rows.

**Wrong — syntax error on `by:`:**

```text
| summarize
    hits_a = countIf(matchesPhrase(content, "rawDataList")),
    hits_b = countIf(matchesRegex(content, "(?i)loginId")),
    total = count()
  , by: { dt.host_group.id }
```

**Correct — wrap block in `{ }`:**

```text
| summarize {
    hits_a = countIf(matchesPhrase(content, "rawDataList")),
    hits_b = countIf(matchesRegex(content, "(?i)loginId")),
    total = count()
  },
  by: { dt.host_group.id }
```

---

## 6. `sort` and `limit`

```text
| sort hit_count desc
| sort hits_keyword_pii desc, hits_hats_style desc
| limit 10
| limit 100
```

Use `limit 10` when showing `content` — never export thousands of PII lines.

---

## 7. `fields` — pick columns (sample step)

```text
| fields timestamp, dt.host_group.id, host.name, log.source, content
| sort timestamp desc
| limit 10
```

Run this **only after** `summarize` shows `hit_count > 0`.

---

## 8. Common log fields

| Field | What it is | Example use |
| --- | --- | --- |
| `content` | Full log line text | PII regex / phrase search |
| `dt.host_group.id` | App host group tag | Scope to column L IDs |
| `host.name` | Server hostname | Drill-down |
| `log.source` | Log file or stream name | e.g. `SystemOut` |
| `timestamp` | When the line was written | Sort samples newest first |

---

## 9. Copy-ready examples (your audit patterns)

### Example 1 — Inventory (logs arriving?)

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, { "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP" })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

### Example 2 — PII keyword hit count (one group)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(insuredPerson|loginId|customer_id)")
| summarize hit_count = count(), by: { dt.host_group.id }
```

### Example 3 — PII across many host groups

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP"
  })
| filter matchesRegex(content, "(?i)(insuredPerson|loginId|EMPLID)")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

### Example 4 — Drill down by host and log file

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP")
| filter matchesPhrase(content, "rawDataList")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### Example 5 — Mini master dashboard (countIf)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| summarize {
    hits_keyword = countIf(matchesRegex(content, "(?i)(insuredPerson|loginId)")),
    hits_hats = countIf(matchesPhrase(content, "rawDataList")),
    total_logs = count()
  },
  by: { dt.host_group.id }
```

### Example 6 — Sample raw lines (last step)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)loginId")
| fields timestamp, host.name, log.source, content
| sort timestamp desc
| limit 10
```

---

## 10. Common mistakes

| Symptom | Cause | Fix |
| --- | --- | --- |
| Parse error at `logs` | Running in **Data explorer** | Logs → Advanced mode |
| `'by' isn't allowed here` | Multiple `countIf` without `{ }` | `summarize { ... }, by: { ... }` |
| No data but GB scanned | Filter too strict or wrong host group ID | Run inventory first; check `C_ALI_BU_*` spelling |
| Unicode regex red squiggle | `\x{3040}` not supported | Use `matchesPhrase` for Japanese labels |
| Too much PII on screen | `fields content` without `limit` | Always `limit 10` on samples |

---

## Data flow map

```
fetch logs, from: now()-24h
  → filter in(host groups) + filter matchesPhrase/Regex(content)
  → summarize count() or countIf() by dt.host_group.id
  → sort hit_count desc
  → (if hits > 0) fields content + limit 10
```

---

## Related files

| File | Role |
| --- | --- |
| `26-common-dql-syntax-examples.md` | This guide |
| `26-common-dql-syntax-examples.dql` | Example queries in one file |
| `26.sh` | One-liner commands reference |
| `8-dql-wrong-ui-data-explorer-fix/` | Wrong UI fix |
| `15-dql-summarize-by-syntax-fix/` | countIf brace fix |
| `23-pii-only-all-column-l/` | Full PII query example |

## Commands

See `26.sh` for copy-paste one-liners. Run in **Logs and Events → Advanced mode**.
