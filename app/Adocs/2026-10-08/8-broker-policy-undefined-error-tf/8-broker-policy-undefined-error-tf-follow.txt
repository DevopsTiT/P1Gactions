# Broker Policy Undefined Error Alert

## Decision tree

```
Splunk: ALJ Broker Policy Maintenance: Cannot read properties of undefined
 Source: index brokerpolicymaintenance-prod-axa-li-jp
  = pods broker-policy-maintenance-web-<hash> (2 pods, JSON logs via S3)
  → filter host.name or k8s.pod.name (check query 1, keep one)
 Match: "Cannot read properties of undefined" (JavaScript null or undefined bug)
 timechart span=1m count | where count > 50
  → any single minute in the last 5 minutes with more than 50 errors
  → summarize count by bin(timestamp, 1m) | filter count > 50 (no makeTimeseries)
 Trigger Once → identity check → 1 problem
 Email, Normal → medium, pagerduty "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the alert catch? | A burst of JavaScript "Cannot read properties of undefined" errors in the broker policy maintenance web app |
| Threshold | More than 50 errors in any one minute, checked over the last 5 minutes |
| Why not every error? | A few of these errors are normal noise; a burst suggests a broken pod or bad release |
| Detector type | Records detector; one-minute buckets with `bin()`, no `makeTimeseries` |
| Severity | medium (Splunk priority Normal) |
| PagerDuty | `"0"` (email only) |
| Recipients | Not copied; route by `app.name` |

## Summary

Splunk counts the error per minute over the last 5 minutes and alerts if any minute has more than 50. The DQL does the same with `summarize ... by bin(timestamp, 1m)` and `filter count > 50`, so a row only appears for a minute above the threshold, and that row opens the problem.

## Splunk query line by line

| Splunk part | What it means | DQL |
|---|---|---|
| `index=brokerpolicymaintenance-prod-axa-li-jp` | Logs of the broker policy maintenance app | Pod filter on `broker-policy-maintenance-web` |
| `*Cannot read properties of undefined*` | JavaScript error: code tried to read a field of something that was empty | `contains(content, "Cannot read properties of undefined", caseSensitive:false)` |
| `timechart span=1m count` | Count matches per minute | `summarize count = count(), by:{ minute = bin(timestamp, 1m) }` |
| `where count > 50` | Keep only minutes with more than 50 | `filter count > 50` |

## Splunk settings to Dynatrace

| Splunk | Dynatrace |
|---|---|
| Cron `*/1` | Detector runs every minute |
| Last 5 minutes | `fetch logs, from:now()-5m` |
| Results > 0 | Any minute above 50 opens a problem |
| Trigger Once | Identity `check`, one problem |
| Expires 24 hours | Problem closes when no minute in the last 5 is above 50 |
| Email, Normal | severity medium, pagerduty `"0"` |

## Terraform

File: `8-broker-policy-undefined-error-tf.tf`

```hcl
resource "dynatrace_davis_anomaly_detectors" "broker_policy_undefined_error" {
  title   = "ALJ Broker Policy Maintenance: Cannot read properties of undefined"
  enabled = true
  source  = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter startsWith(host.name, "broker-policy-maintenance-web") or startsWith(k8s.pod.name, "broker-policy-maintenance-web")
          | filter contains(content, "Cannot read properties of undefined", caseSensitive:false)
          | summarize count = count(), by:{ minute = bin(timestamp, 1m) }
          | filter count > 50
          | fieldsAdd check = "broker_policy_undefined_error"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
      }
    }
  }
  # event_template: CUSTOM_ALERT, severity medium, app.name Broker Policy Maintenance, pagerduty.enabled "0"
}
```

## Data flow

```
broker-policy-maintenance-web pods (2) → JSON logs → S3 forwarder → Dynatrace → Grail
 → detector every minute (last 5 min, per-minute buckets)
   → any minute > 50 errors → 1 problem → medium email → check OCP pod status
   → all minutes ≤ 50 → problem closes
```

## Investigation

| Screenshot | Finding |
|---|---|
| Edit Alert | Search with `timechart span=1m count`, `where count > 50`; `*/1`, Last 5 minutes, > 0, Once; email, Normal |
| Search | 264,810 events per day; 2 hosts, both pods `broker-policy-maintenance-web-5649696b64-*`; JSON with level, message, spanId, traceId; source is S3 forwarder |

## Result

| Step | What to do |
|---|---|
| 1 | Run check query 1 and keep only the field that holds the pod name |
| 2 | Run check query 2 to see how often a minute goes above 50 |
| 3 | `terraform plan`, then apply |

## Related files

| File | Purpose |
|---|---|
| `8-broker-policy-undefined-error-tf.tf` | Detector |
| `8-broker-policy-undefined-error-tf-check.dql` | Check queries |
| `8.sh` | Commands |

## Commands

See `8.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/8-broker-policy-undefined-error-tf"
terraform init
terraform validate
terraform plan
```
