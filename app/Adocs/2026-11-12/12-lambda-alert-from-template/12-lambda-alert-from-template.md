# Lambda Alert From Template

```
Working pair
  detector
    query returns only error rows
    event.type is CUSTOM_ALERT
    title starts with ALJ_OCP4
  alerting profile
    severity level ERROR
    title begins with ALJ_OCP4
  email notification
    uses that profile
UI alert on the screen
  query matches INIT_START
  Define alert condition is not completed
  no CUSTOM_ALERT event
  Problems stays empty
```

| Template piece | Value to keep |
|---|---|
| Analyzer | `dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer` |
| Window | `from: now()-5m` |
| Event type | `CUSTOM_ALERT` |
| Title prefix | `ALJ_OCP4` |
| Profile severity | `ERROR` |
| PagerDuty flag | `0` |

## Summary

The happy-future detector opens a problem because `event.type` is `CUSTOM_ALERT` and the query returns only error rows. The email profile sends when the problem severity level is `ERROR` and the title begins with `ALJ_OCP4`. The Lambda form has the query only. It has no `CUSTOM_ALERT` event, and the query matches normal `INIT_START` lines.

## Investigation

| Source | What it contributes |
|---|---|
| `for_the_happy_future_error_front_end_pod` | Record analyzer, 5-minute window, identity field, `CUSTOM_ALERT`. |
| Event template | `event.name` begins with `ALJ_OCP4`. `alert.severity` is `medium`. `pagerduty.enabled` is `0`. |
| `ALJ_OCP4_alerting_profile` | Severity level `ERROR`. Title filter `BEGINS_WITH` `ALJ_OCP4`. |
| Email resource | Same profile. Sends on open and on close. |
| Edit alert screen | Records query for `Runtime Version`. Section 2 is not completed. |

## Result

The file [12-lambda-log-alert.tf](12-lambda-log-alert.tf) is the detector in that shape. The title starts with `ALJ_OCP4`, so the profile and email already in the photos apply. A second profile with the same filter would send a second mail.

The query counts nothing. It returns rows, which is what the record analyzer uses. A row exists only when an ERROR line arrived in the last 5 minutes. No ERROR line in those 5 minutes means no problem, which is the quiet result.

`pagerduty.enabled` stays `0`, as in the template. The notification path in the photo is email.

## Data flow map

```
ERROR line in the last 5 minutes
        |
        v
record detector
  event.type CUSTOM_ALERT
  event.name starts with ALJ_OCP4
        |
        v
alerting profile
  severity level ERROR
  title begins with ALJ_OCP4
        |
        v
email notification
```

## Related files

| File | Purpose |
|---|---|
| `12-lambda-log-alert.tf` | The detector copied from the happy-future resource. |
| `0-pic.md` | How the two resources connect. |
| `1-investigation.md` | What was copied from the photos. |
| `2-result.md` | What to keep and what was changed. |
| `3-glossary.md` | The words. |
| `12-lambda-alert-from-template-follow.txt` | The same notes for a phone. |
| `12.sh` | Copy commands. |

Commands: [12.sh](12.sh)
