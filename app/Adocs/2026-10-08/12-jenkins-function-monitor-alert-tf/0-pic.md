# Jenkins Function Monitor Pic

```
ceaa2099 job statistics (120 min)
 → applications* or group-jobs*, finished
 → lookup application, pager_duty == 0 only
 → per application + job: fails >= 2 and no SUCCESS?
    yes → problem → email, no PagerDuty
    no  → nothing (closes on first SUCCESS)
```
