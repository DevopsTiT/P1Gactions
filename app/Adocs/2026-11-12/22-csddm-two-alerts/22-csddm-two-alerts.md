# CSDDM Two Alerts

```
Claims API call failed
  prod Lambda log group
  last 24 hours
  count greater than 0
    title ALJ_CLAIMS
    mail honlun.chan and masaya.okuno
    third address is cut off

Document management error
  event contains error
  message does not contain error
  message does not contain elivery not possible
  last 5 minutes
    title ALJ_CSDDM
    mail alj_jp_di_csdigitaldocument@axa.co.jp
    Splunk suppress is 1 hour
```

| Alert | Window | Fires when | Prefix |
|---|---|---|---|
| Claims API fails | Last 24 hours | Count is greater than 0 | `ALJ_CLAIMS` |
| Document management error | Last 5 minutes | Count is greater than 0 | `ALJ_CSDDM` |

## Summary

The Claims alert looks for `claims api call failed` in the prod Lambda log group. The error alert looks for the word `error` in the event, then drops lines whose message contains `error` or `elivery not possible`. The titles use different prefixes, so each mailbox stays with its own alert.

## Investigation

| Item | Claims API | Document management error |
|---|---|---|
| Name | [CSDDM] Send alert email when Claims API fails | CS Digital Document Management Error alerts |
| Index | `cs-digital-document-management` | `cs-digital-document-management` |
| Extra search | Log group `/aws/lambda/cs-digital-document-management-prod-*` and message `claims api call failed` | Event contains `error`. Message does not contain `error`. Message does not contain `elivery not possible`. |
| Schedule | Every day at 10:00 | Every 5 minutes |
| Time range | Not shown | Last 5 minutes |
| Expires | 24 hours | 24 hours |
| Throttle | Off | On, for 1 hour |
| To | `honlun.chan@axa.co.jp` and `masaya.okuno@axa.co.jp` | `alj_jp_di_csdigitaldocument@axa.co.jp` |
| Priority | Normal | Normal |

The Claims To box continues after `alj_jp_di_inoid`. That third address is cut off, so it is not in the file.

The error search shows `*elivery not possible*`. The star can hide a D, so this also matches `delivery not possible`.

## Result

The file is [22-csddm-two-alerts.tf](22-csddm-two-alerts.tf).

The Claims form has no Time Range. The query uses the last 24 hours because the alert runs once a day. Davis runs about once a minute, so the problem opens when the first matching line is in the window. It does not wait until 10:00.

`aws.log.group` is the same field used for the other Lambda log groups. The `prod-*` wildcard is the stable prefix `cs-digital-document-management-prod-`.

The error alert keeps `index == "cs-digital-document-management"`. The word `error` by itself would match other systems. If Grail stores the index under another field, change that line.

Splunk suppresses the error alert for 1 hour. The identity keeps one problem open while the count stays above 0. There is no 24-hour expiry field on either detector. `pagerduty.enabled` is `0` on both.

## Data flow map

```
prod Lambda log group
  claims api call failed
        |
        v
last 24 hours, count greater than 0
        |
        v
ALJ_CLAIMS
  honlun.chan@axa.co.jp
  masaya.okuno@axa.co.jp

index cs-digital-document-management
  event contains error
  message does not contain error
  message does not contain elivery not possible
        |
        v
last 5 minutes, count greater than 0
        |
        v
ALJ_CSDDM
  alj_jp_di_csdigitaldocument@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `22-csddm-two-alerts.tf` | Both detectors, profiles, and emails. |
| `0-pic.md` | How each trigger maps. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | What is still cut off. |
| `3-glossary.md` | The words. |
| `22-csddm-two-alerts-follow.txt` | The same notes for a phone. |
| `22.sh` | Copy commands. |

Commands: [22.sh](22.sh)
