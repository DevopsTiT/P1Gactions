# Lambda Metric Zero Records

```
filtered timeseries returned 0
  drop the log group filter
  set the picker to Last 7 days
    still 0
      metric log.lambda_errors has no points
      fetch logs for gov-inquiry
        logs show a count -> use a fetch logs alert
        logs are also 0 -> check environment and field name
    a line shows
      list the log group values
      copy the real path into the filter
```

| What the screen shows | What it means |
|---|---|
| 0 records | The query ran. No series matched. |
| Last 2 hours | Only 12:54 to 14:55 was searched. |
| No error text | The query syntax was accepted. |

## Summary

`log.lambda_errors` has no points for `/aws/lambda/gov-inquiry-system-dev-logFailure` in the last 2 hours. An error metric often stays empty until an error log is written. Widen the time, drop the filter, then look at the logs themselves.

## Investigation

The notebook query was:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
```

| Item | Value on the screen |
|---|---|
| Result | 0 records |
| Ran at | 11/12/2026 14:54:53 |
| Timeframe | 12:54:00 to 14:55:00 |
| Picker | Last 2 hours |

The custom-device filter is already gone. This empty result is the metric, the log group path, or the time window.

The path contains `dev`. The earlier gov-inquiry alerts used prod log groups. A quiet dev function in a 2-hour window produces no error-metric points.

`timeseries` does not draw a zero line when no points were stored. No points means 0 records.

## Result

Run these in order. Change the picker when the step says so.

**1. Last 7 days. No filter.** This asks whether the metric has any points at all.

```
timeseries errors = sum(log.lambda_errors)
```

| Result | Next step |
|---|---|
| Still 0 records | The metric is empty. Go to step 3 and use logs. |
| A line appears | The metric exists. Go to step 2 and read the real log group names. |

**2. Last 7 days. List the log groups on that metric.**

```
timeseries errors = sum(log.lambda_errors), by: {aws.log_group}
| fields aws.log_group
```

If Dynatrace says the dimension does not exist, run this instead:

```
timeseries errors = sum(log.lambda_errors), by: {aws.log.group}
| fields aws.log.group
```

Copy one value from that list into the filter. Do not type the path from memory if it is not in the list.

**3. Last 24 hours. Look at logs, not the metric.**

```
fetch logs, from: now()-24h
| filter contains(aws.log.group, "gov-inquiry-system", caseSensitive:false)
| summarize count = count(), by: {aws.log.group}
| sort count desc
| limit 20
```

If the field name errors, use `aws.log_group` in the `contains`, the `by`, and the `summarize`.

| Logs result | What to do |
|---|---|
| A count greater than 0 | Logs are here. The metric is not filled for this function. Build the alert with `fetch logs`. |
| 0 records | This environment has no matching logs. Check that the notebook is the environment that receives the Lambda logs. |

A `fetch logs` alert does not need `log.lambda_errors`. This is the shape that returns a row when a matching log exists:

```
fetch logs, from: now()-24h
| filter contains(aws.log.group, "gov-inquiry-system-dev-logFailure", caseSensitive:false)
| filter contains(content, "ERROR", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "gov-inquiry-dev-logfailure"
```

Use the log group string from step 3 if it differs from `dev-logFailure`.

## Data flow map

```
Last 2 hours
  log.lambda_errors
  exact dev log group
        |
        v
  no stored points
        |
        v
  0 records
        |
        +--> Last 7 days, no filter
        |      still 0 -> metric is empty
        |
        +--> fetch logs, gov-inquiry
               count > 0 -> alert on logs
               count = 0 -> wrong environment or no ingest
```

## Related files

| File | Purpose |
|---|---|
| `38-lambda-metric-zero-records.dql` | The three queries, in order. |
| `0-pic.md` | Where a zero result goes next. |
| `1-investigation.md` | What the notebook showed. |
| `2-result.md` | Which query to run next. |
| `3-glossary.md` | The words. |
| `38-lambda-metric-zero-records-follow.txt` | The same notes for a phone. |
| `38.sh` | Copy commands. |

Commands: [38.sh](38.sh)
