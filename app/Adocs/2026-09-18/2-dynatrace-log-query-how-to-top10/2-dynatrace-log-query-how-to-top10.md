# Dynatrace Log Query How To

```
Need Dynatrace logs?
  │
  ├─ Where: Logs app / Notebooks / Workflow DQL
  ├─ Language: DQL (Grail) — fetch logs | filter | summarize
  └─ Start: time range → filter service/host → search text → count/top
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What it is | Query log records stored in Dynatrace (usually **Grail** via **DQL**) |
| How to use | Pick time range → write DQL → run → narrow filters |
| Core pattern | `fetch logs` → `filter` → `fields` / `summarize` / `sort` |
| Below | How-to steps + **10 most common** SRE log examples |

## Summary

Dynatrace log search is mostly **DQL** against the `logs` table. Open Logs or Notebooks, set the time window, start from `fetch logs`, then filter by content, service, host, or status. The ten examples cover errors, services, hosts, counts, and pivots you use on-call.

Related broader DQL pack: `Daily Files/2026-09-17/2-dynatrace-dql-syntax-top10/`.

---

## Investigation

User asked for Dynatrace log query how-to and the 10 most common examples. Focused on Grail DQL `fetch logs` patterns for SRE triage (aligned with Problem → Splunk/DT digs from prior packs).

## Result

Use §1–§3 to run queries; copy §4 examples from this md or `2-ten-common-log-queries.dql`.

---

## 1) What Dynatrace log query is

| Idea | What it means | Why you care |
| --- | --- | --- |
| Log record | One log line (plus attributes) Dynatrace ingested | Evidence during incidents |
| Grail | Dynatrace data lake for logs/events/… | Modern query home |
| DQL | Dynatrace Query Language | How you filter and aggregate logs |
| `fetch logs` | Load log records as the query source | Almost every log query starts here |
| `content` | Common field with the raw message text | `contains` / `matchesPhrase` searches |

Classic Log Monitoring UI may exist in older setups; **prefer DQL** when Grail logs are enabled.

---

## 2) How to use (step by step)

### Where to run

| Place | When to use |
| --- | --- |
| **Logs** app | Fast interactive search |
| **Notebooks** | Save queries, share with team |
| **Workflows** (DQL task) | Automate checks / enrich tickets |
| Problem card → logs | Jump from a Problem’s timeframe |

### Basic workflow

| Step | What to do | Tip |
| --- | --- | --- |
| 1 | Open Logs or Notebooks | — |
| 2 | Set **time range** (last 30m / Problem start) | Wrong range = empty results |
| 3 | Start with `fetch logs` | Then add filters |
| 4 | Filter by text or attributes | Service, host, status, k8s |
| 5 | `fields` or `summarize` | Read lines vs count patterns |
| 6 | `sort` + `limit` | Keep results readable |
| 7 | Save useful queries | Notebook or team snippet bank |

### Mental model

```
Time range (UI)
  → fetch logs
  → filter (what to keep)
  → fields / parse (what to show)
  → summarize (counts / tops)
  → sort + limit
