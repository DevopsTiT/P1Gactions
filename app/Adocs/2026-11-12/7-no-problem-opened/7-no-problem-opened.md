# No Problem Opened

```
Problems stays empty
  Edit alert still open, Save still visible
    press Save
  Data type is Timeseries
    query is fetch logs with no makeTimeseries
      the analyzer has no count to compare
      paste the count query and set above 0
  Data type is Records
    Define alert condition is not completed
      finish that section
    Add details has no event name
      set the title and the event name
  query returns rows in a Notebook
    that is a preview
    a preview does not open a problem
  Problems filters
    set Last 2 hours and clear the filter bar
    still empty → open the custom alert and read its last run
```

| Check | Empty Problems means |
|---|---|
| Save was not pressed | The detector is not running. |
| Timeseries query has no `makeTimeseries` | There is no number to cross a threshold. |
| Define alert condition is unfinished | The query can find logs and still raise nothing. |
| Notebook shows 144 records | The logs exist. The alert has not opened a problem. |

## Summary

The Notebook result is a preview. Dynatrace opens a problem only after the custom alert is saved and its condition is complete. The form you showed had the log query filled in. A `fetch logs` query on Timeseries has no count for the threshold, so no problem is created.

## Investigation

| What we already saw | Effect on Problems |
|---|---|
| Edit alert was open and Save was visible | The detector was still a draft. |
| Records was selected | Each matching line can be an anomaly only after the condition section is complete. |
| Query | The e-signature log group, with no ERROR filter. |
| Notebook | 144 lines from 07:16 to 09:16, including START, END, and Failed to handle. |
| Preview in the chat | Status Pending, text CW test logs found. A preview does not notify. |

## Result

Open the custom alert and walk these checks.

1. If **Save** is still on the screen, the alert is not running. Finish the condition, then press **Save**.
2. Look at **Data type**.

Use Timeseries with this query.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

| Field | Value |
|---|---|
| Data type | Timeseries |
| Analyzer | Static threshold |
| Threshold | Above 0 |
| Title | `Lambda log ERROR` |
| Event name | `Lambda log ERROR` |

A `fetch logs` query without `makeTimeseries` gives the Timeseries analyzer no number. The threshold never trips, so Problems stays empty.

3. Open **Add details** and fill the title and the event name before Save.
4. Open **Problems**. Set the time range to **Last 2 hours**. Clear the filter bar.
5. Wait one minute after Save. The detector runs about once a minute.

| After that minute | What it means |
|---|---|
| A problem named Lambda log ERROR | The alert is firing. |
| Problems is still empty | Open the custom alert and read the last run. A failed query is shown there. |
| An event exists and Problems does not | The event was stored as information. The event name and type in Add details are what open a problem. |

The 144 rows include healthy START and END lines. The query above counts only `ERROR`, which is the `Failed to handle` line.

## Data flow map

```
Notebook 144 rows
        |
        v
preview only
        |
        v
saved alert
  Timeseries
  makeTimeseries count
  interval 1 minute
        |
        v
count above 0
        |
        v
problem Lambda log ERROR
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Why Problems stays empty. |
| `1-investigation.md` | What the earlier screens showed. |
| `2-result.md` | The query and the fields that open a problem. |
| `3-glossary.md` | The words. |
| `7-no-problem-opened-follow.txt` | The same checks for a phone. |
| `7.sh` | Copy commands. |

Commands: [7.sh](7.sh)
