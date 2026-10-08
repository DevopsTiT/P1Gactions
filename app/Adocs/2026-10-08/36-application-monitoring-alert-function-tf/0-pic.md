# Application Monitoring Function Pic

```
Functional job NG? (2+ fails, 0 SUCCESS, 2h)
 app pager_duty = "0"? → no → not this alert
 yes → problem (application + job)
   remarks = maintenance? → planned, wait
   no remarks → check Jenkins console
```

```
build events + console maintenance lines → join on build_url
  → configuration pager_duty == "0" → fn_fails >= 2, fn_oks == 0 → problem
```
