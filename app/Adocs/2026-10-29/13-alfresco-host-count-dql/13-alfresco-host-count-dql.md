# Alfresco Host Count DQL

```
Splunk search on alfrescoacr-batch
  one row per host
  count those rows → Message
  Message is 4 → Statistics stays empty
  Message is not 4 → one row, host Total
DQL
  same time window
  count distinct host.name
  filter Message != 4
  0 records → same quiet result as Statistics (0)
```

| Key point | Detail |
|---|---|
| Splunk index | `alfrescoacr-batch`. |
| What it counts | Distinct hosts, not the 176,642 events. |
| Quiet result | Message is 4, so Statistics shows 0. |
| Time window | 10/28/2026 1:00 PM to 10/29/2026 1:43 PM. |
| DQL output | One row only when the host count is not 4. |

## Summary

This Splunk search counts how many different hosts wrote to `alfrescoacr-batch`. It returns a row only when that number is not 4. Statistics (0) means the window currently has 4 hosts. The DQL below does the same check. Set the Dynatrace time picker to the same window.

## Investigation

| Source | Finding |
|---|---|
| Search | `index="alfrescoacr-batch"`, then `stats count by host`, drop `count`, append a Total row, keep it only when `Message` is not 4. |
| Events | 176,642 from 10/28/2026 1:00:00 PM to 10/29/2026 1:43:12 PM. |
| Statistics | 0. The last `where` removed the Total row. |
| Meaning of 0 | The distinct host count is 4. |

`fields - count` drops the event count so the next `stats count` counts hosts. `appendpipe` adds one row: `host` = `Total`, `Message` = that host count. `where host="Total"` keeps that row. `where NOT Message=4` keeps it only when the count is something other than 4.

## Result

Set the notebook or dashboard time picker to **10/28/2026 1:00 PM through 10/29/2026 1:43 PM** before you compare results.

Paste this. It returns a row only when the host count is not 4.

```
fetch logs
| filter contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| summarize by: { host.name }
| summarize Message = count()
| fieldsAdd host = "Total"
| filter Message != 4
| fields host, Message
```

| Piece | What it means |
|---|---|
| `fetch logs` | Load logs for the time picker window. |
| `log.source` filter | Keep the Alfresco batch logs. Change this field if the 5-row check shows a different name. |
| `summarize by: { host.name }` | One row per host. |
| `Message = count()` | How many host rows that was. |
| `host = "Total"` | Same label the Splunk search writes. |
| `Message != 4` | Drop the row when the count is 4. |

0 records is the same outcome as Statistics (0). The check is quiet because 4 hosts were seen.

To see the number while you build the tile, use this. It always returns one row.

```
fetch logs
| filter contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| summarize Message = countDistinct(host.name)
| fieldsAdd host = "Total"
| fields host, Message
```

A `Message` of 4 matches the quiet Splunk result.

If the first query returns no logs at all, find the field Dynatrace used:

```
fetch logs
| filter contains(log.source, "alfresco", caseSensitive:false)
| limit 5
```

`host.name` has to be the same machine name Splunk stores in `host`. If `host.name` is empty, the count will not match 4. Open one of the five rows and use the field that contains the host name.

## Data flow map

```
alfrescoacr-batch logs
 time window 10/28 1:00 PM → 10/29 1:43 PM
 176,642 events
        |
        v
one row per host.name
        |
        v
Message = how many hosts
        |
        +-- Message is 4 → no output row
        |
        +-- Message is not 4 → host Total, Message = that count
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the Splunk search does. |
| `2-result.md` | The DQL to paste. |
| `3-glossary.md` | Terms. |
| `13-alfresco-host-count-dql-follow.txt` | Same DQL for mobile. |
| `13.sh` | Copy commands. |

Commands: [13.sh](13.sh)
