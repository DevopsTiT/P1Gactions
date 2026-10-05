# Customer Process API Alerts Check Pic

```
customer-process-api.tf
  both dynatrace_log_alert              → do not exist → plan fails

  ALERT 1 success (statusCode 201)
    failure? no → no problem, no SILVA
    → scheduled workflow */5 → DQL [now-6m, now-1m] → email lines if any

  ALERT 2 failures (9 messages)
    → anomaly detector, lower(content), window 5
    → problem → email workflow → aij_jp_dl_adept
```
