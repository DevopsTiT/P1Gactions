# APIGW Failure Count DQL

```
Splunk panel counts FAILURE rows
  index eip1015
  sourcetype eip_mediator_serverlog
  two hosts, stacked with append
  stats count as ErrorCount by Status
        |
        v
paste the DQL
  set the notebook time picker to the dashboard range
        |
        +-- rows come back --> ErrorCount is the panel number
        |
        +-- 0 records
              run the check query
              short host name WPALJA21BC
              read host.name and log.source
              put those fields into the count query
```

| Question | Answer |
|---|---|
| What the panel counts | FAILURE rows from mediator logs on two hosts. |
| What `append` does | It stacks the second host under the first. Then one count runs. |
| What `by Status` returns | One row, Status `FAILURE`, because other statuses are already filtered out. |
| Where the time range comes from | The notebook time picker. This panel uses the dashboard’s shared picker. |

## Summary

Paste one DQL query. It keeps index `eip1015`, sourcetype `eip_mediator_serverlog`, and `Status` `FAILURE`, on hosts `WPALJA21BC` and `WPALJA21B9`. `ErrorCount` is the same number the Splunk panel draws. Set the notebook time picker to the dashboard range before you run it.

## Investigation

The Splunk panel title is `APIGW WPALJA21BC & WPALJA21B9 Failed Count`.

The search box is:

```
index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21BC.prprivmgmt.intraxa" Status=FAILURE
| append [search index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21B9.prprivmgmt.intraxa" Status=FAILURE]
| stats count as ErrorCount by Status
```

| Splunk piece | What it keeps |
|---|---|
| `index=eip1015` | The EIP 1015 log bucket. |
| `sourcetype=eip_mediator_serverlog` | Mediator server log lines. |
| `host="WPALJA21BC.prprivmgmt.intraxa"` | The first API gateway host. |
| `append` and the second `host` | The same FAILURE lines from `WPALJA21B9.prprivmgmt.intraxa`. |
| `Status=FAILURE` | Rows whose Status field is FAILURE. |
| `stats count as ErrorCount by Status` | One count, named ErrorCount, grouped by Status. |
| Shared Time Picker | The dashboard chooses the window. The search itself has no earliest or latest. |
| Auto refresh 1 minute | The dashboard redraws every minute. DQL does not store that. |

`index`, `sourcetype`, `host`, and `Status` are the Splunk field names. The query below uses those names. If Grail stored them under other names, the check query shows the names to use.

## Result

Set the notebook time picker to the same range as the dashboard. Paste this:

```
fetch logs
| filter index == "eip1015"
    and sourcetype == "eip_mediator_serverlog"
    and Status == "FAILURE"
    and (
      host == "WPALJA21BC.prprivmgmt.intraxa"
      or host == "WPALJA21B9.prprivmgmt.intraxa"
    )
| summarize ErrorCount = count(), by: { Status }
```

You should get one row. `Status` is `FAILURE`. `ErrorCount` is the panel number.

To see which host produced the failures, use the same filters and group by host:

```
fetch logs
| filter index == "eip1015"
    and sourcetype == "eip_mediator_serverlog"
    and Status == "FAILURE"
    and (
      host == "WPALJA21BC.prprivmgmt.intraxa"
      or host == "WPALJA21B9.prprivmgmt.intraxa"
    )
| summarize ErrorCount = count(), by: { host }
```

When the first query returns 0 records, run this check. It looks for the short host name and shows the real field names:

```
fetch logs
| filter contains(content, "WPALJA21BC", caseSensitive:false)
    or contains(host.name, "WPALJA21BC", caseSensitive:false)
    or contains(content, "WPALJA21B9", caseSensitive:false)
    or contains(host.name, "WPALJA21B9", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| limit 5
```

Read `host.name` and `log.source` on those five rows. Put the field that contains the host name in place of `host`. Put the field that contains `eip_mediator_serverlog`, or the server.log path, in place of `sourcetype`.

## Data flow map

```
mediator server log
  host WPALJA21BC.prprivmgmt.intraxa
  host WPALJA21B9.prprivmgmt.intraxa
        |
        v
index eip1015
sourcetype eip_mediator_serverlog
Status FAILURE
        |
        v
one stack of both hosts
        |
        v
ErrorCount by Status
```

## Related files

| File | Purpose |
|---|---|
| `1-apigw-failure-count-dql.dql` | The count query, the by-host query, and the check query. |
| `0-pic.md` | From the Splunk panel to ErrorCount. |
| `1-investigation.md` | What each Splunk piece keeps. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `1-apigw-failure-count-dql-follow.txt` | The same steps for a phone. |
| `1.sh` | Copy commands. |

Commands: [1.sh](1.sh)
