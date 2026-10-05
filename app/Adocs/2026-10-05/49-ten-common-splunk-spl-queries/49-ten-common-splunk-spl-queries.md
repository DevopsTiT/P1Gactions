# Ten Common Splunk SPL Queries

## Decision Tree

```
What do I want from Splunk?
 see lines          → search + table + head       (1)
 count              → stats count by field        (2)
 chart over time    → timechart span=1m           (3, 4)
 most common values → top                         (5)
 pull a number      → rex + stats perc            (6)
 percentage         → eval + stats + eval         (7)
 latest per key     → sort - _time + dedup        (8)
 add owner/app info → lookup                      (9)
 alert rule         → timechart + where           (10)
```

## Short Takeaway

| Question | Answer |
|---|---|
| SQL or SPL? | Splunk uses SPL (Search Processing Language), not SQL. Same idea: filter, group, sort |
| How is it shaped? | Search terms first, then commands joined by `\|` |
| Most used commands | `stats`, `timechart`, `table`, `eval`, `rex`, `top`, `dedup`, `lookup`, `where`, `sort` |
| Files | `.spl` for Splunk, `-dql.dql` for the Dynatrace versions |

## Summary

Almost every Splunk search is a filter (index, keywords, field=value) followed by a few pipe commands. These ten patterns cover most real alerts and dashboards, including the ones migrated today. Each has a DQL twin in the companion file.

## SPL vs SQL (for orientation)

| SQL | SPL | What it does |
|---|---|---|
| `FROM table` | `index=name` | Choose data |
| `WHERE x = 1` | `x=1` or `\| where x=1` | Filter |
| `SELECT a, b` | `\| table a b` | Choose columns |
| `COUNT(*) GROUP BY host` | `\| stats count by host` | Group and count |
| `ORDER BY count DESC` | `\| sort - count` | Sort |
| `LIMIT 10` | `\| head 10` | First N rows |
| `JOIN` | `\| lookup` or `\| join` | Add data from another table |
| `CASE WHEN` | `\| eval x=if(...)` | Calculated field |

## The Ten Queries

### 1. Search a phrase, show raw lines

```
index=app_logs "Connection timed out" earliest=-30m
| table _time host source _raw
| sort - _time
| head 50
```

### 2. Count errors per host

```
index=app_logs log_level=ERROR earliest=-1h
| stats count by host
| sort - count
```

### 3. Errors per minute

```
index=app_logs log_level=ERROR earliest=-2h
| timechart span=1m count
```

### 4. Errors per minute by host

```
index=app_logs log_level=ERROR earliest=-2h
| timechart span=1m count by host limit=10
```

### 5. Top 10 values of a field

```
index=web_logs status>=500 earliest=-1h
| top limit=10 uri_path
```

### 6. Extract a number and get percentiles

```
index=app_logs "duration=" earliest=-1h
| rex field=_raw "duration=(?<duration_ms>\d+(\.\d+)?)"
| stats perc50(duration_ms) as p50 perc95(duration_ms) as p95 max(duration_ms) as worst
```

### 7. Error rate percentage

```
index=web_logs earliest=-1h
| eval is_error=if(status>=500, 1, 0)
| stats count as total sum(is_error) as errors by host
| eval error_rate=round(errors / total * 100, 2)
| sort - error_rate
```

### 8. Latest status per job

```
index=controlm earliest=-24h
| sort - _time
| dedup job_name
| table _time job_name status
```

### 9. Enrich with a lookup CSV

```
index=jenkins_console "[HTTP Monitor]" earliest=-15m
| lookup configuration job_name AS name OUTPUT application pager_duty
| stats count by application pager_duty
```

### 10. Alert rule: more than 50 in a minute

```
index=brokerpolicymaintenance-prod-axa-li-jp "Cannot read properties of undefined" earliest=-5m
| timechart span=1m count
| where count > 50
```

## Each Query In DQL

| # | Splunk command | DQL equivalent |
|---|---|---|
| 1 | `table`, `head` | `fields`, `limit` |
| 2 | `stats count by host` | `summarize count(), by:{host.name}` |
| 3 | `timechart span=1m count` | `makeTimeseries count(default: 0), interval:1m` |
| 4 | `timechart ... by host` | `makeTimeseries ..., by:{host.name}` |
| 5 | `top limit=10` | `summarize count() by` + `sort desc` + `limit 10` |
| 6 | `rex` + `perc95` | `parse` + `percentile(x, 95)` |
| 7 | `eval if` + `stats sum` | `fieldsAdd if(..., else:)` + `summarize sum()` |
| 8 | `sort - _time \| dedup` | `sort timestamp desc \| dedup` |
| 9 | `lookup` | `lookup [ load "/lookups/..." ]` |
| 10 | `where count > 50` | Detector with threshold 50 |

Full DQL text is in `49-ten-common-splunk-spl-queries-dql.dql`.

## Common Mistakes In SPL

| Mistake | Result | Fix |
|---|---|---|
| No `index=` | Searches every index you can see: slow | Always start with `index=` |
| Leading wildcard like `*error` | Very slow | Use whole words or fields |
| `head` before `stats` | Counts only the first rows | Put `head` at the end |
| Comparing numbers as strings (`x>="15"`) | Wrong results | Remove the quotes |
| Overlapping alert windows without throttle | Duplicate emails | Match time range to schedule or use throttle |

## Data Flow

```
index + keywords (filter) → rex / eval (new fields)
  → stats / timechart / top (group) → where (filter result)
  → sort → head / table → result or alert
```

## Investigation

| Checked | Evidence |
|---|---|
| Splunk commands in today's screenshots | stats, timechart, table, eval, rex, lookup, dedup, streamstats, where, sort |
| Mistakes seen today | String comparison in Claims overrun, overlapping windows, `head` before median |

## Result

| Step | What to do |
|---|---|
| 1 | Use the `.spl` file to practice in Splunk Search |
| 2 | Use the `-dql.dql` file when moving the same logic to Dynatrace |

## Related Files

| File | Purpose |
|---|---|
| `49-ten-common-splunk-spl-queries.spl` | 10 Splunk searches |
| `49-ten-common-splunk-spl-queries-dql.dql` | Same 10 in DQL |
| `47-common-dql-cheatsheet/47-common-dql-cheatsheet.md` | Full SPL to DQL map |
| `49.sh` | Commands |

## Commands

See `49.sh`. SPL runs in Splunk Search; DQL runs in Dynatrace Notebooks.
