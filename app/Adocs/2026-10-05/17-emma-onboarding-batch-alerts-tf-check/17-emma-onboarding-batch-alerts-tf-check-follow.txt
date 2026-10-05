# Emma Onboarding Batch Alerts Terraform Check

## Decision tree

```
myaxa-onboarding-batch.tf (5 alerts, all dynatrace_log_alert)
 resource exists?                    → NO → plan fails
 same log group, schedule, recipients → 5 copies of one block → for_each map (one detector each)
 every 5 min, last 5 min, > 0, no throttle → detector window 5, dealerting 5
 contains(...) case-sensitive        → add caseSensitive: false (Splunk ignored case)
 alert 2: "handleOnboardedCustomers" and "error" → broad ("errorCount=0" would match) → check sample lines
 subject "Alert: $name$"             → Splunk token, does not work → {{ event()["event.name"] }}
 description "Optional"              → placeholder → write a real one
 priority HIGH, name "_High"         → no PagerDuty action in the file → email only; confirm with Emma team
 secrets?                            → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. All 5 use `dynatrace_log_alert`, which does not exist |
| Shape | 5 near-identical "error line seen" alerts on one Lambda |
| Converted to | One `for_each` detector block (5 detectors) plus one shared email workflow |
| Splunk leftovers | `$name$` in the subject and `"Optional"` descriptions |
| PagerDuty | Not in the file. `_High` only changes the email priority. Confirm whether they want paging |
| Secrets | None |

## Summary

The five alerts differ only in the text they look for, so writing them five times is just copy-paste risk. A `for_each` map keeps one detector definition and five small entries. All five problems share one email workflow that triggers on the common name prefix, sends the matching log lines, and uses the problem name as the subject (replacing the Splunk-only `$name$` token). Make the text matches case-insensitive, and check alert 2's broad "error" match against real lines before go-live.

## The 5 alerts

| # | Alert name suffix | What it matches | Notes |
|---|---|---|---|
| 1 | `sendNotifications_error_High` | `sendNotifications :: error` | Does not overlap with alert 5 because `QueueConsumer` sits between the words |
| 2 | `handleOnboardedCustomers_error_High` | `handleOnboardedCustomers` and `error` anywhere in the line | Broad. Could match harmless text like `errorCount=0` |
| 3 | `sendNotificationsQueueConsumer_email_sending_failed_High` | `sendNotificationsQueueConsumer :: email_sending_failed` | Precise |
| 4 | `sendNotificationsQueueConsumer_message_sending_failed_High` | `sendNotificationsQueueConsumer :: message_sending_failed` | Precise |
| 5 | `sendNotificationsQueueConsumer_error_High` | `sendNotificationsQueueConsumer :: error` | Precise |

All names start with `Prod_Life_Emma_myaxa-onboarding-batch_`.

## Line by line (same for all 5)

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` with `for_each` |
| `description = "Optional"` | Placeholder | Real description per alert (in the map) |
| `contains(aws.log_group, ".../myaxa-onboarding-batch-prod")` | Works | `==` |
| `contains(content, "...")` | Case-sensitive | Add `caseSensitive: false` |
| `sort`, `limit 100` | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| cron `*/5`, `LAST_5_MINUTES`, `expires 24` | | Detector runs every minute |
| `> 0`, `ONCE` | | `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| `throttle_enabled = false` | | `dealertingSamples = 5`: one problem per burst instead of an email every 5 minutes |
| `SEND_EMAIL` to 6 recipients | | Shared email workflow |
| `priority = "HIGH"` | No direct field | Put `[HIGH]` in the subject |
| `subject = "Alert: $name$"` | Splunk token | `[HIGH] Alert: {{ event()["event.name"] }}` |

## Detector query (per alert)

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/myaxa-onboarding-batch-prod"
| filter contains(content, "sendNotificationsQueueConsumer :: error", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
```

Only the second `filter` line changes between alerts; it comes from `each.value.match` in the map.

| Setting | Value |
|---|---|
| Threshold | 0, Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | high |

## Shared email workflow

| Part | What it does |
|---|---|
| Trigger | Any custom problem whose name starts with `Prod_Life_Emma_myaxa-onboarding-batch_` |
| `recent_errors` | Lines matching any of the 5 patterns in the last 10 minutes |
| `send_email` | Subject `[HIGH] Alert: <problem name>`, problem id and lines, to the 6 recipients |

## Questions for the Emma team

| Question | Why it matters |
|---|---|
| Should `_High` page someone (PagerDuty)? | The Splunk file only emails. If they want paging, add a PagerDuty task with a sensitive routing key |
| Does your tenant route all problems to SILVA or PagerDuty automatically? | The Splunk version created no problem. In Dynatrace these become problems, so a tenant-wide routing workflow could pick them up |
| Is alert 2's "error" match too broad? | Run the sample query in `check.dql` |

## Data flow

```
Lambda myaxa-onboarding-batch-prod
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  → 5 detectors every minute (one per message pattern), count > 0 in window 5
  → problem "Prod_Life_Emma_myaxa-onboarding-batch_<alert>" (high)
  → shared email workflow → matching lines → 6 recipients
  → 5 clean minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| 5 screenshots of `myaxa-onboarding-batch.tf` | 5 `dynatrace_log_alert` blocks, 236 lines |
| Query | Same log group; only the content match differs |
| Trigger | All every 5 minutes, last 5 minutes, > 0, once, no throttle |
| Actions | Email only, priority HIGH, subject uses `$name$` |
| Descriptions | All `"Optional"` |
| Secrets | None |

## Result

Not OK. Replace the 5 blocks with one `for_each` detector and one email workflow, fix the case sensitivity, the subject token and the descriptions, and ask the Emma team whether `_High` should page.

## Related files

| File | Purpose |
|---|---|
| `17-emma-onboarding-batch-alerts-tf-check-main.tf` | `for_each` detectors and shared email workflow |
| `17-emma-onboarding-batch-alerts-tf-check-check.dql` | 7-day match counts and alert 2 false-positive sample |
| `17.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/12-gov-inquiry-system-alerts-tf-check/` | Earlier `for_each` pattern |

## Commands

See `17.sh` (not run).
