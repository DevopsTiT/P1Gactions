# Read Alert Status

```
search returned nothing
        |
        v
All alerts list
  find TESTDUMMY host entity
  also look for Test on cloudwatch logs
        |
        +-- no row
        |     the detector was never saved
        |     paste the query and Save
        |     turn the switch on
        |
        +-- row is there
              read the Status column
                Inactive --> turn the switch on
                Pending --> wait 2 minutes
                Error --> query is failing; paste interval:1m and Save once
                Success --> query runs; open Problems with filters cleared
```

| Status on the list | What it means | What you do |
|---|---|---|
| Inactive | The detector is saved and switched off. | Turn the switch on. |
| Pending | Davis has not finished a run yet. | Wait 2 minutes and read Status again. |
| Error | The query run is failing. | Paste the one-minute query below and Save once. |
| Warning | Most runs work, and some fail. | Open the row and read the error text. |
| Success | The query runs. | Clear filters on Problems and search `TESTDUMMY` again. |
| Unavailable | Status cannot be read. | The account needs permission to read system storage. |

## Summary

An empty search means Davis has not written a `TESTDUMMY` event. The Preview chart cannot do that. On the All alerts list, read the Status column for this detector. That status says whether the detector is off, still waiting, or failing its query.

## Investigation

Problems search for `TESTDUMMY` returned nothing. The events search was the check for a written event, and an empty result means the same thing: no event in the last 30 minutes.

Preview already showed the CPU line under the threshold. Preview only draws the chart. Davis writes the event only when the saved detector is switched on and the query run succeeds.

Dynatrace shows that run on the All alerts list in the Status column. Inactive means the switch is off. Error means the query failed. After repeated failures, Dynatrace waits longer between tries: 2 minutes, then 4, then 8, and so on. Saving the same failing query again makes the wait longer.

A valid alert query uses `timeseries` and `interval:1m`. It does not use `from:` or `to:`.

The list may still show the older title `Test on cloudwatch logs` if the new title was never saved.

## Result

Open **All alerts**. Search `TESTDUMMY`. If that row is missing, search `Test on cloudwatch logs`.

**When both searches have no row,** the form was not saved. Create the alert again and use this query:

```
timeseries cpu = avg(dt.host.cpu.usage), interval:1m,
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

| Field | Value |
|---|---|
| Query offset | `2` |
| Threshold | `101` |
| Condition | Below |
| Violating samples | `1` |
| Sliding window | `5` |
| Dealerting samples | `5` |
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Delete the `dt.smartscape_source.id` row. Click Save once. Turn the switch on. Wait 3 minutes. Search Problems for `TESTDUMMY`.

**When the row is there,** read Status and follow the table above. Send a screenshot of that row, including the Status column.

After an Error is fixed, wait for the next run. Do not Save the failing query again.

This alert sends no email. When the problem shows, disable the alert.

## Data flow map

```
empty search
        |
        v
All alerts row
        |
        +-- missing --> Save the detector --> switch on
        |
        +-- Inactive --> switch on
        |
        +-- Error --> fix interval:1m --> Save once --> wait
        |
        +-- Success --> Problems, filters cleared
                |
                v
        TESTDUMMY problem
                |
                v
        disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `65-read-alert-status.dql` | The query to save, and a wider events search. |
| `0-pic.md` | Status decides the next click. |
| `1-investigation.md` | Why an empty search still leaves the chart valid. |
| `2-result.md` | What to do for each status. |
| `3-glossary.md` | The words. |
| `65-read-alert-status-follow.txt` | The same steps for a phone. |
| `65.sh` | Copy commands. |

Commands: [65.sh](65.sh)
