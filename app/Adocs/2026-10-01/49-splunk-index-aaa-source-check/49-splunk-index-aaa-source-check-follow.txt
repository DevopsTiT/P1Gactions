# Check Paths In Splunk Index aaa

## Decision tree

```
Are these paths sources in index=aaa?
 Run A → table with FOUND or NOT FOUND per path
  all FOUND → done
  some NOT FOUND →
    C (all time) shows it? → it stopped sending; check the server
    D (path*) shows it?    → file rotates; data is under a renamed source
    E (folder*) shows a similar name? → spelling or case differs from your list
    none → not sent to aaa → check other index or forwarder (seq 48)
```

## Short takeaway

| Question | Answer |
|---|---|
| Which search first? | A: one table, every path marked FOUND or NOT FOUND. |
| Need only the yes list? | B: shows only the paths that exist. |
| Worried about time range? | C: all time, using `metadata`. |
| File gets rotated? | D: adds `*` to each path. |
| Name slightly different? | E: lists every source under the same folders. |

## Summary

In Splunk the file path of each event is stored in the `source` field. Search A takes your list of paths, compares it with the sources in `index=aaa`, and prints FOUND or NOT FOUND for each, with event count, last time seen and hosts.

## Search A (paste this)

```spl
| tstats count latest(_time) as last_seen where index=aaa earliest=-30d by source host
| stats sum(count) as events max(last_seen) as last_seen values(host) as hosts by source
| append
    [| makeresults
     | eval source=split("/app/ICM_CPW/log/ap/default.log,/app/log/ap/default.log,/app/ICM_CPW/log/sh/default.log,/app/log/ap/monitoringTarget.log,/IFDATA/DATA/GE/LOG/SH/default.log,/IFDATA/DATA/PC/LOG/PISP2/pisp2.log,/opt/HULFT/etc/trace,/opt/HULFT/etc/BatchLog/HUL_JOB.LOG,/opt/plat/logs/pltcomm.log,/var/opt/universal/log/unv.log", ",")
     | mvexpand source
     | eval wanted=1
     | fields source wanted]
| eval key=lower(source)
| stats sum(events) as events max(last_seen) as last_seen values(hosts) as hosts max(wanted) as wanted values(source) as source by key
| where wanted=1
| eval status=if(events>0, "FOUND", "NOT FOUND"), last_seen=strftime(last_seen, "%Y-%m-%d %H:%M:%S")
| table status source events last_seen hosts
| sort status source
```

Example output:

| status | source | events | last_seen | hosts |
|---|---|---|---|---|
| FOUND | /app/log/ap/default.log | 152340 | 2026-10-01 23:30:12 | apsv01 |
| FOUND | /opt/HULFT/etc/BatchLog/HUL_JOB.LOG | 820 | 2026-10-01 22:00:05 | hulsv01 |
| NOT FOUND | /opt/HULFT/etc/trace | | | |

(The rows above are an illustration of the layout, not real data.)

## Search B (only the ones that exist)

```spl
| tstats count where index=aaa earliest=-30d
    source IN ("/app/ICM_CPW/log/ap/default.log", "/app/log/ap/default.log", "/app/ICM_CPW/log/sh/default.log",
               "/app/log/ap/monitoringTarget.log", "/IFDATA/DATA/GE/LOG/SH/default.log", "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log",
               "/opt/HULFT/etc/trace", "/opt/HULFT/etc/BatchLog/HUL_JOB.LOG", "/opt/plat/logs/pltcomm.log", "/var/opt/universal/log/unv.log")
    by source
```

Any path missing from the result is not in `index=aaa` in the last 30 days.

## Searches C, D, E

| Search | When to use | File |
|---|---|---|
| C `metadata type=sources index=aaa` | Check all time, not just 30 days. | `.spl` file, block C |
| D paths with `*` | The app rotates files (`default.log.1`). | block D |
| E folders with `*` | The real path may differ slightly (case, extra folder). | block E |

## Tips

| Tip | Why |
|---|---|
| Set the time picker to "All time" or keep `earliest=-30d` in the search | `earliest=` inside `tstats` overrides the picker. |
| Add the cut-off first line from your screenshot to the list | It is missing from the search. |
| Use Search E when something looks NOT FOUND but should be there | Linux paths are case sensitive, and the forwarder may report a slightly different path. |

## Data flow map

```
your list of paths ─► makeresults rows (wanted=1)
index=aaa ─► tstats by source ─► real sources
merge by lower(source) ─► FOUND (events>0) or NOT FOUND
```

## Related files

| File | What it is |
|---|---|
| `49-splunk-index-aaa-source-check.spl` | Searches A to E for index=aaa |
| `48-splunk-check-sources-in-index/` | Deeper troubleshooting (other index, forwarder, btool) |
| `49.sh` | Mirror and git one-liners |

## Commands

See [`49.sh`](49.sh).
