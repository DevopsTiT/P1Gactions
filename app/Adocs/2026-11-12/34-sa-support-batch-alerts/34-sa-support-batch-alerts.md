# SA Support Batch Alerts

```
index sa-support-batches
  last 6 minutes, count greater than 0
    the word error
    Task timed out
    title ALJ_SABATCH
    commonins list and maki.kawauchi
  last 24 hours, count less than 2
    importFileHandler :: runner :
    or importSagaFundGroup
    or started
    title ALJ_ANNUITY
    annuity payments mailbox
```

| Prefix | Who gets the mail |
|---|---|
| ALJ_SABATCH | The commonins address and Maki Kawauchi |
| ALJ_ANNUITY | `axa.jp_di_bap_annuitypayments@axa.co.jp` |

## Summary

Three detectors on index `sa-support-batches`. The error alert and the timeout alert share `ALJ_SABATCH`. The file-import alert uses `ALJ_ANNUITY` because it mails a different list. That alert fires when fewer than 2 matching lines appear in 24 hours.

## Investigation

| Item | Error | File import | Task timeout |
|---|---|---|---|
| Search | The word `error` | Three message phrases joined by OR | `Task timed out` |
| Window | Last 6 minutes | Last 24 hours | Last 6 minutes |
| Schedule | Every 5 minutes | 08:30 on Monday through Friday | Every 5 minutes |
| Trigger | Count greater than 0, once | Count less than 2, once | Count greater than 0, once |
| Throttle | Off | Off | Off |
| Expires | 24 hours | 24 hours | 24 hours |
| Priority | Normal | Normal | Normal |

The gray "every day at 6PM" line is Splunk's example. The file-import cron is `30 8 * * 1-5`, which is 08:30 on weekdays.

The error form and the timeout form show the same To box. The visible text reads `alj_jp_di_bap_commonins@ound2@axa.co.jp` and `maki.kawauchi.ose@axa.co.jp`. The first value has two `@` signs, so it is not a finished address. Confirm both on the form before apply.

The file-import To line wraps after `@`. The joined address is `axa.jp_di_bap_annuitypayments@axa.co.jp`. Confirm that join.

The file-import search is any of these phrases:

| Phrase | What it matches |
|---|---|
| `importFileHandler :: runner :` | The import handler line |
| `importSagaFundGroup` | The saga fund group line |
| `started` | Any line in this index that contains that word |

Splunk looked at the `message` field. The query uses `content` until the Dynatrace field name is known.

## Result

The file is [34-sa-support-batch-alerts.tf](34-sa-support-batch-alerts.tf).

`index == "sa-support-batches"` stays in every query. The word `error` and the word `started` would match far too much without it. The field name `index` may differ in Dynatrace.

`ALJ_ANNUITY` does not start with `ALJ_SABATCH`, so the annuity mailbox does not also receive the error and timeout alerts.

The file-import detector returns a row when the count is 0 or 1. That matches "is less than 2". If the index field name is wrong, the count stays 0 and this alert fires all the time. If `started` matches too many ordinary lines, the count stays at 2 or more and the alert stays quiet. Check both on a real day of logs.

Davis runs about once a minute. It does not wait for 08:30, and it also evaluates Saturday and Sunday. The Splunk cron does not.

Event severity stays `medium`. Profile severity level stays `ERROR`. Email priority Normal stays on the Splunk form. `pagerduty.enabled` is `0`. The 24-hour expiry has no detector field.

One `alert_key` keeps one open problem while the condition stays true. Throttle is off. A new mail is not sent every minute. If the problem closes and the condition is still true, Dynatrace can open a new problem.

## Data flow map

```
sa-support-batches
        |
        +--> error, or Task timed out
        |      last 6 minutes
        |      count greater than 0
        |      ALJ_SABATCH
        |
        +--> import lines
               last 24 hours
               count less than 2
               ALJ_ANNUITY
               annuity payments
```

## Related files

| File | Purpose |
|---|---|
| `34-sa-support-batch-alerts.tf` | Three detectors, two profiles, and two emails. |
| `0-pic.md` | How the three alerts split. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | Why the file-import alert is separate. |
| `3-glossary.md` | The words. |
| `34-sa-support-batch-alerts-follow.txt` | The same notes for a phone. |
| `34.sh` | Copy commands. |

Commands: [34.sh](34.sh)
