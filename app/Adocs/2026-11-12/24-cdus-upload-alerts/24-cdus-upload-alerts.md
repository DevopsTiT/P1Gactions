# CDUS Upload Alerts

```
createDocumentAction lines
  pending = started - completed - failed
  more than 5 documents
    ALJ_CDUS Pending uploads

  failed is greater than 0
  more than 1 document
    ALJ_CDUS Failed uploads

prod log group
  Failed to init database
  ETIMEDOUT or ECONNREFUSED
  more than 1 line
    ALJ_CDUS Database error

prod log group
  Failed to create CMX Document
  more than 1 line
    ALJ_CDUS CMX error

six batch log groups
  Error Report or ExitError
  any line
    ALJ_CDUS Batch error
    Splunk suppress is 8 hours

all five titles start with ALJ_CDUS
  one profile
  one email
  pagerduty.enabled is 1
```

| Alert | Fires when |
|---|---|
| Pending uploads | More than 5 documents are still pending |
| Failed uploads | More than 1 document has a failed action |
| Database error | More than 1 database init failure |
| CMX error | More than 1 line says Failed to create CMX Document |
| Batch error | Any Error Report or ExitError in the six batch log groups |

## Summary

Five detectors share the prefix `ALJ_CDUS`, one profile, and one email. Mail goes to `axa.jp_di_new_business@axa.co.jp` and `jp.axa_jp_di_bam@axa.co.jp`. PagerDuty is on every form, so `pagerduty.enabled` is `1`. The integration key is not on the screen.

## Investigation

| Item | What the forms show |
|---|---|
| Index | `document-upload-api` |
| Window | Last 15 minutes |
| Cron | Every 5 minutes |
| Expires | 30 minutes |
| Trigger | Once |
| Throttle | Off, except the batch alert, which suppresses for 8 hours |
| Actions | Add to Triggered Alerts, PagerDuty, and Send email |

Pending means the document has `UPLOAD_STARTED` and does not have `UPLOAD_COMPLETED` or `UPLOAD_FAILED`. Splunk dedups `action` and `cmxDocumentId` before it counts. The alert fires when more than 5 documents are in that state.

Failed uploads use the same actions. A document counts when `UPLOAD_FAILED` is present. The alert fires when more than 1 document is in that state.

The database search is `Failed to init database` with `ETIMEDOUT` or `ECONNREFUSED`, in log groups that start with `/aws/lambda/document-upload-api-prod-`.

The CMX search is `Failed to create CMX Document` in those same prod log groups. The description box on that form shows the pending-upload sentence. The search is the CMX failure text.

The batch log groups are `uploadOcr`, `Worker`, `rpaBatchProcess`, `uploadBankAccountScannedImage`, `uploadBankAccountCSVToIFT`, and `uploadBankAccountCameraImage`.

Database and CMX show email priority High. Priority on the other three forms is below the photo.

## Result

The file is [24-cdus-upload-alerts.tf](24-cdus-upload-alerts.tf).

`aws.log.group` is the same field used for the other Lambda log groups. The parse looks for `action:` and `cmxDocumentId:` the way the Splunk `rex` does. Check one real line before apply. If the document id has extra characters after it, the document count can split one document into two.

The first summarize keeps one row per document and action, which is the `dedup`. Splunk dedups the short action name. If two lines for the same action have different text between `action:` and `cmxDocumentId:`, this query can count both.

There is no 30-minute expiry field on the detector. The problem stays open while the last 15 minutes still match. Davis runs about once a minute. The batch identity keeps one problem open while a matching line is in the window. Splunk also suppresses that alert for 8 hours.

Confirm the second mailbox. It reads `jp.axa_jp_di_bam@axa.co.jp`.

## Data flow map

```
createDocumentAction
  action and cmxDocumentId
        |
        +--> pending documents greater than 5
        |
        +--> failed documents greater than 1

prod Lambda log group
        |
        +--> Failed to init database, with ETIMEDOUT or ECONNREFUSED
        |
        +--> Failed to create CMX Document

six batch log groups
  Error Report or ExitError
        |
        v
ALJ_CDUS profile
  email the two addresses
  pagerduty.enabled is 1
```

## Related files

| File | Purpose |
|---|---|
| `24-cdus-upload-alerts.tf` | Five detectors, one profile, and one email. |
| `0-pic.md` | How the five triggers map. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | What to check before apply. |
| `3-glossary.md` | The words. |
| `24-cdus-upload-alerts-follow.txt` | The same notes for a phone. |
| `24.sh` | Copy commands. |

Commands: [24.sh](24.sh)
