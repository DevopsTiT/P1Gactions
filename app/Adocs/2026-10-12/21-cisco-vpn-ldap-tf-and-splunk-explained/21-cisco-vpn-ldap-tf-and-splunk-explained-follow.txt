# Cisco VPN LDAP Alert Explained

## Decision tree

```
Splunk screen (old)                         Dynatrace Terraform (new)
 Alert name + Description            →  title + description
 Search (index, sourcetype, phrase)  →  query.expression (log.source + content)
 Time Range "Last 1 minute"          →  fetch logs, from:now()-5m
 Cron "*/1 * * * *"                  →  not needed, detector runs every minute
 Expires 24 hours                    →  not needed, problem closes itself
 Number of Results > 3               →  dropped, any line = problem
 Trigger Once / For each result      →  alertIdentityFields (log.source)
 Throttle off                        →  identity field keeps one open problem
 Triggered Alert, Critical           →  alert.severity "high"
 PagerDuty                           →  pagerduty.enabled "1" → workflow pages
 Send email                          →  workflow sends email
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk screen do? | Every minute, it searches the last 1 minute of Cisco firewall logs for "Windows_LDAP as FAILED". If more than 3 lines are found, it raises a Critical alert, pages PagerDuty and sends an email. |
| What does the Terraform do? | Every minute, Dynatrace searches the last 5 minutes of the same logs. Any matching line opens a high problem, and a workflow pages PagerDuty and sends an email. |
| Biggest difference | The "more than 3" rule is gone, because the real failure only writes 1 or 2 lines. |
| Why it matters | If LDAP fails, VPN users cannot log in with their Windows account. |

## Summary

The Splunk screen and the Terraform describe the same alarm in two tools. Splunk needs a schedule, a time range, a count rule and actions on one screen. Dynatrace splits it in two: the detector (Terraform) decides "is something wrong", and a workflow decides "who to tell".

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Cisco ASA | The Cisco firewall that also runs the company VPN. | It writes the log line this alert looks for. |
| LDAP | The way the VPN checks a user's name and password against Windows Active Directory. | No LDAP means no VPN login. |
| Syslog | The standard way network devices send log lines to a collector server. | The ASA lines arrive as syslog on server ljcmgt14. |
| Splunk scheduled alert | A saved search that Splunk runs on a timer and checks against a rule. | This is the old alert on the screen. |
| Dynatrace Records detector | A DQL query Dynatrace runs every minute. If it returns rows, it opens a problem. | This is the new alert in the Terraform. |
| Problem | Dynatrace's open incident. It stays open while the query keeps returning rows. | Replaces Splunk's "Triggered Alert". |
| Workflow | A Dynatrace automation that reacts to problems, for example by paging or emailing. | Replaces Splunk's PagerDuty and email actions. |
| Terraform | A tool that creates cloud settings from text files. | Lets the alert live in Git instead of being clicked in a UI. |

### The Splunk screen, field by field

| Field on screen | Value | What it means |
|---|---|---|
| Alert | Cisco VPN : LDAP Connections are failing which will impact end users using windows basic | The name people see when it fires. |
| Description | This alert has been set to monitor the VPN situation in case LDAP connections are failing due to backend system issues... | Why the alert exists: LDAP failure hurts VPN users. |
| Search | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` | Look in the network syslog bucket, only Cisco ASA logs, for lines containing that phrase. |
| `index="networksyslog"` | networksyslog | The Splunk storage bucket for network device logs. |
| `sourcetype=cisco:asa` | cisco:asa | Only lines Splunk recognises as Cisco ASA format. |
| `*Windows_LDAP as FAILED*` | phrase with wildcards | The `*` on both sides means "anything before and after". Splunk ignores upper and lower case here. |
| Alert type | Scheduled | Runs on a timer, not in real time. |
| Run on Cron Schedule | selected | The timer is a cron expression. |
| Time Range | Last 1 minute | Each run looks only at the previous 1 minute of logs. |
| Cron Expression | `*/1 * * * *` | Run every minute. |
| Expires | 24 hours | How long the fired alert stays in Splunk's Triggered Alerts list. It does not change detection. |
| Trigger alert when | Number of Results | The rule counts matching lines. |
| is greater than | 3 | Fire only if there are 4 or more lines in that 1 minute. |
| Trigger | Once or For each result | "Once" sends one alert per run. "For each result" sends one alert per matching line. |
| Throttle | unchecked | No quiet period. It can fire again on the next minute. |
| Add to Triggered Alerts | Severity Critical | Records the alert in Splunk with Critical severity. |
| PagerDuty | action | Pages the on-call engineer. |
| Send email | action | Emails a list (recipients are not shown on screen). |

### Why "greater than 3" was a problem

| Fact | What it means |
|---|---|
| Splunk found 2 matching lines in the last month | The failure is rare. |
| Each line is about one LDAP server, either 10.3.87.1 or 10.3.87.2 | A real failure writes 1 or 2 lines, not 4. |
| The rule needs 4 or more lines inside 1 minute | Neither real failure would have fired the alert. |

So the old alert was effectively silent. The Terraform fires on any matching line.

## Result

### The Terraform, block by block

```hcl
terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}
```

