# MG Up Check DQL

```
panel last 3 minutes
  sourcetype eip_mg_up_check
  host WPALJA21BC or WPALJA21B9
  table host and MG_Result.MG_Status
        |
        v
long job proves the source names
  EIP UP Check WPALJA21BC  491
  EIP UP Check WPALJA21B9  491
        |
        v
DQL last 3 minutes
  those two source names
  those two hosts
  show the status column and the line
```

| What Splunk showed | Value |
|---|---|
| Panel time | Last 3 minutes |
| Hosts | `WPALJA21BC.prprivmgmt.intraxa` and `WPALJA21B9.prprivmgmt.intraxa` |
| Source for BC | `eip_mg_up_check://EIP UP Check WPALJA21BC` |
| Source for B9 | `eip_mg_up_check://EIP UP Check WPALJA21B9` |
| Long job | 982 events, 491 on each host, 15 Nov 10:00 through 16 Nov 10:34 |
| Table columns | `host` and `MG_Result.MG_Status` |

## Summary

The panel keeps the last 3 minutes of the MG up-check for `WPALJA21BC` and `WPALJA21B9`, and shows the host plus `MG_Result.MG_Status`. The DQL uses the two source names from the source popup and returns that status column with the raw line.

## Investigation

The panel search is:

```
index=eip1015 sourcetype=eip_mg_up_check host="WPALJA21BC.prprivmgmt.intraxa" OR host="WPALJA21B9.prprivmgmt.intraxa"
| table host MG_Result.MG_Status
```

The time picker on the panel is Last 3 minutes. Auto refresh is off.

The wider job, same hosts and sourcetype, returned 982 events from 2026-11-15 10:00 through 2026-11-16 10:34.

| Field | Values |
|---|---|
| `host` | `WPALJA21B9.prprivmgmt.intraxa` 491, `WPALJA21BC.prprivmgmt.intraxa` 491 |
| `source` | `eip_mg_up_check://EIP UP Check WPALJA21B9` 491, `eip_mg_up_check://EIP UP Check WPALJA21BC` 491 |
| `MG_Result.MG_Status` | One value across those events. The screenshot does not show the word. |

`MG_Result.MG_Status` is the Splunk field name. The query asks Dynatrace for that same name. The raw line is in `content` when the column is empty.

## Result

Paste this for the panel. It uses the last 3 minutes.

```
fetch logs, from: now()-3m
| filter (
      contains(log.source, "EIP UP Check WPALJA21BC", caseSensitive:false)
      or contains(log.source, "EIP UP Check WPALJA21B9", caseSensitive:false)
    )
| fields timestamp, host.name, log.source, `MG_Result.MG_Status`, content
| sort timestamp desc
```

`MG_Result.MG_Status` is the status cell. `content` is the full line.

To check the long job, set the notebook picker to 15 Nov 10:00 through 16 Nov 10:34 and paste:

```
fetch logs
| filter (
      contains(log.source, "EIP UP Check WPALJA21BC", caseSensitive:false)
      or contains(log.source, "EIP UP Check WPALJA21B9", caseSensitive:false)
    )
| summarize eventCount = count(), by: { log.source }
```

Each source should be near 491.

When the 3-minute query returns 0 records, run:

```
fetch logs, from: now()-3m
| filter contains(content, "WPALJA21BC", caseSensitive:false)
    or contains(content, "WPALJA21B9", caseSensitive:false)
    or contains(host.name, "WPALJA21BC", caseSensitive:false)
    or contains(host.name, "WPALJA21B9", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| limit 5
```

Read `log.source` on those rows and use that value in the filter.

## Data flow map

```
EIP UP Check WPALJA21BC
EIP UP Check WPALJA21B9
        |
        v
last 3 minutes
        |
        v
host
MG_Result.MG_Status
```

## Related files

| File | Purpose |
|---|---|
| `9-mg-up-check-dql.dql` | The 3-minute table, the long count, and the check. |
| `0-pic.md` | From the two sources to the status table. |
| `1-investigation.md` | Host and source counts. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `9-mg-up-check-dql-follow.txt` | The same steps for a phone. |
| `9.sh` | Copy commands. |

Commands: [9.sh](9.sh)
