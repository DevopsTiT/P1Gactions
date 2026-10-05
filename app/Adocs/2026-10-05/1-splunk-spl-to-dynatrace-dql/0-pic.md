# Splunk To DQL Pic

```
SPL: | tstats count where index=networksyslog (source=A OR source=B) by source
          │                     │                        │               │
DQL: fetch logs, from:-30d      │                        │               │
     | filter dt.system.bucket == "networksyslog"        │               │
     | filter in(log.source, array("A","B"))  ───────────┘               │
     | summarize count = count(), by:{log.source}  ──────────────────────┘
```

```
not sure of field names? → summarize by dt.system.bucket → limit 5 sample → pick source field
need "no" rows?          → data record list + lookup + coalesce + if
need last seen?          → summarize max(timestamp) by source
```
