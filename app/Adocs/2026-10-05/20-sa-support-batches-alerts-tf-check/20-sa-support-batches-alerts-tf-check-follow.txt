# SA Support Batches Alerts Terraform Check

## Decision tree

```
sa-support-batches.tf (3 alerts, dynatrace_log_alert)
 resource exists?                           → NO → plan fails
 alert 1 "error" every 5 min                → detector, caseSensitive: false (lowercase "error" misses "ERROR")
 alert 3 "Task timed out" every 5 min       → detector; same recipients as alert 1 → share one email workflow
 alerts 1 and 3 LAST_6_MINUTES on */5       → overlap; detector removes it
 alert 2 weekdays 08:30, last 24 h, < 2     → "did the import run?" check → scheduled workflow, email when count < 2
 alert 2 OR with "started"                  → BUG: "started" matches almost any line → the check almost never fires
   → match runner AND importSagaFundGroup (confirm with check.dql)
 subject "Alert: $name$", "Optional"        → real subject and descriptions
 secrets?                                   → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. All 3 use `dynatrace_log_alert` |
| Main logic bug | Alert 2 counts any line containing "started", so a missed import is hidden |
| Alert 2 type | A "missing run" check (fewer than 2 lines means the import probably didn't run). Detectors can't do this well; a scheduled workflow can |
| Alerts 1 and 3 | Normal error alerts: 2 detectors and one shared email workflow |
| Case | Alert 1's lowercase `"error"` misses `ERROR` in DQL. Add `caseSensitive: false` |
| Secrets | None |

## Summary

Alert 2 is the interesting one. It's an "absence" alert: it should fire when the import did *not* log its usual lines. But the filter is an OR of three phrases, and one of them is just `started`, which appears in lots of unrelated lines. So the count is almost always 2 or more, and the alert stays silent even when the import fails. Tighten the match (the conversion uses runner AND importSagaFundGroup, but check real lines first) and run it as a weekday 08:30 scheduled workflow. Alerts 1 and 3 are standard "line seen" alerts with the same recipients, so they share a `for_each` detector block and one email workflow.

## The 3 alerts

| # | Name | Matches | Schedule | Recipients | Converted |
|---|---|---|---|---|---|
| 1 | Sa Support Batch Error | `error` | Every 5 minutes, last 6 minutes, > 0 | commoninfsound2, maki.kawauchi.os | Detector `Prod_Life_SA_SupportBatch_Error_Normal` |
| 2 | Sa Support Batch File Import Confirmation | `importFileHandler :: runner` or `importSagaFundGroup` or `started` | Weekdays 08:30, last 24 hours, < 2 | annuitypayment | Scheduled workflow, email if count < 2 |
| 3 | Sa Support Batch Task Time Out | `Task timed out` | Every 5 minutes, last 6 minutes, > 0 | commoninfsound2, maki.kawauchi.os | Detector `Prod_Life_SA_SupportBatch_TaskTimeOut_Normal` |

## Alert 2: why "started" breaks it

| Filter | What happens on a day the import fails |
|---|---|
| `runner OR importSagaFundGroup OR started` (current) | Any other job logging "started" (or "Lambda started", "process started") pushes the count above 2. No alert |
| `runner AND importSagaFundGroup` (proposed) | Only real import lines count. Count drops below 2 and the email goes out |

I'm guessing at the right combination. Run query 1 in `check.dql`: it shows per day how many lines each part matches. Query 2 shows real import lines, so you can pick the exact phrases. If the import logs one "started" line and one "finished" line, a cleaner check is "both lines present".

Also confirm when the batch runs. The check at Monday 08:30 looks back to Sunday 08:30. If the import doesn't run on weekends and normally runs after 08:30, Monday would alert falsely.

## Alert 2 conversion

| Original | Dynatrace |
|---|---|
| cron `30 8 * * 1-5`, last 24 hours | Schedule `30 8 * * 1-5`, `time_zone = "Asia/Tokyo"` |
| `NUMBER_OF_RESULTS LESS_THAN 2` | `count_import_lines` total, email only if `total < 2` |
| Email annuitypayment | Same, body shows the count and the last time an import line was seen |

```dql
fetch logs, from:now()-24h
| filter aws.log_group == "/aws/lambda/sa-support-batches-prod"
| filter contains(content, "importFileHandler :: runner", caseSensitive: false) and contains(content, "importSagaFundGroup", caseSensitive: false)
| summarize total = count(), last_seen = max(timestamp)
```

## Alerts 1 and 3 conversion

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/sa-support-batches-prod"
| filter contains(content, "error", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
```

Alert 3 is the same with `"Task timed out"`.

| Setting | Value |
|---|---|
| Threshold | 0, Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | medium |

One email workflow triggers on any problem whose name starts with `Prod_Life_SA_SupportBatch_` and sends the last 10 minutes of error and timeout lines.

Alert 1 matches "error" anywhere, which can be noisy (for example `errorCount=0`). Query 3 in `check.dql` lists the top messages.

## Data flow

```
Lambda sa-support-batches-prod
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  Alerts 1, 3: 2 detectors every minute ("error", "Task timed out") > 0 in window 5
               → problem "Prod_Life_SA_SupportBatch_<alert>" → email workflow → commoninfsound2 + maki.kawauchi.os
  Alert 2:     weekdays 08:30 JST workflow → count import lines (24 h) → < 2? → email annuitypayment
```

## Investigation

| Checked | Finding |
|---|---|
| 3 screenshots of `sa-support-batches.tf` | 3 `dynatrace_log_alert` blocks, 128 lines |
| Log group | All `/aws/lambda/sa-support-batches-prod` |
| Alert 1 | Lowercase "error", 6-minute window on 5-minute cron |
| Alert 2 | OR of 3 phrases including "started", LESS_THAN 2, weekdays 08:30 |
| Alert 3 | "Task timed out", 6-minute window on 5-minute cron |
| Subjects and descriptions | `$name$` and `"Optional"` |
| Secrets | None |

## Result

Not OK. Fix alert 2's match so a missed import actually alerts, run it as a weekday scheduled workflow, and convert alerts 1 and 3 to detectors with a shared email workflow.

## Related files

| File | Purpose |
|---|---|
| `20-sa-support-batches-alerts-tf-check-main.tf` | 2 detectors, email workflow, import-check workflow |
| `20-sa-support-batches-alerts-tf-check-check.dql` | Per-day match counts, sample import lines, error noise check |
| `20.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/19-recruitimp-serverless-alerts-tf-check/` | Previous check (scheduled workflow pattern) |

## Commands

See `20.sh` (not run).
