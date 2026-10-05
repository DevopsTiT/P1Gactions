# PMT API Alerts Terraform Check

## Decision tree

```
pmt-api.tf (9 alerts, all dynatrace_log_alert)
 resource exists?                          → NO → plan fails
 alert 2 parse "LD LD LD LD NUMBER"        → BROKEN: grabs the wrong number → "LD 'Max Memory Used: ' INT:memory_usage"
 alerts 6 and 7 same query                 → DUPLICATE: two problems for one log line → keep 7, delete 6
 throttle 60 SECONDS (alerts 4, 6, 7, 8, 9) → does nothing on a 5-min schedule → probably meant 60 MINUTES; ask
 alert 3 LAST_6_MINUTES on */5             → overlap, same line can alert twice → detector fixes it
 subject "Alert: $name$"                   → Splunk token → {{ event()["event.name"] }}
 description "Optional", names without prefix → rename to Prod_Life_PMT_..._Normal
 contains(...)                             → add caseSensitive: false
 3 recipient groups + 1 problem-only       → 8 detectors (for_each) + 3 email workflows (for_each)
 secrets?                                  → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. All 9 use `dynatrace_log_alert` |
| Real bug 1 | Alert 2's memory parse picks up the wrong number, so the 480 MB check is meaningless |
| Real bug 2 | Alerts 6 and 7 are the same alert twice |
| Suspicious | `throttle_suppress_for = 60` with unit `SECONDS` is shorter than the 5-minute schedule, so it never suppresses anything |
| Converted to | 8 detectors from one `for_each` map, 3 email workflows (one per recipient group) |
| Secrets | None |

## Summary

This file has two real bugs on top of the usual missing resource. The memory alert's parse pattern (`LD LD LD LD NUMBER`) has no anchor text, so it captures whatever number appears first, not "Max Memory Used". And alerts 6 and 7 search for exactly the same message, which would open two problems for every exception. The rest are simple "phrase seen" alerts, so they fit one `for_each` map. Emails go to three different recipient groups, so there's one small workflow per group, each triggered by the names of its own alerts.

## The 9 alerts

| # | Original name | Matches | Original action | Converted |
|---|---|---|---|---|
| 1 | Unexpected Error | `Unexpected error` | Email PA | `Prod_Life_PMT_UnexpectedError_Normal`, group pa |
| 2 | STP APIs Memory Usage over 480MB | Max Memory Used > 480 | Email Koichi + PA | Fixed parse, `max(memory_usage)` > 480, group pa_koichi |
| 3 | TransFormation Timeout | `Task timed out` | Email PA | Typo fixed, group pa |
| 4 | SendApprovalReminder handler failed | Same phrase | Email PA, throttle 60 s | Group pa |
| 5 | pmt-api SFDC Error | `An error occurred while calling sfdc api` | Email adept, Japanese subject | Group adept, subject kept |
| 6 | Exception in myAxaMailSender | Same phrase | Problem MEDIUM, throttle 60 s | **Deleted** (duplicate of 7) |
| 7 | Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal | Same phrase as 6 | Problem MEDIUM, throttle 60 s | Kept, problem only, no email |
| 8 | Exception in ExportData for Datalake | `Exception in ExportData` | Email Koichi + PA, throttle 60 s | Group pa_koichi |
| 9 | Error occurred during email sending process for this user | Same phrase | Email PA, throttle 60 s | Group pa |

PA means `alj_jp_dl_processautomation@axa.co.jp`. Koichi is `koichi.nagamine@axa.co.jp`. adept is `ALJ_JP_DL_adept@axa.co.jp`.

## Bug 1: the memory parse

A Lambda REPORT line looks like this:

```
REPORT RequestId: 3f2a... Duration: 1234.56 ms Billed Duration: 1235 ms Memory Size: 512 MB Max Memory Used: 312 MB
```

| Pattern | What it captures |
|---|---|
| `LD LD LD LD NUMBER:memory_usage` (current) | The first number the matcher can reach, often from the RequestId or Duration. Not the memory value |
| `LD 'Max Memory Used: ' INT:memory_usage` (fixed) | `312`, the number right after the anchor text |

Run query 1 in `check.dql` to see the old and fixed values side by side.

The detector then tracks the peak per minute:

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/pmt-api-prod"
| parse content, "LD 'Max Memory Used: ' INT:memory_usage"
| filter isNotNull(memory_usage)
| makeTimeseries memory_mb = max(memory_usage), interval:1m
```

