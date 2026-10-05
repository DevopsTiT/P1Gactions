# Common DQL Cheatsheet

## Decision Tree

```
What do I need?
 where are my logs?        → query 1 (summarize by log.source, host, namespace, pod)
 see raw lines             → query 2 (fields timestamp, content)
 filter by words           → queries 3 and 4 (contains, not, matchesValue)
 count                     → 5 total, 6 by field
 chart or detector series  → 7, 8 (makeTimeseries), 9 (rolling count)
 pull a value out of text  → 10, 11 (parse)
 new field or if/else      → 12 (fieldsAdd, if, replaceString, coalesce)
 JST time                  → 13 (formatTimestamp)
 latest per key            → 14 (sort + dedup)
 join a CSV                → 16 (lookup)
 did my detector fire?     → 20 (dt.davis.problems, events)
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is DQL? | Dynatrace Query Language, the query language for logs, metrics, events and problems in Grail |
| How is it shaped? | A pipeline: start with `fetch`, then pass the result through commands joined by `\|` |
| Closest Splunk idea | SPL: `index=` becomes `fetch logs \| filter`, `stats` becomes `summarize`, `timechart` becomes `makeTimeseries` |
| File with all queries | `47-common-dql-cheatsheet.dql` (20 ready-to-paste queries) |

## Summary

Most alert migrations need only a dozen commands: `fetch`, `filter`, `fields`, `fieldsAdd`, `parse`, `summarize`, `makeTimeseries`, `sort`, `dedup`, `limit` and `lookup`. Learn them in that order and you can rebuild nearly every Splunk search seen today.

## Splunk to DQL Map

| Splunk SPL | DQL | What it does |
|---|---|---|
| `index=x` | `fetch logs \| filter log.source == "x"` (field depends on ingest) | Pick the data |
| `"text"` | `filter contains(content, "text")` | Line contains text |
| `host=web*` | `filter matchesValue(host.name, "web*")` | Wildcard match |
| `NOT "text"` | `filter not contains(content, "text")` | Exclude lines |
| `earliest=-1h` | `fetch logs, from:now()-1h` | Time range |
| `table _time _raw` | `fields timestamp, content` | Choose columns |
| `eval x=...` | `fieldsAdd x = ...` | New field |
| `rex "(?<n>\d+)"` | `parse content, "LD INT:n"` | Extract a value |
| `stats count` | `summarize count()` | Total count |
| `stats count by host` | `summarize count(), by:{host.name}` | Count per group |
| `timechart span=1m count` | `makeTimeseries count(default: 0), interval:1m` | Count over time |
| `stats latest(x) by y` | `sort timestamp desc \| dedup y` | Latest per key |
| `lookup file.csv k OUTPUT v` | `lookup [ load "/lookups/..." ], sourceField:, lookupField:` | Join a table |
| `sort -count` | `sort count desc` | Sort |
| `head 10` | `limit 10` | First N rows |
| `where count > 50` | `filter count > 50` | Filter after counting |

## Core Commands

| Command | What it means | Example |
|---|---|---|
| `fetch` | Start: which data type and time range | `fetch logs, from:now()-1h` |
| `filter` | Keep rows that match | `filter loglevel == "ERROR"` |
| `fields` | Keep only these columns | `fields timestamp, content` |
| `fieldsAdd` | Add or overwrite a column | `fieldsAdd failed = if(x, 1, else: 0)` |
| `parse` | Pull values from text with a pattern | `parse content, "LD 'id=' INT:id"` |
| `summarize` | Group and aggregate into a table | `summarize count(), by:{host.name}` |
| `makeTimeseries` | Group and aggregate into a time series | `makeTimeseries count(), interval:1m` |
| `sort` | Order rows | `sort timestamp desc` |
| `dedup` | Keep the first row per key | `dedup job_name` |
| `limit` | Cap the number of rows | `limit 100` |
| `lookup` | Join another table | `lookup [ load "/lookups/x" ], ...` |
| `expand` | One row per array item | `expand tc = j[testsuite][testcase]` |

## Useful Functions

| Function | What it does |
|---|---|
| `contains(a, "x", caseSensitive: false)` | Text contains x |
| `matchesValue(a, "x*")` | Wildcard match |
| `startsWith(a, "x")` | Text starts with x |
| `if(cond, a, else: b)` | Conditional value |
| `coalesce(a, b, "default")` | First non-empty value |
| `replaceString(a, "%20", " ")` | Replace text |
| `formatTimestamp(t, format:, timezone:"Asia/Tokyo")` | Print time in JST |
| `count()`, `sum()`, `avg()`, `max()`, `min()` | Aggregations |
| `percentile(x, 95)` | 95th percentile |
| `arrayMovingSum(series, 5)` | Rolling 5-point sum on a time series |
| `arrayMovingMax(series, 10)` | Rolling 10-point max on a time series |

## Parse Pattern Pieces

| Piece | Matches |
|---|---|
| `LD` | Any text (line data), lazily |
| `'text'` | Exact text |
| `INT:name` | Whole number into `name` |
| `DOUBLE:name` | Decimal number into `name` |
| `LD:name` | Text into `name` |
| `JSON:name` | A JSON object into `name` |

## Detector-Ready Query Rules

| Rule | Why |
|---|---|
| No `from:` in the fetch | The detector sets the time range itself |
| End with `makeTimeseries ... interval:1m` | Detectors read one value per minute |
| Use `count(default: 0)` | Empty minutes become 0, not missing |
| Use `arrayMovingSum` for "N in X minutes" | Turns per-minute counts into a rolling total |
| Split with `by:{...}` only when you want one problem per group | Each group becomes its own series |

## Common Mistakes

| Mistake | Result | Fix |
|---|---|---|
| Using a Splunk field name (`index`, `sourcetype`, `host`) | No results | Run query 1 to find the Dynatrace field |
| `@d` for "today" | Midnight UTC, which is 09:00 JST | Use `now()-8h` at 08:00 or JST math |
| Comparing numbers as text (`"15"`) | Wrong results | Parse as `INT` or `DOUBLE` first |
| No `limit` on raw lines | Slow query, large scan cost | Add `limit 100` |
| `makeTimeseries` without `default: 0` | Gaps instead of zeros | Add `default: 0` |

## Data Flow

```
fetch logs (data + time) → filter (rows) → parse / fieldsAdd (new fields)
  → summarize (table) or makeTimeseries (chart / detector)
  → sort / dedup / limit → result
```

## Investigation

| Checked | Evidence |
|---|---|
| Queries used in seq 27 to 46 | `fetch`, `filter`, `parse`, `makeTimeseries`, `arrayMovingSum`, `lookup`, `dedup`, `formatTimestamp` |
| Splunk searches in screenshots | `index`, `stats`, `timechart`, `rex`, `lookup`, `streamstats`, `table` |

## Result

| Step | What to do |
|---|---|
| 1 | Open the Dynatrace Notebooks app |
| 2 | Paste queries from `47-common-dql-cheatsheet.dql` one at a time |
| 3 | Start with query 1 for any new alert to find the right fields |

## Related Files

| File | Purpose |
|---|---|
| `47-common-dql-cheatsheet.dql` | 20 ready-to-paste queries |
| `47.sh` | Commands |

## Commands

See `47.sh`. DQL runs in the Dynatrace Notebooks or Logs app; no CLI needed.
