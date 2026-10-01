# Check Log Paths In A Splunk Index

## Decision tree

```
Is each log path a source in my index?
 Run search 1 (tstats + list) → FOUND or NOT FOUND per path
  FOUND → done (check last_seen is recent)
  NOT FOUND →
    search 2 (wildcard) finds default.log.1 or dated names? → file rotates; data is there under another name
    search 3 (index=*) finds it in another index? → inputs.conf sends it to the wrong index
    search 4 (metadata) shows it long ago only? → file stopped, or host stopped forwarding
    nothing anywhere →
      search 5 (_internal TailingProcessor) mentions the path?
        "permission denied" → splunk user cannot read the file
        "ignoring" or no mention → not in inputs.conf → check forwarder with btool
```

## Short takeaway

| Question | Answer |
|---|---|
| What is a "source" in Splunk? | The full file path the event came from, for example `/app/log/ap/default.log`. |
| Fastest way to check many paths? | `tstats` by source on your index, compared with your list (search 1). |
| Why use `tstats`? | It reads only the index summary, so it is fast even over days of data. |
| What if the file rotates? | Search with a trailing `*` (search 2); rotated names are different sources. |
| What if it is in another index? | Search 3 with `index=*` shows the real index. |
| Is it configured but empty? | Check the forwarder: `_internal` logs (search 5) and `splunk btool inputs list`. |

## Summary

Each path in your list should appear as a `source` value in the index. Search 1 below turns your list into rows and marks each one FOUND or NOT FOUND, with event count, last time seen and hosts. If something is NOT FOUND, searches 2 to 6 tell you why: rotated name, wrong index, stopped long ago, or never read by the forwarder.

## Main content

### Words first

| Term | What it means | Why you care |
|---|---|---|
| index | A storage bucket in Splunk, such as `app_prd`. | You search one index at a time for speed and permissions. |
| source | The file path (or input name) of an event. | This is what your list contains. |
| sourcetype | The format label, such as `log4j`. | Not needed for this check, but shown in search 2. |
| host | The server that sent the event. | Same path on 5 servers = 5 hosts, 1 source. |
| tstats | Fast search over indexed fields only (index, source, host, sourcetype). | Good for "does it exist" questions. |
| Universal Forwarder (UF) | The small agent on each server that reads files and sends them. | If it does not watch the file, nothing arrives. |
| inputs.conf | Forwarder config listing which files to read and to which index. | The root cause of most NOT FOUND cases. |

### Search 1: FOUND or NOT FOUND for every path (start here)

Replace `<your_index>` and pick the time range (here last 7 days).

```spl
| tstats count latest(_time) as last_seen where index=<your_index> earliest=-7d by source host
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

How it works, step by step:

| Step | What it does |
|---|---|
| `tstats ... by source host` | Lists every source really in the index, with counts and last time. |
| `append [ makeresults ... ]` | Adds one row per path from your list, marked `wanted=1`. |
| `eval key=lower(source)` | Compares without case, so `HUL_JOB.LOG` and `hul_job.log` match. |
| `stats ... by key` | Merges the real row and the wanted row for the same path. |
| `where wanted=1` | Keeps only paths from your list. |
| `status` | FOUND if events exist, else NOT FOUND. |

The first line in your screenshot is cut off at the top. Add it to the `split("...")` list with a comma.

### Search 2: rotated file names

Many apps rotate `default.log` into `default.log.1` or `default.log.2026-10-01`. Those are separate sources. Adding `*` at the end catches them. See the `.spl` file, search 2.

### Search 3: is it in a different index?

Same list with `index=*` and `by index source`. If a path shows up under another index, the forwarder's `inputs.conf` has a different `index =` for it. You need read access to that index to see it.

### Search 4: all-time first and last seen

`| metadata type=sources index=<your_index>` gives `firstTime`, `lastTime` and `totalCount` per source. Useful when a file existed once but stopped.

### Search 5 and 6: is the forwarder reading the file?

| Search | What it looks at | What to look for |
|---|---|---|
| 5 | `index=_internal` splunkd log, TailingProcessor and WatchedFile messages | "Permission denied", "File will not be read", "ignoring path". |
| 6 | `metrics.log` `per_source_thruput` | KB per file. Only the busiest sources are kept by default, so missing here is not proof. |

### On the server itself (forwarder side)

Run these on the server that has the files (one per line, also in `48.sh`):

```bash
/opt/splunkforwarder/bin/splunk btool inputs list --debug | grep -iE "ICM_CPW|/app/log/ap|IFDATA|HULFT|pltcomm|universal/log"
/opt/splunkforwarder/bin/splunk list monitor | grep -iE "ICM_CPW|/app/log/ap|IFDATA|HULFT|pltcomm|universal/log"
ls -l /app/ICM_CPW/log/ap/default.log /app/log/ap/default.log /opt/HULFT/etc/trace /var/opt/universal/log/unv.log
sudo -u splunk head -1 /opt/HULFT/etc/BatchLog/HUL_JOB.LOG
```

| Command | What it tells you |
|---|---|
| `btool inputs list --debug` | Which `[monitor://...]` stanzas exist, their `index =`, and which app file set them. |
| `splunk list monitor` | Files the forwarder is actually watching right now. |
| `ls -l` | The file exists and its size is growing. |
| `sudo -u splunk head` | The splunk user can read it (permission check). |

### Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Searching a short time range | Quiet files look NOT FOUND. | Use `earliest=-30d` or search 4. |
| Exact path when the file rotates | Only today's name is checked. | Use search 2 with `*`. |
| Monitor stanza with a typo or wrong case | Linux paths are case sensitive; nothing is read. | Compare with `btool` output. |
| `index =` missing in the stanza | Data goes to `main`. | Search 3 shows it in `main`. |
| Forwarder runs as `splunk` user | Root-only files (often under `/opt/HULFT`) are not readable. | Fix file permissions or ACLs. |
| `/opt/HULFT/etc/trace` has no extension | A stanza like `*.log` does not match it. | Add an explicit stanza for it. |

## Data flow map

```
server file /app/log/ap/default.log
  → Universal Forwarder (inputs.conf [monitor://...] index = X)
  → indexer stores event with source=/app/log/ap/default.log, index=X
  → search head: | tstats ... where index=X by source
      found     → FOUND row
      not found → check rotation (search 2) → other index (search 3)
                → forwarder logs (search 5) → btool on the server
```

## Investigation

| What I checked | Result |
|---|---|
| Your screenshot | 10 readable paths; the top line is cut off. |
| Splunk fields | Path is stored in the indexed `source` field, so `tstats` can check it fast. |

## Result

Run search 1 with your index name. Then use searches 2 to 6 only for NOT FOUND rows.

## Related files

| File | What it is |
|---|---|
| `48-splunk-check-sources-in-index.spl` | All six searches, ready to paste |
| `48.sh` | Forwarder-side checks and git one-liners |

## Commands

See [`48.sh`](48.sh).
