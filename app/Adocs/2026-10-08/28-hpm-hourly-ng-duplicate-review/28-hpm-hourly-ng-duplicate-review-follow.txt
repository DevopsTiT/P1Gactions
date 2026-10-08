# HPM Hourly NG Duplicate Review

## Decision tree

```
Prod_Life_HPM_RealTimeAndFunctionalCheck_NG
  search body different from HPM Owner Portal (seq 27)?
    no -> same search, same application "HPM_Owner_Portal"
  what differs?
    cron 0 * * * * (hourly) instead of every minute, Expires 1 hour
  does Dynatrace need a second detector?
    no -> seq 27 detector checks every minute and keeps the problem open until SUCCESS
    only if the team wants a separate hourly route -> use the optional tf (created disabled)
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new check? | No. Same search as HPM Owner Portal, application "HPM_Owner_Portal". |
| What is different? | Runs hourly at :00 instead of every minute; Expires 1 hour. |
| Migrate it? | Not needed. The seq 27 detector already covers it. |
| Why did Splunk have two? | Most likely an hourly reminder or summary mail next to the every-minute pager alert. |
| If you must keep it | `28-...-optional.tf`, created with `enabled = false`. |

## Summary

Both Splunk alerts read the same jenkins/test data, filter the same application and use the same NG rule. Splunk needed a second, hourly alert to repeat or summarise NG states. Dynatrace does not: one detector keeps a single problem open until the job succeeds, and notification workflows can send reminders if the team wants them.

## Side by side

| Setting | HPM Owner Portal (seq 27) | HPM (this one) |
|---|---|---|
| Search | Same template | Same template |
| Application filter | HPM_Owner_Portal | HPM_Owner_Portal |
| Time range | Last 2 hours | Last 2 hours |
| Cron | Every minute | Hourly at :00 |
| Expires | 24 hours | 1 hour |
| Actions | Alert Status Manager, PagerDuty Enable | Not visible in the screenshot |

## Options

| Option | What it means | When to pick it |
|---|---|---|
| Do not migrate | Retire this Splunk alert when seq 27 goes live | Default; one detector is enough |
| Hourly reminder | Add a reminder step in the Dynatrace notification workflow for open HPM problems | If people relied on the hourly mail |
| Separate detector | Apply `28-...-optional.tf` and set `enabled = true` | Only if it must route to a different team |

## Data flow

```
jenkins/test (ceaa2099) -> Grail
  -> seq 27 detector hpm_owner_portal_realtime_functional_ng (every minute)
  -> one problem per job until SUCCESS -> PagerDuty + email
  (hourly Splunk copy not needed)
```

## Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as seq 27 HPM Owner Portal, including `where application="HPM_Owner_Portal"`. |
| Schedule | Cron `0 * * * *`, Last 2 hours, Expires 1 hour. |
| Trigger | event=2 or recovery, results > 0, Once, no throttle. |
| Actions | Not visible (screenshot ends at Trigger Actions). |

## Result

| Step | What to do |
|---|---|
| 1 | Run the `.spl` queries to compare both alerts' actions and how often each fired. |
| 2 | If the hourly one only emails the same people, retire it with seq 27. |
| 3 | If it routes elsewhere, copy the optional tf into the seq 27 folder and set `enabled = true`. |

## Related files

| File | What it is |
|---|---|
| `28-hpm-hourly-ng-duplicate-review-optional.tf` | Optional detector, disabled |
| `28-hpm-hourly-ng-duplicate-review.spl` | Splunk checks for both HPM alerts |
| `28.sh` | Commands |
| `../27-hpm-owner-portal-ng-and-jenkins-test-fix-tf/` | The detector that covers this alert |

## Commands

From `28.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/27-hpm-owner-portal-ng-and-jenkins-test-fix-tf"
terraform plan
```
