# EIP ND Mode Null Confirmed

## Decision tree

```
Clearer screenshot of "EIP - ND Mode Alerting in case NULL"
  any setting different from seq 16?
    no  -> tf from seq 16 stays the same (copied here)
  does the clearer photo change the "never fires" finding?
    no  -> Last 1 minute + stats count = always 1 row, trigger needs > 1
  next -> run check.dql, then plan and apply
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 16, in a clearer photo. |
| Did any setting change? | No. Search, time range, cron, trigger and action all match. |
| Does Splunk fire today? | No. `stats count` always returns 1 row, and the trigger needs more than 1. |
| Terraform change? | None. Resource `eip_nd_mode_null`, copied unchanged. |

## Summary

Every field in the clearer screenshot matches what seq 16 used, so the detector is unchanged. The clearer photo also confirms the Splunk bug: even when the 1-minute window crosses a 10-minute boundary, `timechart` gives 2 rows and `stats count` collapses them back to 1 row.

## Settings checked again

| Setting | Screenshot | Seq 16 used |
|---|---|---|
| Search | `index=eip10 sourcetype=eip_nd_mode (ACTIVEMQMODE!=A OR ... !=D)`, timechart span=10m, stats count | Same |
| Time range | Last 1 minute | Same |
| Cron | `*/1 * * * *` | Same |
| Trigger | Number of Results greater than 1, Once | Same |
| Throttle | Off | Same |
| Action | Send email, priority High | Same (recipients not copied) |

## Rows Splunk returns in every case

| Situation | Rows after timechart | Rows after stats count | Fires? |
|---|---|---|---|
| Logs arriving normally | 1 | 1 | No |
| No logs at all | 1 (count 0) | 1 | No |
| Window crosses a 10-minute boundary | 2 | 1 | No |

## Terraform

`17-eip-nd-mode-null-confirmed-tf.tf` (same as seq 16):

```
fetch logs, from:now()-10m
| filter matchesValue(log.source, "*eip_nd_mode*")
| summarize event_count = countIf(isNotNull(ACTIVEMQMODE) and ACTIVEMQMODE != "" and ACTIVEMQMODE != "NULL")
| filter event_count == 0
| fieldsAdd check = "eip_nd_mode_null"
```

Severity high, app EIP, pagerduty "0", identity `check`.

## Data flow

```
EIP DB -> ND Mode log -> Grail -> detector (10m count) -> 0? -> problem (high) -> email
```

## Investigation

| What I checked | What I found |
|---|---|
| Clearer screenshot vs seq 16 | Every setting matches. |
| Boundary case | Two timechart buckets still become one stats row. |

## Result

| Step | What to do |
|---|---|
| 1 | Run the check queries (source, ACTIVEMQMODE attribute, past 10-minute gaps). |
| 2 | Plan and apply from `17.sh`. |
| 3 | If seq 16 was already applied, do nothing; it is the same resource. |

## Related files

| File | What it is |
|---|---|
| `17-eip-nd-mode-null-confirmed-tf.tf` | Detector (same as seq 16) |
| `17-eip-nd-mode-null-confirmed-tf-check.dql` | Dynatrace checks |
| `17-eip-nd-mode-null-confirmed-tf.spl` | Splunk checks |
| `17.sh` | Commands |

## Commands

From `17.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/17-eip-nd-mode-null-confirmed-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
