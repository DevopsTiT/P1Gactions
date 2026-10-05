# Emma MsgBox Alert Terraform Check

## Decision tree

```
message-box-api.tf (1 alert, dynatrace_log_alert)
 resource exists?                        → NO → plan fails
 contains "error" or "warn" (lowercase)  → DQL is case-sensitive → misses "ERROR", "WARN" → add caseSensitive: false
 "warn" matches "warning" too            → broad; run noise-check.dql before go-live
 every 5 min, last 5 min, results > 5    → detector: rolling 5-minute sum > 5
 no throttle                             → dealerting 5 (one problem per burst, no repeats every 5 min)
 DYNATRACE_PROBLEM MEDIUM                → alert.severity medium
 SEND_EMAIL (Teams channel + 2)          → email workflow
 "_Normal"                               → no PagerDuty
 secrets?                                → no keys; the Teams channel address lets anyone post to it, so don't share it outside the repo
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. `dynatrace_log_alert` does not exist |
| Main logic bug | `contains(content, "error")` is case-sensitive in DQL, so `ERROR` and `WARN` lines are missed |
| Threshold | More than 5 lines in 5 minutes, not more than 0 |
| Converted to | Detector on a rolling 5-minute sum, plus an email workflow |
| PagerDuty | No, it's `_Normal` |
| Noise risk | Matching every "warn" may fire often. Check history first |

## Summary

This alert is different from the HPM ones in one way: it fires on volume (more than 5 lines in 5 minutes), not on a single error. To keep that meaning, the detector counts per minute and then adds a rolling 5-minute sum, so the threshold 5 compares against the same window Splunk used. The text match must be made case-insensitive, otherwise the alert quietly misses most real error lines. Because it matches both "error" and "warn", run the noise check first so the Teams channel doesn't get flooded.

## Line by line

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` plus an email workflow |
| `contains(aws.log_group, ".../message-box-api-prod")` | Works | Use `==` |
| `contains(content, "error") or contains(content, "warn")` | Bug | Add `caseSensitive: false` to both. Splunk ignored case; DQL does not |
| `sort`, `limit 1000` | Not for alerts | `makeTimeseries` plus `arrayMovingSum(count, 5)` |
| cron `*/5 * * * *`, `LAST_5_MINUTES` | | Detector runs every minute; the rolling sum keeps the 5-minute window |
| `NUMBER_OF_RESULTS > 5`, `ONCE` | | `threshold = 5`, `ABOVE`, `violatingSamples = 1` |
| `throttle_enabled = false` | | `dealertingSamples = 5`: one problem per burst |
| `DYNATRACE_PROBLEM` MEDIUM | | `alert.severity = medium` |
| `SEND_EMAIL` to 3 recipients | | Email workflow (Teams channel address works as a normal email) |
| `priority = "NORMAL"` | | No equivalent needed; `_Normal` means no PagerDuty |

## Detector query

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/message-box-api-prod"
| filter contains(content, "error", caseSensitive: false) or contains(content, "warn", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
| fieldsAdd count = arrayMovingSum(count, 5)
```

| Setting | Value | Why |
|---|---|---|
| Threshold | 5, Above | Same as "results greater than 5" |
| Sliding window | 5 | |
| Violating samples | 1 | Fire on the first minute the rolling sum goes over 5 |
| Dealerting samples | 5 | Close after 5 minutes under the threshold |

Each data point is "lines in the last 5 minutes", so the threshold matches Splunk's 5-minute window. Open query 3 in `noise-check.dql` as a chart to confirm `arrayMovingSum` works in your tenant. If the detector UI rejects it, a fallback is `makeTimeseries ... interval:5m` with the same threshold.

## Noise check before go-live

| Query in `noise-check.dql` | What it tells you |
|---|---|
| 1 | How many 5-minute buckets in the last 7 days had more than 5 lines (how often it would have fired) |
| 2 | Top 20 messages driving the count, to spot harmless "warn" lines |
| 3 | The rolling sum as a chart |

If query 1 shows many buckets, exclude the known harmless messages, or ask the Emma team whether "warn" should be dropped.

## Email workflow

| Part | What it does |
|---|---|
| Trigger | Custom problem named `Prod_Life_Emma_OverallMsgBoxErrors_Normal` opens |
| `recent_errors` | Error and warn lines from the last 10 minutes (up to 100) |
| `send_email` | Problem id plus lines to the Teams channel, gregoire.homassel, and axa_jp_dl_bam |

## Data flow

```
Lambda message-box-api-prod (Emma Life MsgBox)
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  → detector every minute: rolling 5-min count of error/warn lines > 5
  → problem "Prod_Life_Emma_OverallMsgBoxErrors_Normal" (medium)
  → email workflow → Teams channel + 2 mailboxes (no PagerDuty)
  → 5 minutes under threshold → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot `message-box-api.tf` | One `dynatrace_log_alert` "emma_overall_msgbox_errors" |
| Query | Log group message-box-api-prod, content contains lowercase "error" or "warn" |
| Trigger | Every 5 minutes over 5 minutes, more than 5 results, no throttle |
| Actions | Problem MEDIUM, email to a Teams channel address and 2 mailboxes |
| Secrets | No API keys |

## Result

Not OK as is. Use the detector with case-insensitive matching and a rolling 5-minute sum, add the email workflow, keep it out of PagerDuty, and run the noise check before enabling.

## Related files

| File | Purpose |
|---|---|
| `16-emma-msgbox-alert-tf-check-main.tf` | Detector and email workflow |
| `16-emma-msgbox-alert-tf-check-noise-check.dql` | History check and rolling-sum chart |
| `16.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/14-hpm-survey-monkey-alert-tf-check/` | Same detector plus email pattern |

## Commands

See `16.sh` (not run).
