# Manual Lambda Log Alert

```
Notebook shows Lambda logs
  the query is a table of lines
    a custom alert needs a timeseries
  819 lines in 2 hours include INFO
    alerting on every line stays open
  keep aws.log.group containing /aws/lambda/
    keep loglevel ERROR
    makeTimeseries count per 1 minute
  Settings → Analyze and alert → Alerts → Custom alerts
    static threshold
    alert if the count is above 0
    Create
```

| Piece | What to use |
|---|---|
| Where | Settings, Analyze and alert, Alerts, All alerts, Custom alerts. |
| Query result | One number per minute, named `error_count`. |
| Condition | Static threshold. Alert if the metric is above 0. |
| What opens | A Dynatrace problem when an ERROR line arrives. |

## Summary

Create the alert in Settings, not from the table of 819 lines. Paste a query that counts ERROR lines from `/aws/lambda/` once per minute. Set a static threshold above 0. INFO lines such as START and END stay out of the count.

## Investigation

| What is on screen | What it means |
|---|---|
| Query | `fetch logs` filtered with `contains(aws.log.group, "/aws/lambda/")`. The `contains` has no `caseSensitive:false`. |
| Result | 819 records from 06:56 to 08:56 on 2026-11-12. |
| Log groups | `jenkins-to-sharepoint-api-dev-transferFromS3ToSPS` and `light-digital-api-dev-confirm-e-signature`. |
| Levels | INFO rows for START, END, and REPORT. ERROR rows include "Failed to handle" on the e-signature function. |
| Account | `031682695384` on the visible rows. |
| Second query | `timeseries { log_count = count() }` with an empty `filter`. That form reads a metric. These rows are logs. |

## Result

Test this in the Notebook first. Set the time picker to Last 2 hours and run it. You should see a line, and the minutes with the e-signature errors should be above 0.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

Then create the alert by hand.

1. Open Settings.
2. Open Analyze and alert.
3. Open Alerts, then All alerts.
4. Open Custom alerts.
5. Select New alert, then Create your own custom alert.
6. Open Set scope and paste the query above.
7. Open Define alert condition.
8. Choose the static threshold analyzer.
9. Set the threshold to 0.
10. Choose Alert if metric is above.
11. Select Preview. Minutes that contain an ERROR line cross the line.
12. Open Add details.
13. Set the title to `Lambda log ERROR`.
14. Set the event name to `Lambda log ERROR`.
15. Select Create.

| Choice | Why this one |
|---|---|
| Static threshold | The condition is "any ERROR minute". The number 0 does not need a learned baseline. |
| Above 0 | One ERROR line in a minute is enough to open the problem. |
| Interval 1 minute | Dynatrace recommends 1 minute for this alert type. |

The alert creates a Dynatrace problem. A page in PagerDuty still needs the notification rule you already use for problems. This screen does not show that rule.

To watch only the function that failed on this screen, replace the first filter with this line.

```
| filter contains(aws.log.group, "light-digital-api-dev-confirm-e-signature", caseSensitive:false)
```

## Data flow map

```
/aws/lambda/* log lines
        |
        v
keep loglevel ERROR
        |
        v
error_count per minute
        |
        v
static threshold above 0
        |
        v
Dynatrace problem: Lambda log ERROR
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | The path from the notebook to the alert. |
| `1-investigation.md` | What the notebook shows. |
| `2-result.md` | The query and the clicks. |
| `3-glossary.md` | The words. |
| `1-manual-lambda-log-alert-follow.txt` | The same steps for a phone. |
| `1.sh` | Copy commands. |

Commands: [1.sh](1.sh)
