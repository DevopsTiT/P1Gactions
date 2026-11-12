# Emma AGPO Registration Alert

```
last 5 minutes
  a registration exception is in the line
  count is greater than 1
    one CUSTOM_ALERT
    title starts with ALJ_EMMA
      profile matches ALJ_EMMA
        email to the two addresses on the form
```

| Splunk field | Template field |
|---|---|
| Last 5 minutes | `from: now()-5m` |
| Number of results greater than 1 | `filter failed_count > 1` |
| Trigger once | One row, identity `alert_key` |
| Send email | `dynatrace_email_notification` |
| Priority High | Splunk mail priority. The event severity stays `medium`. |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector stays quiet until the last 5 minutes contain more than 1 of the registration exception lines. It then raises one `CUSTOM_ALERT` whose name starts with `ALJ_EMMA`. The profile and the email use that prefix. This does not use the `ALJ_VM` profile or the `ALJ_OCP4` profile.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Prod_Life_Emma_AGPO_Registration_MDM/PODs_Failed_High |
| Description | Alert when MyAxa calls MDM or PODs failed. The note is cut off after "API using shared". |
| Index | `myaxabackend-prod-axa-11-jp` |
| Schedule | Every 5 minutes. Time range Last 5 minutes. |
| Expires | 5 minutes. |
| Trigger | Number of results is greater than 1, once. |
| Throttle | Unchecked. |
| Action | Send email. Priority High. |
| To | `thuphuong.nguyen@axa.co.jp` and `regoire.homassel@axa.co.jp` |

The second address is small on the photo. Confirm the spelling before apply. A name that starts with G would be `gregoire.homassel@axa.co.jp`.

The index is not in the query. The Dynatrace field that holds `myaxabackend-prod-axa-11-jp` is not on this screen.

`CifServiceException: {errorCode}` is written with braces in the Splunk search. The query matches `CifServiceException:` so a real error code still counts. If the braces are literal text in the log, add them back.

## Result

The file is [16-emma-agpo-registration-alert.tf](16-emma-agpo-registration-alert.tf).

`alert.severity` stays `medium`, and the profile severity level stays `ERROR`, the same pair as the working template. Splunk priority High is the email priority on that form.

Throttle is off in Splunk. The identity field keeps one Dynatrace problem open while the count stays above 1. `notify_closed_problems` sends the close mail.

There is no 5-minute expiry field on the detector. The problem stays open while the last 5 minutes still have more than 1 match.

## Data flow map

```
MyAxa registration line
  one of the eight exception phrases
        |
        v
last 5 minutes
  count greater than 1
        |
        v
one CUSTOM_ALERT
  name starts with ALJ_EMMA
        |
        v
ALJ_EMMA profile
  severity level ERROR
        |
        v
email
  thuphuong.nguyen@axa.co.jp
  regoire.homassel@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `16-emma-agpo-registration-alert.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What to confirm before apply. |
| `3-glossary.md` | The words. |
| `16-emma-agpo-registration-alert-follow.txt` | The same notes for a phone. |
| `16.sh` | Copy commands. |

Commands: [16.sh](16.sh)
