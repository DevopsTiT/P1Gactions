# PowerCenter Process Stop Alert

## Decision tree

```
Splunk: index="powercenter" ISP_MASTER_ELECT_LOCK
 index → no Dynatrace match → content filter only
   want a host filter too? → check query 1 → add host.name
 Last 15 minutes, every minute → from:now()-15m
 more than 0 results → no summarize, any line fires
 email High, no PagerDuty → high, PagerDuty 0
 identity → host.name → one problem per PowerCenter node
 already have answer 35? → same search → this one fires first, 35 is the burst version
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | Any `ISP_MASTER_ELECT_LOCK` line in the last 15 minutes. |
| What does that mean? | A PowerCenter domain process stopped and nodes are electing a new master. |
| Threshold | None. One line is enough, so no `summarize`. |
| Identity | `host.name`, one problem per node. |
| Severity | high, PagerDuty off (email High only). |
| Overlap | Same search as answer 35. This alert always fires when 35 does. |

## Summary

The search is the same as answer 35, but the rules are looser. The window is 15 minutes and any single match fires. Because the threshold is 0, the query is just fetch and filter, and the detector turns each host into its own problem.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| PowerCenter | Informatica's batch data integration (ETL) server. | The system being monitored. |
| `ISP_MASTER_ELECT_LOCK` | Message logged when a node tries to take the master election lock. | It shows up when a domain process stops. |
| Results greater than 0 | Fire on any match. | Dynatrace detectors already do this on plain rows. |
| Identity field | Field deciding one problem or many. | `host.name` separates nodes. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| Alert `PowerCenter-ProcessStop` | `title` kept. |
| Description "Optional" | Replaced with a real description. |
| `index="powercenter"` | Not needed. Optional host filter after check query 1. |
| `ISP_MASTER_ELECT_LOCK` | `contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)` |
| Last 15 minutes | `fetch logs, from:now()-15m`. |
| Cron every minute | Dropped. Detector runs every minute. |
| Expires 24 hours | Dropped. |
| Number of results greater than 0 | Detector default. No `summarize`. |
| Trigger once, throttle off | Identity `host.name`. |
| Send email, High | `alert.severity = "high"`, `pagerduty.enabled = "0"`. Recipients not copied. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "powercenter_process_stop" {
  title       = "PowerCenter-ProcessStop"
  description = "Fires when any ISP_MASTER_ELECT_LOCK line is logged in the last 15 minutes. This means a PowerCenter domain process stopped and the nodes are electing a new master."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "host.name"
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
        value = "PowerCenter process stop"
      }
      property {
        key   = "event.description"
        value = "ISP_MASTER_ELECT_LOCK logged in the last 15 minutes. A PowerCenter domain process stopped or failed over. Check the PowerCenter services on the host in this problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "powercenter"
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

### Answer 35 and answer 36 side by side

| Setting | Answer 35 Service Down | Answer 36 Process Stop |
|---|---|---|
| Window | 1 minute | 15 minutes |
| Threshold | More than 2 | More than 0 |
| Severity | medium | high |
| Identity | `scope` (one problem) | `host.name` (per node) |

Process Stop catches everything Service Down catches, and more. Keeping both gives two problems for one incident. If the team agrees, keep only Process Stop.

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Finds the PowerCenter hosts and log files. Add a host filter if you want it as a reference. |
| Check query 2 | Shows how often a 15 minute window has a match, so you know how noisy this will be. |
| PagerDuty | Splunk only sent email. If High should page someone, set `pagerduty.enabled = "1"`. |

## Data flow map

```
PowerCenter domain process stops
  → node logs ISP_MASTER_ELECT_LOCK
  → Dynatrace Grail logs
  → detector every minute, last 15 min, any line
       match → problem (high), one per host.name
  → workflow: pagerduty.enabled = "0" → email
  → no line for 15 min → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `36-powercenter-process-stop-tf.tf` | Full Terraform. |
| `36-powercenter-process-stop-tf-check.dql` | Two check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `36.sh` | Commands, one per line. |

## Commands

All commands are in [`36.sh`](./36.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/36-powercenter-process-stop-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/36-powercenter-process-stop-tf
git commit -m "PowerCenter process stop detector"
git push
```