```

### DQL building blocks for logs

| Command | What it means | Example use |
| --- | --- | --- |
| `fetch logs` | Read log table | Always first |
| `filter` | Keep matching rows | errors only |
| `fields` | Pick columns | timestamp, content, dt.entity.service |
| `fieldsAdd` | Compute new columns | extract status code |
| `summarize` | Aggregate | count by service |
| `sort` | Order | newest first |
| `limit` | Cap rows | 100 lines |
| `summarize ... by:` | Group by | top talkers |

### Common fields (names can vary by ingest)

| Field | What it means |
| --- | --- |
| `timestamp` | When the log happened |
| `content` | Raw log message |
| `loglevel` / `status` | severity if mapped |
| `dt.entity.host` | Host entity |
| `dt.entity.process_group_instance` | Process instance |
| `dt.entity.service` | Service entity |
| `k8s.namespace.name` | Kubernetes namespace |
| `k8s.pod.name` | Pod name |
| `aws.log_group` | CloudWatch-style group (if AWS ingest) |

If a field is missing in your env, browse one raw log record in the UI and copy real attribute names.

### From a Dynatrace Problem (tie-in)

| Step | What to do |
| --- | --- |
| 1 | Open Problem → note **start time** and service name |
| 2 | Set log time range to that window |
| 3 | Filter `content` for `error` / `Exception` / HTTP 500 |
| 4 | Optionally filter service/host entity from the Problem |

---

## 3) Filter tips that save time

| Goal | Pattern |
| --- | --- |
| Find text | `filter contains(content, "timeout")` |
| Phrase | `filter matchesPhrase(content, "Connection timed out")` |
| Case-insensitive-ish | prefer known casing or `matchesValue` where available |
| AND | `filter A and B` |
| OR | `filter A or B` |
| Not | `filter not contains(content, "healthcheck")` |
| Time in query | UI range usually enough; can also constrain in DQL if needed |

---

## 4) Ten most common log query examples

Copy-paste ready. Adjust field names if your ingest differs. Companion file: `2-ten-common-log-queries.dql`.

### 1) Latest logs (sanity check)

```dql
fetch logs
| sort timestamp desc
| fields timestamp, content
| limit 50
```

**Use:** Confirm logs are flowing.

### 2) Search error / exception text

```dql
fetch logs
| filter contains(content, "error") or contains(content, "Exception")
| sort timestamp desc
| fields timestamp, content, loglevel
| limit 100
```

**Use:** First pass on any incident.

### 3) Filter one service (replace name)

```dql
fetch logs
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXXXXXX"
| sort timestamp desc
| fields timestamp, content
| limit 100
```

**Use:** After Problem shows a service id/name — paste the real entity id from the UI.

### 4) Kubernetes namespace + errors

```dql
fetch logs
| filter k8s.namespace.name == "payments"
| filter contains(content, "error") or contains(content, "Exception")
| sort timestamp desc
| fields timestamp, k8s.pod.name, content
| limit 100
```

**Use:** Namespace-scoped outage dig.

### 5) Count errors over time (spike check)

```dql
fetch logs
| filter contains(content, "error") or contains(content, "Exception")
| makeTimeseries count = count(), interval: 1m
```

**Use:** See if errors spiked when the Problem started.

### 6) Top noisy contents / patterns (by host)

```dql
fetch logs
| filter contains(content, "error")
| summarize error_count = count(), by: { dt.entity.host }
| sort error_count desc
| limit 10
```

**Use:** Which host is loudest?

### 7) HTTP 5xx in content

```dql
fetch logs
| filter matchesPhrase(content, " 500 ") or matchesPhrase(content, "status=500") or contains(content, "HTTP/1.1\" 500")
| sort timestamp desc
| fields timestamp, content
| limit 100
```

**Use:** Checkout / API failure stories (like EIP example).

### 8) Exclude health checks

```dql
fetch logs
| filter contains(content, "error")
| filter not contains(content, "health") and not contains(content, "/ready") and not contains(content, "/live")
| sort timestamp desc
| fields timestamp, content
| limit 100
```

**Use:** Cut probe noise.

### 9) Logs for one pod

```dql
fetch logs
| filter k8s.pod.name == "checkout-api-7d9f9b6c4d-abc12"
| sort timestamp desc
| fields timestamp, content
| limit 200
```

**Use:** Follow one bad pod after K8s event.

### 10) Error count by service (top 10)

```dql
fetch logs
| filter contains(content, "error") or contains(content, "Exception") or contains(content, "timeout")
| summarize cnt = count(), by: { dt.entity.service }
| sort cnt desc
| limit 10
```

**Use:** Rank which service to dig first.

---

## 5) Bonus — Problem-aligned “checkout” dig (fake EIP story)

```dql
fetch logs
| filter contains(content, "checkout") or contains(content, "timeout") or contains(content, "SQLException")
| filter contains(content, "error") or contains(content, "Exception")
| sort timestamp desc
| fields timestamp, content, k8s.pod.name, dt.entity.service
| limit 100
```

Set UI time range to Problem start (e.g. 02:14 window). Then paste a `request_id` from results into ServiceNow work notes.

---

## 6) Common mistakes

| Mistake | What goes wrong |
| --- | --- |
| Time range too narrow/wide | Empty or useless flood |
| Wrong field name | Filter matches nothing |
| Only `fetch logs` with no limit | UI overload — always `limit` for raw lines |
| Searching Splunk syntax in DQL | Different language |
| Forgetting logs may live in Splunk only | Some orgs keep app logs in Splunk; DT may have less |

---

## Data flow map

```
App / OneAgent / log ingest
  → Dynatrace Grail (logs)
  → You: Logs app / Notebook
  → DQL: fetch logs | filter | summarize
  → Evidence → Problem triage / SNOW notes
```

## Related files

| Path | Why |
| --- | --- |
| `2-ten-common-log-queries.dql` | All 10 queries in one file |
| `../2026-09-17/2-dynatrace-dql-syntax-top10/` | Broader DQL syntax + other examples |
| `../2026-09-17/31-four-tools-detailed-example/` | When to use DT logs vs Splunk |
| `2.sh` | Paths |

## Commands

See `2.sh` in this folder.
