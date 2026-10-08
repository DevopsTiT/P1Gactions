# HPM Owner Portal Check NG Reconfirm

## Decision tree

```
Prod_Life_HPM_Owner_Portal_RealTimeAndFunctionalCheck_NG (shown again)
 search same as seq 27? → yes (jenkins/test template, application="HPM_Owner_Portal")
 window / cron? → Last 2 hours, */1 → same
 actions visible? → no (cut off) → keep seq 27 value: PagerDuty Enable → pagerduty "1"
 → no tf change: reuse seq 27 hpm-owner-portal tf
 → same resource name hpm_owner_portal_realtime_functional_ng → apply from ONE folder only
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 27. |
| Anything changed? | No. The search, the 2-hour window and the `*/1` cron all match. |
| Which tf to use? | The seq 27 tf, unchanged. |
| Severity and PagerDuty | high and "1" (seq 27 saw PagerDuty Enable) |

## Summary

These screenshots show the HPM Owner Portal check again, with nothing new. The detector opens one problem per job when the counted jobs (everything except App-Ops Functional jobs) have 2 or more non-SUCCESS results in 2 hours with no SUCCESS. PagerDuty stays on, as seen in seq 27.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE`. Same. |
| Application | `where application="HPM_Owner_Portal"`. Same. |
| Last line | `search event=2 OR (status="OK" AND prev_status="NG")`. Same. |
| Schedule | Last 2 hours, `*/1`, expires 24 hours, once, for each result, no throttle. |
| Actions | Cut off at Trigger Actions. Seq 27 saw Alert Status Manager, Production, PagerDuty Enable. |

## Result

| Setting | Value |
|---|---|
| Resource | `hpm_owner_portal_realtime_functional_ng` (same as seq 27) |
| Opens when | `fails >= 2 and oks == 0` in 2 hours |
| Severity | high |
| pagerduty.enabled | "1" |

## Data flow map

```
Jenkins (ceaa2099) build_report JSON (source jenkins/test)
  → drop ABORTED / FAILURE, drop statistics events
  → App-Ops Real Time Check renamed to Functional project; Functional runs not judged
  → lookup configuration → application == "HPM_Owner_Portal"
  → per application+name in 2h: fails >= 2 and oks == 0
  → problem (high, pagerduty 1) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `60-hpm-owner-portal-ng-reconfirm-providers.tf` | Provider block |
| `60-hpm-owner-portal-ng-reconfirm.tf` | Copy of the seq 27 detector |
| `60-hpm-owner-portal-ng-reconfirm-check.dql` | jenkins/test shape, lookup rows, job names |
| `60-hpm-owner-portal-ng-reconfirm.spl` | Job results by application, lookup rows |
| `60.sh` | Commands |

## Commands

These are in `60.sh`. Nothing has been run. Apply from one folder only (27 or 60).

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/60-hpm-owner-portal-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
