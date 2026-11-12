# Create The Dynatrace Alert

```
Create the Lambda error alert
  Notebook test
    ERROR lines become a count per minute
    a minute above 0 is a hit
  Settings → Analyze and alert → Alerts → Custom alerts
    New alert → Create your own custom alert
    paste the timeseries query
    static threshold above 0
    title Lambda log ERROR
    Create
```

| Field | Value |
|---|---|
| Query | The `makeTimeseries` query below. |
| Analyzer | Static threshold. |
| Threshold | 0. |
| Direction | Alert if metric is above. |
| Title | `Lambda log ERROR`. |
| Event name | `Lambda log ERROR`. |

## Summary

Paste the query into a new custom alert and set the threshold above 0. One ERROR line in a minute opens a Dynatrace problem named Lambda log ERROR. The table of 819 lines stays a search. It is not the alert.

## Investigation

| Source | Finding |
|---|---|
| Notebook | `fetch logs` where `aws.log.group` contains `/aws/lambda/`. 819 rows in two hours. |
| Error rows | `Failed to handle` on `/aws/lambda/light-digital-api-dev-confirm-e-signature`, with `loglevel` ERROR. |
| Account on those rows | `031682695384`. |
| Alert form | A custom alert requires `makeTimeseries` and an interval of 1 minute. |

## Result

Run this in the Notebook with Last 2 hours selected. The minutes that contain the e-signature error should be above 0.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

Create the alert with these clicks.

1. Open Settings.
2. Open Analyze and alert.
3. Open Alerts, then All alerts.
4. Open Custom alerts.
5. Select New alert, then Create your own custom alert.
6. Under Set scope, paste the query.
7. Under Define alert condition, choose the static threshold.
8. Set the threshold to 0.
9. Choose Alert if metric is above.
10. Select Preview.
11. Set the title to `Lambda log ERROR`.
12. Set the event name to `Lambda log ERROR`.
13. Select Create.

To limit the alert to the function on the error rows, use this query instead.

```
fetch logs
| filter contains(aws.log.group, "light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

The Create button in that Settings page is what saves the alert. This session cannot press it in your tenant.

## Data flow map

```
Lambda log line
  aws.log.group contains /aws/lambda/
  loglevel is ERROR
        |
        v
error_count for that minute
        |
        v
count above 0
        |
        v
Dynatrace problem
  title Lambda log ERROR
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | The create path. |
| `1-investigation.md` | The notebook evidence. |
| `2-result.md` | The query and the field values. |
| `3-glossary.md` | The words. |
| `3-create-dynatrace-lambda-alert-follow.txt` | The same steps for a phone. |
| `3.sh` | Copy commands. |

Commands: [3.sh](3.sh)
