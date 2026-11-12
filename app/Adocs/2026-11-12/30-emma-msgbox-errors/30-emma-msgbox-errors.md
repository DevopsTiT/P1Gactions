# Emma MsgBox Errors

```
index message-box-api
  loglevel error or warn
  last 5 minutes
  count greater than 5
    title ALJ_MSGBOX
      Teams address is cut off on the form
```

| Splunk field | Template field |
|---|---|
| Last 5 minutes | `from: now()-5m` |
| Count greater than 5 | `filter failed_count > 5` |
| Trigger once | One row, identity `alert_key` |
| Send email | The address is cut off. It starts with `e23bcf34.axa365.onmicrosoft.com` |
| No PagerDuty action | `pagerduty.enabled` is `0` |

## Summary

This detector fires when the last 5 minutes have more than 5 error or warn lines in `message-box-api`. The title starts with `ALJ_MSGBOX`. That keeps it off the `ALJ_EMMA` profile, which mails a different list.

## Investigation

| Item on the form | Value |
|---|---|
| Name | Prod_Life_Emma_OverallMsgBoxErrors_Normal |
| Description | Catch unexpected errors related to Emma Life MsgBox |
| Index | `message-box-api` |
| First search line | `error OR warn` |
| Next lines | A `rex` reads `loglevel`, then keeps `error` or `warn` |
| Time range | Last 5 minutes |
| Cron | Every 5 minutes |
| Expires | 24 hours |
| Trigger | Number of results is greater than 5, once |
| Throttle | Off |
| Priority | Normal |
| To | Cut off. The visible start is `e23bcf34.axa365.onmicrosoft.com` |

`| table` only picks columns. Add to Triggered Alerts is collapsed.

## Result

The file is [30-emma-msgbox-errors.tf](30-emma-msgbox-errors.tf).

Replace `paste-the-teams-address-from-the-form` with the full To address. The first Splunk line can also match a bare `warn` outside this index. The query keeps `index == "message-box-api"`. There is no 24-hour expiry field on the detector.

## Data flow map

```
message-box-api
  error or warn
        |
        v
last 5 minutes
  count greater than 5
        |
        v
CUSTOM_ALERT
  name starts with ALJ_MSGBOX
        |
        v
Teams mail
  address starts with e23bcf34.axa365.onmicrosoft.com
```

## Related files

| File | Purpose |
|---|---|
| `30-emma-msgbox-errors.tf` | Detector, profile, and email. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What to paste into `to`. |
| `3-glossary.md` | The words. |
| `30-emma-msgbox-errors-follow.txt` | The same notes for a phone. |
| `30.sh` | Copy commands. |

Commands: [30.sh](30.sh)
