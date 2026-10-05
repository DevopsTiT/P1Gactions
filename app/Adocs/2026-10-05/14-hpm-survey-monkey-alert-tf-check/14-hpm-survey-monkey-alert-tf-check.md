# HPM Survey Monkey Alert Terraform Check

## Decision tree

```
hpm-survey-monkey.tf (1 alert, dynatrace_log_alert)
 resource exists?                          → NO → plan fails
 schedule: hourly, last 60 min, throttle 60 → same shape as cmx-sharepoint (seq 7)
   → detector every minute, window 5, dealerting 60 (closes after an hour with no errors)
 DYNATRACE_PROBLEM MEDIUM                  → the detector opens the problem; alert.severity = medium
 "_Normal"                                 → email only, keep out of PagerDuty
 filter status == "ERROR" or contains "ERROR" → OK; add caseSensitive: false
 description typos                         → "Lamda" → "Lambda", "Survey money" → "SurveyMonkey"
 secrets?                                  → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. `dynatrace_log_alert` does not exist |
| Shape | Hourly error alert with 60-minute throttle, the same as `cmx-sharepoint-api.tf` |
| Converted to | Detector (window 5, dealerting 60) plus an email workflow |
| PagerDuty | No, it's `_Normal` |
| Query | Fine; just make `contains` case-insensitive |
| Secrets | None |

## Summary

This is the third HPM alert and it's the same pattern as the CMX-to-SharePoint one: look for ERROR lines from a Lambda once an hour, open a medium problem, email three people, then stay quiet for 60 minutes. In Dynatrace the detector checks every minute, so it alerts faster, and `dealertingSamples = 60` gives the same "one alert, then quiet for an hour" feel. An email workflow sends the recent error lines when the problem opens.

## Line by line

| Line | OK? | Fix |
|---|---|---|
| `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` |
| `description` | Typos | "To check Lambda error: failure transferring files from SurveyMonkey to S3" |
| `contains(aws.log_group, "/aws/lambda/hpm-survey-monkey-prod")` | OK | `==` |
| `filter status == "ERROR" or contains(content, "ERROR")` | OK | Add `caseSensitive: false` to `contains` |
| `sort`, `limit 100` | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| cron `0 * * * *`, LAST_60_MINUTES, expires 7 | Hourly | Not needed; detector runs every minute |
| > 0, once | | `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| throttle 60 minutes | | `dealertingSamples = 60` |
| `DYNATRACE_PROBLEM` MEDIUM | | Detector opens the problem; `alert.severity = medium` |
| Email to 3 people | | Email workflow |

## Detector query

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/hpm-survey-monkey-prod"
| filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
```

| Setting | Value |
|---|---|
| Threshold | 0, Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 60 (use the largest allowed if 60 is rejected) |

## Email workflow

| Part | What it does |
|---|---|
| Trigger | Custom problem named `Prod_Life_HPM_SurveyMonkeyLambdaError_Normal` opens |
| `recent_errors` | ERROR lines from the last 10 minutes |
| `send_email` | Problem id plus the lines to naoya.sota, chungyueh.chiu, hiroshi.annaka (@axa.co.jp) |

## The three HPM alerts together

| File | Lambda | Schedule in Splunk | Dynatrace shape |
|---|---|---|---|
| `cmx-sharepoint-api.tf` (seq 7) | cmx-sharepoint-api-prod | Hourly | Detector + email |
| `hpm-sharepoint-api.tf` (seq 13) | hpm-sharepoint-api-prod | Daily 10:00 | Scheduled workflow digest |
| `hpm-survey-monkey.tf` (this one) | hpm-survey-monkey-prod | Hourly | Detector + email |

All three go to the same people and are `_Normal`. If the team is happy with one style, the two hourly ones can share one `for_each` block and one email workflow (filter on names starting with `Prod_Life_HPM_`).

## Data flow

```
Lambda hpm-survey-monkey-prod (SurveyMonkey → S3)
  → CloudWatch → Dynatrace AWS log forwarding → Grail
  → detector every minute: ERROR count > 0 in window 5
  → problem "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal" (medium)
  → email workflow → last 10 min ERROR lines → 3 people (no PagerDuty)
  → 60 minutes without errors → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot `hpm-survey-monkey.tf` | One `dynatrace_log_alert`, hourly, last 60 minutes, throttle 60 minutes |
| Filter | `status == "ERROR"` or content contains "ERROR" |
| Actions | Problem MEDIUM, email to 3 people |
| Compared | Same pattern as seq 7; same recipients as seq 7 and seq 13 |
| Secrets | None |

## Result

Not OK as is. Use a detector (window 5, dealerting 60, case-insensitive ERROR) and an email workflow, fix the description typos, and keep it out of PagerDuty.

## Related files

| File | Purpose |
|---|---|
| `14-hpm-survey-monkey-alert-tf-check-main.tf` | Detector and email workflow |
| `14.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/7-hpm-cmx-sharepoint-alert-tf-check/` | Same hourly pattern |
| `2026-10-05/13-hpm-sharepoint-api-alert-tf-check/` | Daily HPM alert |

## Commands

See `14.sh` (not run).
