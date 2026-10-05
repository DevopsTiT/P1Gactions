# SA Support Batches Alerts Check Pic

```
sa-support-batches.tf (3 × dynatrace_log_alert → plan fails)
  alert 1 "error"            → detector, caseSensitive: false
  alert 3 "Task timed out"   → detector, shares email with alert 1
  alert 2 < 2 lines in 24 h  → weekday 08:30 scheduled workflow
  alert 2 OR "started"       → too broad, hides missed import → runner AND importSagaFundGroup (confirm)
  $name$, "Optional"         → real subject, descriptions
```
