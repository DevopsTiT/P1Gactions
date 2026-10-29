# Splunk Host Count Alert

```
Prod_PnC_Alfrescoacr_BatchPODFrozen_High
  read index alfrescoacr-batch
  one row per host that sent logs
  Message = how many of those rows
  Message is 4 → drop the row → Statistics 0 → alert stays quiet
  Message is any other number → keep host Total → alert has a result
  index has no events → no rows → alert also stays quiet
```

| Key point | Detail |
|---|---|
| Search | `index="alfrescoacr-batch"`, then a host count. |
| `Message` | How many different hosts sent at least one event. |
| Expected number | 4. |
| Quiet result | No statistics row. The earlier run showed Statistics (0) after 176,642 events. |
| Alert shape | A row exists only when the host count is not 4. |

## Summary

This search is an alert check for `Prod_PnC_Alfrescoacr_BatchPODFrozen_High`. It counts how many hosts wrote to the index `alfrescoacr-batch`. Splunk keeps one summary row only when that count is not 4. An empty statistics table means 4 hosts were seen. The same search with `index="agrex"` and `NOT Message=1` expects 1 host.

## Investigation

| Source | Finding |
|---|---|
| Alert title on screen | `Prod_PnC_Alfrescoacr_BatchPODFrozen_High`. |
| Index | `alfrescoacr-batch`. |
| Pipeline | `stats count by host`, drop `count`, `appendpipe` a Total row, keep it only when `Message` is not 4. |
| Earlier run | 176,642 events from 10/28/2026 1:00 PM to 10/29/2026 1:43 PM. Statistics (0). |
| Meaning of that run | The window contained exactly 4 hosts. |
| Second block | `index="agrex"` uses the same steps with `NOT Message=1`. |

## Result

Read the Alfresco search from top to bottom.

```
index="alfrescoacr-batch"
| stats count by host
| fields - count
| appendpipe [|stats count as Message | eval host="Total"]
| where host="Total"
| where NOT Message=4
```

| Line | What it does |
|---|---|
| `index="alfrescoacr-batch"` | Take events from that index for the selected time. |
| `stats count by host` | Make one row per host. The `count` column is how many events that host wrote. |
| `fields - count` | Delete the event-count column. The host names remain, one row each. |
| `appendpipe` | Run the commands in brackets on those rows, then add the result underneath. |
| `stats count as Message` | Count the rows. That number is the number of hosts. The column is named `Message`. |
| `eval host="Total"` | Label that summary row `Total`. |
| `where host="Total"` | Throw away the individual host rows. Keep the summary. |
| `where NOT Message=4` | Keep the summary only when the host count is not 4. |

Four hosts, which matches the quiet run:

```
stats count by host
  host A    count 80000
  host B    count 50000
  host C    count 30000
  host D    count 16642

fields - count
  host A
  host B
  host C
  host D

appendpipe
  host A
  host B
  host C
  host D
  host Total    Message 4

where host="Total"
  host Total    Message 4

where NOT Message=4
  (no row)
```

Three hosts:

```
host Total    Message 3
```

That one row is what an alert search treats as something to send. Five hosts does the same, with `Message` 5. Two hosts, one host, and six hosts all keep the row.

No events in the window is different. `stats` has no host rows to count, so the search ends with no statistics row. A dead index and a healthy count of 4 both look empty on the Statistics tab. The 176,642 events on the earlier run are what show the empty table meant “4 hosts,” not “no logs.”

`appendpipe` counts the rows already in the pipeline. It does not start a second search of the index. That is why dropping down to one row per host first makes `Message` a host count.

The agrex block under it is the same pattern. The index is `agrex`. The last line is `where NOT Message=1`. It stays quiet when exactly one host sent logs.

## Data flow map

```
index alfrescoacr-batch
  events in the time window
        |
        v
one row per host
        |
        v
Message = number of those rows
        |
        +-- Message is 4 → no statistics row → alert stays quiet
        +-- Message is not 4 → one row, host Total → alert has a result
        |
        +-- no events at all → no rows → alert stays quiet
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the search and the earlier run show. |
| `2-result.md` | Line-by-line reading and the 4-host example. |
| `3-glossary.md` | Terms. |
| `17-splunk-host-count-alert-follow.txt` | Same explanation for mobile. |
| `17.sh` | Copy commands. |

Commands: [17.sh](17.sh)
