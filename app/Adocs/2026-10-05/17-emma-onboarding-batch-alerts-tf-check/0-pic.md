# Emma Onboarding Batch Alerts Check Pic

```
myaxa-onboarding-batch.tf (5 × dynatrace_log_alert → plan fails)
  5 copies, one log group   → for_each map, 5 detectors
  > 0 every 5 min, no throttle → window 5, dealerting 5
  case-sensitive contains   → caseSensitive: false
  alert 2 "error" broad     → check.dql sample
  subject $name$            → {{ event()["event.name"] }}
  "Optional" description    → real text
  _High, email only         → ask: PagerDuty or not?
```
