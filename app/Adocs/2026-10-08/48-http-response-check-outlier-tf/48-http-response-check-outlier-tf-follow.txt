# HTTP Response Check Outlier

## Decision tree

```
HTTP Response Check Outlier (AGGW LB)
 sourcetype="text:jenkins" exists? → no (seq 45) → never matches
 subject "[TEST]", one recipient? → yes → experiment, not on-call
 "head 1" after timechart → oldest bucket (24h ago) → logic bug even with data
 → recommendation: do NOT migrate as a real alert
 still want response-time outlier detection?
   → optional tf: newest 10m bucket vs median ± 20×MAD, enabled = false, severity low
   → better long-term: Dynatrace synthetic HTTP monitor or service response-time anomaly detection
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it try to do? | Flag when AGGW LB response time is far from normal: outside median ± 20 × MAD over 24 hours. |
| Does it work in Splunk? | No. The sourcetype is missing, and `head 1` checks the oldest bucket. |
| Who gets it? | One person, with the subject "[TEST]". |
| Recommendation | Do not migrate as an alert. An optional, corrected detector is provided switched off. |
| Severity and PagerDuty | low and "0" |

## Summary

This is a test alert that never worked. Its sourcetype does not exist, and even with data it judges the bucket from 24 hours ago, because `timechart` output is oldest-first and `head 1` takes that first row. The optional tf fixes the logic so it compares the newest 10-minute bucket against median ± 20 × MAD. It ships disabled with low severity, so nothing changes unless someone deliberately turns it on.

## Investigation

### What the Splunk search does

| Step | What it does |
|---|---|
| `[HTTP Monitor]` and `job_name="HTTP Monitor - AGGW LB"` | Keeps HTTP Monitor lines for the AGGW load balancer job. |
| `replace(duration,"s","")` | Turns "1.2s" into 1.2. |
| `timechart span=10m max(duration)` | Takes the slowest response in each 10-minute bucket. |
| `streamstats window=200 median` | Calculates the median over the buckets. |
| `median(absDev)` | Calculates the MAD, which measures the normal spread. |
| `median ± MAD × 20` | Sets wide bounds, so only extreme values count. |
| `head 1` | Keeps the first row, which is the oldest bucket. |
| `search isOutlier="1"` | Alerts if that bucket is outside the bounds. |

### Problems found

| Problem | Effect |
|---|---|
| The sourcetype `text:jenkins` is missing | No events, so the alert never fires. |
| `head 1` after `timechart` | It checks the bucket from 24 hours ago instead of the latest one. |
| The outlier calculation is repeated twice | Harmless, but it shows copy-paste testing. |
| "[TEST]" subject and one recipient | Not an on-call alert. |

### Other settings

| Setting | Value |
|---|---|
| Time range | Last 24 hours |
| Cron | `*/10 * * * *` |
| Action | Email to one person, Priority Normal. I did not copy the recipient. |

## Result

| Setting | Value |
|---|---|
| Resource | `http_response_check_outlier` |
| enabled | false |
| Logic | Newest 10-minute max compared with median ± 20 × MAD over 24 hours |
| Duration parse | `LD 'duration=' DOUBLE:duration`, which needs to be confirmed |
| Severity | low |
| pagerduty.enabled | "0" |

### Better long-term options

| Option | Why |
|---|---|
| Dynatrace HTTP synthetic monitor on the AGGW LB URL | Built-in response-time and availability alerts, with no Jenkins log parsing. |
| Service response-time anomaly detection | Learns a baseline automatically if the AGGW traffic goes through a monitored service. |

## Data flow map

```
Splunk: text:jenkins → 0 events → never fires (and head 1 = oldest bucket)
Dynatrace (optional, disabled):
  Jenkins console "[HTTP Monitor] ... duration=<n>s" (AGGW LB job)
  → 10-minute max response time over 24h
  → median, MAD over buckets
  → newest bucket outside median ± 20×MAD → low-severity problem
```

## Related files

| File | What it is |
|---|---|
| `48-http-response-check-outlier-tf.tf` | Optional corrected detector, disabled |
| `48-http-response-check-outlier-tf-check.dql` | Line format and a 10-minute response time chart |
| `48-http-response-check-outlier-tf.spl` | Sourcetype proof and scheduler result count |
| `48.sh` | Commands |

## Commands

These are in `48.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/48-http-response-check-outlier-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
