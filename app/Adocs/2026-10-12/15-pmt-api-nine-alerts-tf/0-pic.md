# PMT API Nine Alerts Pic

```
9 x dynatrace_log_alert → 1 resource with for_each (9 detectors)
 Alert 2 parse LD → null → never fires → fixed with INT
 Alerts 6 and 7 identical → delete one
 Alert 9 "occured" → check real spelling
 60s throttles → no effect → dropped
 all → medium, pagerduty.enabled "0"
```

```
pmt-api logs → CloudWatch → Grail → 9 detectors (5m) → problems (medium) → workflow → email
```
