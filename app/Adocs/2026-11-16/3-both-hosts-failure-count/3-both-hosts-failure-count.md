# Both Hosts Failure Count

```
host WPALJA21BC
  file apigw5500/server.log
  101 FAILURE rows in its own job
host WPALJA21B9
  file apigw5590/server.log
  89 FAILURE rows in its own job
        |
        v
panel append stacks both
  stats count as ErrorCount by Status
        |
        v
one DQL
  both file paths
  both hosts
  line text status: failure
  ErrorCount grouped as FAILURE
```

| Host | File path | Job you already ran |
|---|---|---|
| `WPALJA21BC.prprivmgmt.intraxa` | `/opt/softwareag/log/1015/apigw5500/server.log` | 101 events, 16 Nov 09:00–09:13 |
| `WPALJA21B9.prprivmgmt.intraxa` | `/opt/softwareag/log/1015/apigw5590/server.log` | 89 events, 15 Nov 09:00 through 16 Nov 09:15 |

## Summary

The third panel stacks FAILURE rows from both API gateway hosts and returns one count named `ErrorCount`. The two hosts write different files: `apigw5500` and `apigw5590`. The DQL keeps both files, both hosts, and the line text `status: failure`.

## Investigation

The panel title is `APIGW WPALJA21BC & WPALJA21B9 Failed Count`. The search is:

```
index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21BC.prprivmgmt.intraxa" Status=FAILURE
| append [search index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21B9.prprivmgmt.intraxa" Status=FAILURE]
| stats count as ErrorCount by Status
```

`append` stacks the second host under the first. `by Status` then counts that stack. Every row is already FAILURE, so the table is one row.

The host jobs show the file each host writes:

| Piece | WPALJA21BC | WPALJA21B9 |
|---|---|---|
| Host value | `WPALJA21BC.prprivmgmt.intraxa` | `WPALJA21B9.prprivmgmt.intraxa` |
| Source file | `/opt/softwareag/log/1015/apigw5500/server.log` | `/opt/softwareag/log/1015/apigw5590/server.log` |
| Line text | `status: FAILURE` | `status: FAILURE` |

The panel time range is the dashboard shared picker. The 101 and the 89 came from different windows, so they are not added together.

## Result

Set the notebook time picker to the same range as the dashboard. Paste this:

```
fetch logs
| filter (
      contains(log.source, "/opt/softwareag/log/1015/apigw5500/server.log", caseSensitive:false)
      or contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    )
    and (
      contains(host.name, "WPALJA21BC", caseSensitive:false)
      or contains(host.name, "WPALJA21B9", caseSensitive:false)
      or contains(content, "WPALJA21BC.prprivmgmt.intraxa", caseSensitive:false)
      or contains(content, "WPALJA21B9.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| fieldsAdd Status = "FAILURE"
| summarize ErrorCount = count(), by: { Status }
```

The result is one row. `Status` is `FAILURE`. `ErrorCount` is the panel number for the picker window.

To see the two hosts separately:

```
fetch logs
| filter (
      contains(log.source, "/opt/softwareag/log/1015/apigw5500/server.log", caseSensitive:false)
      or contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    )
    and (
      contains(host.name, "WPALJA21BC", caseSensitive:false)
      or contains(host.name, "WPALJA21B9", caseSensitive:false)
      or contains(content, "WPALJA21BC.prprivmgmt.intraxa", caseSensitive:false)
      or contains(content, "WPALJA21B9.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| summarize ErrorCount = count(), by: { host.name }
```

## Data flow map

```
WPALJA21BC
  apigw5500/server.log
  status: FAILURE
        |
WPALJA21B9
  apigw5590/server.log
  status: FAILURE
        |
        v
one stack
        |
        v
ErrorCount
  Status = FAILURE
```

## Related files

| File | Purpose |
|---|---|
| `3-both-hosts-failure-count.dql` | The panel count and the by-host count. |
| `0-pic.md` | Both files into one ErrorCount. |
| `1-investigation.md` | The two jobs and the panel search. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `3-both-hosts-failure-count-follow.txt` | The same steps for a phone. |
| `3.sh` | Copy commands. |

Commands: [3.sh](3.sh)
