# eopt Logs Via Multilogforwarder

## Decision tree

```
Query A (search "eoptsystemapi") → 469 rows → all Splunk's own license and metrics logs → not eopt app logs
Query B (content words) → other apps found:
   cap-portal-system-api, tax-deduction-process-api
   via log.source = multilogforwarder-log-handler-dynatrace
   namespace pattern = <app>-prod-axa-li-jp
Query C (k8s fields contain eopt) → 0
Query D (log.source logforwarders or eopt) → 0
Query E (ingest sources) → oneagent, /api/v2/logs/ingest, aws_firehose, extensions
 conclusion → eopt is not onboarded to the Dynatrace log forwarder
 fix → add namespace eopt-prod-axa-li-jp to multilogforwarder-log-handler-dynatrace
 then → check query 1 returns rows → detector (this answer) starts working
 meanwhile → keep the Splunk alert
```

## Short takeaway

| Question | Answer |
|---|---|
| Are eopt app logs in Dynatrace? | No. Confirmed by all five checks. |
| What were the 469 search hits? | Splunk's own license and metrics logs that mention the eopt S3 path. Not eopt app logs. |
| How do other OpenPaaS apps get in? | Through `multilogforwarder-log-handler-dynatrace` into `/api/v2/logs/ingest`. |
| What needs to change? | Add eopt (namespace `eopt-prod-axa-li-jp`) to that forwarder. |
| Detector status | Rewritten for the forwarder fields. It stays silent until logs arrive. |

## Summary

The checks close the case: eopt app logs never reach Dynatrace. Other OpenPaaS apps such as cap-portal and tax-deduction do, through a log forwarder that labels lines with `k8s.namespace.name` and `k8s.pod.name`. Ask for eopt to be added to that forwarder, then this detector will work without further changes.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| multilogforwarder | The pipeline that copies OpenPaaS pod logs to Splunk and, for some apps, to Dynatrace. | eopt is only on the Splunk side today. |
| `/api/v2/logs/ingest` | Dynatrace's log intake API. | Where the forwarder sends logs. |
| `k8s.namespace.name` | The Kubernetes namespace, a folder for one app's pods. | Stable filter for one app. |
| `k8s.pod.name` | The pod name. | Used to pick backend pods. |
| Splunk internal logs | Splunk's own records of licence use and searches. | They mention "eopt" but are not eopt logs. |

### What each check found

| Check | Result | What it means |
|---|---|---|
| A. `search "eoptsystemapi"`, 24 hours | 469 records | All from `/app/splunk/var/log/splunk/license_usage.log` and `metrics.log` on Splunk servers. They mention the eopt S3 source because Splunk counts licence use per source. |
| B. content words | 8 rows | Splunk servers (WPALJA2196, ceaa20c8, ceaa20c1, ceaa20c6), plus cap-portal-system-api and tax-deduction-process-api pods. No eopt pods. |
| C. k8s fields contain eopt | 0 | No eopt namespace or pod in Dynatrace logs. |
| D. log.source contains logforwarders or eopt | 0 | The forwarder uses a different `log.source` name. |
| E. ingest sources | 6 sources | oneagent 73.5M, /api/v2/logs/ingest 896K, aws_firehose 200K, sql-oracle, sql-server, certificate monitor. |

### Apps already forwarded (from check B)

| k8s.pod.name | k8s.namespace.name | Lines in 1 hour |
|---|---|---|
| cap-portal-system-api-5d655c77f8-h7n8m | capportalsystemapi-prod-axa-li-jp | 1,070 |
| cap-portal-system-api-5d655c77f8-qcbng | capportalsystemapi-prod-axa-li-jp | 1,074 |
| tax-deduction-process-api-dd4f5c786-pffv5 | taxdeduction-prod-axa-li-jp | 1,552 |
| tax-deduction-process-api-dd4f5c786-pll9v | taxdeduction-prod-axa-li-jp | 1,598 |

The namespace pattern `<app>-prod-axa-li-jp` matches the Splunk index names. eopt's Splunk index is `eopt-prod-axa-li-jp`, so that is the expected namespace.

## Result

### Ask the platform team

> eopt pod logs (namespace eopt-prod-axa-li-jp: eoptsystemapi, eoptprocessapi, eoptfrontend) reach Splunk but not Dynatrace. Other apps such as capportalsystemapi-prod-axa-li-jp and taxdeduction-prod-axa-li-jp are already sent through multilogforwarder-log-handler-dynatrace to /api/v2/logs/ingest. Please add eopt-prod-axa-li-jp to the Dynatrace handler so we can migrate the "eopt - OpenPaaS Pod Error (Backend)" alert.

### Detector, ready for the forwarder

```hcl
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_backend" {
  title       = "eopt - OpenPaaS Pod Error (Backend)"
  description = "An eopt backend pod (eoptsystemapi or eoptprocessapi) on OpenPaaS logged a line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
          | filter startsWith(k8s.pod.name, "eoptsystemapi-") or startsWith(k8s.pod.name, "eoptprocessapi-")
          | parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
          | filter level == "ERROR"
          | filter endsWith(log_ts, "Z") and contains(log_ts, "T")
          | fieldsAdd service = if(startsWith(k8s.pod.name, "eoptsystemapi-"), "eoptsystemapi", else:"eoptprocessapi")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "service"
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
        value = "eopt - OpenPaaS Pod Error (Backend): {service}"
      }
      property {
        key   = "event.description"
        value = "eopt backend service {service} logged level ERROR in the last hour. See k8s.pod.name and the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "eopt"
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

### Changes from answer 27

| Part | Answer 27 | Now |
|---|---|---|
| Scope | `coalesce(k8s.pod.name, host.name)` | `k8s.namespace.name == "eopt-prod-axa-li-jp"` |
| Pod filter | on `pod` | on `k8s.pod.name` |
| Why | We did not know the fields | Forwarded apps carry k8s fields and no `host.name` |

Same resource name as answer 27. Apply only this folder.

### Things you can check today

| Check | Why |
|---|---|
| Check query 2 | Lists every namespace the forwarder already sends. Confirms eopt is missing and shows the naming pattern. |
| Check query 3 | Tests the level parse on taxdeduction, which uses the same Java logging. If it shows ERROR, INFO and DEBUG, the parse will work for eopt too. |
| Check query 4 | Raw taxdeduction lines, to compare with the eopt format in Splunk. |
| Check query 1 | Run after the forwarder change. Rows mean the detector is live. |

## Data flow map

```
TODAY
cap-portal, tax-deduction pods → multilogforwarder → Splunk + Dynatrace ✔
eopt pods                      → multilogforwarder → Splunk only ✘

AFTER THE CHANGE
eopt pods (eopt-prod-axa-li-jp)
  → multilogforwarder-log-handler-dynatrace → /api/v2/logs/ingest
  → Grail logs (k8s.namespace.name, k8s.pod.name)
  → detector every minute, last 1 h, level ERROR
  → problem per service (medium) → workflow → email
  → then switch off the Splunk alert
```

## Related files

| File | What it holds |
|---|---|
| `30-eopt-logs-via-multilogforwarder-tf.tf` | Detector for the forwarder fields. |
| `30-eopt-logs-via-multilogforwarder-tf-check.dql` | Four check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Check results. |
| `2-result.md` | Next steps. |
| `3-glossary.md` | Words used. |
| `30.sh` | Commands, one per line. |

## Commands

All commands are in [`30.sh`](./30.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/30-eopt-logs-via-multilogforwarder-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/30-eopt-logs-via-multilogforwarder-tf
git commit -m "eopt backend error detector for multilogforwarder fields"
git push
```
