# HPM SharePoint Lambda Error

```
index hpm-sharepoint-api
  message contains ERROR
  last 24 hours
  count greater than 0
    title ALJ_HPM
      naoya.sota@axa.co.jp
      chungyueh.chiu@axa.co.jp
```

| Splunk field | Template field |
|---|---|
| Last 24 hours | `from: now()-24h` |
| Cron `10 6 * * *` | 06:10 every day. Davis still runs about once a minute. |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| Throttle 60 minutes | One open problem while the count stays above 0 |
| Send email | Both addresses on the form |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector fires when the last 24 hours contain an `ERROR` line in `hpm-sharepoint-api`. The title starts with `ALJ_HPM`, so it does not use the `ALJ_CMX` profile. Mail goes to `naoya.sota@axa.co.jp` and `chungyueh.chiu@axa.co.jp`.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Prod_Life_HPM_SharepointAPILambdaError_Normal |
| Description | Check the Lambda error for a failure transferring files from S3 to SharePoint and from SharePoint to S3. The form spells it Lamda. |
| Search | `index="hpm-sharepoint-api" message="*ERROR*"` |
| Time range | Last 24 hours |
| Cron | `10 6 * * *` |
| Expires | 7 days |
| Trigger | Number of results is greater than 0, once |
| Throttle | On, for 60 minutes |
| Actions | Add to Triggered Alerts, collapsed. Send email. |
| To | `naoya.sota@axa.co.jp` and `chungyueh.chiu@axa.co.jp` |
| Priority | Normal |

The gray line under the cron box says every day at 6PM. That is Splunk’s example. This cron is 06:10.

The earlier CMX form read the second address as `chungyuah.chiu@axa.co.jp`. This form reads `chungyueh.chiu@axa.co.jp`.

## Result

The file is [27-hpm-sharepoint-lambda-error.tf](27-hpm-sharepoint-lambda-error.tf).

`index` stays in the query. `ERROR` by itself would match other systems. Splunk suppresses this alert for 60 minutes. The identity keeps one Dynatrace problem open while the last 24 hours still contain a match. There is no 7-day expiry field on the detector.

## Data flow map

```
hpm-sharepoint-api
  message contains ERROR
        |
        v
last 24 hours
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_HPM
        |
        v
email
  naoya.sota@axa.co.jp
  chungyueh.chiu@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `27-hpm-sharepoint-lambda-error.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What to confirm before apply. |
| `3-glossary.md` | The words. |
| `27-hpm-sharepoint-lambda-error-follow.txt` | The same notes for a phone. |
| `27.sh` | Copy commands. |

Commands: [27.sh](27.sh)
