# CCI AWS Batch Timeout Investigation

## What was checked

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` is not a resource in `dynatrace-oss/dynatrace`. |
| Breadcrumb in the editor | `Migration > CW > configuration 2 > cci-fa-comm-calc.tf`. Looks like a Splunk-to-Dynatrace migration draft. |
| Field names | `cron_expression`, `expires`, `trigger_mode`, `throttle_enabled` and `$name$` are Splunk saved-search concepts. |
| Query | Valid DQL filters, but no time range. |
| Log group filter | Two `contains()` checks; the shorter one covers the longer one. |
| Actions | PagerDuty integration key and six email addresses in plain text (not copied). |
| Format used on 2026-10-08 | `dynatrace_davis_anomaly_detectors` with `pagerduty.enabled` set in `event_template`. |

## Line-by-line

| Line(s) | Verdict |
|---|---|
| 1 | Resource type does not exist. |
| 4 | `"Optional"` is a placeholder. |
| 6–11 | Keep the filters; add `from:now()-6m`. |
| 13–17 | Splunk scheduling. Not used by a Records detector. |
| 19–24 | Same as the detector default (rows found means alert). |
| 26 | Replaced by `alertIdentityFields`. |
| 28–32 | Secret in plain text. Remove. |
| 34–46 | Email belongs in the workflow. `$name$` is Splunk token syntax. |
