# Application Monitoring URL Confirm

## Decision tree

```
Application Monitoring Alert - URL (shown again)
 search same as seq 44/45? → yes (sourcetype="text:jenkins", [HTTP Monitor], status→responsecode)
 PagerDuty? → Disable → pagerduty "0"
 Alert Status Manager, Production? → yes → severity high
 text:jenkins exists in jenkins_console? → no (seq 45) → Splunk alert is silent
 → no tf change: reuse seq 45 tf (enabled = false)
 → same resource name application_monitoring_alert_url → apply from ONE folder only
 ready to enable? → run check.dql → few NG jobs and format OK → set enabled = true
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same "Application Monitoring Alert - URL" as seq 44 and 45. |
| Anything changed in the screenshots? | No. The search, schedule and actions all match. |
| Does it work in Splunk? | No. The sourcetype `text:jenkins` does not exist, so it finds nothing. |
| Which tf to use? | The seq 45 tf, unchanged, with `enabled = false`. |
| Severity and PagerDuty | high and "0" |

## Summary

These screenshots show the same URL alert again, with nothing new. The tf is the seq 45 version: one problem per application and job when the HTTP Monitor returns non-200 at least twice in 15 minutes with no 200. It ships disabled because Splunk has been silent, and Dynatrace may surface old failures that nobody has seen.

## Investigation

| What I checked | What I found |
|---|---|
| Search text | It matches seq 45 line by line. |
| `rename status as responsecode` | Handled by the `parse ... 'status=' INT:responsecode` line. |
| `streamstats count ... where index<=2` | Splunk looks at the newest 2 runs per job. The Dynatrace version needs at least 2 fails and no OK within 15 minutes. |
| `search status="NG" OR (status="OK" AND prev_status="NG")` | Splunk mails on NG and on recovery. Dynatrace opens a problem and closes it automatically. |
| Schedule | `*/1`, last 15 minutes, expires 24 hours, for each result, no throttle. |
| Action | Alert Status Manager, Production email, PagerDuty Disable. I did not copy the recipients. |
| Sourcetype | `text:jenkins` is missing (seq 45 finding), so the alert is dead. |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_url` (same as seq 44/45, an in-place update) |
| enabled | false |
| Identity | application, name |
| Severity | high |
| pagerduty.enabled | "0" |
| Next step | Run `49-application-monitoring-url-confirm-check.dql`, then enable it if the NG list is short and sane |

## Data flow map

```
Jenkins HTTP Monitor job (ceaa2099) → console "[HTTP Monitor] ... status=<code>"
  → Dynatrace logs (no sourcetype filter)
  → name from log.source → lookup /lookups/jenkins/configuration (application)
  → per application+name in 15m: fails >= 2 and oks == 0
  → problem (high, pagerduty 0) → closes when a 200 returns
Splunk: sourcetype=text:jenkins → 0 events → never fires
```

## Related files

| File | What it is |
|---|---|
| `49-application-monitoring-url-confirm.tf` | Copy of the seq 45 tf, unchanged |
| `49-application-monitoring-url-confirm-check.dql` | Checks before enabling |
| `49-application-monitoring-url-confirm.spl` | Sourcetype proof and scheduler history |
| `49.sh` | Commands |

## Commands

These are in `49.sh`. Nothing has been run. Apply from one folder only (seq 45 or seq 49, not both).

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/49-application-monitoring-url-confirm"
terraform init
terraform validate
terraform plan
terraform apply
```
