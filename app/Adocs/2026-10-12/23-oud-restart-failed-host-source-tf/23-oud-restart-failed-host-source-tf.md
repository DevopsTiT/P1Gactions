# OUD Restart Failed Host And Source

## Decision tree

```
Splunk: index=ods sourcetype=oud_service failed
 host → only WPALJA2162 → host.name contains "WPALJA2162"
 source → 4 files under /opt/oracle/oud/<instance>/OUD/logs/
   access logs (98.7%) → "failed" = normal failed user logins → skip
   errors logs (asinst_1 + asinst_2) → restart and startup failures → keep
   pattern → startsWith "/opt/oracle/oud/" + endsWith "/OUD/logs/errors"
 not sure oud_service is the errors log?
   Splunk: index=ods sourcetype=oud_service | stats count by source
     errors paths → keep this pattern
     access paths → switch endsWith to "/OUD/logs/access"
 identity → log.source → one problem per OUD instance
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from answer 22? | Added a `log.source` pattern on top of the host filter. |
| Which files match? | `/opt/oracle/oud/asinst_1/OUD/logs/errors` and `/opt/oracle/oud/asinst_2/OUD/logs/errors`. |
| Which files are skipped? | Both `access` logs. |
| Identity | `log.source`, so each OUD instance gets its own problem. |
| Severity | high, PagerDuty on. |

## Summary

The host has four OUD log files. The access logs hold 98.7% of events and record every login, so "failed" there usually means a user typed a wrong password, not a broken restart. The pattern keeps only the errors logs of both OUD instances, which is where startup and restart failures are written.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| OUD instance | One running copy of Oracle Unified Directory. `asinst_1` and `asinst_2` are two instances on the same host. | A restart can fail on one and not the other. |
| access log | OUD's record of every client request, including failed logins. | Huge and full of normal "failed" lines. |
| errors log | OUD's record of server problems, startup and shutdown. | Where a failed restart shows up. |
| `startsWith` | DQL check that text begins with a value. | Locks the path to `/opt/oracle/oud/`. |
| `endsWith` | DQL check that text ends with a value. | Picks the errors file of any instance. |

### Sources from the Splunk screen

| Source | Share | In the pattern |
|---|---|---|
| /opt/oracle/oud/asinst_1/OUD/logs/access | 98.658% | No |
| /opt/oracle/oud/asinst_1/OUD/logs/errors | 1.33% | Yes |
| /opt/oracle/oud/asinst_2/OUD/logs/errors | 0.012% | Yes |
| /opt/oracle/oud/asinst_2/OUD/logs/access | 0% | No |

### One thing to confirm

Splunk has two sourcetypes for these four files, and the alert used `oud_service`. The screen does not show which files belong to `oud_service`. Run this once in Splunk:

```
index=ods sourcetype=oud_service | stats count by source
```

| Result | What to do |
|---|---|
| Errors paths | Keep the Terraform as is. |
| Access paths | Change `endsWith(log.source, "/OUD/logs/errors")` to `"/OUD/logs/access"`, and expect much more noise. |
| Both | Remove the `endsWith` line and keep only `startsWith`. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "OUD restart failed"
  description = "An OUD errors log on host WPALJA2162 logged a failed line in the last 24 hours. The Oracle Unified Directory (OUD) restart may not have completed."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(host.name, "WPALJA2162", caseSensitive:false)
          | filter startsWith(log.source, "/opt/oracle/oud/")
          | filter endsWith(log.source, "/OUD/logs/errors")
          | filter contains(content, "failed", caseSensitive:false)
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
        value = "OUD restart failed"
      }
      property {
        key   = "event.description"
        value = "An OUD errors log on host WPALJA2162 logged a failed line. The OUD restart may not have completed, so directory lookups can fail. See log.source and the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "oud"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
```

### Changes from answer 22

| Part | Answer 22 | Now |
|---|---|---|
| Source filter | None | `startsWith "/opt/oracle/oud/"` and `endsWith "/OUD/logs/errors"` |
| Identity | `host.name` | `log.source`, one problem per instance |
| Description | Mentions the host | Mentions the errors log |

Same resource name as answer 22. Apply only this folder.

## Data flow map

```
OUD restart on WPALJA2162
  ├─ asinst_1 → /opt/oracle/oud/asinst_1/OUD/logs/errors ─┐
  ├─ asinst_2 → /opt/oracle/oud/asinst_2/OUD/logs/errors ─┤ kept
  └─ access logs (logins) ─────────────────────────────── skipped
  → Dynatrace Grail logs
  → detector every minute, last 24 h, "failed"
       one problem per errors file (high)
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → no failed line for 24 h → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `23-oud-restart-failed-host-source-tf.tf` | Full Terraform. |
| `23-oud-restart-failed-host-source-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `23.sh` | Commands, one per line. |

## Commands

All commands are in [`23.sh`](./23.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/23-oud-restart-failed-host-source-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/23-oud-restart-failed-host-source-tf
git commit -m "OUD restart failed detector scoped to host and errors logs"
git push
```
