# PowerCenter Down Alerts Check

## Decision tree

```
3 Splunk alerts, same search: index="powercenter" ISP_MASTER_ELECT_LOCK
 same search, different thresholds? → yes (> 0 per 15 min, > 2 per 1 min, > 3 per 1 min)
   does "> 0" fire whenever "> 2" or "> 3" fires? → yes → the 2 Normal alerts add nothing
     → merge into 1 detector (High, any line)
 is the line rare or constant background? → check.dql query 2
   rare (0 most minutes)          → keep threshold "0"
   1-2 per minute is normal       → set threshold "2" (matches the old 0031 alert)
 which field is index="powercenter"? → check.dql query 1 → fix the CONFIRM line
 need email? → user asked Terraform only → standard flow handles paging
```

## Short takeaway

| Question | Answer |
|---|---|
| Are the 3 alerts different? | No. Same search, only the thresholds and time ranges differ |
| How many detectors? | One. The "> 0 in 15 minutes" alert already covers the other two |
| Biggest Splunk problem | PowerCenter-ProcessStop checks the last 15 minutes every minute, so one event emails up to 15 times |
| Severity | High, taken from PowerCenter-ProcessStop |
| What must be confirmed | The Dynatrace field that replaces `index="powercenter"` |

## Summary

All three alerts look for the text `ISP_MASTER_ELECT_LOCK` in PowerCenter logs. The High one fires on any single line, so the two Normal ones (more than 2 or 3 lines per minute) can never fire on their own. One Dynatrace detector replaces all three and opens a single problem that stays open until 15 quiet minutes pass, instead of repeated emails.

## The three Splunk alerts

| Alert | Time range | Runs | Fires when | Priority |
|---|---|---|---|---|
| 0031_MWSP-PowerCenter-Service-Down-Alert | Last 1 minute | Every minute | More than 2 lines | Normal |
| PowerCenter-ProcessStop | Last 15 minutes | Every minute | More than 0 lines | High |
| Powercenter down | Last 1 minute | Every minute | More than 3 lines | Normal |

## Issues found

| Issue | What it means |
|---|---|
| Three alerts for one signal | Recipients get up to three emails for the same event |
| 15-minute window checked every minute | One line is counted 15 times in a row, so ProcessStop can email up to 15 times |
| No throttle on any alert | Nothing stops the repeats above |
| Normal alerts are covered by the High one | "> 2" and "> 3" can only be true when "> 0" is already true |
| ProcessStop description says "Optional" | The description was never filled in |
| Subject uses `$name$` | Splunk token; Dynatrace uses the detector name instead |
| Case sensitivity | Splunk search terms ignore case; DQL needs `caseSensitive: false` |

## Dynatrace settings

| Setting | Value | Why |
|---|---|---|
| Query | Count lines containing `ISP_MASTER_ELECT_LOCK` per minute, per host | Same as the Splunk search |
| Threshold | 0, ABOVE | Any line, like PowerCenter-ProcessStop |
| Violating samples | 1 of 5 | Fire on the first minute that has a line |
| Dealerting samples | 15 | Stay one problem until 15 quiet minutes, like the old 15-minute window |
| `alert.severity` | high | From ProcessStop |
| `dt.source_entity` | The host | Lets the standard SILVA and PagerDuty flow find host tags for routing |

Terraform: `28-powercenter-down-alerts-check.tf`

```hcl
query = <<-EOT
  fetch logs
  | filter matchesValue(log.source, "*powercenter*")   // CONFIRM
  | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive: false)
  | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
EOT
threshold = "0"   ABOVE   violating 1   window 5   dealerting 15
```

## Data flow

```
PowerCenter server log
   → OneAgent ships log to Grail
   → detector query every minute: count ISP_MASTER_ELECT_LOCK per host
   → count > 0 → CUSTOM_ALERT problem "Prod_MWSP_PowerCenter_ServiceDown_High" on the host
   → standard flow → SILVA ticket + PagerDuty (host tags give the group)
   → 15 quiet minutes → problem closes
```

## Investigation

| Checked | Found |
|---|---|
| Search text in all 3 screenshots | Identical: `index="powercenter" ISP_MASTER_ELECT_LOCK` |
| Time ranges | 1 minute, 15 minutes, 1 minute |
| Cron | Every minute for all three |
| Trigger thresholds | > 2, > 0, > 3 results |
| Throttle | Off on all three |
| Recipients | MW and infra middleware lists (not copied in full) |

## Result

| Step | Action |
|---|---|
| 1 | Run `check.dql` query 1 and replace the `log.source` guess with the real field |
| 2 | Run query 2. If lines appear in most minutes, change threshold to "2" |
| 3 | Run query 3 to read real lines and confirm they mean "service down" |
| 4 | `terraform plan` should show 1 detector |
| 5 | After cutover, disable all three Splunk alerts together |

Email is not sent by this file. If the MW team still wants email, add a workflow later.

## Related files

| File | Purpose |
|---|---|
| `28-powercenter-down-alerts-check.tf` | The detector |
| `28-powercenter-down-alerts-check-check.dql` | Field, volume and raw-line checks |
| `28.sh` | Commands |

## Commands

See `28.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
