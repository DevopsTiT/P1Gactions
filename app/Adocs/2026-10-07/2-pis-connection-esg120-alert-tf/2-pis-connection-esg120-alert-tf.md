# PIS Connection ESG120 Alert

## Decision Tree

```
Splunk: index=claims host=CEAA20B8 sourcetype=pis_defaultlog | regex "errorCode": "ESG120", last 5 min, > 0
 → Dynatrace Records detector: any matching line = alert
 check.dql query 1 → PISP2 log in Dynatrace?
   no → ingest /IFDATA/DATA/PC/LOG/PISP2/pisp2.log first
 check.dql query 3 → ESG120 lines with other spacing?
   yes → match "ESG120" more loosely
 Splunk alert has Alert Status Manager with PagerDuty Enable further down? → pagerduty.enabled = "1"
```

## Short Takeaway

| Question | Answer |
|---|---|
| What it watches | The PIS batch log reporting errorCode ESG120 |
| What ESG120 means here | The batch could not connect to OpenPaaS through ESG |
| Host and file | CEAA20B8.prprivmgmt.intraxa, /IFDATA/DATA/PC/LOG/PISP2/pisp2.log |
| Dynatrace type | Records detector, no makeTimeseries |
| Severity | medium (Splunk email priority Normal) |
| PagerDuty | "0": only Send email is visible; check for an Alert Status Manager action |

## Summary

The Splunk alert runs every 5 minutes and emails if the PIS batch log contains `"errorCode": "ESG120"` at least once. The Dynatrace Records detector raises an alert for any matching line, so "more than 0" is built in. It checks every minute, and `host.name` as the identity field keeps it to one open problem per host.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index=claims sourcetype=pis_defaultlog` | `contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/")` |
| `host="CEAA20B8.prprivmgmt.intraxa"` | `matchesValue(host.name, "CEAA20B8*")` |
| `regex _raw = "\"errorCode\"\:\s\"ESG120\""` | `contains(content, "\"errorCode\": \"ESG120\"")` |
| Last 5 minutes, cron */5 | Checks every minute and looks back 2 hours |
| Results > 0 | Any row raises an alert |
| Expires 24 hours | No equivalent |
| For each result | One problem per host (`alertIdentityFields[0] = host.name`) |
| Email, priority Normal | `alert.severity medium`, `pagerduty.enabled 0` |

## About The Regex

| Part | What it means |
|---|---|
| `\"errorCode\"` | The JSON key "errorCode" with its quotes |
| `\:` | A colon |
| `\s` | Exactly one whitespace character, normally a space |
| `\"ESG120\"` | The value "ESG120" with its quotes |

In DQL the same text is `"errorCode": "ESG120"`, with the inner quotes escaped. Check query 3 finds any line that uses a tab or no space instead.

## Query

```
fetch logs
| filter contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/") or matchesValue(host.name, "CEAA20B8*")
| filter contains(content, "\"errorCode\": \"ESG120\"")
```

## Data Flow

```
PIS batch on CEAA20B8 → /IFDATA/DATA/PC/LOG/PISP2/pisp2.log → OneAgent → Grail
  → every minute: any "errorCode": "ESG120" line in the last 2 hours?
      yes → medium problem (PIS) → email through the standard flow
      no rows → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Search screenshot | 729,504 events, one host, one source, one sourcetype |
| Sample lines | Spring Batch job logs (paymentInputSystemBatch, conversionBatchHandlingStep, Job status COMPLETED) |
| Alert screenshot | Last 5 minutes, cron */5, > 0, no throttle, Send email priority Normal |
| Hidden actions | Page may scroll; an Alert Status Manager action was hidden like this on the ESG alert |
| Host name | Read as CEAA20B8; the log path filter also catches it if the name differs |

## Result

| Step | What to do |
|---|---|
| 1 | Scroll the Splunk alert for an Alert Status Manager or PagerDuty action |
| 2 | Run check.dql query 1 to confirm the log is ingested |
| 3 | Run query 2 for past ESG120 lines and query 3 for spacing differences |
| 4 | `terraform plan` shows 1 to add |

## Related Files

| File | Purpose |
|---|---|
| `2-pis-connection-esg120-alert-tf.tf` | Detector Terraform |
| `2-pis-connection-esg120-alert-tf-check.dql` | Check queries |
| `2.sh` | Commands |
