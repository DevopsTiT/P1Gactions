# Dynatrace Dql Syntax Top10

```
Need Dynatrace query?
  │
  ├─ Logs / events / spans / metrics in Notebooks, Log viewer, Log alerts
  │     → use DQL (Dynatrace Query Language)
  │
  ├─ Shape: fetch <source> | filter ... | parse ... | stats ... | sort ... | limit ...
  │
  └─ Start from Top 10 examples below → copy → change names/ids
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What DQL is | Pipe-based query language for logs, events, spans, metrics, and more |
| Core shape | `fetch` → `filter` → `parse` / `fields` → `stats` → `sort` → `limit` |
| Where you run it | Logs app, Notebooks, Dashboards, scheduled log alerts (Terraform `search_query`) |
| Your CDUS alerts | Examples 8–10 match failed / pending upload patterns |

## Summary

DQL reads data with `fetch`, narrows it with `filter`, extracts fields with `parse`, and summarizes with `stats`. Below: syntax basics, then 10 copy-paste examples from simple to your upload alerts.

---

## Investigation

Scoped to DQL (not classic Log Monitoring v1 Lucene-only, not Metrics API selector syntax). Examples use common SaaS fields; rename `aws.log_group` / content patterns to match your tenant.

## Result

Use the syntax table + Top 10. Paste into Dynatrace → Logs / Notebooks → DQL. For Terraform log alerts, put the same query inside `search_query = <<-EOT ... EOT`.

---

## 1) What DQL is (plain English)

**DQL** = Dynatrace Query Language.

| Idea | Meaning |
| --- | --- |
| Fetch | Pick a data source (logs, events, spans, …) |
| Pipe `\|` | Send results to the next step |
| Filter | Keep only rows you care about |
| Parse | Pull values out of free-text log lines |
| Stats | Count / sum / avg and group |
| Limit | Cap how many rows you return |

Analogy: like a kitchen line — grab ingredients (`fetch`), wash (`filter`), chop (`parse`), plate counts (`stats`), serve top N (`limit`).

---

## 2) Basic syntax

```dql
fetch <source>
| <command> ...
| <command> ...
```

### Common sources

| Source | What it means |
| --- | --- |
| `logs` | Log records |
| `events` | Davis / custom events (varies by tenant) |
| `spans` | Distributed traces spans |
| `bizevents` | Business events (if enabled) |
| `metrics` | Metric timeseries (DQL metrics) |

### Commands you will use most

| Command | What it does | Example |
| --- | --- | --- |
| `filter` | Keep matching rows | `filter status == "ERROR"` |
| `filterOut` | Drop matching rows | `filterOut status == "DEBUG"` |
| `fields` | Keep / rename columns | `fields timestamp, content` |
| `fieldsAdd` | Add calculated columns | `fieldsAdd len = stringLength(content)` |
| `parse` | Extract from text | `parse content, "LD 'action:' WORD:action"` |
| `stats` | Aggregate | `stats count() by status` |
| `sort` | Order rows | `sort timestamp desc` |
| `limit` | Cap rows | `limit 100` |
| `summarize` | Another aggregation style (use when docs/UI suggest it) | depends on version |
| `lookup` / `join` | Enrich with other data | advanced |

### Operators (filters)

| Operator | Meaning |
| --- | --- |
| `==` `!=` | Equal / not equal |
| `>` `<` `>=` `<=` | Compare numbers |
| `and` `or` `not` | Combine conditions |
| `contains(field, "text")` | Field contains text |
| `matchesPhrase` / `matchesValue` | Phrase / value match (when available) |
| `in(...)` | Value in a list |
| `isNull` / `isNotNull` | Null checks |

### Strings and time

| Tip | Example |
| --- | --- |
| Strings use double quotes | `"UPLOAD_FAILED"` |
| Time range often set in UI | Last 15 minutes picker |
| In alerts, Terraform sets `time_range` | `LAST_15_MINUTES` |

### Parse pattern bits (common)

| Token | Meaning |
| --- | --- |
| `LD` | Lazy data (skip until next marker) |
| `WORD:name` | One word → field `name` |
| `DATA:name` | Rest of line → field |
| `INT:name` / `DOUBLE:name` | Numbers |
| `'action:'` | Literal text to find |

---

## 3) Top 10 DQL examples

### 1) Latest 100 logs (smoke test)

```dql
fetch logs
| sort timestamp desc
| limit 100
```

**Why:** Prove DQL works and you see log volume.

---

### 2) Error logs only

```dql
fetch logs
| filter status == "ERROR" or loglevel == "ERROR" or contains(content, "ERROR")
| sort timestamp desc
| limit 100
```

**Why:** Fast on-call scan. Field names differ by ingest — try `status`, `loglevel`, or `content`.

---

### 3) Filter by AWS Lambda log group

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| sort timestamp desc
| limit 100
```

