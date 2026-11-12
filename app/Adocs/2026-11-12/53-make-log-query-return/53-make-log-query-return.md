# Make Log Query Return

```
same log group query
  picker Last 2 hours
    0 records
  picker Last 365 days
    a line with old spikes
      the query works
      a short alert window still stays quiet
    still 0
      drop the log group filter
```

| Picker | What it tests |
|---|---|
| Last 2 hours | Whether a new error was stored today. It was not. |
| Last 365 days | Whether this query can return the series at all. |

## Summary

Use the log group query with no `default` and no `fieldsAdd`. Set the notebook picker to **Last 365 days**. A line means the query works. The last 2 hours stays empty because no new error point was stored.

## Investigation

This query returned 0 records from 14:03 to 16:04:

```
timeseries errors = sum(log.lambda_errors),
  default: 0,
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

`default: 0` did not create a series. An earlier long chart of the same log group showed old spikes and a flat recent section.

## Result

**Test.** Picker **Last 365 days**. Run only this:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
```

| Result | What it means |
|---|---|
| A line, with spikes in the older part | The query works. Last 2 hours is empty because nothing new was stored. |
| Still 0 records | Drop the filter and list whatever log groups the metric has. |

The list query, still on **Last 365 days**:

```
timeseries errors = sum(log.lambda_errors), by: {aws.log_group}
| fields aws.log_group
```

Do not put this long window on the alert. An alert window of a few minutes only sees the flat end, so it will not open a problem. The host query is still the one that can open a problem today.

## Data flow map

```
Last 2 hours
  no points
  0 records
        |
Last 365 days
  old spikes
  query returns a line
        |
short alert window
  still the flat end
  no problem from this metric today
```

## Related files

| File | Purpose |
|---|---|
| `53-make-log-query-return.dql` | The two notebook tests. |
| `0-pic.md` | Which picker to use. |
| `1-investigation.md` | Why the short window is empty. |
| `2-result.md` | The query to run. |
| `3-glossary.md` | The words. |
| `53-make-log-query-return-follow.txt` | The same notes for a phone. |
| `53.sh` | Copy commands. |

Commands: [53.sh](53.sh)
