# Logs Do Not Open Problems

```
514 log lines are on the screen
  every visible line is INFO
  the text is INIT_START Runtime Version
    a Lambda writes that line on a normal start
  the screen is a Notebook search
    a search stores nothing in Problems
  a problem opens only after a saved alert
    the condition has to be met
    these INFO lines do not meet an error condition
```

| What this screen is | What it is not |
|---|---|
| Proof that CloudWatch log lines reached Dynatrace. | A Dynatrace problem. |
| 514 INFO lines about Runtime Version. | A failure. |
| A query someone ran by hand. | A saved alert. |

## Summary

Getting logs and opening a problem are two different results. This query found 514 normal startup lines. Dynatrace keeps them as logs. Davis opens a problem only when a saved alert condition is met, and these INFO lines do not meet an error condition.

## Investigation

| Item | Value on the screen |
|---|---|
| Time range | Last 7 days, ending 2026-11-12 09:53. |
| Query | `aws.log.group` contains `/aws/lambda/light-digital-api-dev-confirm-e-signature`, and `content` contains `Runtime Version`. |
| Count | 514 records. |
| loglevel | INFO on the visible rows. |
| content | `INIT_START Runtime Version: nodejs:20.v101 Runtime Version ARN`. |
| Account | `031682695384`. |
| Message above the query | No records. That is a separate result from the 514 lines. |

The first `contains` has no `caseSensitive:false`. The second one has it. The path is lowercase, so this run still matched.

## Result

Leave these 514 lines as logs. They show the function started. They should not become problems.

A problem for this function needs a saved Timeseries alert on the error lines.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

| Field | Value |
|---|---|
| Data type | Timeseries |
| Threshold | Above 0 |
| Title | `Lambda log ERROR` |

Press Save. A minute with an ERROR count above 0 is what opens the problem. A minute full of `INIT_START` stays quiet.

The CloudWatch alarm is still a separate trigger. Its ALARM state is not one of these log lines, so this search cannot show that the alarm fired.

## Data flow map

```
Lambda starts
        |
        v
INFO line: INIT_START Runtime Version
        |
        v
Dynatrace logs
  this Notebook shows 514
        |
        v
Problems
  stays empty
  no saved alert condition was met
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Why these lines stay out of Problems. |
| `1-investigation.md` | What the 514 rows are. |
| `2-result.md` | Which query can open a problem. |
| `3-glossary.md` | The words. |
| `10-logs-do-not-open-problems-follow.txt` | The same answer for a phone. |
| `10.sh` | Copy commands. |

Commands: [10.sh](10.sh)
