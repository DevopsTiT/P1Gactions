# Compass Glue Skip Alert

```
Glue error log group
  message contains skipping table
  last 5 minutes
  count greater than 0
    one CUSTOM_ALERT
    title starts with ALJ_GLUE
      mail yuta.inoue@axa.co.jp
      mail shihao.he@axa.co.jp
```

| Splunk field | Template field |
|---|---|
| Last 5 minutes | `from: now()-5m` |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| Send email | Both addresses on the form |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector fires when the last 5 minutes contain a `skipping table` line in the Compass sales Glue error log group. The title starts with `ALJ_GLUE`. That keeps it off the `ALJ_COMPASS` profile, which mails a different list.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Prod_Life_Compass_BigData連動Glue_Skip発生 |
| Description | Optional |
| Index | `compass-sales*` |
| Log group | `/aws-glue/jobs/custom/compass-sales-performance/error` |
| Message | Contains `skipping table` |
| Time range | Last 5 minutes |
| Cron | Every 5 minutes |
| Expires | 2400 days |
| Trigger | Number of results is greater than 0, once |
| Throttle | Unchecked |
| To | `yuta.inoue@axa.co.jp` and `shihao.he@axa.co.jp` |
| Priority | Normal |
| Subject | `Splunk Alert: $name$` |

The log group path wraps after `compass-sales` on the form. The next line continues `-performance/error`.

## Result

The file is [21-compass-glue-skip-alert.tf](21-compass-glue-skip-alert.tf).

`aws.log.group` is the field already used for the Lambda log groups. If these Glue lines use another field, change that one line. The Splunk index `compass-sales*` is not in the query. The log group path is the scope.

There is no 2400-day expiry field on the detector. The problem stays open while the last 5 minutes still have a matching line.

## Data flow map

```
Glue log group
  compass-sales-performance/error
  skipping table
        |
        v
last 5 minutes
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_GLUE
        |
        v
email
  yuta.inoue@axa.co.jp
  shihao.he@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `21-compass-glue-skip-alert.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | Why the prefix is ALJ_GLUE. |
| `3-glossary.md` | The words. |
| `21-compass-glue-skip-alert-follow.txt` | The same notes for a phone. |
| `21.sh` | Copy commands. |

Commands: [21.sh](21.sh)
