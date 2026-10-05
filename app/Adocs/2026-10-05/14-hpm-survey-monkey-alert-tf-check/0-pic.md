# HPM Survey Monkey Alert Check Pic

```
hpm-survey-monkey.tf (dynatrace_log_alert → plan fails)
  hourly, 60 min, throttle 60  → detector window 5, dealerting 60
  problem MEDIUM               → alert.severity medium
  _Normal                      → email workflow only, no PagerDuty
  status == ERROR or ERROR     → OK, caseSensitive: false
  typos                        → Lambda, SurveyMonkey
```
