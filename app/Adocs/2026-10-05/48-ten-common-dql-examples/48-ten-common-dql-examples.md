# Ten Common DQL Examples

## Decision Tree

```
What data do I need?
 log lines           → fetch logs        (examples 1 to 4)
 metrics (CPU, k8s)  → timeseries        (examples 5, 6, 8)
 traces / requests   → fetch spans       (example 7)
 problems            → fetch dt.davis.problems (example 9)
 inventory           → fetch dt.entity.host    (example 10)
Then:
 table of numbers → summarize
 chart over time  → makeTimeseries (logs) or timeseries (metrics)
```

## Short Takeaway

| Question | Answer |
|---|---|
| What are the 10 examples? | 4 log, 3 metric, 1 trace, 1 problem, 1 entity query |
| Two ways to start | `fetch` for records (logs, spans, problems, entities); `timeseries` for metrics |
| Where to run | Dynatrace Notebooks or Logs app |
| File | `48-ten-common-dql-examples.dql` |

## Summary

DQL starts with either `fetch` (rows such as log lines, spans, problems or entities) or `timeseries` (metric values over time). After that you filter, add fields, and summarize. These ten examples cover the questions an SRE asks most: what is failing, how often, how slow, which host, and what is open right now.

## The Ten Examples

| # | Question it answers | Starts with | Key commands |
|---|---|---|---|
| 1 | Which hosts log the most errors? | `fetch logs` | `filter`, `summarize by`, `sort`, `limit` |
| 2 | What do the latest matching lines say? | `fetch logs` | `contains`, `fields`, `sort` |
| 3 | Are errors rising? | `fetch logs` | `in()`, `makeTimeseries by` |
| 4 | How slow are requests in the log text? | `fetch logs` | `parse`, `percentile` |
| 5 | What is CPU per host? | `timeseries` | `avg()`, `entityName()` |
| 6 | Which hosts are busiest? | `timeseries` | `arrayAvg`, `sort`, `limit` |
| 7 | Which services are slowest? | `fetch spans` | `percentile(duration, 95)` |
| 8 | Which namespaces have restarting containers? | `timeseries` | `arraySum`, `filter` |
| 9 | What problems are open now? | `fetch dt.davis.problems` | `filter event.status` |
| 10 | What hosts exist? | `fetch dt.entity.host` | `fields`, `sort` |

### 1. Error logs per host

```
fetch logs, from:now()-1h
| filter loglevel == "ERROR"
| summarize errors = count(), by:{host.name}
| sort errors desc
| limit 10
```

### 2. Search a phrase, latest lines

```
fetch logs, from:now()-30m
| filter contains(content, "timed out", caseSensitive: false)
| fields timestamp, host.name, log.source, content
| sort timestamp desc
| limit 50
```

### 3. Error trend per minute by level

```
fetch logs, from:now()-2h
| filter in(loglevel, {"ERROR", "WARN"})
| makeTimeseries lines = count(default: 0), by:{loglevel}, interval:1m
```

### 4. Extract a number and get percentiles

```
fetch logs, from:now()-1h
| filter contains(content, "duration=")
| parse content, "LD 'duration=' DOUBLE:duration_ms"
| summarize p50 = percentile(duration_ms, 50), p95 = percentile(duration_ms, 95), worst = max(duration_ms)
```

### 5. Host CPU (metric)

```
timeseries cpu = avg(dt.host.cpu.usage), by:{dt.entity.host}, from:now()-1h
| fieldsAdd host = entityName(dt.entity.host)
```

### 6. Top 10 busiest hosts

```
timeseries cpu = avg(dt.host.cpu.usage), by:{dt.entity.host}, from:now()-1h
| fieldsAdd avg_cpu = arrayAvg(cpu), host = entityName(dt.entity.host)
| fields host, avg_cpu
| sort avg_cpu desc
| limit 10
```

### 7. Slowest services from traces

```
fetch spans, from:now()-1h
| filter request.is_root_span == true
| summarize requests = count(), p95 = percentile(duration, 95), by:{dt.entity.service}
| fieldsAdd service = entityName(dt.entity.service)
| sort p95 desc
| limit 10
```

### 8. Kubernetes restarts per namespace

```
timeseries restarts = sum(dt.kubernetes.container.restarts), by:{k8s.namespace.name}, from:now()-24h
| fieldsAdd total = arraySum(restarts)
| filter total > 0
| sort total desc
```

### 9. Open problems now

```
fetch dt.davis.problems, from:now()-24h
| filter event.status == "ACTIVE"
| fields timestamp, display_id, event.name, event.category
| sort timestamp desc
```

### 10. Host inventory

```
fetch dt.entity.host
| fields id, entity.name, osType
| sort entity.name asc
| limit 100
```

## fetch vs timeseries

| Start | Use for | Output |
|---|---|---|
| `fetch logs` | Log lines | Rows |
| `fetch spans` | Traces and requests | Rows |
| `fetch dt.davis.problems` | Problems | Rows |
| `fetch dt.entity.host` | Inventory of hosts | Rows |
| `timeseries` | Metrics such as CPU or restarts | One array of values per series |

## Common Mistakes

| Mistake | Result | Fix |
|---|---|---|
| `fetch` on a metric name | Error | Use `timeseries` for metrics |
| Forgetting `entityName()` | You see IDs like HOST-1234 | Add `entityName(dt.entity.host)` |
| `sort` on a timeseries array | Error or odd order | Reduce first with `arrayAvg` or `arraySum` |
| No `limit` on raw lines | Slow, costly scan | Add `limit` |
| Metric key differs in your tenant | No data | Check the metric browser for the exact key |

## Data Flow

```
fetch (rows) or timeseries (metric arrays)
  → filter → fieldsAdd / parse
  → summarize (table) or makeTimeseries (chart)
  → sort → limit → result
```

## Investigation

| Checked | Evidence |
|---|---|
| Data types covered | Logs, metrics, spans, problems, entities |
| Metric keys used | `dt.host.cpu.usage`, `dt.kubernetes.container.restarts` (confirm in your tenant) |
| Overlap with seq 47 | Seq 47 was log-focused; this adds metrics, traces and entities |

## Result

| Step | What to do |
|---|---|
| 1 | Open a Notebook |
| 2 | Paste each example from the `.dql` file |
| 3 | Change filters (host, namespace, phrase) to your own values |

## Related Files

| File | Purpose |
|---|---|
| `48-ten-common-dql-examples.dql` | The 10 queries |
| `47-common-dql-cheatsheet/47-common-dql-cheatsheet.dql` | 20 log-focused queries with Splunk mapping |
| `48.sh` | Commands |

## Commands

See `48.sh`. DQL runs in the Dynatrace UI; no CLI needed.
