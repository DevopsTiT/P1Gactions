# Onboarding Batch Alerts

```
index myaxa-onboarding-batch
  last 5 minutes
  count greater than 0
    sendNotifications :: error
    message sending failed
    email sending failed
    handleOnboardedCustomers :: error
      title ALJ_ONBOARD
      axa.jp_di_emma_support@axa.co.jp
      shunjin.chen@axa.co.jp

    sendNotificationsQueueConsumer :: error
      title ALJ_MOBILE
      Splunk Mobile role is not selected
```

| Alert | Line |
|---|---|
| sendNotifications error | `sendNotifications :: error` |
| Message sending failed | `sendNotificationsQueueConsumer :: message sending failed` |
| Queue consumer error | `sendNotificationsQueueConsumer :: error` |
| Email sending failed | `sendNotificationsQueueConsumer :: email sending failed` |
| Onboarded customers error | `handleOnboardedCustomers :: error` |

## Summary

Four detectors share the prefix `ALJ_ONBOARD`, one profile, and one email. The queue-consumer error form sends to Splunk Mobile and the role is still `Select...`. That detector uses `ALJ_MOBILE` so it does not mail the support list. There is no PagerDuty action, so `pagerduty.enabled` is `0`.

## Investigation

| Item | What the forms show |
|---|---|
| Index | `myaxa-onboarding-batch` |
| Window | Last 5 minutes |
| Cron | Every 5 minutes |
| Expires | 24 hours |
| Trigger | Number of results is greater than 0, once |
| Throttle | Off |
| Email priority | High on the four mail forms |
| To | `axa.jp_di_emma_support@axa.co.jp` and `shunjin.chen@axa.co.jp` |
| Mobile form | Role is not selected. Severity is Info. Title is empty. |

The onboarded-customers search also has the shorter phrase `handleOnboardedCustomers`. The longer phrase `handleOnboardedCustomers :: error` already contains it.

## Result

The file is [31-onboarding-batch-alerts.tf](31-onboarding-batch-alerts.tf).

`index` stays in every query. Email priority High is the Splunk mail priority. Event severity stays `medium`, and the profile severity level stays `ERROR`. There is no 24-hour expiry field on the detector. The mobile detector has no email resource because no role was selected.

## Data flow map

```
myaxa-onboarding-batch
        |
        +--> four error phrases
        |      ALJ_ONBOARD
        |      emma support and shunjin.chen
        |
        +--> queue consumer :: error
               ALJ_MOBILE
               no recipient selected
```

## Related files

| File | Purpose |
|---|---|
| `31-onboarding-batch-alerts.tf` | Five detectors, one profile, and one email. |
| `0-pic.md` | How the triggers map. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | Why the mobile alert is separate. |
| `3-glossary.md` | The words. |
| `31-onboarding-batch-alerts-follow.txt` | The same notes for a phone. |
| `31.sh` | Copy commands. |

Commands: [31.sh](31.sh)
