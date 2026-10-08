# HTTP Response Check Outlier Confirm

## Decision tree

```
HTTP Response Check Outlier (shown again)
 search same as seq 48? → yes (text:jenkins, AGGW LB, 10m max, median ± 20×MAD, head 1)
 schedule? → */10, Last 24 hours → same
 action? → Send email to one person, "[TEST]" subject → experiment
 text:jenkins exists? → no → never fires
 head 1 after timechart → oldest bucket → logic bug
 → no change: reuse seq 48 tf (enabled = false, low, pagerduty 0)
 → recommendation unchanged: don't migrate as a real alert
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 48. |
| Anything changed? | No. The search, schedule and email action all match. |
| Does it work in Splunk? | No. The sourcetype is missing, and `head 1` checks the oldest bucket. |
| Which tf to use? | The seq 48 tf, unchanged, with `enabled = false`. |
| Severity and PagerDuty | low and "0" |

## Summary

These screenshots show the same test alert again. It still never fires in Splunk, and even with data it would judge the bucket from 24 hours ago. The seq 48 tf is an optional, corrected version that judges the newest bucket and ships disabled.

## Investigation

| What I checked | What I found |
|---|---|
| Search | Same as seq 48, including the outlier calculation written twice. |
| Time range and cron | Last 24 hours, `*/10`. |
| Trigger | Results > 0, once, for each result, no throttle. |
| Action | Send email, Priority Normal, "[TEST] Splunk Alert" subject, one recipient. I did not copy the address. |
| Sourcetype | `text:jenkins` is missing (seq 45 finding). |

## Result

| Setting | Value |
|---|---|
| Resource | `http_response_check_outlier` (same as seq 48) |
| enabled | false |
| Severity | low |
| pagerduty.enabled | "0" |
| Recommendation | Don't migrate as an alert. A Dynatrace synthetic HTTP monitor on the AGGW LB URL is the better long-term option. |

## Data flow map

```
Splunk: text:jenkins → 0 events → never fires
Dynatrace (optional, disabled):
  "[HTTP Monitor] ... duration=<n>s" (HTTP Monitor - AGGW LB)
  → 10m max over 24h → median, MAD
  → newest bucket outside median ± 20×MAD → low-severity problem
```

## Related files

| File | What it is |
|---|---|
| `51-http-response-check-outlier-confirm.tf` | Copy of the seq 48 tf |
| `51-http-response-check-outlier-confirm-check.dql` | Line format and 10-minute chart |
| `51-http-response-check-outlier-confirm.spl` | Sourcetype proof and scheduler history |
| `51.sh` | Commands |

## Commands

These are in `51.sh`. Nothing has been run. Apply from one folder only.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/51-http-response-check-outlier-confirm"
terraform init
terraform validate
terraform plan
terraform apply
```
