# CCL AWS Batch Timeout

```
line contains Task timed out
  line does not contain 10DEBUG:
  last 6 minutes
  count greater than 0
    one CUSTOM_ALERT
    title starts with ALJ_CCL
      email alj_jp_di_oog_to@axa.co.jp
      pagerduty.enabled is 1
```

| Splunk field | Template field |
|---|---|
| Last 6 minutes | `from: now()-6m` |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| PagerDuty action is present | `pagerduty.enabled` is `1` |
| Send email | The address that is fully visible |
| Priority Normal | Splunk mail priority. Event severity stays `medium`. |

## Summary

This detector fires when the last 6 minutes contain a `Task timed out` line and that line does not contain `10DEBUG:`. The title starts with `ALJ_CCL`. Mail goes to `alj_jp_di_oog_to@axa.co.jp`. PagerDuty is enabled with the flag only.

## Investigation

| Item on the form | Value |
|---|---|
| Name | CCL_AWS_Batch Time Out |
| Description | Optional |
| Search | `index=ccl-fa-comm-calc "Task timed out"` then a second line |
| Second line | Cut off after `message!="10DEBUG:` |
| Index | `ccl-fa-comm-calc` |
| Time range | Last 6 minutes |
| Cron | Every 5 minutes |
| Expires | 24 hours |
| Trigger | Number of results is greater than 0, once |
| Throttle | Unchecked |
| Actions | PagerDuty and Send email |
| To | `alj_jp_di_oog_to@axa.co.jp` |
| Second To line | Cut off. It is not in the file. |
| Priority | Normal |
| Subject | `Splunk Alert: $name$` |

The PagerDuty row is collapsed. The integration key is not on the screen.

## Result

The file is [19-ccl-aws-batch-timeout.tf](19-ccl-aws-batch-timeout.tf).

The exclusion uses the visible text `10DEBUG:`. If the quoted string continues past the box, paste the rest into the filter. The index `ccl-fa-comm-calc` is not in the query. Add it after the Dynatrace field name is known.

Davis runs about once a minute. The Splunk cron is every 5 minutes, and each search looks back 6 minutes. The identity keeps one problem open while the count stays above 0.

## Data flow map

```
ccl-fa-comm-calc line
  contains Task timed out
  does not contain 10DEBUG:
        |
        v
last 6 minutes
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_CCL
        |
        +--> email
        |      alj_jp_di_oog_to@axa.co.jp
        |
        +--> pagerduty.enabled is 1
               the integration key is inside the collapsed PagerDuty row
```

## Related files

| File | Purpose |
|---|---|
| `19-ccl-aws-batch-timeout.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What is still cut off. |
| `3-glossary.md` | The words. |
| `19-ccl-aws-batch-timeout-follow.txt` | The same notes for a phone. |
| `19.sh` | Copy commands. |

Commands: [19.sh](19.sh)
