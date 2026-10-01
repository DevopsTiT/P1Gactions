# DQL Icontains Pic2 Paths

## Decision Tree

```
Does the pic1 result (log.source for HOST_GROUP-D4032DA3E0240421) icontain pic2?
 │
 ├─ QA: per source → icontains_pic2 true/false + which pic2 path matched
 │     any true?  → those sources are pic2 files
 │     all false? → go on
 │
 ├─ QB: per pic2 path → FOUND / MISSING
 │     MISSING everywhere? → this host group does not send pic2 files
 │
 └─ QC: loose check by file name (SystemOut.log, trace, HULFT ...)
       matches here but not in QA? → similar file on Windows, different path
                                     (example: D:\HULFT Family\...\etc\trace.log)
       no matches?                 → pic2 files belong to another (Linux) host group
```

## Short Takeaway

| Question | Answer |
|---|---|
| What does "icontains" mean here? | `log.source` contains the pic2 text, ignoring upper and lower case |
| DQL used | `contains(log.source, x, caseSensitive: false)` |
| How all 23 paths are checked at once | Put pic2 in an `array(...)`, then `iAny(...)` and `iCollectArray(...)` loop over it |
| Wildcard lines | `*` is dropped and the text before it is used, for example `ApacheDaemonError.` |
| Expected result for this host group | All false and all MISSING in QA and QB, because pic1 sources are Windows paths |
| Likely loose matches in QC | HULFT trace on `D:\HULFT Family\HULFT-HUB Server\etc\trace.log` |

## Summary

QA answers your question directly: one row per pic1 source with `icontains_pic2` true or false and the matched pic2 path. QB flips it around and lists each pic2 path as FOUND or MISSING. QC is a looser check on file names only, useful because pic1 is Windows and pic2 is Linux, so full paths can never match.

## Key DQL Pieces

| Piece | What it does |
|---|---|
| `summarize log_count = count(), by:{log.source}` first | Shrinks millions of log lines to about 27 rows, so the contains checks are cheap |
| `fieldsAdd pic2 = array(...)` | Holds the 23 pic2 paths on every row |
| `pic2[]` | "Each element of the array", used inside iterative functions |
| `iAny(contains(log.source, pic2[], caseSensitive: false))` | True when the source contains at least one pic2 path |
| `iCollectArray(if(..., pic2[]))` | Collects the pic2 paths that matched |
| `arrayRemoveNulls(...)` | Removes the empty slots for paths that did not match |
| `expand pic2_path` (QB) | One row per matched pic2 path |
| `append [data record(...)]` (QB) | Adds all 23 paths so unmatched ones show as MISSING |

## QA — Pic1 Result Icontains Pic2

```
fetch logs
| filter dt.entity.host_group == "HOST_GROUP-D4032DA3E0240421"
| summarize log_count = count(), by:{log.source}
| fieldsAdd pic2 = array(
    "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemOut.log",
    "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemErr.log",
    "/opt/IBM/WebSphere/Profiles/ICM01/logs/server1/SystemOut.log",
    "/opt/IBM/WebSphere/Profiles/ICM01/logs/server1/SystemErr.log",
    "/opt/IBM/WebSphere/Profiles/CPE01/logs/server1/SystemOut.log",
    "/opt/IBM/WebSphere/Profiles/CPE01/logs/server1/SystemErr.log",
    "/opt/IBM/WebSphere/Profiles/CPE01/log/",
    "/opt/IBM/WebSphere/Profiles/CPE01/FileNet/server1/p8_server_error.log",
    "/opt/IBM/WebSphere/Profiles/CPE01/FileNet/server1/pesvr_system.log",
    "/app/ICM_CPW/log/ap/monitoringTarget.log",
    "/data/apache/inst1/logs/ApacheDaemonError.",
    "/data/apache/inst1/logs/error_ssl.",
    "/opt/jboss/standalone/log/server.log",
    "/app/ICM_CPW/log/ap/default.log",
    "/app/log/ap/default.log",
    "/app/ICM_CPW/log/sh/default.log",
    "/app/log/ap/monitoringTarget.log",
    "/IFDATA/DATA/GE/LOG/SH/default.log",
    "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log",
    "/opt/HULFT/etc/trace",
    "/opt/HULFT/etc/BatchLog/HUL_JOB.LOG",
    "/opt/plat/logs/pltcomm.log",
    "/var/opt/universal/log/unv.log")
| fieldsAdd icontains_pic2 = iAny(contains(log.source, pic2[], caseSensitive: false))
| fieldsAdd matched_pic2 = arrayRemoveNulls(iCollectArray(if(contains(log.source, pic2[], caseSensitive: false), pic2[])))
| fields log.source, log_count, icontains_pic2, matched_pic2
| sort icontains_pic2 desc, log_count desc
```

QB and QC are in [`2-dql-icontains-pic2-paths.dql`](2-dql-icontains-pic2-paths.dql).

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Keeping `*` in the pic2 text | `contains` looks for a literal star and never matches | Use the text before the star |
| Running `contains` before `summarize` | Checks every log line, much slower | Summarize by `log.source` first, as in the queries |
| Expecting Windows and Linux paths to match | Always false | Use QC for a file-name level check |
| Short timeframe | Quiet files look absent | Use 24 h |
| Notebook error on `iCollectArray` or `iAny` | Older tenant without iterative functions | Tell me and I will send a version using `in()` and `if()` only |

## Data Flow

```
fetch logs (host group filter)
   → summarize by log.source  (pic1 table, ~27 rows)
   → add pic2 array to each row
   → iAny / iCollectArray with contains(caseSensitive: false)
        QA: per source → true/false + matched path
        QB: expand + append 23 paths → FOUND / MISSING
        QC: file-name list → loose match
```

## Related Files

| File | What it is |
|---|---|
| `2-dql-icontains-pic2-paths.dql` | QA, QB, QC ready to paste |
| `../1-log-source-check-expected-paths/` | Earlier exact-match version (Q1 to Q3) |
| `2.sh` | Copy-to-clipboard and mirror one-liners |
