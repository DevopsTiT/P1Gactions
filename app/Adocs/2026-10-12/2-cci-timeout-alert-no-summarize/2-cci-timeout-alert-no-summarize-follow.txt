# CCI Timeout Alert Without Summarize

## Decision tree

```
Remove summarize from the timeout detector?
 yes → query returns raw log lines
   any line found → problem opens
   identity field aws.log_group → still one open problem, not one per line
   lose the count, first/last time and sample columns → read the log lines on the problem instead
 many timeouts in 6 minutes? → still fine; one problem, more rows behind it
```

## Short takeaway

| Question | Answer |
|---|---|
| Can the summarize go? | Yes. The detector only needs rows to exist. |
| Does it change when it alerts? | No. One timeout line still opens the problem. |
| Does it create more problems? | No. `alertIdentityFields = aws.log_group` still groups them into one. |
| What do you lose? | The handy `timeouts`, `first_seen`, `last_seen` and `sample` columns. |

## Summary

The `summarize` step was there only to make the problem easier to read. The detector alerts whenever the query returns rows, so dropping it doesn't change when or how often it fires. The event description now points to the log lines instead of the removed columns.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| `summarize` | Groups rows and calculates totals, such as a count. | Optional here; only makes the output tidier. |
| Records detector | Opens a problem when the query returns at least one row. | Raw rows are enough to trigger it. |
| `alertIdentityFields` | Fields that decide whether rows belong to the same problem. | Keeps one problem per log group even with many lines. |

### What changed from seq 1

| Part | Seq 1 | Seq 2 |
|---|---|---|
| Query | Filters plus `summarize ... by:{ aws.log_group }` | Filters only |
| Rows returned | One row per log group | One row per timeout log line |
| Identity field | `aws.log_group` | `aws.log_group` (unchanged) |
| Event description | Mentions timeouts, first_seen, last_seen, sample | Mentions the log lines (content) |

## Result

File: `2-cci-timeout-alert-no-summarize.tf`. The query is now:

```
fetch logs, from:now()-6m
| filter contains(aws.log_group, "cci-fa-comm-calc")
| filter contains(content, "Task timed out", caseSensitive:false)
| filter not contains(content, "[DEBUG]")
```

Event description:

```
Lambda cci-fa-comm-calc timed out. See the matching log lines (content) on the problem.
```

Everything else (title, identity field, severity high, `pagerduty.enabled = "1"`) is the same as seq 1. Both files use the resource name `cci_aws_batch_timeout`, so apply from one folder only.

## Data flow map

```
Lambda timeout
  → CloudWatch Logs "Task timed out"
  → Dynatrace Grail logs
  → Records detector, every minute, last 6 minutes (raw lines)
      lines found → one problem per log group
      no lines    → problem closes
  → workflow → PagerDuty and email
```

## Related files

| File | What it is |
|---|---|
| `2-cci-timeout-alert-no-summarize.tf` | Updated Terraform |
| `2-cci-timeout-alert-no-summarize-check.dql` | Field and history check queries (same as seq 1) |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | What changed |
| `2-result.md` | Final query |
| `3-glossary.md` | Terms |
| `2.sh` | Commands |

## Commands

All commands are in [`2.sh`](2.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/2-cci-timeout-alert-no-summarize"
terraform init
terraform validate
terraform plan
```
