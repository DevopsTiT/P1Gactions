# OUD Restart Failed Terraform Only

## Decision tree

```
Need only the Terraform file, no workflow
 → one resource: dynatrace_davis_anomaly_detectors "oud_restart_failed"
 → problem opens → standard SILVA + PagerDuty workflow still picks it up (it watches all problems)
 → no separate email (the email workflow from seq 25 is dropped)
 before apply → replace "*oud_service*" with the real log.source (seq 25 check.dql query 1)
```

## Short takeaway

| Question | Answer |
|---|---|
| What's in the file? | One detector resource, nothing else |
| Still pages? | Yes, through the standard SILVA and PagerDuty workflow, because it triggers on every new problem |
| Still emails? | Not from this file. The Splunk "Send email" action is not covered unless your standard flow or a problem notification sends email |
| Must change before apply | The `log.source` filter |

## Summary

The file below is just the detector from seq 25, without the email workflow. It checks the OUD service log every minute and opens a High problem on the OUD host when "failed" appears. Paging still works through your existing standard workflow.

## Terraform file

```hcl
resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "Prod_OUD_RestartFailed_High"
  description = "The OUD (Oracle Unified Directory) service restart logged 'failed'. Directory lookups and logins that depend on OUD may fail."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*oud_service*")
          | filter matchesPhrase(content, "failed")
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
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
        value = "Prod_OUD_RestartFailed_High"
      }
      property {
        key   = "event.description"
        value = "OUD service restart failed on {dims:dt.entity.host}. Check the oud_service log on that host."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "dt.source_entity"
        value = "{dims:dt.entity.host}"
      }
    }
  }

  execution_settings {}
}
```

## Before you apply

| Item | What to do |
|---|---|
| `"*oud_service*"` | Replace with the real `log.source` from seq 25 `check.dql` query 1 |
| `dt.source_entity` | Confirm on a test run that the host fills in; if not, remove that property |
| Email | Decide whether the standard flow or a problem notification covers the Splunk email |

## Data flow

```
OUD host log → Grail → detector every minute ("failed" > 0 per host)
  → problem "Prod_OUD_RestartFailed_High" on the host
  → standard SILVA + PagerDuty workflow
```

## Investigation

| Checked | Finding |
|---|---|
| Request | Terraform only, no workflow |
| Seq 25 main.tf | Detector plus email workflow; the workflow is removed here |
| Standard flow | Triggers on all new problems, including custom ones |

## Result

Use `26-oud-restart-failed-terraform-only.tf`: one detector resource. Fix the `log.source` filter before applying.

## Related files

| File | Purpose |
|---|---|
| `26-oud-restart-failed-terraform-only.tf` | The detector only |
| `2026-10-05/25-oud-restart-failed-alert-transform/` | Full version with check queries |
| `26.sh` | Validate, plan, mirror and git one-liners |

## Commands

See `26.sh` (not run).
