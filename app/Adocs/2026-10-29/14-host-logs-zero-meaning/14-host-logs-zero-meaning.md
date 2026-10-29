# Host Logs Zero Meaning

```
Host page Logs = 0
  which clock? → Last 2 hours
  which host? → alfrescoacr-batch-innsuite-prod-0 only
  Dynatrace linked any log line to this host in that window?
    no → the Logs tile stays 0
  did the process write a file on disk?
    this page does not answer that
  Splunk index over ~24 hours still has events
    those lines are not on this host page
  confirm → DQL on host.name for 2 hours, then 24 hours
```

| Key point | Detail |
|---|---|
| Logs tile | 0 for the last 2 hours. |
| What that says | Dynatrace has no log line linked to this host in that window. |
| What it leaves open | The process may still be writing logs that Dynatrace does not ingest. |
| Mode | App only. The banner says the page is filled by the agent inside the container. |
| Still present | 1 process, 4 services, 5 connected entities. |

## Summary

Logs **0** means this Dynatrace host page received no log lines for `alfrescoacr-batch-innsuite-prod-0` in the last 2 hours. It does not mean the batch wrote nothing. The page is in app-only mode and marked Not analyzed, so host charts are empty for the same reason. Splunk already counted events for the `alfrescoacr-batch` index over a longer window.

## Investigation

| Source | Finding |
|---|---|
| Host | `alfrescoacr-batch-innsuite-prod-0`. |
| Time picker | Last 2 hours. |
| Status | Not analyzed. |
| Banner | App-only mode. Data comes from the special agent inside the container. |
| Logs | 0. |
| Events | 0. |
| CPU, memory, network | Dashes. Charts say no data available. |
| Processes | Total 1. Load under 1%. Memory 3091. Enabled 1. |
| Connected entities | 5. |
| Services | 4. |
| Hosts in and hosts out | 0. |

The **4** under Services is four services on this one host. The Splunk search’s **4** was four hosts in the index. These are different counts.

## Result

Read the Logs **0** as “no log line is attached to this host for the last 2 hours.”

Three limits sit on that number:

| Limit | What it means |
|---|---|
| Last 2 hours | Lines older than 2 hours do not show on this page. |
| This host only | The other Alfresco hosts are not included. |
| App-only mode | Full host monitoring is off. Log ingest is separate from the process and service data you still see. |

The process row and the four services show Dynatrace can see the application. The empty CPU and network charts match Not analyzed. They are the same kind of gap as the log zero.

Splunk’s 176,642 events were for the index `alfrescoacr-batch` from 10/28/2026 1:00 PM to 10/29/2026 1:43 PM. That count can stay large while this one host page shows 0.

Confirm on this host:

```
fetch logs, from: now()-2h
| filter contains(host.name, "alfrescoacr-batch-innsuite-prod-0", caseSensitive:false)
| summarize log_count = count()
```

Widen the clock to the Splunk window:

```
fetch logs, from: now()-24h
| filter contains(host.name, "alfrescoacr-batch-innsuite-prod-0", caseSensitive:false)
| summarize log_count = count()
```

If `host.name` is empty on the log, search the line text:

```
fetch logs, from: now()-24h
| filter contains(content, "alfrescoacr-batch-innsuite-prod-0", caseSensitive:false)
| summarize log_count = count()
```

`log_count` **0** on all three means these lines are not in Dynatrace for this host. The host page is reporting that gap. It is not a disk check.

## Data flow map

```
alfrescoacr-batch-innsuite-prod-0
        |
        +--> special agent inside the container
        |      process 1
        |      services 4
        |      connected entities 5
        |
        +--> host page, Last 2 hours, app only
               Logs 0
               Events 0
               CPU and network charts empty
        |
        +--> Splunk index alfrescoacr-batch
               events over the longer window
               not shown on this host page
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the host page shows. |
| `2-result.md` | How to read Logs 0, plus the DQL. |
| `3-glossary.md` | Terms. |
| `14-host-logs-zero-meaning-follow.txt` | Same answer for mobile. |
| `14.sh` | Copy commands. |

Commands: [14.sh](14.sh)
