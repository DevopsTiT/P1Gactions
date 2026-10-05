# Customer Process API Alerts Terraform Check

## Decision tree

```
customer-process-api.tf (2 alerts, both dynatrace_log_alert)
 resource exists?                          → NO → plan fails (same as the other files)
 ALERT 1 Success Request Monitoring ("statusCode":201)
   is it a failure?                        → NO, it reports successful contract requests
   open a Davis problem?                   → NO, that would create SILVA tickets / pages for good news
   use                                     → scheduled workflow every 5 min: DQL → email the lines if any
 ALERT 2 Customer Process API Alerts (9 failure messages)
   is it a failure?                        → YES → anomaly detector + email workflow
   case?                                   → lower(content) once, compare lower-case strings
   OR chain                                → fine in DQL; keep it inside one filter
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. Both resources use `dynatrace_log_alert`, which does not exist |
| Alert 1 | A "success" notification, so use a scheduled workflow that emails the matching lines; don't open a problem |
| Alert 2 | Anomaly detector (window 5) plus email workflow |
| Case | Use `lower(content)` once, then lower-case search strings |
| Secrets | None |

## Summary

Alert 1 is the unusual one: it emails the team when a request **succeeds** (HTTP 201), so they see real production contract requests. If you turned that into a Davis problem, every successful request would look like an incident and could hit your SILVA and PagerDuty workflow. A scheduled workflow that queries the last 5 minutes and emails the lines is the right fit. Alert 2 is a normal failure alert with 9 known error messages; it becomes an anomaly detector plus an email workflow.

## Alert 1 — Customer Process API Success Request Monitoring

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_automation_workflow` with a schedule |
| log group `/aws/lambda/customer-process-api-prod` | OK | Use `==` |
| `contains(content, "\"statusCode\":201")` | OK if the JSON has no space | If logs look like `"statusCode": 201`, change the text (check below) |
| `fields`, `sort`, `limit 100` | OK here | The workflow keeps them so the email can list the lines |
| `*/5`, LAST_5_MINUTES | | Schedule `cron = "*/5 * * * *"`, query `from:now()-6m, to:now()-1m` |
| > 0, once | | Email task runs only if there are records |
| Email to 4 people, `!!PROD!! Alert: $name$` | | Email task with the real title in the subject |

Why `from:now()-6m, to:now()-1m`: logs can take a minute to arrive. Shifting the window by 1 minute avoids missing lines that arrive late, and still covers 5 minutes per run with no overlap.

```hcl
trigger {
  schedule {
    active    = true
    time_zone = "Asia/Tokyo"
    trigger {
      cron = "*/5 * * * *"
    }
  }
}
```

Email content lists each line:

```
{{ result("find_success").records | length }} successful request(s) in the last 5 minutes.

{% for r in result("find_success").records %}{{ r.timestamp }}  {{ r.content }}
{% endfor %}
```

Check the 201 text format first:

```dql
fetch logs, from:-1d
| filter aws.log_group == "/aws/lambda/customer-process-api-prod"
| filter contains(content, "statusCode")
| fields timestamp, content
| limit 10
```

## Alert 2 — Customer Process API Alerts

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` |
| `description = "Optional"` | Placeholder | Real text |
| 9 `contains` checks joined with `or` | Logic OK | Keep in one filter; make them case-insensitive |
| `fields`, `sort`, `limit 100` | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| `*/5`, LAST_5_MINUTES, > 0, once | | `slidingWindow = 5`, `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| throttle off | | `dealertingSamples = 5` |
| Email to aij_jp_dl_adept | | Email workflow on the problem name |

The 9 messages, in lower case so one `lower(content)` handles every case:

| Message | What it likely means |
|---|---|
| task timed out | Lambda ran past its time limit |
| an error occurred | Generic error from the code or an AWS SDK call |
| failed to handle: lifejdata | Processing of LifeJData failed |
| got unexpected investment company code | Input had an unknown investment company code |
| the policy is ineligible for creating a request | Business rule rejected the request |
| ibl0250002 | A specific application error code |
| `<statuscd>eb` | A response with status code EB (likely an error status in an XML reply) |
| imported a total of 0 data | Import ran but brought in nothing |
| handler error: too many connections | Database or downstream connection limit hit |

The photo is small; compare each string with the original file before applying (especially `IBL0250002` and `<StatusCd>EB`).

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/customer-process-api-prod"
| fieldsAdd c = lower(content)
| filter contains(c, "task timed out")
    or contains(c, "an error occurred")
    or contains(c, "failed to handle: lifejdata")
    or contains(c, "got unexpected investment company code")
    or contains(c, "the policy is ineligible for creating a request")
    or contains(c, "ibl0250002")
    or contains(c, "<statuscd>eb")
    or contains(c, "imported a total of 0 data")
    or contains(c, "handler error: too many connections")
| makeTimeseries count = count(default: 0), interval:1m
```

To see which messages actually fire (helps tune later):

```dql
fetch logs, from:-7d
| filter aws.log_group == "/aws/lambda/customer-process-api-prod"
| fieldsAdd c = lower(content)
| fieldsAdd reason = if(contains(c, "task timed out"), "timeout",
    else: if(contains(c, "too many connections"), "too many connections",
    else: if(contains(c, "imported a total of 0 data"), "zero import",
    else: if(contains(c, "ibl0250002"), "IBL0250002",
    else: if(contains(c, "policy is ineligible"), "ineligible policy",
    else: if(contains(c, "investment company code"), "bad company code",
    else: if(contains(c, "failed to handle: lifejdata"), "lifejdata",
    else: if(contains(c, "<statuscd>eb"), "status EB",
    else: if(contains(c, "an error occurred"), "an error occurred")))))))))
| filter isNotNull(reason)
| summarize count = count(), by:{reason}
| sort count desc
```

## Routing

| Alert | Opens a problem? | Goes to |
|---|---|---|
| 1 Success monitoring | No | Email to iori.baba, ryo.masuda, naoki.takuda, akito.matsumoto.ose (@axa.co.jp, check spelling) |
| 2 API alerts | Yes | Email to aij_jp_dl_adept@axa.co.jp; make sure your SILVA/PagerDuty workflow treats it the way the team expects |

## Data flow

```
ALERT 1 (success notice)
  every 5 min schedule → DQL: "statusCode":201 in [now-6m, now-1m]
    → records > 0 ? → email the lines to 4 people
    → none          → skip

ALERT 2 (failures)
  Lambda logs → Grail → detector every minute (9 messages, any case, window 5)
    → count > 0 → problem "Customer Process API Alerts"
    → email workflow → aij_jp_dl_adept
    → 5 quiet minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Two screenshots of `customer-process-api.tf` | Two `dynatrace_log_alert` resources |
| Alert 1 | Success (201) monitoring, every 5 minutes, 4 recipients, subject `!!PROD!! Alert: $name$` |
| Alert 2 | 9 failure strings joined with `or`, every 5 minutes, 1 recipient |
| Case | All strings were case-insensitive in Splunk; `lower(content)` reproduces that |
| Secrets | None |

## Result

Not OK as is. Alert 1 becomes a scheduled workflow that emails the 201 lines (no problem, no ticket). Alert 2 becomes an anomaly detector with a case-insensitive OR filter, plus an email workflow. Check the 201 text format and the 9 strings against the original file, then validate and plan.

## Related files

| File | Purpose |
|---|---|
| `9-customer-process-api-alerts-tf-check-main.tf` | Both fixed alerts and the email workflow |
| `9.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/8-cs-digital-document-alerts-tf-check/` | Scheduled workflow pattern used for the daily alert |

## Commands

See `9.sh` (not run).
