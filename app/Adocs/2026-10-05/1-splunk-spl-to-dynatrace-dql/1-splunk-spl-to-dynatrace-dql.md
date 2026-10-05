# Splunk Source Check To Dynatrace DQL

## Decision tree

```
Convert "does index=networksyslog have these sources?" to DQL
 Step 0: which Dynatrace field holds the Splunk "index"?
   bucket named networksyslog?           → filter dt.system.bucket == "networksyslog"
   attribute named index?                → filter index == "networksyslog"
   only log.source = syslog?             → filter log.source == "syslog" (plus a host or app filter)
 Step 1: which field holds the Splunk "source"?
   file path or udp:514 style value       → usually log.source
   network device name                    → usually host.name or syslog.hostname
 Step 2: pick the query
   just see which exist                  → Query 1 (filter + summarize by source)
   yes/no for every source               → Query 2 (data record + lookup)
   last time each source sent data       → Query 3 (summarize max(timestamp))
 0 rows unexpectedly?
   timeframe too short?                  → from:-30d
   wrong field name?                     → run Step 0 discovery again
   no permission on bucket?              → ask admin for storage:buckets:read on that bucket
```

## Short takeaway

| Question | Answer |
|---|---|
| Splunk `index=networksyslog` in DQL | Usually `filter dt.system.bucket == "networksyslog"`, but confirm the field first |
| Splunk `source` in DQL | Usually `log.source` |
| Splunk `tstats count by source` in DQL | `summarize count = count(), by:{log.source}` |
| Splunk `metadata type=sources` in DQL | `summarize lastSeen = max(timestamp), by:{log.source}` |
| Biggest difference | DQL has no tstats shortcut; it scans log records, so always narrow time and bucket |

## Summary

DQL starts with `fetch logs` and filters with `filter`. Splunk's `index` usually becomes a Grail **bucket** (where logs are stored), and Splunk's `source` usually becomes the `log.source` attribute. Your site may name these fields differently, so run the discovery query first, then swap in the right names.

## Splunk to DQL mapping

| Splunk | DQL | What it means |
|---|---|---|
| `index=networksyslog` | `filter dt.system.bucket == "networksyslog"` | Pick the storage bucket |
| `source="X"` | `filter log.source == "X"` | Exact match on one source |
| `source="*a.log"` | `filter endsWith(log.source, "a.log")` | Wildcard at the start |
| `source IN ("A","B")` | `filter in(log.source, array("A","B"))` | Match any value in a list |
| `stats count by source` | `summarize count = count(), by:{log.source}` | Count per source |
| Time picker | `fetch logs, from:-30d` | How far back to look |
| `table a b` | `fields a, b` | Choose output columns |
| `eval found=if(...)` | `fieldsAdd found = if(..., "yes", else:"no")` | Add a computed column |

## Step 0 — discover the field names (run first)

Which bucket the network syslog lands in:

```dql
fetch logs, from:-1h
| summarize count = count(), by:{dt.system.bucket}
| sort count desc
```

What the syslog records look like:

```dql
fetch logs, from:-1h
| filter dt.system.bucket == "networksyslog"
| limit 5
```

Look at the record and note which field holds the path or device you used as `source` in Splunk. Common ones are `log.source`, `host.name`, `syslog.hostname` and `syslog.appname`.

## Query 1 — which sources exist (same as the one-line tstats)

```dql
fetch logs, from:-30d
| filter dt.system.bucket == "networksyslog"
| filter in(log.source, array("/var/log/app/a.log", "/var/log/app/b.log", "/var/log/app/c.log"))
| summarize count = count(), by:{log.source}
```

| What you see | What it means |
|---|---|
| A row for a source | That source has logs in the bucket in the last 30 days |
| No row for a source | That source has no logs there in that time |

## Query 2 — yes/no for every source

```dql
data record(source = "/var/log/app/a.log"),
     record(source = "/var/log/app/b.log"),
     record(source = "/var/log/app/c.log")
| lookup [
    fetch logs, from:-30d
    | filter dt.system.bucket == "networksyslog"
    | summarize events = count(), by:{log.source}
  ], sourceField:source, lookupField:log.source, fields:{events}
| fieldsAdd events = coalesce(events, 0)
| fieldsAdd found = if(events > 0, "yes", else:"no")
```

| Part | What it does |
|---|---|
| `data record(...)` | Makes your own list of sources, like makeresults in Splunk |
| `lookup [...]` | Counts real logs per source and joins the count onto your list |
| `coalesce(events, 0)` | Turns "no match" into 0 |
| `found` | yes when there are logs, no when there are none |

## Query 3 — last seen per source (like `metadata type=sources`)

```dql
fetch logs, from:-30d
| filter dt.system.bucket == "networksyslog"
| summarize count = count(), firstSeen = min(timestamp), lastSeen = max(timestamp), by:{log.source}
| sort lastSeen desc
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Copying `index=` as a field name | Dynatrace has no `index`; use the bucket or the attribute you found in Step 0 |
| Using `=` in filters | DQL compares with `==` |
| Single quotes around strings | DQL strings use double quotes |
| Leaving the default 2-hour timeframe | Add `from:-30d` or set the timeframe in the Notebook |
| Running without a bucket filter over 30 days | Scans a lot of data and costs query credits; always filter the bucket first |

## About the screenshot

The JSON in your screenshot is a Dynatrace **problem event** (`event.kind: DAVIS_PROBLEM`, Windows host TS12). It is not a syslog record, so it is not needed for this conversion. If you want to find the matching log lines for that problem, filter on the host instead:

```dql
fetch logs, from:"2026-10-01T04:50:00Z", to:"2026-10-01T05:20:00Z"
| filter contains(host.name, "ts12")
| filter contains(content, "258")
| limit 50
```

## Data flow

```
your source list
  → fetch logs (Grail)
  → filter bucket networksyslog       (Splunk: index=networksyslog)
  → filter / lookup on log.source     (Splunk: source=...)
  → summarize count by source         (Splunk: tstats count by source)
  → found yes or no
```

## Investigation

| Checked | Finding |
|---|---|
| Earlier Splunk answer (`2026-10-02/1-splunk-simple-source-check`) | Three SPL versions: tstats, tstats plus list, metadata |
| DQL concepts | `fetch logs`, `filter`, `summarize`, `lookup`, `data record` cover all three |
| Field mapping | Splunk index usually maps to a Grail bucket; source usually maps to `log.source`, but this depends on how ingest was set up |
| Screenshot | It is a problem event, not network syslog |

## Result

Run Step 0 to confirm the bucket and source field names. Then use Query 1 for a quick check, Query 2 for a yes/no report, or Query 3 for last-seen times.

## Related files

| File | Purpose |
|---|---|
| `1-splunk-spl-to-dynatrace-dql.dql` | All DQL queries, ready to paste into a Notebook |
| `1.sh` | Mirror and git one-liners |
| `2026-10-02/1-splunk-simple-source-check/` | The original SPL versions |

## Commands

See `1.sh` (not run).
