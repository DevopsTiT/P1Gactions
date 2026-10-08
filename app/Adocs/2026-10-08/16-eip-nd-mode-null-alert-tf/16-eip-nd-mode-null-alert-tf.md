# EIP ND Mode Null Alert TF

## Decision tree

```
Any EIP ND Mode entry with an ACTIVEMQMODE value in the last 10 minutes?
  yes -> healthy, no problem
  no  -> one problem "EIP - ND Mode Alerting in case NULL" (high)
         likely cause: EIP database returned NULL
         or: the ND Mode job / log stopped writing
         or: log forwarding to Dynatrace broke
Problem fires all the time right after apply?
  -> ACTIVEMQMODE is not an attribute (check.dql query 2)
  -> parse it from content, then re-plan
```

## Short takeaway

| Question | Answer |
|---|---|
| What should the alert catch? | No ND Mode log entries for 10 minutes. |
| Does the Splunk alert work today? | No. `stats count` always returns 1 row, so "results > 1" never fires. |
| Dynatrace pattern | Absence check: `summarize countIf(...)` then `filter event_count == 0`. |
| Identity | Constant `check`, so one problem at a time. |
| Severity | high (Splunk priority High). |
| PagerDuty | "0" (email only). |

## Summary

The Splunk alert's description says "fire if ND Mode logs stop for 10 minutes", but the search can't do that: it looks at 1 minute and its trigger can never be true. The Dynatrace detector implements the description: count ND Mode entries with a mode value in the last 10 minutes, and open a problem when the count is 0.

## Why the Splunk alert never fires

| Part | What it really does |
|---|---|
| `ACTIVEMQMODE!=A OR ACTIVEMQMODE!=B OR ...` | Every value differs from at least one letter, so this is true for any event that has ACTIVEMQMODE. It just means "the field has a value". |
| `timechart span=10m count` | Over a 1-minute range, this gives 1 or 2 time buckets. |
| `stats count as event_count` | Counts the buckets, not the events. The result is always exactly 1 row. |
| Trigger: Number of Results > 1 | 1 row is never greater than 1, so the alert can't fire. |
| Time range: Last 1 minute | The description says 10 minutes. |

## Splunk to Dynatrace mapping

| Splunk piece | Dynatrace |
|---|---|
| `index=eip10 sourcetype=eip_nd_mode` | `matchesValue(log.source, "*eip_nd_mode*")` (CONFIRM with check query 1) |
| ACTIVEMQMODE has a value | `countIf(isNotNull(ACTIVEMQMODE) and ACTIVEMQMODE != "" and ACTIVEMQMODE != "NULL")` |
| 10-minute interval (from the description) | `from:now()-10m` |
| Count is 0 | `filter event_count == 0` |
| Trigger Once | Constant identity `check` |
| Email, priority High | severity high, pagerduty "0" (recipients not copied) |

## Terraform

Full file: `16-eip-nd-mode-null-alert-tf.tf`. Query:

```
fetch logs, from:now()-10m
| filter matchesValue(log.source, "*eip_nd_mode*")
| summarize event_count = countIf(isNotNull(ACTIVEMQMODE) and ACTIVEMQMODE != "" and ACTIVEMQMODE != "NULL")
| filter event_count == 0
| fieldsAdd check = "eip_nd_mode_null"
```

`summarize` without `by` always returns one row, even when no logs match. That is what makes the absence check work.

## Data flow

```
EIP database -> ND Mode job -> eip_nd_mode log -> Dynatrace Grail
  -> Records detector (every minute, last 10 min)
  -> event_count == 0 ? -> problem (high, app EIP) -> workflow -> email
```

## Investigation

| What I checked | What I found |
|---|---|
| Description | Intends a 10-minute "no entries" alert. |
| Search | OR of `!=` terms, then timechart, then stats count. |
| Time range | Last 1 minute, cron every minute. |
| Trigger | Number of Results > 1, Once, no throttle. |
| Action | Email, priority High. Recipients not copied. |
| Conclusion | Splunk can never fire. It's a dead alert today. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to find the real `log.source` for ND Mode logs. |
| 2 | Run query 2. If ACTIVEMQMODE is null everywhere, parse it from `content` first. |
| 3 | Run query 3 to see if any 10-minute bucket was 0 in the last day (expected alert count). |
| 4 | `terraform plan` and `terraform apply` from `16.sh`. |
| 5 | Tell the EIP team the Splunk alert never fired, so a new Dynatrace alert may surface old gaps. |

## Related files

| File | What it is |
|---|---|
| `16-eip-nd-mode-null-alert-tf.tf` | The detector |
| `16-eip-nd-mode-null-alert-tf-check.dql` | Dynatrace checks |
| `16-eip-nd-mode-null-alert-tf.spl` | Splunk checks |
| `16.sh` | Commands |

## Commands

From `16.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/16-eip-nd-mode-null-alert-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
