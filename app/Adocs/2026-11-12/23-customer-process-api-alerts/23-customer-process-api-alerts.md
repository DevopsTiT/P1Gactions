# Customer Process API Alerts

```
index customer-process-api
  one of the nine message phrases
  last 5 minutes
  count greater than 0
    title ALJ_CPA
      mail alj_jp_di_adect@axa.co.jp
```

| Splunk field | Template field |
|---|---|
| Last 5 minutes | `from: now()-5m` |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| dedup message | At this threshold, the first match still fires |
| Send email | The address on the form |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector fires when the last 5 minutes contain one of the nine Customer Process API phrases. The title starts with `ALJ_CPA`. Mail goes to `alj_jp_di_adect@axa.co.jp`.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Customer Process API Alerts |
| Description | Optional |
| Index | `customer-process-api` |
| Time range | Last 5 minutes |
| Cron | Every 5 minutes |
| Expires | 24 hours |
| Trigger | Number of results is greater than 0, once |
| Throttle | Unchecked |
| To | `alj_jp_di_adect@axa.co.jp` |

The nine phrases are `Task timed out`, `An error occurred`, `Failed to handle: lifeJData`, `Got unexpected investment company code`, `The policy is ineligible for creating a request`, `1BL0250002`, `<StatusCd>EB`, `imported a total of 0 data`, and `Handler Error: Too many connections`.

`dedup message` keeps one row per message text. `| table` only picks columns. The threshold is greater than 0, so the first matching line fires either way.

Priority and subject are below the bottom of the photo.

## Result

The file is [23-customer-process-api-alerts.tf](23-customer-process-api-alerts.tf).

`index` stays in the query. `Task timed out` and `An error occurred` would match other systems without it. If Grail stores the index under another field, change that line.

There is no 24-hour expiry field on the detector.

## Data flow map

```
customer-process-api
  one of the nine phrases
        |
        v
last 5 minutes
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_CPA
        |
        v
email
  alj_jp_di_adect@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `23-customer-process-api-alerts.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What to confirm before apply. |
| `3-glossary.md` | The words. |
| `23-customer-process-api-alerts-follow.txt` | The same notes for a phone. |
| `23.sh` | Copy commands. |

Commands: [23.sh](23.sh)
