# Lambda Errors Chart Found

```
chart shows a line
  spikes are in the old part of the chart
  the recent part is flat
    alert window is a few minutes
      recent value is 0
      no problem opens
    a new error is stored
      the line rises
      the alert can open a problem
```

| Question | Answer |
|---|---|
| Did the query fail? | No. The metric and the dev log group match. |
| Why was Last 2 hours empty? | No error points were stored in that window. |
| Will the alert fire today? | No. The recent part of the chart is flat. |

## Summary

`log.lambda_errors` for `/aws/lambda/gov-inquiry-system-dev-logFailure` has old spikes and no recent errors. Keep this query. Set the alert to fire when the line is above 0. It stays quiet until a new error arrives.

## Investigation

The notebook query is:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
```

The picker is a long range, about a year. The chart has spikes in the older part, around October and November 2025. From the later months through the right edge, the line is flat.

Last 2 hours returned 0 records because that window sits on the flat part. `timeseries` does not keep a point when nothing was stored.

The log group path is valid. `aws.log_group` is the field that returned this line. One series is listed for `/aws/lambda/gov-inquiry-system-dev-logFailure`.

## Result

Use this same query on the alert. Do not add `dt.entity.custom_device` back. That filter removed the line.

In **Define alert condition**:

| Setting | Value |
|---|---|
| Metric line | `errors` |
| Condition | Above 0 |
| Window | A few minutes, or the default sliding window |

The notebook picker is only the preview. The alert uses its own window. A few minutes of a flat line does not open a problem. That is the result you want while the function is quiet.

A new error log writes a new point. The line goes above 0. The condition is met. The problem opens.

To check what the alert sees, set the notebook picker to **Last 2 hours** and run the same query. An empty chart or a flat 0 means the alert will not fire.

Leave the entity out of the query. In **Add details**, set `dt.source_entity` to the real `CUSTOM_DEVICE-...` id if the problem should show on that device. Keep `event.type` as `CUSTOM_ALERT`.

Do not stretch the alert window back to 2025 to force a problem. That would alert on old spikes.

## Data flow map

```
dev logFailure
  log.lambda_errors
        |
        +--> late 2025
        |      spikes
        |      visible on a long picker
        |
        +--> recent hours
               flat
               short alert window
               no problem
               a new error point opens the problem
```

## Related files

| File | Purpose |
|---|---|
| `39-lambda-errors-chart-found.dql` | The query that returned the line. |
| `0-pic.md` | Why the alert stays quiet. |
| `1-investigation.md` | What the chart shows. |
| `2-result.md` | The condition to set. |
| `3-glossary.md` | The words. |
| `39-lambda-errors-chart-found-follow.txt` | The same notes for a phone. |
| `39.sh` | Copy commands. |

Commands: [39.sh](39.sh)
