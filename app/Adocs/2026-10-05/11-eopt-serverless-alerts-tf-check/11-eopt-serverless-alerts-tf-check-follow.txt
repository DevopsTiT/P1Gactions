# EOPT Serverless Alerts Terraform Check

## Decision tree

```
eopt-serverless.tf (2 alerts, both dynatrace_log_alert)
 resource exists?                          → NO → plan fails
 parse "LD '-' x4 LD SPACE WORD:level"
   works for Lambda default lines?        → yes, by luck (4 hyphens land inside the request id)
   Python "[ERROR]" or JSON logs?          → NO → level never matches → alert silent
   safer?                                  → check if Dynatrace already sets loglevel; use that
 ALERT 1 E-Tool Error Lambda (*/5, 5 min)  → detector + email workflow that lists the lines
 ALERT 2 eopt AWS Serverless Error (daily) → scheduled workflow at 10:00 JST, count + latest 100 lines
 secrets?                                  → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. Both use `dynatrace_log_alert`, which does not exist |
| Biggest risk | The `parse` pattern is fragile; if the log format differs, the alerts never fire |
| Alert 1 | Detector every minute plus an email that lists the recent ERROR lines |
| Alert 2 | Daily digest, so a scheduled workflow (same pattern as the CSDDM daily alert) |
| Secrets | None |

## Summary

Both alerts look for ERROR lines from the `eopt-serverless-prod` Lambda. Alert 1 is the real-time one (every 5 minutes, short "filtered" email). Alert 2 is a daily 10:00 digest of the last 24 hours with full lines. The query is already DQL, but its `parse` pattern finds the level by skipping four hyphens and then grabbing the next word. That happens to work for the default Node.js Lambda format and breaks for other formats, so check it first.

## How the parse pattern works (and why it's fragile)

Default Lambda log line (Node.js):

```
2026-10-05T01:02:03.456Z	1a2b3c4d-1111-2222-3333-444455556666	ERROR	Something failed
```

| Step | Pattern part | What it consumes |
|---|---|---|
| 1 | `LD '-'` | `2026-` (first hyphen, in the date) |
| 2 | `LD '-'` | `10-` (second hyphen, in the date) |
| 3 | `LD '-'` | `05T01:02:03.456Z<TAB>1a2b3c4d-` (first hyphen in the request id) |
| 4 | `LD '-'` | `1111-` |
| 5 | `LD SPACE WORD:level` | Skips `2222-3333-444455556666`, then the tab, then grabs `ERROR` |

| Log format | Result |
|---|---|
| Node.js default (above) | Works |
| Python default `[ERROR]	2026-...	request-id	message` | Fails: the level comes before the hyphens |
| Lambda JSON logging `{"level":"ERROR",...}` | Fails |
| Message without a request id | Fails or grabs the wrong word |

Run this to see which format you have and whether Dynatrace already detected the level:

```dql
fetch logs, from:-1d
| filter startsWith(aws.log_group, "/aws/lambda/eopt-serverless-prod")
| parse content, "LD '-' LD '-' LD '-' LD '-' LD SPACE WORD:level"
| fields timestamp, loglevel, level, content
| limit 20
```

| What you see | Use |
|---|---|
| `loglevel` shows ERROR on error lines | `filter loglevel == "ERROR"` (simplest; swap it into `eopt_error_filter` in the `.tf`) |
| `level` correct, `loglevel` empty or wrong | Keep the parse (default in the file) |
| Both wrong | Share a sample line and I'll write a pattern for it |

## Alert 1 — E-Tool Error Lambda (Filtered Output)

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` |
| `contains(aws.log_group, ...)` | OK | `startsWith` (same scope, clearer) |
| parse and `level == "ERROR"` | Fragile | Check as above |
| `fields timestamp, level, content` | Useful for the email | Kept in the email workflow's query |
| `*/5`, 5 minutes, > 0, once | | Window 5, threshold 0, ABOVE, violating 1, dealerting 5 |
| Email to aij_jp_dl_etool_maintenance | | Email workflow: fetch the last 10 minutes of ERROR lines, then email them |

## Alert 2 — eopt - AWS Serverless Error (Full Output)

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_automation_workflow` with a schedule |
| cron `0 10 * * *`, last 24 hours | Daily | `cron = "0 10 * * *"`, `time_zone = "Asia/Tokyo"`, `from:now()-24h` |
| `limit 100` | Hides the real total | Count task for the total, list task for the latest 100 |
| > 0 | | Email only if total > 0 |
| Email to etool_maintenance and chungyueh.chiu | | Email task |

Alert 2 reports the same errors as Alert 1, just once a day. That's fine if the team wants a daily summary on top of real-time emails.

## Fixed file

`11-eopt-serverless-alerts-tf-check-main.tf`:

| Resource | What it does |
|---|---|
| `local.eopt_error_filter` | One place for the ERROR filter; swap to `loglevel` if the check shows it works |
| `dynatrace_davis_anomaly_detectors.etool_error_lambda` | Opens a problem when any ERROR line appears (window 5) |
| `dynatrace_automation_workflow.etool_error_lambda_email` | On that problem: fetch last 10 minutes of ERROR lines, email timestamp, level, message |
| `dynatrace_automation_workflow.eopt_aws_serverless_error` | Daily 10:00 JST: count and latest 100 ERROR lines, email if any |

## Data flow

```
Lambda eopt-serverless-prod
  → CloudWatch /aws/lambda/eopt-serverless-prod
  → Dynatrace AWS log forwarding → Grail
  ALERT 1: detector every minute → ERROR count > 0 → problem "E-Tool Error Lambda"
           → email workflow → last 10 min ERROR lines → aij_jp_dl_etool_maintenance
  ALERT 2: 10:00 JST schedule → count + latest 100 ERROR lines in 24h
           → total > 0 → email etool_maintenance + chungyueh.chiu
```

## Investigation

| Checked | Finding |
|---|---|
| Two screenshots of `eopt-serverless.tf` | Two `dynatrace_log_alert` resources |
| Alert 1 | ERROR via parse, every 5 minutes, 1 recipient |
| Alert 2 | Same query, daily at 10:00 over 24 hours, 2 recipients |
| Parse pattern | Relies on hyphen positions in the default Node.js Lambda format |
| Secrets | None |

## Result

Not OK as is. Run the check query to confirm the log format, then use the detector plus email workflow for Alert 1 and the scheduled workflow for Alert 2. If Dynatrace already sets `loglevel`, use it instead of the parse.

## Related files

| File | Purpose |
|---|---|
| `11-eopt-serverless-alerts-tf-check-main.tf` | Both alerts |
| `11.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/8-cs-digital-document-alerts-tf-check/` | Same daily-digest pattern |

## Commands

See `11.sh` (not run).
