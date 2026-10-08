# Jenkins URL Monitor Pic

```
"[HTTP Monitor]" lines (last 15 min)
 → name from job path, responsecode from line
 → lookup application, pager_duty
 → per application + name: fails >= 2 and oks == 0?
    yes → problem → pager_duty 0? email only : PagerDuty
    no  → nothing (or problem closes on a 200)
```