**Why:** Same log group as your CDUS Terraform alerts.

---

### 4) Search free text in content

```dql
fetch logs
| filter contains(content, "UPLOAD_FAILED")
| sort timestamp desc
| limit 50
```

**Why:** Quick keyword hunt before writing parse/stats.

---

### 5) Parse fields from content

```dql
fetch logs
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
| fields timestamp, action, cmxDocumentId, content
| sort timestamp desc
| limit 100
```

**Why:** Turn messy text into columns you can filter and count.

---

### 6) Count by action

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:")
| parse content, "LD 'action:' WORD:action"
| stats count() as cnt by action
| sort cnt desc
| limit 20
```

**Why:** See which upload actions dominate (STARTED / COMPLETED / FAILED).

---

### 7) Count errors by host (or service)

```dql
fetch logs
| filter status == "ERROR" or contains(content, "Exception")
| stats count() as errors by host.name
| sort errors desc
| limit 10
```

**Why:** Top noisy hosts. If `host.name` is empty, try `dt.entity.host`, `k8s.pod.name`, or `service.name`.

---

### 8) Failed uploads per document (your pic 1 pattern)

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
| stats
    count(if(action == "UPLOAD_STARTED", 1, null)) as started,
    count(if(action == "UPLOAD_COMPLETED", 1, null)) as completed,
    count(if(action == "UPLOAD_FAILED", 1, null)) as failed,
    by: {cmxDocumentId}
| filter failed > 0
| sort failed desc
| limit 100
```

**Why:** Alert when any document has failures. Matches `cdus_backend_failed_uploads`.

---

### 9) Pending uploads per document (fixed pic 2 pattern)

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
| stats
    count(if(action == "UPLOAD_STARTED", 1, null)) as started,
    count(if(action == "UPLOAD_COMPLETED", 1, null)) as completed,
    count(if(action == "UPLOAD_FAILED", 1, null)) as failed,
    by: {cmxDocumentId}
| filter started > 0 and completed == 0 and failed == 0
| sort started desc
| limit 100
```

**Why:** Started but never completed or failed. Matches corrected pending alert.

---

### 10) Spans with slow requests (APM-style)

```dql
fetch spans
| filter duration > 2000ms
| fields start_time, duration, request.url, service.name, http.response.status_code
| sort duration desc
| limit 20
```

**Why:** Find slow traces. Duration unit/field names can vary slightly by tenant version — adjust if the UI suggests another field.

---

## 4) Mini cheatsheet

```
fetch logs
| filter <condition>
| parse content, "<pattern>"
| stats <agg> by <field>
| sort <field> desc
| limit N
```

Conditional count (very common in alerts):

```dql
count(if(action == "UPLOAD_FAILED", 1, null)) as failed
```

---

## 5) Common mistakes

| Mistake | Fix |
| --- | --- |
| No `fetch` | Always start with `fetch logs` (or other source) |
| Wrong field name | Open one raw log → copy real attribute names |
| Parse never matches | First `filter contains(...)` then tighten parse |
| Alert lists rows only | Use `stats` + `filter` like examples 8–9 |
| Too wide time range | Start with last 15–60 minutes |
| `limit` before `stats` | Aggregate first, then sort/limit |

---

## Data flow map

```
UI time range
  → fetch logs/spans/...
  → filter (narrow)
  → parse (extract fields)
  → stats (count/group)
  → sort + limit
  → table / chart / log alert trigger
```

## Related files

| Path | Why |
| --- | --- |
| `../1-cdus-pending-match-failed-pattern/` | Pending/failed alert DQL applied |
| `2-dynatrace-dql-top10-examples.dql` | All 10 queries in one file |
| `2.sh` | Open/remind paths |

## Commands

See `2.sh` in this folder.
