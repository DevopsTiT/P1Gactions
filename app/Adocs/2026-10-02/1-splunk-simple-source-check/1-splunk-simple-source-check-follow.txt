# Splunk Simple Source Check

## Decision tree

```
Do I want to know if index=aaa has certain sources?
 Only need "which of these exist"?        → Query 1 (tstats + OR)       → rows shown = found
 Need a clear yes/no for every source?    → Query 2 (tstats + list)     → found=no means missing
 Want the fastest rough look?             → Query 3 (metadata)          → approximate, no time filter needed
 Source got 0 rows but should exist?
   time picker too short?                 → set All time or earliest=-30d
   path written differently?              → try a wildcard like source="*app.log"
   no permission on index?                → ask Splunk admin for role access
```

## Short takeaway

| Question | Answer |
|---|---|
| Simplest query | `\| tstats count where index=aaa (source="A" OR source="B") by source` |
| How to read it | A source that appears in the result is in the index |
| What about missing ones | They simply do not appear, so use Query 2 if you need "no" rows |
| Why tstats | It reads only index metadata, so it is very fast even on big indexes |

## Summary

You do not need the long makeresults/append version from seq 49. One `tstats` line answers "which of these sources exist in index=aaa". If you also want a row that says **no** for the missing ones, add a small list on top (Query 2).

## Query 1 — simplest (shows only the found ones)

```spl
| tstats count where index=aaa (source="/var/log/app/a.log" OR source="/var/log/app/b.log" OR source="/var/log/app/c.log") by source
```

| Result | What it means |
|---|---|
| A row for a source | That source has events in index=aaa in the chosen time range |
| No row for a source | That source has no events there in that time range |

With wildcards (good when hosts or dates vary in the path):

```spl
| tstats count where index=aaa (source="*a.log" OR source="*b.log") by source
```

## Query 2 — yes/no for every source

```spl
| tstats count where index=aaa by source
| append [| makeresults | eval source=split("/var/log/app/a.log,/var/log/app/b.log,/var/log/app/c.log", ",") | mvexpand source | eval count=0]
| stats sum(count) as events by source
| search source IN ("/var/log/app/a.log","/var/log/app/b.log","/var/log/app/c.log")
| eval found=if(events>0, "yes", "no")
```

| Column | What it means |
|---|---|
| source | The path you asked about |
| events | Number of events in the time range |
| found | yes when events is more than 0, no when it is 0 |

## Query 3 — fastest rough look

```spl
| metadata type=sources index=aaa
| search source IN ("/var/log/app/a.log","/var/log/app/b.log")
| eval lastSeen=strftime(lastTime, "%F %T")
| table source totalCount lastSeen
```

| Point | What it means |
|---|---|
| Fast | Reads a small summary file, not events |
| Approximate | Counts can be slightly off, fine for "exists or not" |
| lastSeen | Shows when that source last sent data |

## Common mistakes

| Mistake | Fix |
|---|---|
| Time picker left at "Last 24 hours" | Old or quiet sources look missing; use All time or `earliest=-30d` |
| Path typed with a different slash or case | Copy the exact path from one event, or use a wildcard |
| Windows paths with backslashes | Escape them (`C:\\logs\\a.log`) or use a wildcard like `*\\a.log` |
| Using `index=aaa source=... \| stats count by source` | Works, but scans raw events and is much slower than tstats |

## Data flow

```
You type source list
   → tstats reads index=aaa metadata (tsidx), not raw events
   → groups by source
   → (Query 2) your list is added with count=0
   → stats sums counts per source
   → found = yes if count > 0, else no
```

## Investigation

| Checked | Finding |
|---|---|
| Seq 49 (`2026-10-01/49-splunk-index-aaa-source-check`) | Used a longer makeresults + append + stats compare |
| tstats behavior | Only returns rows that exist, so missing sources show as no row |
| metadata command | Fast summary per source, counts are approximate |

## Result

Use Query 1 for a quick look. Use Query 2 when you need a report with yes/no per source. Use Query 3 when the index is huge and you just want a rough check.

## Related files

| File | Purpose |
|---|---|
| `1-splunk-simple-source-check.spl` | The three queries, ready to paste |
| `1.sh` | Mirror and git one-liners |
| `2026-10-01/49-splunk-index-aaa-source-check/` | The longer earlier version |

## Commands

See `1.sh` (not run).
