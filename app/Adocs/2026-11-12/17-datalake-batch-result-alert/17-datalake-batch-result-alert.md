# Datalake Batch Result Alert

```
index batch_monitoring_logs
  any line in the window
  count greater than 0
    one CUSTOM_ALERT
    title starts with ALJ_DATALAKE
      profile matches ALJ_DATALAKE
        email to masayuki.yasuda@axa.co.jp
```

| Splunk field | Template field |
|---|---|
| Time range Today | `from: now()-24h` |
| Cron `0 8 * * *` | The detector still runs about once a minute. |
| Number of results greater than 0 | `filter result_count > 0` |
| Trigger once | One row, identity `alert_key` |
| Send email | One address, visible on the form. |
| Priority Normal | Splunk mail priority. Event severity stays `medium`. |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This alert sends when the batch monitoring index has any line. The detector returns one row only when that count is greater than 0, then raises one `CUSTOM_ALERT` named with `ALJ_DATALAKE`. Mail goes to `masayuki.yasuda@axa.co.jp`.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Datalake_Batch Result |
| Description | Optional |
| Search | `index="batch_monitoring_logs" \| table _time _raw` |
| Time range | Today |
| Cron | `0 8 * * *` |
| Expires | 24 hours |
| Trigger | Number of results is greater than 0, once. |
| Throttle | Unchecked. |
| Action | Send email. Priority Normal. |
| To | `masayuki.yasuda@axa.co.jp` |
| Subject | `Splunk Alert: $name$` |

The gray line under the cron box, "every day at 6PM", is Splunk's example. This alert's cron is `0 8 * * *`, which is 08:00 every day.

`| table _time _raw` only picks columns. It does not drop lines. Any event in that index counts.

## Result

The file is [17-datalake-batch-result-alert.tf](17-datalake-batch-result-alert.tf).

The query filters `index == "batch_monitoring_logs"`. That is the Splunk field name. If Grail stores the index under another name, change that one line. An empty filter would match every log in the tenant, so the index line stays in the query.

Splunk Today means midnight until the search runs. This query uses the last 24 hours. At 08:00, Today is about 8 hours, and the last 24 hours also includes yesterday.

Davis runs about once a minute. It does not wait for 08:00. The problem opens when the first matching line is inside the window, and the identity keeps that one problem open while the count stays above 0.

There is no 24-hour expiry field on the detector.

## Data flow map

```
batch_monitoring_logs
  any line
        |
        v
last 24 hours
  count greater than 0
        |
        v
one CUSTOM_ALERT
  name starts with ALJ_DATALAKE
        |
        v
ALJ_DATALAKE profile
  severity level ERROR
        |
        v
email
  masayuki.yasuda@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `17-datalake-batch-result-alert.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What to check before apply. |
| `3-glossary.md` | The words. |
| `17-datalake-batch-result-alert-follow.txt` | The same notes for a phone. |
| `17.sh` | Copy commands. |

Commands: [17.sh](17.sh)
