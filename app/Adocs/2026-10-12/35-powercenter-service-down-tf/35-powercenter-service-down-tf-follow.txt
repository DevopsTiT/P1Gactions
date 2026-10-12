# PowerCenter Service Down Alert

## Decision tree

```
Splunk: index="powercenter" ISP_MASTER_ELECT_LOCK
 index → no Dynatrace match → content filter only (message code is specific)
   want a host filter too? → check query 1 → add host.name
 Last 1 minute, every minute → from:now()-1m
 more than 2 results → summarize count() → filter lock_events > 2
 email Normal → medium, PagerDuty 0
 check query 3 empty? → PowerCenter logs not in Dynatrace → fix ingest first
 alerts never fire? → check query 2 → late logs → widen to 2 min
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | More than 2 `ISP_MASTER_ELECT_LOCK` lines in 1 minute. |
| What does that mean? | PowerCenter nodes are fighting over who is the master, which happens when the domain service goes down or fails over. |
| Scope | Content only. Add a host filter after check query 1. |
| Severity | medium, PagerDuty off (email Normal). |
| Main risk | PowerCenter logs may not be in Dynatrace yet. |

## Summary

The Splunk alert counts a PowerCenter message code over one minute and fires above 2. In Dynatrace that needs a count and a threshold, so the query uses `summarize count()` and `filter lock_events > 2`. The message code is unique enough to work without the Splunk index.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| PowerCenter | Informatica's batch data integration (ETL) server. | The system being monitored. |
| Domain | A group of PowerCenter nodes managed together. One node is the master. | If the master goes, services stop. |
| `ISP_MASTER_ELECT_LOCK` | Message logged when a node tries to take the master election lock. | Many of these in a short time point to the master being lost. |
| Threshold | The number that must be passed, here 2. | Needs `summarize` because plain rows have no count. |
| Identity field | Field deciding one problem or many. | `scope` gives one open problem. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| Alert `0031_MWSP-PowerCenter-Service-Down-Alert` | `title` kept. |
| Description | Kept, with the condition added. |
| `index="powercenter"` | Not needed. Optional host filter after check query 1. |
| `ISP_MASTER_ELECT_LOCK` | `contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)` |
| Last 1 minute, cron every minute | `fetch logs, from:now()-1m`. |
| Expires 24 hours | Dropped. |
| Number of results greater than 2 | `summarize lock_events = count()` then `filter lock_events > 2`. |
| Throttle off | Identity `scope`. |
| Send email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`. Workflow sends email. Recipients not copied. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "mwsp_powercenter_service_down" {
  title       = "0031_MWSP-PowerCenter-Service-Down-Alert"
  description = "This alert will trigger after detecting the service down from Powercenter server. Fires when more than 2 ISP_MASTER_ELECT_LOCK lines are logged in 1 minute."
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
          | filter lock_events > 2
          | fieldsAdd scope = "powercenter-service"
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
        value = "MWSP PowerCenter service down"
      }
      property {
        key   = "event.description"
        value = "More than 2 ISP_MASTER_ELECT_LOCK lines in 1 minute. The PowerCenter domain service may be down or failing over. See lock_events, hosts and sample on the problem."
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

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Shows which hosts and files log the message. Add `\| filter contains(host.name, "<host>")` if you want the host as a reference. |
| Check query 2 | Shows minutes with more than 2 lines over 30 days. Confirms the threshold fires when expected. |
| Check query 3 | Confirms PowerCenter logs reach Dynatrace at all. If empty, fix ingest first. |
| Late logs | If logs arrive late, a 1 minute window can miss them. Use `from:now()-2m` and raise the threshold to match. |
| Severity | The name says "Service Down" but the email was Normal priority. If the team treats it as urgent, set `high` and `pagerduty.enabled = "1"`. |

## Data flow map

```
PowerCenter domain node loses master
  → nodes log ISP_MASTER_ELECT_LOCK repeatedly
  → Dynatrace Grail logs
  → detector every minute, last 1 min, count lines
       more than 2 → problem (medium), one open problem
  → workflow: pagerduty.enabled = "0" → email
  → 2 or fewer → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `35-powercenter-service-down-tf.tf` | Full Terraform. |
| `35-powercenter-service-down-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `35.sh` | Commands, one per line. |

## Commands

All commands are in [`35.sh`](./35.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/35-powercenter-service-down-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/35-powercenter-service-down-tf
git commit -m "PowerCenter service down detector"
git push
```
