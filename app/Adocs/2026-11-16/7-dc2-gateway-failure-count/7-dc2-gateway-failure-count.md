# DC2 Gateway Failure Count

```
panel APIGW WPALJA21C0 and WPALJA21BF
  both Status FAILURE
  append stacks the two hosts
  stats count as ErrorCount by Status
  dashboard shows 2
        |
        v
DQL
  both host names
  line text status: failure
  one ErrorCount
        |
        +-- count is 2 on the same time range --> matches the panel
        |
        +-- 0 records
              file path for these hosts is not known yet
              run the check query
              read log.source
```

| What the panel uses | Value |
|---|---|
| Title | `APIGW WPALJA21C0 & WPALJA21BF Failed Count` |
| First host | `WPALJA21C0.prprivmgmt.intraxa` |
| Second host | `WPALJA21BF.prprivmgmt.intraxa` |
| Status | `FAILURE` |
| Count on the dashboard | `2` |
| Dashboard section | `EIP 1015 DC2 (Singtel)` |

## Summary

This is the same kind of count as the BC and B9 panel, for a different pair of hosts. Stack FAILURE lines from `WPALJA21C0` and `WPALJA21BF`. `ErrorCount` is the red number. On the current dashboard range that number is 2.

## Investigation

The search in the panel is:

```
index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21C0.prprivmgmt.intraxa" Status=FAILURE
| append [search index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21BF.prprivmgmt.intraxa" Status=FAILURE]
| stats count as ErrorCount by Status
```

`append` stacks the second host under the first. The count then runs once. The panel shows `FAILURE` and the number `2`.

The time range is the dashboard shared picker. Set the notebook picker to that same range if you want the DQL count to be 2.

The file paths `apigw5500` and `apigw5590` belong to `WPALJA21BC` and `WPALJA21B9`. They are not on this panel. This query filters by the two host names and the line text `status: failure`.

## Result

Set the notebook time picker to the dashboard range. Paste:

```
fetch logs
| filter (
      contains(host.name, "WPALJA21C0", caseSensitive:false)
      or contains(host.name, "WPALJA21BF", caseSensitive:false)
      or contains(content, "WPALJA21C0.prprivmgmt.intraxa", caseSensitive:false)
      or contains(content, "WPALJA21BF.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| fieldsAdd Status = "FAILURE"
| summarize ErrorCount = count(), by: { Status }
```

You get one row. `Status` is `FAILURE`. `ErrorCount` is the red number. For the range on the screen, that number is 2.

Split by host:

```
fetch logs
| filter (
      contains(host.name, "WPALJA21C0", caseSensitive:false)
      or contains(host.name, "WPALJA21BF", caseSensitive:false)
      or contains(content, "WPALJA21C0.prprivmgmt.intraxa", caseSensitive:false)
      or contains(content, "WPALJA21BF.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| summarize ErrorCount = count(), by: { host.name }
```

When the count is 0, run this and read `log.source`:

```
fetch logs
| filter contains(content, "WPALJA21C0", caseSensitive:false)
    or contains(host.name, "WPALJA21C0", caseSensitive:false)
    or contains(content, "WPALJA21BF", caseSensitive:false)
    or contains(host.name, "WPALJA21BF", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| limit 5
```

## Data flow map

```
WPALJA21C0.prprivmgmt.intraxa
  status: FAILURE
        |
WPALJA21BF.prprivmgmt.intraxa
  status: FAILURE
        |
        v
one stack
        |
        v
ErrorCount
  the panel shows 2
```

## Related files

| File | Purpose |
|---|---|
| `7-dc2-gateway-failure-count.dql` | The panel count, the by-host count, and the check. |
| `0-pic.md` | Both DC2 hosts into one ErrorCount. |
| `1-investigation.md` | The panel search and the red 2. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `7-dc2-gateway-failure-count-follow.txt` | The same steps for a phone. |
| `7.sh` | Copy commands. |

Commands: [7.sh](7.sh)
