# CloudWatch Query Empty

```
log.lambda_errors last 2 hours
  default 0 still 0 records
    do not save the alert
    no row for {dt.entity.host}
next
  drop the log group filter
  Last 7 days
    a line -> copy a real log group
    still 0 -> this metric has no recent points
host CPU query
  1 record
  that one can open a problem
```

| Query | Result |
|---|---|
| Host CPU, `HOST-00026D8D201D203A` | 1 record |
| `log.lambda_errors` for the dev log group, with `default: 0` | 0 records |

## Summary

`default: 0` did not create a series. That log group stored no error points from 14:03 to 16:04, so the alert has nothing to judge. Keep that query off the alert. The host query on the same screen is the one that can open a problem.

## Investigation

The lower notebook query was:

```
timeseries errors = sum(log.lambda_errors),
  default: 0,
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

| Item | Value |
|---|---|
| Result | 0 records |
| Ran at | 11/12/2026 16:03:18 |
| Timeframe | 14:03:00 to 16:04:00 |

`fieldsAdd` never ran. An empty timeseries stays empty.

The upper query returned 1 record for the same host, from 13:37 to 15:38, with the CPU line under 20.

## Result

Do not paste the CloudWatch query into the alert.

To see whether `log.lambda_errors` has any log group at all, set the picker to **Last 7 days** and run:

```
timeseries errors = sum(log.lambda_errors), by: {aws.log_group}
| fields aws.log_group
```

| Result | What it means |
|---|---|
| One or more log groups | Copy one of those names into the filter. |
| Still 0 records | This metric has no points in the last 7 days. It cannot open a problem today. |

The query that can open a problem is the one that already returned a row:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

Condition `cpu` below 101. `dt.source_entity` is `{dt.entity.host}`. Title `TESTDUMMY host entity`. Disable it after the problem shows.

## Data flow map

```
dev logFailure, last 2 hours
  default 0
        |
        v
  0 records
  do not save
        |
host CPU
  1 record
        |
        v
  alert can open a problem
```

## Related files

| File | Purpose |
|---|---|
| `51-cloudwatch-query-empty.dql` | The wider metric check. |
| `0-pic.md` | Which query to keep off the alert. |
| `1-investigation.md` | The 0-record run. |
| `2-result.md` | What to run next. |
| `3-glossary.md` | The words. |
| `51-cloudwatch-query-empty-follow.txt` | The same notes for a phone. |
| `51.sh` | Copy commands. |

Commands: [51.sh](51.sh)
