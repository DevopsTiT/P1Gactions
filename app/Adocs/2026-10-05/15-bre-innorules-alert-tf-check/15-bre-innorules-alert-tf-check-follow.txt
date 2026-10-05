# BRE InnoRules Alert Terraform Check

## Decision tree

```
innorules.tf (1 alert, dynatrace_log_alert)
 resource exists?                       → NO → plan fails
 integration_key hard-coded (line 37)?  → YES → remove, rotate if pushed, use a sensitive variable
 cron "*/5 1-5 * * *"                   → runs only 01:00–05:59 every day. Intended? (weekdays = "*/5 * * * 1-5")
 last 5 min, no throttle                → pages every 5 min while errors continue
   → detector window 5, dealerting 5 + PagerDuty dedup_key per problem
 parse "LD SPACE LD SPACE WORD:loglevel" → works only for "timestamp requestId LEVEL ..." lines → run parse-check.dql
 contains(content, "ERROR")             → case-sensitive is correct here (log level is uppercase)
 alert_name "BRE alert"                 → too vague; follow the Prod_Life_<Team>_<What> naming
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. `dynatrace_log_alert` does not exist |
| Biggest risk | PagerDuty integration key is hard-coded in the file |
| Schedule doubt | `*/5 1-5 * * *` means every 5 minutes between 01:00 and 05:59, every day. Probably meant weekdays |
| Converted to | Detector plus a PagerDuty workflow (one incident per problem) |
| Query | Keep it, but confirm the parse matches the real log format |

## Summary

This is the first file in the set that pages PagerDuty, so two things matter more than usual: the routing key must not live in Git, and the alert must not page every 5 minutes for the same outage. A detector opens one problem and keeps it open while errors continue, and the PagerDuty `dedup_key` is tied to the problem ID, so on-call gets one incident. The cron line almost certainly has the weekday range in the hour field; confirm with the BRE team before deciding whether a time window is needed at all.

## Line by line

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` plus a workflow |
| `alert_name = "BRE alert"` | Vague | `Prod_Life_BRE_InnoRulesError` (match your team's naming) |
| `contains(aws.log_group, ".../innorules-prod")` | Works | Use `==` |
| `contains(content, "ERROR")` | OK | Keep; it's a cheap pre-filter before parse |
| `parse content, "LD SPACE LD SPACE WORD:loglevel"` | Fragile | Works for Node.js-style lines (`timestamp<tab>requestId<tab>ERROR<tab>msg`). Fails for Python-style `[ERROR] ...`. Check with `parse-check.dql` |
| `filter loglevel == "ERROR"` | OK | Keep |
| `sort`, `limit 100` | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| `cron_expression = "*/5 1-5 * * *"` | Suspicious | Hours 1 to 5 only. See below |
| `LAST_5_MINUTES`, `expires 24` | | Not needed with a detector |
| `> 0`, `ONCE` | | `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| `throttle_enabled = false` | Noisy | Detector keeps one problem open; `dealertingSamples = 5` closes it after 5 clean minutes |
| `action_type = "PAGERDUTY"` | | PagerDuty workflow (http-function, Events v2) |
| `integration_key = "..."` | Secret in Git | Delete. Pass `var.bre_pagerduty_routing_key` from a CI secret, or keep it in the Dynatrace credential vault. Rotate the key in PagerDuty if this file was ever pushed |
| `custom_description` | OK | Used as the PagerDuty summary |

## The cron line

Cron fields are: minute, hour, day of month, month, day of week.

| Expression | What it means |
|---|---|
| `*/5 1-5 * * *` (current) | Every 5 minutes from 01:00 to 05:59, every day. Errors at 10:00 never alert |
| `*/5 * * * 1-5` (likely intended) | Every 5 minutes, all day, Monday to Friday |
| `*/5 * * * *` | Every 5 minutes, all the time |

Also check which time zone Splunk used. If the Splunk server ran in UTC, 01:00–05:59 UTC is 10:00–14:59 JST, which would be a business-hours window.

| If the team says | Do this |
|---|---|
| Page any time | Use the detector in `main.tf` as is |
| Weekdays or business hours only | Keep the detector, and add a time condition to the PagerDuty task, or switch to a scheduled workflow with the right cron and `time_zone = "Asia/Tokyo"` |

## Detector query

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/innorules-prod"
| filter contains(content, "ERROR")
| parse content, "LD SPACE LD SPACE WORD:loglevel"
| filter loglevel == "ERROR"
| makeTimeseries count = count(default: 0), interval:1m
```

| Setting | Value |
|---|---|
| Threshold | 0, Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | high (pages) |

If `parse-check.dql` shows `status_error` matches `raw_error`, you can drop the parse and use `filter status == "ERROR"`, which is simpler and doesn't break when the log format changes.

## PagerDuty workflow

| Part | What it does |
|---|---|
| Trigger | Custom problem named `Prod_Life_BRE_InnoRulesError` opens |
| `pagerduty_trigger` | POST to PagerDuty Events v2 with `dedup_key = dt-problem-<problem id>`, so repeats join the same incident |
| Key | `var.bre_pagerduty_routing_key` (sensitive, from CI secret) |

If your tenant already has the standard SILVA plus PagerDuty problem workflow (preview then post), route this problem through it using tags instead of adding a separate workflow.

## Data flow

```
Lambda innorules-prod (BRE rules engine)
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  → detector every minute: lines with level ERROR > 0 in window 5
  → problem "Prod_Life_BRE_InnoRulesError" (high)
  → PagerDuty workflow → Events v2 (dedup by problem id) → BRE on-call
  → 5 clean minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot `innorules.tf` | One `dynatrace_log_alert` "bre_alert_innorules" |
| Query | Log group innorules-prod, contains ERROR, parse level, level == ERROR |
| Schedule | `*/5 1-5 * * *`, last 5 minutes, no throttle |
| Action | PagerDuty with a hard-coded integration key |
| Compared | Same PagerDuty shape as the CDUS routing in seq 10 |

## Result

Not OK. Replace with a detector and a PagerDuty workflow, move the key out of Git and rotate it, confirm the cron intent with the BRE team, and run `parse-check.dql` to make sure the parse matches real lines.

## Related files

| File | Purpose |
|---|---|
| `15-bre-innorules-alert-tf-check-main.tf` | Detector and PagerDuty workflow |
| `15-bre-innorules-alert-tf-check-parse-check.dql` | Confirms the parse pattern matches real log lines |
| `15.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/10-document-upload-api-alerts-tf-check/` | Same PagerDuty workflow pattern |

## Commands

See `15.sh` (not run).
