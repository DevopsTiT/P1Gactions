# CMX SharePoint Lambda Error

```
index cmx-sharepoint-api
  message contains Error
  last 1 hour
  count greater than 0
    one CUSTOM_ALERT
    title starts with ALJ_CMX
      mail to the two addresses on the form
```

| Splunk field | Template field |
|---|---|
| Run every hour | Query window `from: now()-1h` |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| Throttle 60 minutes | One open problem while the count stays above 0 |
| Send email | Both addresses that are visible |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector fires when the last hour has an Error line in `cmx-sharepoint-api`. The title starts with `ALJ_CMX`. Mail goes to `naoya.sota@axa.co.jp` and `chungyuah.chiu@axa.co.jp`.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal |
| Description | Check the Lambda error for a failure transferring files from CMX to SharePoint. The form spells it Lamda. |
| Search | `index="cmx-sharepoint-api" message="*Error*"` |
| Schedule | Every hour, at minute 0 |
| Time range | Not shown on this form |
| Expires | 7 days |
| Trigger | Number of results is greater than 0, once |
| Throttle | On, for 60 minutes |
| Actions | Add to Triggered Alerts, collapsed. Send email. |
| To | `naoya.sota@axa.co.jp` and `chungyuah.chiu@axa.co.jp` |
| Priority | Normal |
| Subject | `Splunk Alert: $name$` |

The second address is small on the photo. It reads `chungyuah.chiu@axa.co.jp`.

Add to Triggered Alerts is collapsed, so that severity is not copied.

## Result

The file is [20-cmx-sharepoint-lambda-error.tf](20-cmx-sharepoint-lambda-error.tf).

The form does not show a Time Range. The query uses the last hour because the alert runs every hour. Change `from:` if the saved search window is different.

`index` is the Splunk field name. `Error` by itself would match logs from other systems, so the index line stays in the query. If Grail stores the index under another field, change that line.

Splunk suppresses this alert for 60 minutes after it fires. The identity keeps one Dynatrace problem open while the count stays above 0. If the problem closes and a new Error line arrives inside that same hour, Dynatrace can mail again.

There is no 7-day expiry field on the detector.

## Data flow map

```
cmx-sharepoint-api
  message contains Error
        |
        v
last 1 hour
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_CMX
        |
        v
email
  naoya.sota@axa.co.jp
  chungyuah.chiu@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `20-cmx-sharepoint-lambda-error.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What to confirm before apply. |
| `3-glossary.md` | The words. |
| `20-cmx-sharepoint-lambda-error-follow.txt` | The same notes for a phone. |
| `20.sh` | Copy commands. |

Commands: [20.sh](20.sh)
