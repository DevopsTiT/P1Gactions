# CS Digital Document Alerts Terraform Check

## Decision tree

```
cs-digital-document-management.tf (2 alerts, both dynatrace_log_alert)
 resource exists?                        → NO → plan fails (same as the other files)
 ALERT 1 [CSDDM] Claims API fails
   cron 0 10 * * *, last 24 hours        → daily digest, not real-time
   anomaly detector fits?                → NO (it checks every minute)
   use                                   → scheduled workflow: DQL count over 24h → email if > 0
   or switch to real-time?               → only if the team agrees (emails at any hour)
 ALERT 2 CS DDM Error alerts
   */5, last 5 min, > 0, throttle 1 hour → anomaly detector, window 5, dealerting 60
   "error" lower case                    → caseSensitive: false (Splunk ignored case)
   not "elivery not possible"            → was a trick to match Delivery and delivery; use "delivery not possible" with caseSensitive: false
 email for both                          → workflow email task
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. Both resources use `dynatrace_log_alert`, which does not exist |
| Alert 1 | A once-a-day report, so build it as a scheduled workflow (DQL plus email), not an anomaly detector |
| Alert 2 | Anomaly detector with window 5 and dealerting 60, plus an email workflow |
| Case | Add `caseSensitive: false`, especially for the lower-case "error" |
| Secrets | None |

## Summary

Two alerts, same broken resource. They need different Dynatrace building blocks. Alert 1 runs once a day at 10:00 and looks back 24 hours. A Dynatrace anomaly detector can't do "once a day", so the faithful conversion is a **scheduled workflow** that runs a DQL count and emails only when it's above 0. Alert 2 is a normal "check every 5 minutes" alert, so it becomes an anomaly detector plus a small workflow that sends the email.

## Alert 1 — [CSDDM] Send alert email when Claims API fails

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_automation_workflow` with a schedule trigger |
| `description = "Optional"` | Placeholder | Real text |
| log group `/aws/lambda/cs-digital-document-management-prod` | OK | Use `==` |
| `contains(content, "claims api call failed")` | Case | Add `caseSensitive: false` |
| `sort`, `limit 100` | Not needed | `summarize failures = count()` |
| cron `0 10 * * *`, LAST_24_HOURS | Daily | Schedule trigger `cron = "0 10 * * *"`, `time_zone = "Asia/Tokyo"`, query `from:now()-24h` |
| > 0, once, no throttle | | Email task runs only if `failures > 0` |
| SEND_EMAIL to 4 recipients | | Email task |

```hcl
resource "dynatrace_automation_workflow" "csddm_claims_api_fails" {
  title       = "[CSDDM] Send alert email when Claims API fails"
  description = "Every day at 10:00 JST, count 'claims api call failed' in cs-digital-document-management-prod over the last 24 hours and email if more than 0."

  tasks {
    task {
      name   = "count_failures"
      action = "dynatrace.automations:execute-dql-query"
      active = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter aws.log_group == "/aws/lambda/cs-digital-document-management-prod"
          | filter contains(content, "claims api call failed", caseSensitive: false)
          | summarize failures = count()
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name   = "send_email"
      action = "dynatrace.email:send-email"
      active = true
      input = jsonencode({
        to = [
          "honlun.chan@axa.co.jp",
          "masaya.okuno@axa.co.jp",
          "aij_jp_dl_incident_claims_it@axa.co.jp",
          "axa_jp_dl_claims_transformation@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: [CSDDM] Send alert email when Claims API fails"
        content = "Claims API call failed {{ result(\"count_failures\").records[0].failures }} time(s) in the last 24 hours."
      })
      conditions {
        states = {
          count_failures = "SUCCESS"
        }
        custom = "{{ result(\"count_failures\").records[0].failures > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 10 * * *"
      }
    }
  }
}
```

