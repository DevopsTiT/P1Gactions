# HPM SharePoint API Alert Terraform Check

## Decision tree

```
hpm-sharepoint-api.tf (1 alert, dynatrace_log_alert)
 resource exists?                          → NO → plan fails
 schedule: daily 10:00, last 24 hours      → daily digest → scheduled workflow (count + latest 100 + email)
 throttle 60 minutes                       → meaningless with a daily run → drop
 DYNATRACE_PROBLEM MEDIUM on a daily check → a problem would open once a day at 10:00 and look like a live incident
   team really wants a problem?            → add a JavaScript task that raises a CUSTOM_ALERT (see seq 10 pending pattern)
   otherwise                               → email only ("_Normal" = not urgent, no PagerDuty)
 filter status == "ERROR" or contains "ERROR" → OK; status is the Dynatrace log status field; make contains ignore case
 secrets?                                  → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. `dynatrace_log_alert` does not exist |
| What kind of alert | Once-a-day summary of yesterday's errors, so a scheduled workflow |
| Problem MEDIUM | Doesn't fit a daily digest; email only unless the team insists |
| Throttle 60 minutes | Has no effect on a daily run; remove |
| Query | Fine; `status` is a real Dynatrace log field |
| Related | Same team and recipients as `cmx-sharepoint-api.tf` (seq 7), which was hourly |

## Summary

This is the sister alert of the CMX-to-SharePoint one: same team, same three recipients, but it runs once a day at 10:00 over the last 24 hours. That makes it a daily digest, so the right Dynatrace shape is a scheduled workflow that counts errors, lists the latest 100 and emails only when there are any. The `DYNATRACE_PROBLEM` action and 60-minute throttle were copied from the hourly alert and don't make sense for a once-a-day check.

## Line by line

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_automation_workflow` with a schedule |
| `description` "To check Lamda error..." | Field OK | Fix the typo "Lamda" to "Lambda" |
| `contains(aws.log_group, "/aws/lambda/hpm-sharepoint-api-prod")` | OK | `==` |
| `filter status == "ERROR" or contains(content, "ERROR")` | OK | `status` is the level Dynatrace detected; add `caseSensitive: false` to the `contains` |
| `sort`, `limit 100` | Hides the total | Count task for the total, list task for the latest 100 |
| cron `0 10 * * *`, LAST_24_HOURS, expires 7 | Daily | `cron = "0 10 * * *"`, `time_zone = "Asia/Tokyo"`, `from:now()-24h` |
| > 0, once | | Email only if total > 0 |
| throttle 60 minutes | No effect | Remove |
| `DYNATRACE_PROBLEM` MEDIUM | Doesn't fit | Email only (or raise an event from the workflow if really needed) |
| Email to 3 people | | Email task |

## Fixed query

```dql
fetch logs, from:now()-24h
| filter aws.log_group == "/aws/lambda/hpm-sharepoint-api-prod"
| filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
| summarize total = count()
```

The list task uses the same filters with `fields timestamp, status, content | sort timestamp desc | limit 100`.

## Workflow

| Task | What it does |
|---|---|
| Schedule | Every day at 10:00 Asia/Tokyo |
| `count_errors` | Total ERROR lines in the last 24 hours |
| `list_errors` | Latest 100 ERROR lines |
| `send_email` | Runs only if total > 0; sends total plus the lines to naoya.sota, chungyueh.chiu and hiroshi.annaka (@axa.co.jp; check spelling) |

## If the team wants a problem too

A daily check would open the problem at 10:00 for errors that may have happened at 02:00, so it is late and looks like a live incident. If they still want it, add a JavaScript task after `count_errors` that calls `eventsClient.createEvent` with `eventType: 'CUSTOM_ALERT'` and title `Prod_Life_HPM_SharepointAPILambdaError_Normal` (same code shape as the pending-uploads task in seq 10). Keep it out of PagerDuty since it is `_Normal`. The better option for real-time is the hourly-style detector used in seq 7.

## Data flow

```
Lambda hpm-sharepoint-api-prod (S3 <-> SharePoint)
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  → 10:00 JST schedule
  → count ERROR lines in last 24h + list latest 100
  → total > 0 ? → email 3 people
  → total = 0  → skip
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot `hpm-sharepoint-api.tf` | One `dynatrace_log_alert`, daily cron at 10:00 over 24 hours |
| Filter | `status == "ERROR"` or content contains "ERROR" |
| Actions | Problem MEDIUM, throttle 60 minutes, email to 3 people |
| Compared with seq 7 | Same team and recipients; seq 7 was hourly, this is daily |
| Secrets | None |

## Result

Not OK as is. Build it as a daily scheduled workflow (count, latest 100, email if any), drop the throttle and the problem action, and add `caseSensitive: false` to the content filter.

## Related files

| File | Purpose |
|---|---|
| `13-hpm-sharepoint-api-alert-tf-check-main.tf` | Fixed daily workflow |
| `13.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/7-hpm-cmx-sharepoint-alert-tf-check/` | Sister alert (hourly) |
| `2026-10-05/10-document-upload-api-alerts-tf-check/` | JavaScript event-raising pattern |

## Commands

See `13.sh` (not run).
