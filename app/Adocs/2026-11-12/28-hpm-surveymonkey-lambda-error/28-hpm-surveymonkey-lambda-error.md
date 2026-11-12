# HPM SurveyMonkey Lambda Error

```
index hpm-survey-monkey
  message contains ERROR
  last 60 minutes
  count greater than 0
    title starts with ALJ_HPM
      the SharePoint HPM profile already matches
      mail naoya.sota@axa.co.jp
      mail chungyueh.chiu@axa.co.jp
```

| Splunk field | Template field |
|---|---|
| Last 60 minutes | `from: now()-60m` |
| Cron `0 * * * *` | The start of every hour. Davis still runs about once a minute. |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| Throttle 60 minutes | One open problem while the count stays above 0 |
| Send email | The existing `ALJ_HPM` email |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector fires when the last 60 minutes contain an `ERROR` line in `hpm-survey-monkey`. The title starts with `ALJ_HPM`. The profile and the email from the SharePoint HPM alert already match that prefix and already mail the same two people. This file has the detector only.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Prod_Life_HPM_SurveyMonkeyLambdaError_Normal |
| Description | Check the Lambda error for a failure transferring files from SurveyMonkey to S3. The form says Survey money. |
| Search | `index="hpm-survey-monkey" message="*ERROR*"` |
| Time range | Last 60 minutes |
| Cron | `0 * * * *` |
| Expires | 7 days |
| Trigger | Number of results is greater than 0, once |
| Throttle | On, for 60 minutes |
| To | `naoya.sota@axa.co.jp` and `chungyueh.chiu@axa.co.jp` |
| Priority | Normal |

The gray line under the cron box says every day at 6PM. That is Splunk’s example. This cron is minute 0 of every hour.

## Result

The file is [28-hpm-surveymonkey-lambda-error.tf](28-hpm-surveymonkey-lambda-error.tf).

A second `ALJ_HPM` profile would send two mails. Keep the profile and email from the SharePoint HPM file. `index` stays in the query. There is no 7-day expiry field on the detector.

## Data flow map

```
hpm-survey-monkey
  message contains ERROR
        |
        v
last 60 minutes
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_HPM
        |
        v
existing ALJ_HPM email
  naoya.sota@axa.co.jp
  chungyueh.chiu@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `28-hpm-surveymonkey-lambda-error.tf` | The detector. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | Why the profile is not repeated. |
| `3-glossary.md` | The words. |
| `28-hpm-surveymonkey-lambda-error-follow.txt` | The same notes for a phone. |
| `28.sh` | Copy commands. |

Commands: [28.sh](28.sh)
