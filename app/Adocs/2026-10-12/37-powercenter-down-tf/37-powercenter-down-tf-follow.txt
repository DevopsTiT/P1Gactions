# Powercenter Down Alert

## Decision tree

```
Splunk: index="powercenter" ISP_MASTER_ELECT_LOCK
 index → no Dynatrace match → content filter only
   want a host filter too? → check query 1 → add host.name
 Last 1 minute, every minute → from:now()-1m
 more than 3 results → summarize count() → filter lock_events > 3
 email Normal → medium, PagerDuty 0
 same search as answers 35 and 36? → yes → consider keeping only one
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | More than 3 `ISP_MASTER_ELECT_LOCK` lines in 1 minute. |
| Threshold | Above 0, so the query uses `summarize` and `filter lock_events > 3`. |
| Identity | `scope`, one open problem. |
| Severity | medium, PagerDuty off (email Normal). |
| Overlap | Same search as answers 35 and 36, only stricter. |

## Summary

This is the third PowerCenter alert built on the same message code. It counts lines in the last minute and fires above 3. Answer 35 fires above 2 with the same window, and answer 36 fires on any line in 15 minutes, so whenever this alert fires, both of those have already fired.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| PowerCenter | Informatica's batch data integration (ETL) server. | The system being monitored. |
| `ISP_MASTER_ELECT_LOCK` | Message logged when a node tries to take the master election lock. | A burst of them means the domain lost its master. |
| Threshold | The number that must be passed, here 3. | Needs `summarize` to get a count. |
| Identity field | Field deciding one problem or many. | `scope` gives one open problem. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| Alert `Powercenter down` | `title` kept. |
| Description | Kept, with the condition added. |
| `index="powercenter"` | Not needed. Optional host filter after check query 1. |
| `ISP_MASTER_ELECT_LOCK` | `contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)` |
| Last 1 minute | `fetch logs, from:now()-1m`. |
| Cron `*/1 * * * *` | Dropped. Detector runs every minute. |
| Expires 24 hours | Dropped. |
| Number of results greater than 3 | `summarize lock_events = count()` then `filter lock_events > 3`. |
| Trigger once, throttle off | Identity `scope`. |
| Send email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`. Recipients not copied. |
| Subject `Splunk Alert Middleware Alert $name$` | Dropped. Splunk token. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "powercenter_down" {
  title       = "Powercenter down"
  description = "This alert will be created when powercenter is down. Fires when more than 3 ISP_MASTER_ELECT_LOCK lines are logged in 1 minute."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1m
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)
          | summarize lock_events = count(),
                      hosts = collectDistinct(host.name),
                      sample = takeFirst(content)
          | filter lock_events > 3
          | fieldsAdd scope = "powercenter-down"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "Powercenter down"
      }
      property {
        key   = "event.description"
        value = "More than 3 ISP_MASTER_ELECT_LOCK lines in 1 minute. PowerCenter may be down. See lock_events, hosts and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
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

### The three PowerCenter alerts

| Setting | 35 Service Down | 36 Process Stop | 37 Powercenter down |
|---|---|---|---|
| Window | 1 minute | 15 minutes | 1 minute |
| Threshold | More than 2 | More than 0 | More than 3 |
| Severity | medium | high | medium |
| Identity | `scope` | `host.name` | `scope` |

One PowerCenter incident can open three problems. The Splunk alerts went to different mail groups, which is likely why there are three. In Dynatrace, one detector and a workflow that emails every group is cleaner. Keep all three only if each team must get its own problem.

## Data flow map

```
PowerCenter loses its domain master
  → nodes log ISP_MASTER_ELECT_LOCK
  → Dynatrace Grail logs
  → detector every minute, last 1 min, count lines
       more than 3 → problem (medium), one open problem
  → workflow: pagerduty.enabled = "0" → email
  → 3 or fewer → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `37-powercenter-down-tf.tf` | Full Terraform. |
| `37-powercenter-down-tf-check.dql` | Two check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `37.sh` | Commands, one per line. |

## Commands

All commands are in [`37.sh`](./37.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/37-powercenter-down-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/37-powercenter-down-tf
git commit -m "Powercenter down detector"
git push
```
