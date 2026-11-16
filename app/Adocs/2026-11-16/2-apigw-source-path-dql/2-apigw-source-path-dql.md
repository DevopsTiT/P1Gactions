# APIGW Source Path DQL

```
Splunk job 9:00 to 9:13
  101 events
  host is only WPALJA21BC.prprivmgmt.intraxa
  source is only /opt/softwareag/log/1015/apigw5500/server.log
  the line contains status: FAILURE
        |
        v
DQL uses that file path and that host
  set the picker to 9:00–9:13 to match 101
  from: now()-15m is the same length later in the day
        |
        +-- count comes back --> ErrorCount
        |
        +-- 0 records
              the file path is not in log.source
              run the short-name check
              read the field that holds server.log
```

| What Splunk showed | Value |
|---|---|
| Event count | 101 |
| Time | 2026-11-16 09:00:00 through 09:13:01 |
| Host | `WPALJA21BC.prprivmgmt.intraxa` on every row |
| Source file | `/opt/softwareag/log/1015/apigw5500/server.log` on every row |
| Line text | `status: FAILURE` |

## Summary

Use the file path and the host from this search. Dynatrace keeps the file path in `log.source`. The failure text is inside the line. For the same 101, set the notebook time to 09:00–09:13. A later 15-minute window will not return 101.

## Investigation

The search that returned 101 events is:

```
index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21BC.prprivmgmt.intraxa" Status=FAILURE
```

The job window is 2026-11-16 09:00:00.000 through 09:13:01.000.

The host popup has one value, count 101. The source popup has one value, count 101:

```
/opt/softwareag/log/1015/apigw5500/server.log
```

An opened line contains `status: FAILURE`. Splunk’s `Status` field is that text. Splunk’s `sourcetype` is a label. The file path is the value that identifies the log in Dynatrace.

This job is host `WPALJA21BC` only. The dashboard panel also names `WPALJA21B9`. The second query adds that host with the same file path.

## Result

Match the 101. Set the notebook time picker to 2026-11-16 09:00 through 09:13, then paste:

```
fetch logs
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5500/server.log", caseSensitive:false)
    and (
      contains(host.name, "WPALJA21BC", caseSensitive:false)
      or contains(content, "WPALJA21BC.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| summarize ErrorCount = count()
```

For a fresh window of about the same length, put the time on the fetch line:

```
fetch logs, from: now()-15m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5500/server.log", caseSensitive:false)
    and (
      contains(host.name, "WPALJA21BC", caseSensitive:false)
      or contains(content, "WPALJA21BC.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| summarize ErrorCount = count()
```

Both dashboard hosts, split so you can see which gateway failed:

```
fetch logs, from: now()-15m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5500/server.log", caseSensitive:false)
    and (
      contains(host.name, "WPALJA21BC", caseSensitive:false)
      or contains(host.name, "WPALJA21B9", caseSensitive:false)
      or contains(content, "WPALJA21BC.prprivmgmt.intraxa", caseSensitive:false)
      or contains(content, "WPALJA21B9.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| summarize ErrorCount = count(), by: { host.name }
```

When the count is 0, the file path is stored in another field. Run:

```
fetch logs, from: now()-15m
| filter contains(content, "WPALJA21BC", caseSensitive:false)
    or contains(host.name, "WPALJA21BC", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| limit 5
```

Read the five rows. Use the field that contains `server.log` in place of `log.source`.

## Data flow map

```
/opt/softwareag/log/1015/apigw5500/server.log
  host WPALJA21BC.prprivmgmt.intraxa
  line text status: FAILURE
        |
        v
101 events from 09:00 to 09:13
        |
        v
DQL log.source + host + status: failure
        |
        v
ErrorCount
```

## Related files

| File | Purpose |
|---|---|
| `2-apigw-source-path-dql.dql` | The three queries plus the check. |
| `0-pic.md` | From the Splunk popups to ErrorCount. |
| `1-investigation.md` | The 101-event job. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `2-apigw-source-path-dql-follow.txt` | The same steps for a phone. |
| `2.sh` | Copy commands. |

Commands: [2.sh](2.sh)
