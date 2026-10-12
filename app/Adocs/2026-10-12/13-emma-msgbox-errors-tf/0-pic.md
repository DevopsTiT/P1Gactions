# Emma MsgBox Errors Pic

```
dynatrace_log_alert → Records detector
 threshold > 5 → summarize count → filter matches > 5
 status error or warn, not DeprecationWarning → kept
 MEDIUM → alert.severity medium
 no PagerDuty → pagerduty.enabled "0"
```

```
message-box-api logs → CloudWatch → Grail → detector (5m, count > 5) → problem (medium) → workflow → email
```
