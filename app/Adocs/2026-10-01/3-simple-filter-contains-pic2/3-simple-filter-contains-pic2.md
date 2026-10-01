# Simple Filter Contains Pic2

## Decision Tree

```
Your 2 lines (fetch logs + host group filter)
 │
 ├─ Q1: add "filter contains(...) or contains(...)" for the 23 pic2 items
 │     rows returned → those log.source values are pic2 files (listed with counts)
 │     0 records     → result does NOT contain any pic2 item
 │
 └─ Q2: same check as one summary row
       contains_pic2 = YES → pic2_sources tells how many files matched
       contains_pic2 = NO  → none (expected: this host group is Windows)
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is added to your query? | One `filter` line with 23 `contains(..., caseSensitive: false)` checks joined by `or` |
| Why `contains` and not `==` | Rotated files and longer paths still match; `caseSensitive: false` ignores upper and lower case |
| Wildcard pic2 lines | The `*` part is dropped, for example `ApacheDaemonError.` |
| How to read Q1 | Any row means yes; "0 records" means no |
| How to read Q2 | One row: `contains_pic2` YES or NO, plus counts |
| Expected here | 0 records and NO, because this host group's sources are Windows paths |

## Summary

This version keeps your two lines exactly and adds plain `contains` checks. No arrays or iterative functions, so it works on any tenant. Q1 lists matching sources; Q2 gives a single YES or NO.

## Q1 — Your Query Plus The Pic2 Filter

```
fetch logs
| filter dt.entity.host_group == "HOST_GROUP-D4032DA3E0240421"
| filter contains(log.source, "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemOut.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemErr.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/ICM01/logs/server1/SystemOut.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/ICM01/logs/server1/SystemErr.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/CPE01/logs/server1/SystemOut.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/CPE01/logs/server1/SystemErr.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/CPE01/log/", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/CPE01/FileNet/server1/p8_server_error.log", caseSensitive: false)
      or contains(log.source, "/opt/IBM/WebSphere/Profiles/CPE01/FileNet/server1/pesvr_system.log", caseSensitive: false)
      or contains(log.source, "/app/ICM_CPW/log/ap/monitoringTarget.log", caseSensitive: false)
      or contains(log.source, "/data/apache/inst1/logs/ApacheDaemonError.", caseSensitive: false)
      or contains(log.source, "/data/apache/inst1/logs/error_ssl.", caseSensitive: false)
      or contains(log.source, "/opt/jboss/standalone/log/server.log", caseSensitive: false)
      or contains(log.source, "/app/ICM_CPW/log/ap/default.log", caseSensitive: false)
      or contains(log.source, "/app/log/ap/default.log", caseSensitive: false)
      or contains(log.source, "/app/ICM_CPW/log/sh/default.log", caseSensitive: false)
      or contains(log.source, "/app/log/ap/monitoringTarget.log", caseSensitive: false)
      or contains(log.source, "/IFDATA/DATA/GE/LOG/SH/default.log", caseSensitive: false)
      or contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log", caseSensitive: false)
      or contains(log.source, "/opt/HULFT/etc/trace", caseSensitive: false)
      or contains(log.source, "/opt/HULFT/etc/BatchLog/HUL_JOB.LOG", caseSensitive: false)
      or contains(log.source, "/opt/plat/logs/pltcomm.log", caseSensitive: false)
      or contains(log.source, "/var/opt/universal/log/unv.log", caseSensitive: false)
| summarize log_count = count(), by:{log.source}
| sort log_count desc
```

Q2 (single YES/NO row) is in [`3-simple-filter-contains-pic2.dql`](3-simple-filter-contains-pic2.dql).

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Keeping `*` in the text | Never matches | Use the text before `*` |
| Timeframe 30 minutes | Quiet files missed | Use 24 h |
| Reading "0 records" as an error | It is the answer: no pic2 items | Run Q2 for an explicit NO |

## Data Flow

```
fetch logs → host group filter → contains(pic2 item 1) or ... or (item 23)
   Q1 → summarize by log.source → matching files (or 0 records)
   Q2 → countIf → contains_pic2 YES / NO
```

## Related Files

| File | What it is |
|---|---|
| `3-simple-filter-contains-pic2.dql` | Q1 and Q2 |
| `../2-dql-icontains-pic2-paths/` | Array version with FOUND/MISSING per item |
| `3.sh` | Clipboard and mirror one-liners |