| Part | What it means |
|---|---|
| `required_providers` | Tells Terraform to download the Dynatrace plugin. |
| `provider "dynatrace" {}` | Connects to Dynatrace. The URL and API token come from environment variables (`DYNATRACE_ENV_URL`, `DYNATRACE_API_TOKEN`), so no secret is in the file. |

```hcl
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN ... Fires when a Cisco ASA log under /var/log/ASA reports Windows_LDAP as FAILED."
  enabled     = true
  source      = "Davis Anomaly Detection"
```

| Part | What it means |
|---|---|
| `dynatrace_davis_anomaly_detectors` | The real Dynatrace resource type for a detector. The old `dynatrace_log_alert` does not exist. |
| `cisco_vpn_ldap_connections_failing` | Terraform's own name for this resource. Used in state, not shown to users. |
| `title` | Same as Splunk "Alert". |
| `description` | Same as Splunk "Description", finished in full sentences. |
| `enabled = true` | The detector is switched on. |
| `source` | Fixed label Dynatrace expects for this kind of detector. |

```hcl
  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(log.source, "/var/log/ASA", caseSensitive:false)
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "log.source"
      }
    }
  }
```

| Part | What it means |
|---|---|
| `RecordAnomalyDetectionAnalyzer` | "Open a problem when this query returns rows." |
| `fetch logs, from:now()-5m` | Read the last 5 minutes of logs. Wider than Splunk's 1 minute so late syslog lines are not missed. |
| `contains(log.source, "/var/log/ASA")` | Only lines from files under `/var/log/ASA`. This replaces Splunk's index and sourcetype. It covers all four ASA files. |
| `contains(content, "Windows_LDAP as FAILED")` | Same phrase as the Splunk search. |
| `caseSensitive:false` | Ignore upper and lower case, like Splunk. |
| No `summarize` and no `> 3` | Any single matching line opens a problem. |
| `alertIdentityFields[0] = "log.source"` | Lines from the same file belong to the same problem. A different file opens a separate problem. This is what stops repeat alerts, like a throttle. |

```hcl
  event_template {
    properties {
      property { key = "event.type"        value = "CUSTOM_ALERT" }
      property { key = "event.name"        value = "Cisco VPN : LDAP Connections are failing" }
      property { key = "event.description" value = "A Cisco ASA marked a Windows_LDAP server as FAILED. ..." }
      property { key = "alert.severity"    value = "high" }
      property { key = "app.name"          value = "cisco-vpn" }
      property { key = "pagerduty.enabled" value = "1" }
    }
  }

  execution_settings {}
}
```

| Property | What it means |
|---|---|
| `event.type = CUSTOM_ALERT` | The kind of problem Dynatrace opens. |
| `event.name` | The short title on the problem card. |
| `event.description` | The text the on-call engineer reads. It says what failed and who is affected. |
| `alert.severity = high` | Our label for Splunk's Critical. The workflow reads it. |
| `app.name = cisco-vpn` | Groups the problem with other VPN alerts. |
| `pagerduty.enabled = 1` | Tells the workflow to page PagerDuty. `0` would mean email only. |
| `execution_settings {}` | Default run settings: every minute. |

### Old screen next to new Terraform

| Splunk screen | Terraform |
|---|---|
| Alert | `title` |
| Description | `description` |
| Search index and sourcetype | `contains(log.source, "/var/log/ASA")` |
| Search phrase | `contains(content, "Windows_LDAP as FAILED")` |
| Time Range Last 1 minute | `from:now()-5m` |
| Cron every minute | Built in. Detectors always run every minute. |
| Expires 24 hours | Not needed. The problem closes about 5 minutes after the last line. |
| Number of Results greater than 3 | Removed. |
| Trigger Once or For each result | `alertIdentityFields` = `log.source` |
| Throttle | Covered by the identity field. |
| Severity Critical | `alert.severity = "high"` |
| PagerDuty | `pagerduty.enabled = "1"` |
| Send email | Workflow. |

## Data flow map

```
OLD (Splunk)
ASA → syslog → ljcmgt14 → Splunk index networksyslog
  → every minute: search last 1 min
  → more than 3 lines? → Critical alert → PagerDuty + email
     (real failures write 1-2 lines → never fired)

NEW (Dynatrace)
ASA → syslog → ljcmgt14 /var/log/ASA/*.log → Dynatrace Grail
  → detector every minute: search last 5 min
  → any line? → problem (high), one per log.source
  → workflow reads pagerduty.enabled = 1 → PagerDuty + email
  → no new line for 5 min → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `../20-cisco-vpn-ldap-logsource-tf/20-cisco-vpn-ldap-logsource-tf.tf` | The Terraform explained here. |
| `0-pic.md` | Side-by-side map. |
| `1-investigation.md` | Screen fields read. |
| `2-result.md` | Short outcome. |
| `3-glossary.md` | Words used. |
| `21.sh` | Commands, one per line. |

## Commands

All commands are in [`21.sh`](./21.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/20-cisco-vpn-ldap-logsource-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/21-cisco-vpn-ldap-tf-and-splunk-explained
git commit -m "Explain Cisco VPN LDAP Splunk alert and Terraform"
git push
```
