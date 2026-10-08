# HPM Hourly Duplicate Reconfirm

## Decision tree

```
Prod_Life_HPM_RealTimeAndFunctionalCheck_NG (shown again)
 seen before? → yes, seq 28 (duplicate review)
 search filter? → where application="HPM_Owner_Portal" → same jobs as HPM Owner Portal (seq 27 / 60)
 difference? → seq 28 saw cron "0 * * * *" (hourly), Expires 1 hour; not visible this time
 → recommendation unchanged: do not migrate
   seq 27/60 detector checks the same jobs every minute and keeps one problem open until SUCCESS
 team needs a separately routed copy? → optional tf, enabled = false, different resource name
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. Seq 28 reviewed it. |
| What is it? | An hourly copy of the HPM Owner Portal check, with the same search and `application="HPM_Owner_Portal"`. |
| Should it be migrated? | No. `hpm_owner_portal_realtime_functional_ng` (seq 27/60) already covers the same jobs every minute. |
| Optional tf | `hpm_hourly_realtime_functional_ng`, `enabled = false`, only if a separate route is needed |

## Summary

This alert has a different title but watches exactly the same HPM Owner Portal jobs. In Dynatrace, one detector keeps a single problem open until the job succeeds, so an hourly reminder copy adds nothing but duplicate noise. The optional tf from seq 28 is kept switched off in case the team wants a separately routed copy.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE`. Same as HPM Owner Portal. |
| Application filter | `where application="HPM_Owner_Portal"`, not a separate "HPM" application. |
| Schedule and actions | Not visible this time. Seq 28 saw an hourly cron (`0 * * * *`) and Expires 1 hour. |
| Splunk check | `.spl` line 1 lists every `Prod_Life_HPM*` alert with its cron and actions, so you can compare them side by side. |

## Result

| Item | Value |
|---|---|
| Recommendation | Do not migrate. Keep only `hpm_owner_portal_realtime_functional_ng`. |
| Optional resource | `hpm_hourly_realtime_functional_ng` |
| enabled | false |
| Severity | high |
| pagerduty.enabled | "0" |

## Data flow map

```
Same Jenkins jobs (application HPM_Owner_Portal)
  ├─ Splunk: Prod_Life_HPM_Owner_Portal_... (every minute)  → Dynatrace seq 27/60 detector (kept)
  └─ Splunk: Prod_Life_HPM_...              (hourly copy)   → not migrated (optional tf, disabled)
```

## Related files

| File | What it is |
|---|---|
| `61-hpm-hourly-duplicate-reconfirm-optional.tf` | Optional disabled copy (from seq 28) |
| `61-hpm-hourly-duplicate-reconfirm-providers.tf` | Provider block |
| `61-hpm-hourly-duplicate-reconfirm.spl` | All Prod_Life_HPM* alerts with cron and actions, fire history |
| `61.sh` | Commands |

## Commands

These are in `61.sh`. Nothing has been run. Only apply if you decide to keep the optional copy.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/61-hpm-hourly-duplicate-reconfirm"
terraform init
terraform validate
terraform plan
```
