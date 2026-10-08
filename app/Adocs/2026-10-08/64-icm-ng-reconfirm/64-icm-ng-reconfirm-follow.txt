# ICM NG Reconfirm

## Decision tree

```
Edit Alert screenshot, title cut off
 tail = test_result (PASSED) + type "Functionally" + event > 0? → jenkins_statistics template
 cron */3 + 2 hours + Triggered Alerts Medium + Alert Status Manager? → only ICM has this combination (seq 30/40)
 anything different from seq 40? → no
 PagerDuty visible? → no (cut off below Alert Status Manager) → keep "0", CONFIRM
 → same resource icm_realtime_functional_ng → apply from ONE folder only (40 or 64)
 title is NOT ICM? → tell me the title; Cockpit360, FCR and Compass use cron */1 and High
```

## Short takeaway

| Question | Answer |
|---|---|
| Which alert is this? | Prod_Life_ICM_RealTimeAndFunctionalCheck_NG, matched by its settings. The title is not in the screenshot. |
| Is it new? | No. It is the same as seq 40. |
| What changed in the tf? | Nothing. Seq 64 is a copy of seq 40 with a note. |
| Severity | medium, because the Splunk Triggered Alerts severity is Medium. |
| PagerDuty | "0" until you check the Alert Status Manager PagerDuty setting. |
| Which folder to apply? | One folder only: seq 40 or seq 64. |

## Summary

The screenshot shows the end of the `jenkins_statistics` search plus the schedule and actions. Every visible setting matches ICM from seq 40, so the Terraform does not change. The only open point is the PagerDuty setting, which is below the visible area again.

## Investigation

| What I checked | What I found |
|---|---|
| Search tail | `test_result` from `teststatus="PASSED"`, `stats ... by name`, `status` OK if any SUCCESS, `type="Functionally"`. This is the jenkins_statistics template. |
| Last lines | `check_maintenance_window`, `add_alert_info`, `search event > 0 OR (status="OK" AND prev_status="NG")`. Same as seq 40. |
| Schedule | Cron `*/3`, last 2 hours, expires 24 hours. |
| Trigger | Number of results greater than 0, once, for each result, no throttle. |
| Actions | Add to Triggered Alerts with Severity Medium, and Alert Status Manager. |
| Other alerts with this combination | None today. Cockpit360, FCR and Compass run every minute with high severity. |
| PagerDuty | Not visible. |

## Result

| Setting | Seq 40 | Seq 64 |
|---|---|---|
| Resource | `icm_realtime_functional_ng` | same |
| Query | jenkins_statistics template, `cfg.application == "Claims ICM"`, 2 hours | unchanged |
| Judgement | `rt_fails >= 2 and rt_oks == 0` | unchanged |
| Severity | medium | medium |
| pagerduty.enabled | "0" | "0" (CONFIRM) |

If the Alert Status Manager shows PagerDuty Enable, change `pagerduty.enabled` to "1" before you apply.

## Data flow map

```
Jenkins (ceaa2099) statistics JSON (job_duration present, audit_trail dropped)
  → applications* = Functional, group-jobs* = Real Time
  → name = "Building ..." with " » " → "/"
  → lookup configuration → application == "Claims ICM"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (medium, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `64-icm-ng-reconfirm.tf` | Detector, same as seq 40 |
| `64-icm-ng-reconfirm-check.dql` | Template shape and Claims ICM lookup rows |
| `64-icm-ng-reconfirm.spl` | Saved search actions, including PagerDuty |
| `64.sh` | Commands |

## Commands

These are in `64.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/64-icm-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
