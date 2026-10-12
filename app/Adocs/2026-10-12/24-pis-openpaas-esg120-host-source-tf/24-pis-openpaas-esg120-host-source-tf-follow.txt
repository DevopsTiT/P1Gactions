# PIS OpenPaaS ESG120 Alert

## Decision tree

```
Splunk: index=claims host=CEAA20B8 sourcetype=pis_defaultlog | regex "errorCode": "ESG120"
 index + sourcetype → no Dynatrace match
   host → host.name contains "CEAA20B8"
   source → log.source contains "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log"
 regex errorCode ESG120 → contains "errorCode" and contains "ESG120"
 Last 5 minutes → from:now()-5m
 results > 0 → any line
 email only, Normal → medium, PagerDuty 0
 host name unclear (CEAA2088 or CEAA20B8)? → check query 1
 zero rows but Splunk has 18? → JSON split over lines → check query 3
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | `"errorCode": "ESG120"` ("Routing failed") in pisp2.log on host CEAA20B8. |
| Scope | Host and source, as on the Splunk event. |
| Window | 5 minutes, same as Splunk. |
| Severity | medium, because the only action was a Normal email. |
| PagerDuty | Off (`"0"`). |
| How often? | Splunk matched 18 events in about a month. |

## Summary

The Splunk alert watches the PIS batch log for error code ESG120, which means the batch could not route a request to OpenPaaS. The Dynatrace detector uses the same host and source file as references, and replaces the Splunk regex with two simple `contains` checks.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| PIS | The claims batch system writing `pisp2.log`. | The source of the error. |
| OpenPaaS | The platform the batch sends requests to. | ESG120 means the batch could not reach it. |
| ESG120 | Error code with message "Routing failed". | The single thing this alert looks for. |
| `regex _raw` | Splunk command that keeps events whose raw text matches a pattern. | Replaced by `contains` in DQL. |
| `host.name` | Dynatrace field with the server name. | Reference 1: CEAA20B8. |
| `log.source` | Dynatrace field with the file path. | Reference 2: pisp2.log. |

### What the Splunk screens show

| Fact | What it means |
|---|---|
| Alert PIS Connection issue (Batch->OpenPaaS) Alert | Title kept. |
| Description Optional | Replaced with a real description. |
| Search host | Alert screen reads `CEAA2088`, event list reads `CEAA20B8`. The event list is clearer, so the Terraform uses `CEAA20B8`. |
| Source | `/IFDATA/DATA/PC/LOG/PISP2/pisp2.log` (1 value). |
| Regex `"errorCode":\s"ESG120"` | errorCode, colon, one space, "ESG120". |
| Event message | `"errorMessage": "Routing failed"` |
| Time range Last 5 minutes, cron every 5 minutes | Checks the last 5 minutes. |
| Number of results greater than 0 | Any match fires. |
| Action | Send email only, priority Normal. Recipient not copied. |
| Matches | 18 of 2,106,626 events. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index=claims` | Not needed. Host and source already narrow it. |
| `host="CEAA20B8.prprivmgmt.intraxa"` | `contains(host.name, "CEAA20B8", caseSensitive:false)` |
| `sourcetype=pis_defaultlog` | `contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log", caseSensitive:false)` |
| `regex _raw = "\"errorCode\":\s\"ESG120\""` | `contains(content, "errorCode") and contains(content, "ESG120")`. No escaping needed, and spacing differences do not break it. |
| Last 5 minutes | `fetch logs, from:now()-5m` |
| Cron every 5 minutes | Dropped. The detector runs every minute. |
| Expires 24 hours | Dropped. |
| Results greater than 0 | Detector default. |
| Email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`, workflow sends email. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "pis_connection_issue_batch_openpaas" {
  title       = "PIS Connection issue (Batch->OpenPaaS) Alert"
  description = "The PIS batch on host CEAA20B8 logged errorCode ESG120 (Routing failed) in pisp2.log in the last 5 minutes. The batch could not reach OpenPaaS."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(host.name, "CEAA20B8", caseSensitive:false)
          | filter contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log", caseSensitive:false)
          | filter contains(content, "errorCode") and contains(content, "ESG120")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "log.source"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "PIS Connection issue (Batch->OpenPaaS)"
      }
      property {
        key   = "event.description"
        value = "PIS batch on CEAA20B8 logged errorCode ESG120 (Routing failed). Requests from the batch to OpenPaaS are not getting through. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "pis"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
```

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Confirms whether the host is CEAA20B8 or CEAA2088 and shows the exact `log.source` path. |
| Check query 2 | Should return about the same 18 events Splunk found. |
| Check query 3 | Splunk shows each event as 7 lines of JSON. If Dynatrace stores each line separately, "errorCode" and "ESG120" are still on the same line, so the filter works. If not, keep only `contains(content, "ESG120")`. |

## Data flow map

```
PIS batch on CEAA20B8 calls OpenPaaS
  → routing fails → writes {"errorCode": "ESG120", "errorMessage": "Routing failed"}
  → /IFDATA/DATA/PC/LOG/PISP2/pisp2.log
  → Dynatrace Grail logs (host.name, log.source)
  → detector every minute, last 5 min
       host + source + ESG120 → problem (medium)
  → workflow: pagerduty.enabled = "0" → email
  → no ESG120 for 5 min → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `24-pis-openpaas-esg120-host-source-tf.tf` | Full Terraform. |
| `24-pis-openpaas-esg120-host-source-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `24.sh` | Commands, one per line. |

## Commands

All commands are in [`24.sh`](./24.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/24-pis-openpaas-esg120-host-source-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/24-pis-openpaas-esg120-host-source-tf
git commit -m "PIS OpenPaaS ESG120 detector scoped to host and source"
git push
```