| Choice | What happens |
|---|---|
| Keep daily (above) | Same as Splunk: one email at 10:00 if anything failed yesterday; no problem, no SILVA ticket |
| Switch to real-time | Use an anomaly detector like Alert 2; emails within minutes, at any hour. Ask the claims team first |

Confirm the Splunk server's time zone. If the old 10:00 was UTC, use `time_zone = "UTC"` instead.

## Alert 2 — CS Digital Document Management Error alerts

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` |
| `contains(content, "error")` | Case problem | `caseSensitive: false`; without it `ERROR` and `Error` are missed |
| `not contains(content, "elivery not possible")` | Works, but odd | Dropping the D was a trick to match both cases. Use `not contains(content, "delivery not possible", caseSensitive: false)` |
| `sort`, `limit 100` | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| `*/5`, LAST_5_MINUTES | | `slidingWindow = 5` |
| > 0, once | | `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| throttle 1 hour | | `dealertingSamples = 60` |
| SEND_EMAIL to aij_jp_dl_csdigitaldocument | | Email workflow triggered by this problem |

The detector and the email workflow are both in `8-cs-digital-document-alerts-tf-check-main.tf`. The email workflow triggers on custom problems whose name matches `CS Digital Document Management Error alerts`:

```hcl
trigger {
  event {
    active = true
    config {
      davis_problem {
        categories {
          custom = true
        }
        custom_filter = "matchesPhrase(event.name, \"CS Digital Document Management Error alerts\")"
        trigger_on    = "open"
      }
    }
  }
}
```

"error" is broad. Check what it catches before going live:

```dql
fetch logs, from:-7d
| filter aws.log_group == "/aws/lambda/cs-digital-document-management-prod"
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "delivery not possible", caseSensitive: false)
| summarize count = count(), by:{line = substring(content, from:0, to:120)}
| sort count desc
| limit 30
```

## Things to verify in your tenant

| Item | Why |
|---|---|
| Email action input fields (`to`, `cc`, `bcc`, `subject`, `content`) | Build one email task in the Workflows UI, then export it with `terraform-provider-dynatrace -export dynatrace_automation_workflow` and compare |
| DQL task result path `records[0].failures` | Matches the `summarize failures = count()` name; check in a manual run |
| Your SILVA/PagerDuty OPEN workflow | Alert 2 opens a problem; make sure that workflow doesn't page for it if it is email-only |

## Data flow

```
ALERT 1 (daily)
  10:00 JST schedule → DQL: count "claims api call failed" in last 24h
    → failures > 0 ? → email 4 recipients
    → failures = 0   → email skipped

ALERT 2 (continuous)
  Lambda logs → Grail → detector every minute (window 5, "error" minus "delivery not possible")
    → count > 0 → problem "CS Digital Document Management Error alerts"
    → email workflow → aij_jp_dl_csdigitaldocument
    → 60 quiet minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Two screenshots of `cs-digital-document-management.tf` | Two `dynatrace_log_alert` resources |
| Alert 1 | Daily cron at 10:00 over 24 hours, 4 recipients |
| Alert 2 | Every 5 minutes, "error" minus "elivery not possible", throttle 1 hour, 1 recipient |
| Provider docs, `automation_workflow` | Supports schedule trigger with `cron` and `time_zone`, `davis_problem` trigger with `custom_filter`, task `conditions` with `custom` and `else` |
| Secrets | None |

## Result

Not OK as is. Alert 1 becomes a scheduled workflow (DQL count plus conditional email at 10:00 JST). Alert 2 becomes an anomaly detector (window 5, dealerting 60, case-insensitive "error") plus an email workflow. Validate and plan before merging.

## Related files

| File | Purpose |
|---|---|
| `8-cs-digital-document-alerts-tf-check-main.tf` | Both fixed alerts and the email workflow |
| `8.sh` | Validate, plan, export, mirror and git one-liners |
| `2026-10-05/7-hpm-cmx-sharepoint-alert-tf-check/` | Previous check (case-sensitivity explained) |

## Commands

See `8.sh` (not run).
