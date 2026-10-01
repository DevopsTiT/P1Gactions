# Check Log Sources Against Expected Paths

## Decision Tree

```
Want: does host group HOST_GROUP-D4032DA3E0240421 send the pic2 log files?
 │
 ├─ Run Q2 (coverage report)
 │    all rows FOUND        → every expected file is ingested, done
 │    some rows MISSING     → go on
 │
 ├─ Look at your Q1 result: are the sources C:\ and D:\ (Windows)?
 │    yes → this host group is Windows; pic2 paths are Linux
 │          → MISSING is expected here → run Q3 to find the right host group
 │    no  → go on
 │
 ├─ Run Q3 (all host groups)
 │    path appears under another host group → you checked the wrong group
 │    path appears nowhere                  → not ingested at all
 │         file exists on the host?   no  → app does not write it, not a Dynatrace issue
 │         yes → check Log ingest rules / OneAgent log module / file permissions
 │
 └─ Wildcard paths (*.log) MISSING but similar names exist?
      → Q1 shows the real names; adjust the startsWith/endsWith prefixes
```

## Short Takeaway

| Question | Answer |
|---|---|
| What does your query show? | The 27 log files this host group sends, with a count for each |
| Are pic2 paths in it? | Not in the visible rows. All visible sources are Windows (`C:\`, `D:\`). Pic2 paths are Linux (`/opt`, `/app`, `/data`). |
| Closest match | `D:\HULFT Family\HULFT-HUB Server\etc\trace.log` is the Windows version of pic2's `/opt/HULFT/etc/trace`, but it is a different file |
| How to check properly | Q2 lists all 23 pic2 paths with FOUND or MISSING |
| How to find where they are | Q3 drops the host group filter and shows which host group sends each path |

## Summary

Your query groups logs by `log.source` for one host group. Q1 adds an `in_pic2` true/false column to your result. Q2 turns the pic2 list into a checklist and marks each path FOUND or MISSING, including paths with zero logs. Q3 shows which host group really sends those Linux files. Based on your screenshot, expect Q2 to show MISSING for everything, because this host group is Windows.

## The Pic2 List (lines 462–484, 23 paths)

| # | Expected path | Kind |
|---|---|---|
| 1 | `/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemOut.log` | Exact |
| 2 | `/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemErr.log` | Exact |
| 3 | `/opt/IBM/WebSphere/Profiles/ICM01/logs/server1/SystemOut.log` | Exact |
| 4 | `/opt/IBM/WebSphere/Profiles/ICM01/logs/server1/SystemErr.log` | Exact |
| 5 | `/opt/IBM/WebSphere/Profiles/CPE01/logs/server1/SystemOut.log` | Exact |
| 6 | `/opt/IBM/WebSphere/Profiles/CPE01/logs/server1/SystemErr.log` | Exact |
| 7 | `/opt/IBM/WebSphere/Profiles/CPE01/log/*.log` | Wildcard |
| 8 | `/opt/IBM/WebSphere/Profiles/CPE01/FileNet/server1/p8_server_error.log` | Exact |
| 9 | `/opt/IBM/WebSphere/Profiles/CPE01/FileNet/server1/pesvr_system.log` | Exact |
| 10 | `/app/ICM_CPW/log/ap/monitoringTarget.log` | Exact |
| 11 | `/data/apache/inst1/logs/ApacheDaemonError.*.log` | Wildcard |
| 12 | `/data/apache/inst1/logs/error_ssl.*.log` | Wildcard |
| 13 | `/opt/jboss/standalone/log/server.log` | Exact |
| 14 | `/app/ICM_CPW/log/ap/default.log` | Exact |
| 15 | `/app/log/ap/default.log` | Exact |
| 16 | `/app/ICM_CPW/log/sh/default.log` | Exact |
| 17 | `/app/log/ap/monitoringTarget.log` | Exact |
| 18 | `/IFDATA/DATA/GE/LOG/SH/default.log` | Exact |
| 19 | `/IFDATA/DATA/PC/LOG/PISP2/pisp2.log` | Exact |
| 20 | `/opt/HULFT/etc/trace` | Exact, no extension |
| 21 | `/opt/HULFT/etc/BatchLog/HUL_JOB.LOG` | Exact, upper case |
| 22 | `/opt/plat/logs/pltcomm.log` | Exact |
| 23 | `/var/opt/universal/log/unv.log` | Exact |

Line 461 and above were not visible in the picture. If the list continues above, add those paths to the arrays.

## How The Queries Work

| Step | What it does | Why |
|---|---|---|
| `filter dt.entity.host_group == ...` | Keeps only your host group | Same as your query |
| `filter startsWith(log.source, "/")` | Keeps Linux paths only | Cuts scanned data; Windows paths can never match |
| `fieldsAdd path_key = ...` | Rotated files like `ApacheDaemonError.20261001.log` become the pattern `ApacheDaemonError.*.log`. Other files keep their real path. | Lets wildcard lines match with a simple exact compare |
| `in(path_key, array(...))` | True when the path is in the pic2 list | The actual check |
| `append [data record(...)]` (Q2 only) | Adds all 23 expected paths as rows | Paths with zero logs would otherwise be invisible; this makes them show as MISSING |
| Second `summarize` (Q2 only) | Joins real counts with the checklist rows | One row per expected path |
| `status` | FOUND when count is above 0, else MISSING | Easy to read |

## Q2 — Coverage Report (main query)

```
fetch logs
| filter dt.entity.host_group == "HOST_GROUP-D4032DA3E0240421"
| filter startsWith(log.source, "/")
| fieldsAdd path_key = if(startsWith(log.source, "/opt/IBM/WebSphere/Profiles/CPE01/log/") and endsWith(log.source, ".log"), "/opt/IBM/WebSphere/Profiles/CPE01/log/*.log",
    else: if(startsWith(log.source, "/data/apache/inst1/logs/ApacheDaemonError.") and endsWith(log.source, ".log"), "/data/apache/inst1/logs/ApacheDaemonError.*.log",
    else: if(startsWith(log.source, "/data/apache/inst1/logs/error_ssl.") and endsWith(log.source, ".log"), "/data/apache/inst1/logs/error_ssl.*.log",
    else: log.source)))
| summarize log_count = count(), real_sources = collectDistinct(log.source), by:{path_key}
| append [
    data record(path_key = "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemOut.log"),
      record(path_key = "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemErr.log"),
      ... all 23 paths, see the .dql file ...
      record(path_key = "/var/opt/universal/log/unv.log")
    | fieldsAdd expected = true
  ]
| summarize log_count = sum(log_count), expected = max(expected), real_sources = arrayFlatten(collectArray(real_sources)), by:{path_key}
| filter expected == true
| fieldsAdd status = if(isNotNull(log_count) and log_count > 0, "FOUND", else: "MISSING")
| fields status, path_key, log_count, real_sources
| sort status asc, path_key asc
```

Full Q1, Q2 and Q3 are in [`1-log-source-check-expected-paths.dql`](1-log-source-check-expected-paths.dql). Paste one query at a time into the notebook.

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Checking a Windows host group for Linux paths | Everything MISSING | Run Q3 to find the Linux host group |
| Timeframe too short | Quiet files (HULFT trace, batch logs) look MISSING | Use 24 h for Q2 |
| Timeframe too long on Q3 | Large scan, slow and costly | Keep Q3 to 30 min to 2 h, then widen if needed |
| Case differences | `HUL_JOB.LOG` vs `hul_job.log` do not match | Compare with Q1's real names; `log.source` comparison is case-sensitive |
| Rotated name pattern differs | Wildcard path shows MISSING | Check Q1 for the real name and adjust the prefix |

## Data Flow

```
Linux host file (/opt/... /app/...)
   │  OneAgent log module reads it (if a log ingest rule allows it)
   ▼
Dynatrace Grail logs  (log.source = full file path, dt.entity.host_group = host group ID)
   │
   ├─ Q1: your host group → every source + in_pic2 true/false
   ├─ Q2: your host group → 23 pic2 paths → FOUND / MISSING
   └─ Q3: all host groups → which group sends each pic2 path
```

## Related Files

| File | What it is |
|---|---|
| `1-log-source-check-expected-paths.dql` | Q1, Q2 and Q3, ready to paste |
| `1.sh` | Mirror copy one-liners (no Dynatrace commands needed; queries run in the notebook) |