Threshold 480, Above. If the function's Memory Size is 512 MB, 480 means "within about 6% of running out".

## Bug 2: alerts 6 and 7 are duplicates

Both search `pmt-api-prod` for `Exception in myAxaMailSender` with the same schedule and the same action. Keep alert 7 (it has a proper name and description) and delete alert 6. Query 3 in `check.dql` confirms they match the same lines.

## The 60-second throttle

| Setting | What happens |
|---|---|
| Schedule every 5 minutes, throttle 60 seconds | The throttle expires before the next run, so it never suppresses anything |
| What they probably meant | 60 minutes: one alert, then quiet for an hour |

In the conversion, all alerts use `dealertingSamples = 5` (one problem per burst). If the team confirms "60 minutes", change it to 60 for alerts 4, 7, 8 and 9.

## Detector query (all phrase alerts)

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/pmt-api-prod"
| parse content, "LD 'Max Memory Used: ' INT:memory_usage"
| filter contains(content, "Unexpected error", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
```

The parse line is shared by every query in the map. On non-REPORT lines it just leaves `memory_usage` empty and costs very little.

| Setting | Value |
|---|---|
| Threshold | 0 (480 for memory), Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | medium |

## Email workflows (one per recipient group)

| Group | Recipients | Alerts | Subject |
|---|---|---|---|
| pa | processautomation | 1, 3, 4, 9 | `Alert: <problem name>` |
| pa_koichi | koichi.nagamine, processautomation | 2, 8 | `Alert: <problem name>` |
| adept | ALJ_JP_DL_adept | 5 | `[pmt-api] SFDC処理失敗のお知らせ` |
| none | nobody | 7 | Problem only, as in the original |

Each workflow triggers on the exact names of its alerts (built with `matchesPhrase ... or ...` from the map) and sends the matching lines from the last 10 minutes.

## Questions for the PMT team

| Question | Why it matters |
|---|---|
| Was the throttle meant to be 60 minutes? | Changes dealerting from 5 to 60 for 4 alerts |
| OK to rename to `Prod_Life_PMT_..._Normal`? | Email subjects will change |
| Should alert 7 also email someone? | In Splunk it only created a problem |
| What is the Lambda's Memory Size? | Confirms 480 MB is the right line |

## Data flow

```
Lambda pmt-api-prod
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  → 8 detectors every minute (7 phrase counts > 0, 1 peak memory > 480 MB)
  → problem "<alert name>" (medium)
  → email workflow for that alert's group (pa, pa_koichi, adept) → recipients
  → alert 7: problem only
  → 5 clean minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| 9 screenshots of `pmt-api.tf` | 9 `dynatrace_log_alert` blocks, 384 lines |
| Log group | All `/aws/lambda/pmt-api-prod` |
| Alert 2 parse | No anchor text, captures the wrong number |
| Alerts 6 and 7 | Identical query and action |
| Throttle | 60 seconds on alerts 4, 6, 7, 8, 9 |
| Alert 3 | `LAST_6_MINUTES` on a 5-minute cron |
| Recipients | 3 email groups, and alerts 6 and 7 are problem only |
| Secrets | None |

## Result

Not OK. Fix the memory parse, drop the duplicate alert 6, convert the rest with one `for_each` detector map and three email workflows, and confirm the throttle intent with the team.

## Related files

| File | Purpose |
|---|---|
| `18-pmt-api-alerts-tf-check-main.tf` | 8 detectors and 3 email workflows |
| `18-pmt-api-alerts-tf-check-check.dql` | Parse comparison, memory peaks, duplicate proof, match counts |
| `18.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/17-emma-onboarding-batch-alerts-tf-check/` | Same `for_each` pattern |

## Commands

See `18.sh` (not run).
