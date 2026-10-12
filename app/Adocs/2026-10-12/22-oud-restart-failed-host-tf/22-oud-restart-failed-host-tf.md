# OUD Restart Failed Host Alert

## Decision tree

```
Splunk: index=ods sourcetype=oud_service failed
 index=ods → only one host (WPALJA2162.prprivmgmt.intraxa, 100%)
   Dynatrace has no index → filter host.name contains "WPALJA2162"
 sourcetype=oud_service → no Dynatrace match
   check query 2 → which log.source holds the "failed" lines?
     only the service log → keep as is
     OUD errors log also matches with noise → add log.source filter
 Last 24 hours → from:now()-24h
 results > 0 → detector default (any line)
 Severity High + PagerDuty → high, pagerduty.enabled 1
 no rows in check query 1? → host not monitored or named differently → fix first
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | Any line containing "failed" on host WPALJA2162 in the last 24 hours. |
| Why scope by host? | Splunk shows the `ods` index comes from that one host only. |
| Severity | high, because Splunk severity was High. |
| PagerDuty | On (`"1"`). |
| Main risk | "failed" is a common word. Other OUD logs on the host may also contain it. |

## Summary

The Splunk index and sourcetype do not exist in Dynatrace. Because every `ods` event comes from host WPALJA2162, the host is the natural replacement. The query keeps the Splunk 24 hour window and opens a problem on any "failed" line. Run check query 2 to make sure only the OUD service log matches.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| OUD | Oracle Unified Directory, an LDAP directory server. | Apps use it to look up users. If it is down after a restart, logins and lookups fail. |
| `host.name` | The Dynatrace field holding the server name a log line came from. | Replaces Splunk's index here. |
| `log.source` | The file path the log line came from. | Lets you narrow further if "failed" matches too much. |
| Records detector | A DQL query Dynatrace runs every minute that opens a problem when rows return. | Replaces the Splunk scheduled alert. |
| Identity field | Field that decides one problem or many. | `host.name`, so one problem for this server. |

### What the Splunk screens show

| Fact | What it means |
|---|---|
| Alert name OUD restart failed | The alert watches the OUD restart job. |
| Description Optional | Empty. Replaced with a real description. |
| Search `index=ods sourcetype=oud_service failed` | In the ods bucket, service log only, lines with the word failed. |
| Time range Last 24 hours | Each run looks at a full day. |
| Cron looks like `1 4 * * *` | Once a day at 04:01. Please confirm, the photo is blurry. |
| Number of Results greater than 0 | Any matching line fires it. |
| Severity High, PagerDuty, email | It pages. |
| index=ods host field, 1 value | WPALJA2162.prprivmgmt.intraxa holds 100% of 346,670 events. |
| 4 sources, 2 sourcetypes | One is `odu_errorlog` from `/opt/oracle/oud/asinst_1/OUD/logs/errors`. The other is `oud_service`, the one the alert uses. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index=ods` | `contains(host.name, "WPALJA2162", caseSensitive:false)` |
| `sourcetype=oud_service` | No direct match. Optional `log.source` filter after check query 2. |
| `failed` | `contains(content, "failed", caseSensitive:false)` |
| Last 24 hours | `fetch logs, from:now()-24h` |
| Cron daily | Dropped. The detector runs every minute, so you hear about a failure within minutes instead of the next morning. |
| Expires 24 hours | Dropped. The problem closes 24 hours after the last failed line. |
| Results greater than 0 | Detector default. |
| Throttle off | Identity `host.name` keeps one open problem. |
| Severity High | `alert.severity = "high"` |
| PagerDuty | `pagerduty.enabled = "1"` |
| Send email | Workflow. No recipients copied. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "OUD restart failed"
  description = "The Oracle Unified Directory (OUD) service on host WPALJA2162 logged a failed line in the last 24 hours. The OUD restart may not have completed."
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
          | filter contains(content, "failed", caseSensitive:false)
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
        value = "OUD restart failed"
      }
      property {
        key   = "event.description"
        value = "The OUD service on host WPALJA2162 logged a failed line. The OUD restart may not have completed, so directory lookups can fail. See the matching log lines (content) on the problem."
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

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Confirms the host is in Dynatrace and shows its exact `host.name`. |
| Check query 2 | Shows which files on the host contain "failed". If the OUD errors log matches with normal lines, add `\| filter log.source == "<service log path>"`. |
| Check query 3 | Shows how many days would have fired in the last 30. Many days means the filter is too wide. |
| Window choice | 24 hours keeps the problem open for a full day after one failure. If you want it to close sooner, use a shorter window such as `from:now()-1h`. |

## Data flow map

```
OUD restart job on WPALJA2162
  → writes service log (Splunk sourcetype oud_service)
  → Dynatrace Grail logs (host.name = WPALJA2162...)
  → detector every minute, last 24 h
       host WPALJA2162 + "failed" → problem (high)
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → no failed line for 24 h → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `22-oud-restart-failed-host-tf.tf` | Full Terraform. |
| `22-oud-restart-failed-host-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `22.sh` | Commands, one per line. |

## Commands

All commands are in [`22.sh`](./22.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/22-oud-restart-failed-host-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/22-oud-restart-failed-host-tf
git commit -m "OUD restart failed detector scoped to host"
git push
```
