# Control-M Job Health Check

## Decision tree

```
Splunk: Control-M job health check
 Search: index=main host=CEAA204C "RETURN_CD:2" (last 10 min, every 5 min, > 0, email High)
 Does CEAA204C send data to index=main?
  screenshot 2: index=main has only ljpljob01 and wpalja2199 → NO
  → Splunk alert cannot fire today (dead alert?)
 Check where CEAA204C logs went (.spl query 1, check.dql query 1)
  found in another index or in Dynatrace → keep detector, fix filter if needed
  found nowhere                         → ask the Control-M team if the job still runs; maybe retire
 Detector (when data exists): host CEAA204C*, contains "RETURN_CD:2" → 1 problem, high, no PagerDuty
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it for? | Health check of the Control-M data collection job: alert when it ends with return code 2 |
| Search | `host=CEAA204C` and the text `RETURN_CD:2`, last 10 minutes |
| Big finding | `index=main` currently has no data from CEAA204C, so the Splunk alert cannot fire |
| Detector | Records, host `CEAA204C*`, `contains(content, "RETURN_CD:2")` |
| Severity and PagerDuty | high (Splunk priority High), `"0"` (email only) |
| Before apply | Confirm CEAA204C logs exist in Dynatrace (check query 1) |

## Summary

The alert looks for `RETURN_CD:2` from the Control-M server CEAA204C, which means the data collection job ended with an error. The index search shows `index=main` only contains two other hosts, so this alert has probably been silent for a while. The Terraform is ready, but first confirm the logs exist, otherwise the detector will also never fire.

## Splunk to Dynatrace

| Splunk | What it means | Dynatrace |
|---|---|---|
| `index=main` | Default index | Not needed |
| `host="CEAA204C.prprivmgmt.intraxa"` | Control-M server | `matchesValue(host.name, "CEAA204C*")` (case-insensitive) |
| `RETURN_CD:2` | Job return code 2 (error) | `contains(content, "RETURN_CD:2")` |
| Last 10 minutes, every 5 minutes | Overlapping windows | `from:now()-10m`, runs every minute |
| Results > 0, Once | Any match, one email | Any row, identity `check` |
| Email, High | Ops list, high priority | severity high, pagerduty `"0"` |

## Terraform

File: `14-controlm-job-health-check-tf.tf`

```hcl
resource "dynatrace_davis_anomaly_detectors" "controlm_job_health_check" {
  title   = "Control-M job health check"
  enabled = true
  source  = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-10m
          | filter matchesValue(host.name, "CEAA204C*")
          | filter contains(content, "RETURN_CD:2")
          | fields timestamp, host.name, log.source, content
          | fieldsAdd check = "controlm_job_health_check"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
      }
    }
  }
  # event_template: CUSTOM_ALERT, severity high, app.name Control-M, pagerduty.enabled "0"
}
```

## Data flow

```
Control-M data collection job on CEAA204C → log "RETURN_CD:2"
 → (today: not in Splunk index=main) → Splunk alert silent
 → Dynatrace (if OneAgent or forwarder sends it) → detector (10 min) → high problem → email
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 (Edit Alert) | Search above; `*/5`; Last 10 minutes; > 0; Once; no throttle; email ops list; High; subject `[PROD]Splunk Alert: $name$` |
| 2 (index=main) | 323,622 events; host has 2 values: ljpljob01 (99.994%) and wpalja2199 (19 events); no CEAA204C |

## Result

| Step | What to do |
|---|---|
| 1 | Run `.spl` query 1 to find where CEAA204C logs go in Splunk |
| 2 | Run check query 1 to see if CEAA204C logs reach Dynatrace |
| 3 | Run check query 2: if `RETURN_CD:2` shows up on another host, change the host filter |
| 4 | If no data anywhere, ask the Control-M team whether this job still exists before migrating |

## Related files

| File | Purpose |
|---|---|
| `14-controlm-job-health-check-tf.tf` | Detector |
| `14-controlm-job-health-check-tf-check.dql` | Dynatrace checks |
| `14-controlm-job-health-check-tf.spl` | Splunk checks |
| `14.sh` | Commands |

## Commands

See `14.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/14-controlm-job-health-check-tf"
terraform init
terraform validate
terraform plan
```
