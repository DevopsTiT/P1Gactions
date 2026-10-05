# RecruitImp Serverless Alerts Terraform Check

## Decision tree

```
recruitimp-serverless.tf (2 alerts, dynatrace_log_alert)
 resource exists?                          → NO → plan fails
 log group spelled two ways                → alert 1 "recrutimp", alert 2 "recruitimp" → one matches nothing → check.dql query 1
 alert 1: daily 08:00, last 24 h           → scheduled workflow digest (count + list, email only if > 0)
 alert 1 parse "LD LD WORD:level"          → no anchor, unreliable → status == "ERROR" or TAB-ERROR-TAB or "[ERROR]"
 alert 2: every 5 min                      → detector + email workflow
 alert 2 parse "WORD:a WORD:b WORD:c"      → BROKEN: no SPACE between matchers → never matches → add SPACE, NSPACE for ids
 subject "Alert: $name$", "Optional"       → Splunk leftovers → real subject and descriptions
 secrets?                                  → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. Both use `dynatrace_log_alert` |
| Bug 1 | The log group is spelled `recrutimp` in alert 1 and `recruitimp` in alert 2. One of them watches nothing |
| Bug 2 | Alert 2's parse has no `SPACE` between the fields, so it never matches and never alerts |
| Weak spot | Alert 1's parse `LD LD WORD` has no anchor text, so `level` may be the wrong word |
| Converted to | Alert 1 as a daily scheduled workflow, alert 2 as a detector plus email |
| Secrets | None |

## Summary

Both alerts in this file probably never fired correctly. One of the two log group names is misspelled, and alert 2's parse pattern can't match any line because the three `WORD` fields have nothing between them. Alert 1 is a daily 08:00 report, so it becomes a scheduled workflow that only emails when there were errors. Alert 2 runs every 5 minutes, so it becomes a detector plus an email. Run `check.dql` first: it shows which log group is real and how many lines the old and new filters catch.

## Bug 1: two spellings of the log group

| Alert | Log group in the file |
|---|---|
| 1 (AWS Serverless Error) | `/aws/lambda/recrutimp-serverless-prod` |
| 2 (RI Monitoring Error) | `/aws/lambda/recruitimp-serverless-prod` |

The file is named `recruitimp-serverless.tf`, so `recruitimp` is most likely right. The Terraform uses one shared local, so you only fix it in one place. Query 1 in `check.dql` shows which name actually has logs. (The alert name and resource names also say `recrutimp`.)

## Bug 2: alert 2's parse

| Pattern | Result |
|---|---|
| `WORD:session_id WORD:level WORD:user_id` (current) | `WORD` stops at a space, and the next `WORD` cannot match a space. The pattern never matches, `level` is always empty, and the alert never fires |
| `NSPACE:session_id SPACE WORD:level SPACE NSPACE:user_id` (fixed) | Matches `abc-123 ERROR u-456 ...`. `NSPACE` also accepts IDs with dashes, which `WORD` does not |

Query 3 in `check.dql` compares both, and query 4 shows real lines so you can confirm the format starts with the session ID.

## Alert 1: weak parse

`parse content, "LD LD WORD:level"` has no fixed text to anchor on. Two `LD` in a row can split the line in many ways, so `level` might be the first word of the line, not the log level. The conversion uses a filter that works for both common Lambda formats instead:

```dql
fetch logs, from:now()-24h
| filter aws.log_group == "/aws/lambda/recruitimp-serverless-prod"
| filter status == "ERROR" or contains(content, "\tERROR\t") or contains(content, "[ERROR]")
```

| Lambda runtime | Line format | Caught by |
|---|---|---|
| Node.js | `2026-10-05T08:00:00Z<TAB>requestId<TAB>ERROR<TAB>message` | `\tERROR\t` |
| Python | `[ERROR]<TAB>2026-10-05T08:00:00Z<TAB>requestId<TAB>message` | `[ERROR]` |
| Either, if Dynatrace detected the level | Any | `status == "ERROR"` |

## Alert 1 conversion: daily workflow

| Original | Dynatrace |
|---|---|
| cron `0 8 * * *`, last 24 hours | Schedule `0 8 * * *`, `time_zone = "Asia/Tokyo"` |
| `> 0`, once | `list_errors` and the email run only if `count_errors` total > 0 |
| No throttle | Not needed; it runs once a day |
| Email to etool_maintenance and chungyueh.chiu | Same, subject shows the count, body lists the latest 100 lines |

Check what time zone the Splunk server used. If it was UTC, the old report arrived at 17:00 JST, not 08:00.

## Alert 2 conversion: detector plus email

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/recruitimp-serverless-prod"
| parse content, "NSPACE:session_id SPACE WORD:level SPACE NSPACE:user_id"
| filter level == "ERROR"
| makeTimeseries count = count(default: 0), interval:1m
```

| Setting | Value |
|---|---|
| Threshold | 0, Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | medium |

The email lists the last 10 minutes of matching lines with `session_id` and `user_id`, sent to etool_maintenance.

## Data flow

```
Lambda recruitimp-serverless-prod
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  Alert 1: 08:00 JST daily workflow → count ERROR (24 h) → > 0? → list 100 → email etool_maintenance + chungyueh.chiu
  Alert 2: detector every minute → RI level ERROR > 0 in window 5
           → problem "Prod_Life_RecruitImp_RIMonitoringError_Normal"
           → email workflow → etool_maintenance
           → 5 clean minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| 2 screenshots of `recruitimp-serverless.tf` | 2 `dynatrace_log_alert` blocks, 87 lines |
| Log group | Spelled `recrutimp` in alert 1 and `recruitimp` in alert 2 |
| Alert 1 | Daily 08:00, last 24 hours, parse `LD LD WORD:level`, email 2 recipients |
| Alert 2 | Every 5 minutes, parse with no SPACE between WORD matchers, email 1 recipient |
| Subjects and descriptions | `$name$` and `"Optional"` |
| Secrets | None |

## Result

Not OK. Confirm the log group spelling, fix alert 2's parse, replace alert 1's parse with a robust ERROR filter, and convert to a daily workflow (alert 1) and a detector plus email (alert 2).

## Related files

| File | Purpose |
|---|---|
| `19-recruitimp-serverless-alerts-tf-check-main.tf` | Daily workflow, detector and email workflow |
| `19-recruitimp-serverless-alerts-tf-check-check.dql` | Log group check, old vs new parse counts, sample lines |
| `19.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/13-hpm-sharepoint-api-alert-tf-check/` | Same daily digest pattern |

## Commands

See `19.sh` (not run).
