# Picker Still Two Hours

```
query is the log group query
  picker says Last 2 hours
    14:25 to 16:26
    0 records
  change the picker to Last 365 days
    run the same query again
```

| What is on the screen | What it means |
|---|---|
| Picker | Last 2 hours |
| Timeframe | 14:25:00 to 16:26:00 |
| Result | 0 records |

## Summary

The query did not fail. The picker is still Last 2 hours. That window has no error points for this log group. Change the picker to **Last 365 days** and run the same query again.

## Investigation

The notebook ran the log group timeseries with `fieldsAdd dt.entity.host`. Executed at 16:25:41. The timeframe printed under the query is 14:25 to 16:26. The picker control still shows Last 2 hours.

`fieldsAdd` adds a column only after a series exists. With 0 records, that line does not create a host row.

## Result

Leave the query as it is. Click the picker that says **Last 2 hours**. Choose **Last 365 days**. Run again.

| Result | What it means |
|---|---|
| A line | The query works. The row should show `dt.entity.host`. |
| Still 0 records | This log group has no stored points in that year. |

Do not change `by`. Do not remove `fieldsAdd`.

## Data flow map

```
Last 2 hours
  no points
  0 records
        |
change picker
        |
Last 365 days
  same query
  old spikes can return
```

## Related files

| File | Purpose |
|---|---|
| `56-picker-still-two-hours.dql` | The same query. Only the picker changes. |
| `0-pic.md` | What to click. |
| `1-investigation.md` | The timeframe on the screen. |
| `2-result.md` | The picker to choose. |
| `3-glossary.md` | The words. |
| `56-picker-still-two-hours-follow.txt` | The same notes for a phone. |
| `56.sh` | Copy commands. |

Commands: [56.sh](56.sh)
