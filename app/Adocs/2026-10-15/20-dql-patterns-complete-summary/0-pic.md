# DQL Patterns Pic

```
Which pattern?
 just find lines with text        → P1 text search
 label which keywords appear      → P2 keyword tagging
 need a value from the text       → P3 parse
 one entry has many lines         → P4 split + expand
 counts, top N, duplicates, chart → P5 summarize / makeTimeseries
 who stopped logging              → P6 max(timestamp)
 Splunk had [subsearch]           → P7 lookup join
 log line is escaped JSON         → P8 replaceString + JSON:j
 CPU, memory, numbers over time   → P9 timeseries
 data comes from a CSV table      → P10 load
 0 rows anywhere → time + source lines only → 0 = not onboarded or wrong field
```
