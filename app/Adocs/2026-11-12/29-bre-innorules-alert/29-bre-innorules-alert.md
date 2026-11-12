# BRE Innorules Alert

```
index starts with innorules
  extracted loglevel is ERROR
  last 5 minutes
  count greater than 0
    title ALJ_BRE
      pagerduty.enabled is 1
      no email action on the form
```

| Splunk field | Template field |
|---|---|
| Last 5 minutes | `from: now()-5m` |
| Count greater than 0 | `filter failed_count > 0` |
| Trigger once | One row, identity `alert_key` |
| PagerDuty action | `pagerduty.enabled` is `1` |
| No Send email action | No email resource |

## Summary

This detector fires when the last 5 minutes contain an `ERROR` line in an `innorules` index. The title starts with `ALJ_BRE`. PagerDuty is the only action. The integration key is not on the screen.

## Investigation

| Item on the form | Value |
|---|---|
| Name | BRE alert |
| Description | Alert when logs from innorules contain loglevel error |
| Index | `innorules*` |
| Search | A `rex` reads a word from the message, then `where loglevel="ERROR"` |
| Time range | Last 5 minutes |
| Cron | Every 5 minutes |
| Expires | 24 hours |
| Trigger | Number of results is greater than 0, once |
| Throttle | Off |
| Action | PagerDuty |

The `rex` is `.*(.+?\s+){2}(?P<loglevel>\w+)\s+`. It takes one word from the message and names it `loglevel`.

## Result

The file is [29-bre-innorules-alert.tf](29-bre-innorules-alert.tf).

The query uses `contains` on `index` because the Splunk index is `innorules*`. If Grail stores that name under another field, change that line. `loglevel == "ERROR"` matches the `where` clause. A line that only has the letters ERROR in the message body can also match the `contains` on `content`. Check one real message before apply.

There is no 24-hour expiry field on the detector.

## Data flow map

```
innorules index
  loglevel word is ERROR
        |
        v
last 5 minutes
  count greater than 0
        |
        v
CUSTOM_ALERT
  name starts with ALJ_BRE
        |
        v
pagerduty.enabled is 1
  the integration key is inside the collapsed PagerDuty row
```

## Related files

| File | Purpose |
|---|---|
| `29-bre-innorules-alert.tf` | Detector and profile. |
| `0-pic.md` | How the trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What is not on the form. |
| `3-glossary.md` | The words. |
| `29-bre-innorules-alert-follow.txt` | The same notes for a phone. |
| `29.sh` | Copy commands. |

Commands: [29.sh](29.sh)
