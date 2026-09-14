# Common Dynatrace Grail Queries

```
Where to run?
  → Notebooks / Logs app (DQL) / Dashboard DQL tile
What is Grail?
  → Dynatrace data lakehouse (logs, metrics, traces, events, entities)
Language?
  → DQL (Dynatrace Query Language)
```

| Key point | Detail |
| --- | --- |
| What this is | Common **DQL** queries against **Grail** |
| Start here | `fetch logs` for on-call log work |
| Your patterns | ERROR/FATAL, host `app` tag, JP PII check, Task timed out |

## Summary

**Grail** stores observability data. You query it with **DQL**. Most day-2 work for your team starts with `fetch logs`, then filter, then `summarize`. Metrics use `timeseries` / `fetch metrics`. Always set a short timeframe in the UI first.

---

## 0. Beginner map

| Concept | What it means | Why you care |
| --- | --- | --- |
| Grail | Storage for logs, metrics, spans, events, entities | One place to query |
| DQL | Query language (like SPL, but Dynatrace) | Write filters and counts |
| `fetch` | Choose the table (logs, events, …) | First line of almost every query |
| `filter` | Keep matching rows | Narrow the blast radius |
| `summarize` | Count / group | Dashboards and triage |
| `fields` / `sort` / `limit` | Shape the output | Readable results |

```
UI timeframe (e.g. last 2h)
  → fetch <table>
  → filter …
  → summarize / fields / sort / limit
```

---

## 1. Logs — most common

### 1.1 Latest logs (any)

```dql
fetch logs
| sort timestamp desc
| fields timestamp, host.name, loglevel, content
| limit 50
```

### 1.2 ERROR / FATAL only

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| sort timestamp desc
| fields timestamp, host.name, loglevel, content
| limit 100
```

### 1.3 Count ERROR/FATAL by host

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| summarize hits = count(), by: { host.name, loglevel }
| sort hits desc
```

### 1.4 ERROR/FATAL with host tag `app` (your multi-app pattern)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd application = coalesce(toString(`dt.entity.host.tags[app]`), "unknown-application")
| summarize error_fatal_count = count(), by: { application, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

Prefer richer name when present:

```dql
| fieldsAdd application = coalesce(toString(`dt.entity.host.tags[AGO_GLOBAL_APP]`), toString(`dt.entity.host.tags[app]`), "unknown-application")
```

### 1.5 Search text in content (like Splunk keyword)

```dql
fetch logs
| filter contains(content, "Task timed out")
| filter not contains(content, "DEBUG")
| sort timestamp desc
| fields timestamp, host.name, content
| limit 100
```

### 1.6 CCI-style timeout (Grail equivalent of your Splunk alert)

```dql
fetch logs
| filter contains(content, "Task timed out")
| filter not matchesValue(content, ".*DEBUG.*")
| summarize hits = count(), by: { host.name }
| sort hits desc
```

### 1.7 Exceptions / stack traces

```dql
fetch logs
| filter contains(content, "Exception") or contains(content, "Traceback")
| sort timestamp desc
| fields timestamp, host.name, content
| limit 50
```

### 1.8 Logs for one host

```dql
fetch logs
| filter host.name == "YOUR-HOST-NAME"
| sort timestamp desc
| fields timestamp, loglevel, content
| limit 100
```

### 1.9 JP PII keyword check (verify masking)

```dql
fetch logs
| filter matchesValue(content, ".*[\\u3000-\\u30FF\\u4E00-\\u9FFF].*")
| filter matchesValue(content, ".*(氏名|住所|電話|メール|マイナンバー|口座番号).*")
| summarize hits = count(), by: { host.name }
| sort hits desc
| limit 50
```

---

## 2. Events / Problems

### 2.1 Recent events

```dql
fetch events
| sort timestamp desc
| fields timestamp, event.type, event.kind, event.name
| limit 50
```

### 2.2 Problem-like / error events (tenant fields vary)

```dql
fetch events
| filter event.kind == "DAVIS_PROBLEM" or contains(event.name, "Problem")
| sort timestamp desc
| limit 50
```

---

## 3. Metrics (Grail timeseries style)

### 3.1 CPU by host (example)

```dql
timeseries avg(dt.host.cpu.usage), by: { dt.entity.host }
```

### 3.2 Memory available (example)

```dql
timeseries avg(dt.host.memory.avail.ratio), by: { dt.entity.host }
```

> Classic **Data Explorer** still uses metric selectors; new Dashboards often use DQL `timeseries`. Metric keys can differ by agent version — pick from Metrics browser if a name fails.

---

## 4. Spans / traces (APM)

### 4.1 Failed spans

```dql
fetch spans
| filter span.status_code == "ERROR" or request.is_failed == true
| sort start_time desc
| fields start_time, endpoint.name, service.name, duration
| limit 50
```

### 4.2 Slow requests

```dql
fetch spans
| filter duration > 2000000000
| sort duration desc
| fields start_time, service.name, endpoint.name, duration
| limit 50
```

> Duration is often in **nanoseconds** (2e9 ≈ 2 seconds). Confirm unit in your tenant.

---

## 5. Entities (inventory)

### 5.1 Hosts and tags

```dql
fetch dt.entity.host
| fields id, entity.name, tags
| limit 100
```

### 5.2 Find hosts with tag `app`

```dql
fetch dt.entity.host
| filter matchesValue(tags, "app:*") or isNotNull(tags[app])
| fields entity.name, tags
| limit 100
```

---

## 6. Handy operators cheat sheet

| Operator | What it does | Example |
| --- | --- | --- |
| `==` | Exact match | `loglevel == "ERROR"` |
| `contains` | Substring | `contains(content, "timeout")` |
| `matchesValue` | Regex / pattern | `matchesValue(content, ".*Exception.*")` |
| `in` | List | `loglevel in {"ERROR","FATAL"}` |
| `not` | Negate | `not contains(content, "DEBUG")` |
| `summarize … by:` | Group count | `summarize c=count(), by:{host.name}` |
| `sort` | Order | `sort timestamp desc` |
| `limit` | Cap rows | `limit 50` |
| `fields` / `fieldsAdd` | Keep / add columns | `fields timestamp, content` |

---

## Investigation

Aligned with your recent Grail work: ERROR/FATAL by host + `app` tag, JP PII verify, and Splunk→Grail style “Task timed out” for CCI.

## Result

Keep this as a cheat sheet. Start with §1 logs; copy from `common-grail-queries.dql` into Notebooks.

## Data flow

```
UI timeframe
  → fetch logs|events|spans|metrics|dt.entity.*
  → filter
  → summarize / fields
  → triage (host, app tag, content)
```

## Related files

| File | Purpose |
| --- | --- |
| `common-grail-queries.dql` | All queries in one file |
| `5.sh` | Where to paste reminders |
| Prior | `2026-09-07/17-host-tags-usable-for-app/` |

## Commands

See `5.sh`.
