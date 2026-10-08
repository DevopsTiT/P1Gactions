# HPM Hourly Duplicate PagerDuty Enable

## Decision tree

```
Prod_Life_HPM_RealTimeAndFunctionalCheck_NG (full settings now visible)
 search filter? → application="HPM_Owner_Portal" → same jobs as HPM Owner Portal (seq 27 / 60)
 cron? → 0 * * * * (hourly), Expires 1 hour, Last 2 hours
 actions? → Alert Status Manager, Production, PagerDuty Enable
 does the kept detector page? → yes, hpm_owner_portal_realtime_functional_ng has pagerduty "1"
 → paging is covered → still do not migrate
 optional copy kept? → pagerduty "1" now (was "0" in seq 28/61), still enabled = false
```

## Short takeaway

| Question | Answer |
|---|---|
| What's new? | The actions are visible: Alert Status Manager, Production, PagerDuty Enable. |
| Does that change the recommendation? | No. The HPM Owner Portal detector (seq 27/60) already pages for the same jobs. |
| What changed in the files? | The optional copy now has `pagerduty.enabled = "1"`, matching Splunk. It stays disabled. |
| Should it be migrated? | No. Keep only `hpm_owner_portal_realtime_functional_ng`. |

## Summary

With the full settings visible, this alert is an hourly copy of HPM Owner Portal that also pages. The every-minute HPM Owner Portal detector already pages for the same jobs and keeps one problem open until the job succeeds, so nothing is lost by not migrating this copy. The optional tf now matches Splunk's PagerDuty setting, in case the team still wants it.

## Investigation

| What I checked | What I found |
|---|---|
| Search | Same as HPM Owner Portal, including `where application="HPM_Owner_Portal"`. |
| Time range | Last 2 hours. |
| Cron | `0 * * * *`, once an hour at minute 0. |
| Expires | 1 hour. |
| Trigger | Results > 0, once, for each result, no throttle. |
| Action | Alert Status Manager, Production email. I did not copy the recipients. |
| PagerDuty | Enable. A URL was visible, and I did not copy it. |

### Hourly copy compared with HPM Owner Portal

| Setting | HPM Owner Portal (kept) | HPM hourly copy |
|---|---|---|
| Jobs watched | HPM_Owner_Portal | HPM_Owner_Portal |
| Cron | `*/1` | `0 * * * *` |
| PagerDuty | Enable | Enable |
| Dynatrace | `hpm_owner_portal_realtime_functional_ng`, enabled | Not migrated (optional, disabled) |

## Result

| Item | Value |
|---|---|
| Recommendation | Do not migrate |
| Optional resource | `hpm_hourly_realtime_functional_ng` |
| enabled | false |
| Severity | high |
| pagerduty.enabled | "1" (was "0" in seq 28 and 61) |

## Data flow map

```
Same Jenkins jobs (application HPM_Owner_Portal)
  ├─ Splunk: Prod_Life_HPM_Owner_Portal_... (every minute, PD Enable) → Dynatrace seq 27/60 (kept, pagerduty 1)
  └─ Splunk: Prod_Life_HPM_...              (hourly, PD Enable)       → not migrated (optional, disabled, pagerduty 1)
```

## Related files

| File | What it is |
|---|---|
| `62-hpm-hourly-duplicate-pd-enable-optional.tf` | Optional disabled copy with pagerduty "1" |
| `62-hpm-hourly-duplicate-pd-enable-providers.tf` | Provider block |
| `62-hpm-hourly-duplicate-pd-enable.spl` | All Prod_Life_HPM* alerts with cron and actions, fire history |
| `62.sh` | Commands |

## Commands

These are in `62.sh`. Nothing has been run. Only apply if you decide to keep the optional copy.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/62-hpm-hourly-duplicate-pd-enable"
terraform init
terraform validate
terraform plan
```
